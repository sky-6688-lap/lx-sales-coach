#!/usr/bin/env bash
# 发布前机械校验：结构、frontmatter、链接、红线关键词、文件规模
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="$(command -v python3 || command -v python || true)"
if [[ -z "$PY" ]]; then
  echo "校验失败：找不到 python3 / python" >&2
  exit 1
fi

"$PY" - "$repo_root" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
errors = []
warnings = []

# 1. 必需文件
required = [
    "SKILL.md", "README.md", "VERSION.md", "CHANGELOG.md", "LICENSE",
    "agents/openai.yaml",
    "tests/test-cases.md", "tests/regression-checklist.md",
    "scripts/verify-release.sh", "scripts/install-local.sh",
]
for rel in required:
    if not (root / rel).is_file():
        errors.append(f"缺少必需文件：{rel}")

# 2. frontmatter 与目录名一致
skill_path = root / "SKILL.md"
if skill_path.is_file():
    skill = skill_path.read_text(encoding="utf-8")
    if not skill.startswith("---\n"):
        errors.append("SKILL.md 缺少 frontmatter")
    if f"name: {root.name}" not in skill.split("---", 2)[1]:
        errors.append(f"SKILL.md 的 name 与目录名 {root.name} 不一致")
    for key in ["description:", "agent_created:", "short-description:"]:
        if key not in skill:
            errors.append(f"SKILL.md 缺少 {key}")
    required_sections = [
        "## 一、运行时不可丢失的规则",
        "## 三、第一道门禁（硬性）",
        "## 四、状态机：先判状态，再路由",
        "## 五、回答格式（四段式，缺一不可）",
        "## 六、消息风格六条",
        "## 七、绝对红线",
    ]
    for section in required_sections:
        if section not in skill:
            errors.append(f"SKILL.md 缺少章节：{section}")
else:
    skill = ""

# 3. references 数量与规模
ref_dir = root / "references"
refs = sorted(ref_dir.glob("*.md")) if ref_dir.is_dir() else []
if len(refs) != 81:
    errors.append(f"references 应有 81 篇，实际 {len(refs)} 篇")
nums = sorted(int(p.name.split("-")[0]) for p in refs if "-" in p.name and p.name[:2].isdigit())
if nums != list(range(81)):
    missing = sorted(set(range(81)) - set(nums))
    errors.append(f"references 编号应为 00–80 连续，缺号：{missing}")

all_md = [p for p in root.rglob("*.md") if ".git" not in p.parts]
for p in all_md:
    text = p.read_text(encoding="utf-8")
    if len(text.strip()) < 300:
        errors.append(f"文件内容过短：{p.relative_to(root)}")
    if "TODO" in text or "（此处补）" in text:
        warnings.append(f"存在未写完的占位：{p.relative_to(root)}")

# 4. 相对链接目标存在
link_re = re.compile(r"\]\(([^)]+)\)")
for p in all_md:
    text = p.read_text(encoding="utf-8")
    for target in link_re.findall(text):
        target = target.split("#", 1)[0].strip()
        if not target or target.startswith(("http://", "https://", "mailto:")):
            continue
        resolved = (p.parent / target).resolve()
        if not resolved.exists():
            errors.append(f"悬空链接：{p.relative_to(root)} -> {target}")

# 5. 红线关键词：不得出现第三方产品原文特征
forbidden = [
    "南景", "成交复利系统", "销冠十点", "黄金谈单五步", "钩子成交法",
    "点线面体", "语气词密集", "反问收尾", "说咱们", "追单七阶段",
]
for p in all_md:
    text = p.read_text(encoding="utf-8")
    for word in forbidden:
        if word in text:
            errors.append(f"疑似第三方原文残留：{p.relative_to(root)} 含「{word}」")

# 6. 对外归属与承接模块：只检查引用块（成品消息）里的肯定语境
# 说明性文本、禁止清单、负面案例会引用违规词本身，不纳入检测
negation_markers = [
    "禁止", "不写", "红线", "不许", "不要", "不出现", "不是", "不用",
    "不制造", "不得", "别写", "避免", "删掉", "不夹带", "不承诺", "违规",
]
suspect_words = ["欢迎咨询", "私信领取", "扫码添加", "限时优惠", "今天最后一天", "保证成交"]
for p in all_md:
    for lineno, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
        if not line.lstrip().startswith(">"):
            continue
        for word in suspect_words:
            if word in line and not any(n in line for n in negation_markers):
                errors.append(f"疑似承接/违规表述：{p.relative_to(root)}:{lineno} 含「{word}」")

# 7. VERSION 与 CHANGELOG 版本一致
version = (root / "VERSION.md").read_text(encoding="utf-8") if (root / "VERSION.md").is_file() else ""
changelog = (root / "CHANGELOG.md").read_text(encoding="utf-8") if (root / "CHANGELOG.md").is_file() else ""
m = re.search(r"Version:\s*(v[\d.]+)", version)
if not m:
    errors.append("VERSION.md 缺少版本号")
elif m.group(1) not in changelog:
    errors.append("CHANGELOG.md 没有对应版本的记录")

# 8. 统计
total_chars = sum(len(p.read_text(encoding="utf-8")) for p in all_md)
total_bytes = sum(p.stat().st_size for p in root.rglob("*") if p.is_file())
if total_chars < 160000:
    errors.append(f"内容规模不足：{total_chars:,} 字符，应不低于 16 万字符")
print(f"检查文件：{len(all_md)} 个 markdown，references {len(refs)} 篇，约 {total_chars:,} 字符 / {total_bytes:,} 字节")

for w in warnings:
    print(f"[提示] {w}")
if errors:
    for e in errors:
        print(f"[失败] {e}", file=sys.stderr)
    print(f"校验失败：{len(errors)} 项", file=sys.stderr)
    sys.exit(1)
print("校验通过：结构 / frontmatter / 链接 / 红线关键词 / 版本一致")
PY
