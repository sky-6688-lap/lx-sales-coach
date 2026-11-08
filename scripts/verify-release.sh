#!/usr/bin/env bash
# 发布前机械校验：结构、frontmatter、链接、红线关键词、文件规模、可达性、内容质量
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
        "## 五、回答格式（四段式，默认结构）",
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

# 8. 可达性：81 篇不能出现「写了但永远读不到」的死文件
skill_text = (root / "SKILL.md").read_text(encoding="utf-8") if (root / "SKILL.md").is_file() else ""
router_text = (ref_dir / "00-router.md").read_text(encoding="utf-8") if (ref_dir / "00-router.md").is_file() else ""
index_path = ref_dir / "80-glossary-and-index.md"
index_text = index_path.read_text(encoding="utf-8") if index_path.is_file() else ""
corpus = "\n".join(
    p.read_text(encoding="utf-8") for p in refs
    if p.name not in ("00-router.md", "80-glossary-and-index.md")
)
for p in refs:
    if p.name in ("00-router.md", "80-glossary-and-index.md"):
        continue
    if not any(p.name in t for t in (skill_text, router_text, index_text, corpus)):
        errors.append(f"不可达文件：{p.name} 未被 SKILL.md / 00 / 80 / 其他参考篇点名")

missing_idx = [p.name for p in refs if p.name not in index_text]
if missing_idx:
    errors.append(f"80 全库速查表未点名 {len(missing_idx)} 篇：{missing_idx[:6]}")
if "逐状态精确寻址表" not in skill_text:
    errors.append("SKILL.md 缺少逐状态精确寻址表")
for p in refs[:17]:
    if "## 深挖指引" not in p.read_text(encoding="utf-8"):
        errors.append(f"主链路缺少深挖指引：{p.name}")

# 9. 规则一致性与文档同步
if "四段式，缺一不可" in skill_text:
    errors.append("SKILL.md 仍写「四段式缺一不可」，与 00 / 20 的简化口径冲突")
if "门禁 = 三件事 + 一句客户原话" not in skill_text:
    errors.append("SKILL.md 门禁四项口径未统一")
readme = (root / "README.md").read_text(encoding="utf-8") if (root / "README.md").is_file() else ""
for token in ("17–75", "76–80"):
    if token not in readme:
        errors.append(f"README 分组与 SKILL/00 不一致，缺少「{token}」")

# 10. 成品示例消息长度：示例就是标准，不能自己违反六条风格规则
skip_markers = (".md", "模板示例", "状态 S", "SKILL.md")
skip_prefixes = ("补 ", "本文", "本篇", "相关：", "判断：", "依据：")
long_msgs = []
for p in refs:
    for lineno, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
        if not line.startswith("> ") or line.startswith(">>"):
            continue
        s = line[2:].strip()
        if len(s) < 10 or s.startswith("#") or any(m in s for m in skip_markers) or s.startswith(skip_prefixes):
            continue
        if len(s) > 60:
            long_msgs.append(f"{p.name}:{lineno}（{len(s)} 字）")
if long_msgs:
    errors.append(f"成品示例消息超过 60 字共 {len(long_msgs)} 条：{long_msgs[:6]}")

# 11. 统计
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
print("校验通过：结构 / frontmatter / 链接 / 红线关键词 / 版本一致 / 81 篇可达性 / 索引覆盖 / 示例消息长度 / 规则一致性")
PY
