#!/usr/bin/env python3
"""跨平台语义触发实测：真实调用本机 Codex / Claude Code CLI，不伪造结果。

用法：
    python3 scripts/run-platform-smoke.py               # 探测 + 跑全部用例
    python3 scripts/run-platform-smoke.py --list        # 只列出用例
    python3 scripts/run-platform-smoke.py T01 T04       # 只跑指定用例

判定依据是 CLI 的 --json 事件：从 command_execution 里提取实际读取的 .md 文件，
再对照 tests/platform-smoke.md 的期望落点。没有可用 CLI 时明确报「未实测」，不写通过记录。
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / "tests" / "platform-smoke-results.md"
STATE = ROOT / "tests" / ".platform-smoke-state.json"
SKILL_NAME = "lx-sales-coach"

CASES = [
    ("T01", "客户说太贵了，怎么回？", ["SKILL.md"], ["三件事", "卖的是什么"], "门禁四项，不给成品消息"),
    ("T02", "卖 2980 的求职陪跑，第二次聊，客户原话是「我再考虑一下」，接下来怎么回？",
     ["06-objection-decision.md", "38-decision-variants.md"], ["判断", ">"], "S3 决策分支 + 四段式"),
    ("T03", "卖 2980 的求职陪跑，第二次聊，客户原话是「预算只有一半」，怎么接？",
     ["34-price-budget.md"], ["预算", ">"], "精确寻址命中细分篇 34"),
    ("T04", "别问了，先给我一句能发的。", ["14-quick-answers.md", "SKILL.md"],
     ["[产品]"], "急救例外 2-3 条短句带占位"),
    ("T05", "卖 2980 的求职陪跑，第二次聊，客户原话是「我再考虑一下」。简单说，怎么回？",
     ["SKILL.md", "06-objection-decision.md", "38-decision-variants.md"], [">"],
     "简单说只给两段、成品不省"),
    ("T06", "卖 2980 的求职陪跑，第二次聊，客户没有说别的，我没有客户原话，怎么回？",
     ["SKILL.md"], [">"], "无原话不猜措辞并给出成品消息"),
    ("T07", "客户发了条 60 秒语音问价，我该回语音还是文字？卖 2980 的求职陪跑，第一次聊。",
     ["81-channel-wechat.md"], ["语音"], "新维度渠道篇 81"),
    ("T08", "卖 2980 的求职陪跑，第二次聊，客户原话是「顺便再帮我改一下简历吧」，做到一半加需求又不加钱，怎么说？",
     ["85-scope-creep.md"], ["范围"], "新维度履约篇 85"),
    ("T09", "客户问「能不能保证我一定拿到 offer」？卖 2980 的求职陪跑，第二次聊。",
     ["21-boundaries-and-compliance.md", "07-objection-trust.md", "39-trust-and-guarantees.md"],
     ["保证"], "合规红线不承诺结果"),
    ("T10", "想给每单建一张能填的卡片，给我一张表。",
     ["93-worksheet-deal-card.md"], ["|"], "可填写工作表 93"),
    ("T11", "客户说太贵了，怎么回？", ["SKILL.md"], ["三件事"], "重复 T01 验证一致性"),
    ("T12", "朋友介绍来的客户想按熟人价，卖 2980 的求职陪跑，第二次聊，客户原话「都是朋友，便宜点吧」，怎么回？",
     ["89-referral-from-friends.md"], [">"], "新维度关系篇 89"),
]

MD_RE = re.compile(r"[\w\-./\\]+\.md")


def home() -> Path:
    return Path.home()


def discover_cli():
    """返回 (平台名, 可执行文件路径, 参数前缀) 或 None。"""
    exe = shutil.which("codex")
    candidates = []
    if exe:
        candidates.append(Path(exe))
    h = home()
    candidates += [
        h / ".codex" / ".sandbox-bin" / "codex.exe",
        h / ".codex" / ".sandbox-bin" / "codex",
    ]
    bindir = h / "AppData" / "Local" / "OpenAI" / "Codex" / "bin"
    if bindir.is_dir():
        candidates += sorted(bindir.glob("*/codex.exe"), reverse=True)
    cfg = h / ".codex" / "config.toml"
    if cfg.is_file():
        m = re.search(r"CODEX_CLI_PATH\s*=\s*'([^']+)'", cfg.read_text(encoding="utf-8", errors="replace"))
        if m:
            candidates.insert(0, Path(m.group(1)))
    for c in candidates:
        if c.is_file():
            return "Codex", str(c), "codex"
    claude = shutil.which("claude")
    if claude:
        return "Claude Code", claude, "claude"
    return None


def detect_proxy() -> dict:
    """Windows 上优先用系统代理；CLI 常因会话代理白名单连不上后端。"""
    env = os.environ.copy()
    override = os.environ.get("CODEX_SMOKE_PROXY")
    proxy = override
    if not proxy and sys.platform == "win32":
        try:
            import winreg
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Internet Settings",
            )
            enabled, _ = winreg.QueryValueEx(key, "ProxyEnable")
            server, _ = winreg.QueryValueEx(key, "ProxyServer")
            if enabled and server:
                proxy = "http://" + server.split(";")[0]
        except Exception:
            pass
    if proxy:
        for k in ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy"):
            env[k] = proxy
    return env, proxy


def run_one(cli, prefix, case, ws: Path, env: dict, tmp: Path):
    cid, prompt, expect_files, keywords, label = case
    out_md = tmp / f"out-{cid}.md"
    if prefix == "codex":
        cmd = [cli, "exec", "--skip-git-repo-check", "--ephemeral", "-s", "read-only",
               "-C", str(ws), "--json", "-o", str(out_md), prompt]
    else:
        cmd = [cli, "-p", prompt]
    t0 = time.time()
    try:
        p = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True,
                           timeout=int(os.environ.get("CODEX_SMOKE_TIMEOUT", "260")), env=env)
        raw = p.stdout.decode("utf-8", errors="replace")
        rc = p.returncode
    except subprocess.TimeoutExpired:
        return {"id": cid, "ok": False, "verdict": "TIMEOUT", "seconds": round(time.time() - t0, 1),
                "reads": [], "commands": [], "answer": "", "errors": ["CLI 调用超时"]}
    events = []
    for line in raw.splitlines():
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            pass
    commands, msgs, errors = [], [], []
    for e in events:
        item = e.get("item", {}) if e.get("type") == "item.completed" else {}
        if item.get("type") == "command_execution":
            commands.append(item.get("command", ""))
        if item.get("type") == "agent_message":
            msgs.append(item.get("text", ""))
        if e.get("type") == "error" or item.get("type") == "error":
            errors.append((e.get("message") or item.get("message") or "")[:200])
    reads = sorted({m.replace("\\", "/").split("/")[-1] for c in commands for m in MD_RE.findall(c)})
    answer = out_md.read_text(encoding="utf-8", errors="replace").strip() if out_md.exists() else (msgs[-1] if msgs else "")
    # 判定
    hit = [f for f in expect_files if f in reads]
    norm_cmds = [c.replace("\\", "/") for c in commands]
    loaded = any(SKILL_NAME in c for c in norm_cmds)
    contamination = [c for c in norm_cmds if "skills/" in c.lower() and SKILL_NAME not in c]
    kw_hit = [k for k in keywords if k in answer]
    if prefix != "codex":
        verdict = "MANUAL"  # Claude Code 无 --json 事件，需人工按文档口径判读
    elif not loaded:
        verdict = "FAIL(未加载本技能)"
    elif contamination:
        verdict = "FAIL(串包：读取了其他技能目录)"
    elif any(g in answer for g in ("我猜你是", "我猜他", "他肯定是嫌贵", "一定是嫌贵")):
        # 开放式回答不适合字面关键词；但「猜客户心思」是硬红线，所有用例都查
        verdict = "FAIL(猜测客户心思)"
    elif not hit:
        verdict = "WARN(落点未命中)"
    elif not kw_hit:
        # 关键词是「期望出现的语义信号」，允许同义表达；一个都没出现才算缺失
        verdict = "WARN(关键词缺失)"
    else:
        verdict = "PASS"
    # 成品消息格式是独立指标，不并入 PASS/FAIL 主判定（工作表类产出本来就是表格）
    quoted = [l[2:].strip() for l in answer.splitlines() if l.startswith("> ")]
    too_long = [q for q in quoted if len(q) > 120]
    fullwidth = any("【" in q or "】" in q for q in quoted)
    if not quoted:
        fmt = "—（无引用块消息）"
    elif fullwidth:
        fmt = "全角占位符"
    elif too_long:
        fmt = f"{len(too_long)} 条写成一大段"
    else:
        fmt = "OK"
    return {"id": cid, "label": label, "ok": verdict == "PASS", "verdict": verdict,
            "seconds": round(time.time() - t0, 1), "rc": rc, "reads": reads,
            "commands": commands, "answer": answer, "errors": errors,
            "hit": hit, "kw_hit": kw_hit, "contamination": contamination, "format": fmt}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cases", nargs="*", help="只跑指定用例编号")
    ap.add_argument("--list", action="store_true", help="只列出用例")
    ap.add_argument("--detect-only", action="store_true", help="只探测环境")
    args = ap.parse_args()
    if args.list:
        for c in CASES:
            print(f"{c[0]}  {c[4]}  <- {c[1]}")
        return 0
    found = discover_cli()
    env, proxy = detect_proxy()
    print(f"CLI: {found[0] + ' -> ' + found[1] if found else '未发现 Codex / Claude Code CLI'}")
    print(f"代理: {proxy or '未设置（用环境默认）'}")
    for d in (home() / ".workbuddy" / "skills", home() / ".codex" / "skills", home() / ".claude" / "skills"):
        print(f"安装: {d / SKILL_NAME} {'已装' if (d / SKILL_NAME).is_dir() else '未装'}")
    if args.detect_only or not found:
        if not found:
            print("没有可自动执行的运行时：本次为环境探测，未生成任何实测通过记录。")
        return 0
    cli, prefix = found[1], found[2]
    sel = args.cases or [c[0] for c in CASES]
    by_id = {c[0]: c for c in CASES}
    unknown = [x for x in sel if x not in by_id]
    if unknown:
        print(f"未知用例：{unknown}", file=sys.stderr)
        return 2
    with tempfile.TemporaryDirectory(prefix="skill-smoke-") as td:
        tmp = Path(td)
        ws = tmp / "empty-workspace"
        ws.mkdir()
        results = []
        for cid in sel:
            print(f"[{cid}] 执行中 ...", flush=True)
            r = run_one(cli, prefix, by_id[cid], ws, env, tmp)
            results.append(r)
            print(f"[{cid}] {r['verdict']}  {r['seconds']}s  reads={','.join(r['reads'])[:100]}", flush=True)
        # 多轮实测结果按用例累积，报告始终覆盖全部 12 条；每条保留最近一次的真实结果
        state = {}
        if STATE.is_file():
            try:
                state = json.loads(STATE.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                state = {}
        for r in results:
            state[r["id"]] = r
        STATE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")
        all_results = [state[k] for k in sorted(state)]
        lines = ["# 平台触发实测记录", "",
                 f"- 生成时间：{time.strftime('%Y-%m-%d %H:%M:%S')}",
                 f"- 运行时：{found[0]}（本机 CLI，具体路径用 --detect-only 查看）",
                 f"- 方式：scripts/run-platform-smoke.py 真实调用，判定口径见 tests/platform-smoke.md",
                 "- 技能环境：本机完整环境（若并存其他销售技能，串包会被单独判为失败）",
                 f"- 代理：{proxy or '环境默认'}",
                 f"- 本次执行：{', '.join(r['id'] for r in results)}；下表为各用例最近一次结果", "",
                 "| 用例 | 判定 | 耗时 | 实际读取 | 命中 | 成品格式 | 备注 |",
                 "|---|---|---|---|---|---|---|"]
        for r in all_results:
            lines.append(f"| {r['id']} {r.get('label','')} | {r['verdict']} | {r['seconds']}s | "
                         f"{', '.join(r['reads']) or '（无）'} | {', '.join(r['hit']) or '—'} | "
                         f"{r.get('format','—')} | {'; '.join(r['errors'])[:80] or '—'} |")
        lines += ["", "> 「成品格式」是独立观察指标：单条写成一大段（超过 3 行）属软性建议（SKILL.md 写的是「短句连发，写成一大段就拆」），"
                  "全角占位符与串包才是硬问题。工作表类用例产出表格，无引用块消息属正常。", ""]
        lines += ["", "## 原始回答（各用例最近一次）", ""]
        for r in all_results:
            lines += [f"### {r['id']} {r.get('label','')}", "", "```text", r["answer"][:2500], "```", ""]
        RESULTS.write_text("\n".join(lines), encoding="utf-8")
    passed = sum(1 for r in all_results if r["verdict"] == "PASS")
    this_pass = sum(1 for r in results if r["verdict"] == "PASS")
    print(f"\n本次：{this_pass}/{len(results)} PASS；全量最近状态：{passed}/{len(all_results)} PASS"
          f"，明细已写入 {RESULTS.relative_to(ROOT)}")
    return 0 if passed == len(all_results) else 1


if __name__ == "__main__":
    sys.exit(main())
