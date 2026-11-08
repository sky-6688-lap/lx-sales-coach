#!/usr/bin/env python3
"""跨平台静态兼容检查（WorkBuddy / Codex / Claude Code）。

只依赖 Python 标准库，CI 不需要额外安装包。
对照本机 Codex 系统技能 `~/.codex/skills/.system/*/agents/openai.yaml` 的真实格式。
注意：本脚本不启动任何 Agent 运行时，不能替代语义触发实测；实测见 tests/platform-smoke.md。
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOME = Path.home()
errors: list[str] = []
notes: list[str] = []

# 1. SKILL.md frontmatter（三平台共用）
skill_bytes = (ROOT / "SKILL.md").read_bytes()
try:
    skill = skill_bytes.decode("utf-8")
except UnicodeDecodeError:
    print("[失败] SKILL.md 不是 UTF-8", file=sys.stderr)
    sys.exit(1)
fm = re.match(r"^---\s*\n(.*?)\n---\s*\n", skill, re.S)
if not fm:
    errors.append("SKILL.md 缺少以 --- 包裹的 frontmatter")
    front = ""
else:
    front = fm.group(1)

def field(key: str) -> str | None:
    m = re.search(rf"^{re.escape(key)}:\s*(.+)$", front, re.M)
    return m.group(1).strip().strip('"\'') if m else None

name = field("name")
desc = field("description")
if not name:
    errors.append("frontmatter 缺少 name")
elif name != ROOT.name:
    errors.append(f"name={name} 与文件夹名 {ROOT.name} 不一致（三平台都按目录名索引）")
elif not re.fullmatch(r"[a-z0-9-]+", name):
    errors.append("name 只能含小写字母、数字与连字符（Claude Code 约束）")
if not desc:
    errors.append("frontmatter 缺少 description（Agent 靠它决定是否触发）")
elif len(desc) > 1024:
    errors.append(f"description 长 {len(desc)} 字符，超过 1024 上限")
if "short-description:" not in front:
    errors.append("frontmatter 缺少 metadata.short-description（Codex / WorkBuddy 展示用）")
if "agent_created:" in front:
    notes.append("agent_created 为 WorkBuddy 专有字段，Codex / Claude Code 会忽略，属正常差异")
notes.append(f"description 长度 {len(desc or '')} 字符，触发词内联，三平台均可读取")

# 2. agents/openai.yaml（Codex 专属接口文件）
yaml_path = ROOT / "agents" / "openai.yaml"
if not yaml_path.is_file():
    errors.append("缺少 agents/openai.yaml（Codex 展示名与默认提示词）")
else:
    y = yaml_path.read_text(encoding="utf-8")
    if not re.search(r"^interface:\s*$", y, re.M):
        errors.append("agents/openai.yaml 缺少 interface: 顶层键")
    for key in ("display_name:", "short_description:", "default_prompt:"):
        if key not in y:
            errors.append(f"agents/openai.yaml 缺少 {key}")
    m = re.search(r"\$([a-z0-9-]+)", y)
    if not m:
        errors.append("default_prompt 未用 $<skill-name> 引用本技能")
    elif name and m.group(1) != name:
        errors.append(f"default_prompt 引用 ${m.group(1)}，与 name={name} 不一致")
    for key in ("icon_small:", "icon_large:"):
        im = re.search(rf"^{key}\s*[\"']?([^\"'\n]+)", y, re.M)
        if im and not (ROOT / "agents" / im.group(1).strip().lstrip("./")).exists():
            errors.append(f"{key} 指向不存在的图标文件：{im.group(1).strip()}")
    notes.append("agents/openai.yaml 字段与本机 Codex 系统技能一致（interface / display_name / short_description / default_prompt）")

# 3. 编码、行尾、路径：CI 跑在 Linux，shell 脚本必须是 LF
generated = {"tests/canary-prompts.md", "tests/platform-smoke-results.md",
             "tests/.platform-smoke-state.json"}
tracked = [p for p in ROOT.rglob("*") if p.is_file() and ".git" not in p.parts
           and p.relative_to(ROOT).as_posix() not in generated
           and "__pycache__" not in p.parts]
for p in tracked:
    raw = p.read_bytes()
    if p.suffix in {".md", ".json", ".yaml", ".yml", ".sh", ".py"}:
        try:
            raw.decode("utf-8")
        except UnicodeDecodeError:
            errors.append(f"非 UTF-8 文件：{p.relative_to(ROOT)}")
    # 所有文本统一 LF：Windows 上 Python write_text 会悄悄把 \n 变 \r\n，
    # 会让工作区 / zip / 仓库三份内容不一致（ Git blob SHA 不同）。
    if p.suffix in {".md", ".json", ".yaml", ".yml", ".sh", ".py"} and b"\r\n" in raw:
        errors.append(f"文本文件含 CRLF，跨平台内容会不一致：{p.relative_to(ROOT)}")
    if p.suffix in {".md", ".yaml", ".yml"}:
        text = raw.decode("utf-8", errors="ignore")
        # 只认「前面不是字母/数字/下划线」的单个盘符，避免把 https:// 里的 s:// 误判成盘符
        for hit in re.findall(r"(?<![A-Za-z0-9_])[A-Za-z]:[\\/][^\s)\]`]+", text):
            errors.append(f"含本机绝对路径（影响其他平台）：{p.relative_to(ROOT)} -> {hit[:50]}")
notes.append(f"扫描 {len(tracked)} 个文件：UTF-8 / 全文本 LF 行尾 / 无绝对路径")

# 4. 本机各平台技能目录探测（只报告，不判失败）
platform_dirs = {
    "WorkBuddy": HOME / ".workbuddy" / "skills",
    "Codex": HOME / ".codex" / "skills",
    "Claude Code": HOME / ".claude" / "skills",
}
for label, d in platform_dirs.items():
    installed = (d / ROOT.name).is_dir() if d.is_dir() else False
    state = "已安装" if installed else ("目录存在、未安装本技能" if d.is_dir() else "本机无此目录")
    notes.append(f"{label}: {state}（{d}）")
for cli in ("codex", "claude"):
    from shutil import which
    found = which(cli)
    where = "PATH"
    if not found and cli == "codex":
        # 桌面版 Codex 常把 CLI 放在应用目录、不加入 PATH；不能因此误报「未安装」
        probes = [
            Path.home() / ".codex" / ".sandbox-bin" / "codex.exe",
            Path.home() / ".codex" / ".sandbox-bin" / "codex",
        ]
        bindir = Path.home() / "AppData" / "Local" / "OpenAI" / "Codex" / "bin"
        if bindir.is_dir():
            probes += sorted(bindir.glob("*/codex.exe"), reverse=True)
        cfg = Path.home() / ".codex" / "config.toml"
        if cfg.is_file():
            m = re.search(r"CODEX_CLI_PATH\s*=\s*'([^']+)'", cfg.read_text(encoding="utf-8", errors="replace"))
            if m:
                probes.insert(0, Path(m.group(1)))
        for c in probes:
            if c.is_file():
                found, where = str(c), "桌面版路径"
                break
    notes.append(f"{cli} CLI: {('可用（' + where + '）') if found else '未发现，语义触发实测需换环境执行'}")

print("跨平台静态兼容检查：")
for n in notes:
    print(f"  · {n}")
if errors:
    for e in errors:
        print(f"[失败] {e}", file=sys.stderr)
    print(f"校验失败：{len(errors)} 项", file=sys.stderr)
    sys.exit(1)
print("通过：frontmatter / Codex 接口文件 / 编码行尾 / 路径 均兼容三平台")
print("提醒：本脚本不验证语义触发，实测请用 tests/platform-smoke.md 与 scripts/platform-smoke.sh")
