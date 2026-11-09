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
import json
import re
import sys

root = Path(sys.argv[1])
errors = []
warnings = []

# 0. 机器可读基线：篇数与规模从这里读，扩写内容时只改 version.json
meta_path = root / "version.json"
if meta_path.is_file():
    try:
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"version.json 无法解析：{exc}")
        meta = {}
else:
    meta = {}
integ = meta.get("integrity", {})
expected = integ.get("references")
min_chars = integ.get("min_chars", 160000)
min_bytes = integ.get("min_bytes", 390000)
if expected is None:
    errors.append("version.json 缺少 integrity.references")

# 1. 必需文件
required = [
    "SKILL.md", "README.md", "VERSION.md", "CHANGELOG.md", "LICENSE", "version.json",
    "agents/openai.yaml", ".gitignore", ".github/workflows/ci.yml",
    "tests/test-cases.md", "tests/regression-checklist.md", "tests/canary-cases.json",
    "tests/platform-smoke.md",
    "scripts/verify-release.sh", "scripts/install-local.sh", "scripts/run-canary.py",
    "scripts/check-compat.py", "scripts/platform-smoke.sh", "scripts/run-platform-smoke.py",
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
if expected and len(refs) != expected:
    errors.append(f"references 应为 version.json 声明的 {expected} 篇，实际 {len(refs)} 篇")
nums = sorted(int(p.name.split("-")[0]) for p in refs if "-" in p.name and p.name[:2].isdigit())
if expected and nums != list(range(expected)):
    missing = sorted(set(range(expected)) - set(nums))
    errors.append(f"references 编号应为 00–{expected-1:02d} 连续，缺号：{missing}")

# 本机生成的实测记录 / 提示词不参与发布内容校验与规模统计（已在 .gitignore 中排除）
generated = {"tests/canary-prompts.md", "tests/platform-smoke-results.md",
             "tests/.platform-smoke-state.json"}
all_md = [p for p in root.rglob("*.md") if ".git" not in p.parts
          and p.relative_to(root).as_posix() not in generated]
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
else:
    if m.group(1) not in changelog:
        errors.append("CHANGELOG.md 没有对应版本的记录")
    if meta.get("version") and m.group(1) != meta["version"]:
        errors.append(f"VERSION.md 的 {m.group(1)} 与 version.json 的 {meta['version']} 不一致")
    if m.group(1) not in (root / "README.md").read_text(encoding="utf-8", errors="ignore") and "已更新到" + m.group(1) not in version:
        warnings.append("README 未直接出现版本号（通过 VERSION.md 跳转，可接受）")
if not meta.get("version"):
    errors.append("version.json 缺少 version")
if not meta.get("integrity", {}).get("min_chars"):
    errors.append("version.json 缺少内容规模基线")
# canary 条数与声明篇数一致（详细落点检查由 run-canary.py 负责）
canary_path = root / "tests" / "canary-cases.json"
if canary_path.is_file():
    try:
        canary = json.loads(canary_path.read_text(encoding="utf-8"))
        if expected and len(canary.get("cases", [])) != expected:
            errors.append(f"canary 条数 {len(canary.get('cases', []))} 与声明的 {expected} 篇不一致")
    except json.JSONDecodeError as exc:
        errors.append(f"canary-cases.json 无法解析：{exc}")

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
# 按问题查文件表也要逐篇可反查，避免「只有全库速查认得、按问题找不到」
quick_sec = index_text.split("## 二、按问题查文件（速查）")[-1]
quick_sec = quick_sec.split("## 三、")[0] if "## 三、" in quick_sec else quick_sec.split("## 四、")[0]
quick_nums = set()
for line in quick_sec.splitlines():
    if not line.startswith("|"):
        continue
    quick_nums |= {int(x) for x in re.findall(r"(?<!\d)(\d{2})-[a-z]", line)}
    for cell in line.split("|"):
        c = cell.strip()
        if c and re.fullmatch(r"[\d\s/、,，]+", c):
            quick_nums |= {int(x) for x in re.findall(r"\b(\d{2})\b", c)}
missing_quick = sorted(set(range(len(refs))) - quick_nums)
if missing_quick:
    errors.append(f"80 按问题查文件表未覆盖 {len(missing_quick)} 个编号：{missing_quick[:10]}")
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
# 实测暴露的三类硬规则，缺一条就可能退回旧行为
for rule, why in [
    ("加载后只认这一份", "缺少技能隔离声明，实测会串读到其他销售技能的话术文件"),
    ("技能隔离", "运行时规则缺少「不读取其他技能目录」"),
    ("占位符一律方括号", "实测出现过【】占位符，必须写进硬格式规则"),
    ("具体场景优先于状态大类", "缺少细分篇优先规则，实测会只回主篇不进细分文件"),
    ("门禁齐了就直接出结果", "实测出现过背景齐全仍倒回去反问、且不给成品消息"),
    ("动笔前红线闸门", "实测创作类请求会跳过红线、进 16 篇编案例与夹带链接"),
    ("场景例外清单", "实测合规 / 争议 / 渠道会被门禁四项劫持，只给判断不给成品消息"),
    ("红线拒绝的标准输出", "实测红线守住了但第三段只有说明文字，没给引用块里的等价消息"),
    ("例外场景的成品消息同样过规则 12", "实测例外场景出现单条超 60 字的长解释"),
    ("命中后回答的第一句就是边界本身", "实测拒绝句之前仍带角色宣告或先答应后否定的开场白"),
    ("输出第一句规则（全局，优先于以下所有规则）", "角色宣告开场反复出现，需提到文件最顶端"),
]:
    if rule not in skill_text:
        errors.append(f"SKILL.md {why}：缺「{rule}」")
for trigger in ("别问了", "给我一句能发的", "一单一卡", "退款"):
    if trigger not in skill_text.split("---", 2)[1]:
        errors.append(f"description 缺少实测补强的触发词「{trigger}」")
readme = (root / "README.md").read_text(encoding="utf-8") if (root / "README.md").is_file() else ""
for token in ("17–75", "76–80", "81–96"):
    if token not in readme:
        errors.append(f"README 分组与 SKILL/00 不一致，缺少「{token}」")
if "version.json" not in readme:
    errors.append("README 未说明机器可读版本文件 version.json")

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
total_bytes = sum(p.stat().st_size for p in root.rglob("*") if p.is_file()
                  and p.relative_to(root).as_posix() not in generated)
if total_chars < min_chars:
    errors.append(f"内容规模不足：{total_chars:,} 字符，应不低于 version.json 声明的 {min_chars:,}")
if total_bytes < min_bytes:
    errors.append(f"内容规模不足：{total_bytes:,} 字节，应不低于 version.json 声明的 {min_bytes:,}")
print(f"检查文件：{len(all_md)} 个 markdown，references {len(refs)} 篇，约 {total_chars:,} 字符 / {total_bytes:,} 字节")

for w in warnings:
    print(f"[提示] {w}")
if errors:
    for e in errors:
        print(f"[失败] {e}", file=sys.stderr)
    print(f"校验失败：{len(errors)} 项", file=sys.stderr)
    sys.exit(1)
print(f"校验通过：结构 / frontmatter / 链接 / 红线关键词 / 版本一致 / {len(refs)} 篇可达性 / 索引覆盖 / 示例消息长度 / 规则一致性")
PY
