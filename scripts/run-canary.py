#!/usr/bin/env python3
"""Canary 回归：验证「每个具体场景都有明确、可达的文件落点」。

纯脚本不能替 Agent 做语义路由判断，所以这里硬检查的是结构可满足性：
落点文件存在、编号一致、在 SKILL.md 精确寻址表与 80 全库速查表中均被点名、
问句互不重复。真正的语义命中用 --emit-prompts 生成提示词，在 Agent 运行时实测。
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REF = ROOT / "references"


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"[失败] 无法读取 {path.relative_to(ROOT)}: {exc}", file=sys.stderr)
        sys.exit(1)


def emit_prompts(cases: list[dict], version: str, out: Path) -> None:
    lines = [
        "# Canary 运行时实测提示词",
        "",
        f"> 由 `python3 scripts/run-canary.py --emit-prompts` 生成，对应版本 {version}。",
        "> 静态脚本只能验证「落点存在且可达」；下面这些提示词用来验证 Agent 真的会路由到那篇。",
        "",
        "## 怎么跑",
        "",
        "1. 每条提示词**开一个新对话**，避免上一轮的上下文干扰状态判定。",
        "2. 把「提问」整段发给装有本 Skill 的 Agent，必要时补上门禁四项（卖什么 / 价格档 / 上次停在哪 / 客户原话）。",
        "3. 记录：它实际引用或读取了哪个文件、给的是否是可直接发的消息、有没有触发门禁。",
        "4. 命中期望文件记为通过；命中别的文件但判断合理，记为「可接受」并写清原因；读不到任何文件记为失败。",
        "5. 结果填进 `tests/platform-smoke-results.md`（本机记录，不提交仓库）。",
        "",
        "## 提示词",
        "",
    ]
    for i in range(0, len(cases), 10):
        batch = cases[i : i + 10]
        lines += [f"### 第 {i // 10 + 1} 批（{i:02d}–{i + len(batch) - 1:02d}）", "",
                  "| 编号 | 提问 | 期望命中 | 实际命中 | 结果 |", "|---|---|---|---|---|"]
        for c in batch:
            q = c["question"].replace("|", "\\|")
            lines.append(f"| {c['id']} | {q} | `{c['expect']}` |  |  |")
        lines.append("")
        lines += [
            "<details><summary>可直接粘贴的提问文本</summary>",
            "",
            "```text",
        ]
        for c in batch:
            lines += [
                f"[{c['id']}] 背景：卖的是 2980 的陪跑，第二次聊，客户原话见下方提问。",
                f"提问：{c['question']}",
                "请按本 Skill 的规则回答，并在结尾注明你读取了哪个参考文件。",
                "",
            ]
        lines += ["```", "", "</details>", ""]
    lines += ["## 结果记录", "",
              "| 平台 | 批次 | 通过 | 可接受 | 失败 | 备注 |", "|---|---|---|---|---|---|",
              "|  |  |  |  |  |  |", ""]
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"已生成运行时实测提示词：{out.relative_to(ROOT)}（{len(cases)} 条，分 {(len(cases)+9)//10} 批）")


def main() -> int:
    ap = argparse.ArgumentParser(description="Canary 路由落点回归")
    ap.add_argument("--emit-prompts", nargs="?", const=str(ROOT / "tests" / "canary-prompts.md"),
                    help="生成可粘贴给 Agent 的实测提示词（默认 tests/canary-prompts.md）")
    args = ap.parse_args()

    meta = load_json(ROOT / "version.json")
    data = load_json(ROOT / "tests" / "canary-cases.json")
    cases = data["cases"]
    expected = meta["integrity"]["references"]
    skill = (ROOT / "SKILL.md").read_text(encoding="utf-8")
    index = (REF / "80-glossary-and-index.md").read_text(encoding="utf-8")

    errors: list[str] = []
    warnings: list[str] = []

    if len(cases) != expected:
        errors.append(f"canary 条数 {len(cases)} 与 version.json 的 references={expected} 不一致")
    ids = [c["id"] for c in cases]
    want_ids = [f"{n:02d}" for n in range(expected)]
    if ids != want_ids:
        missing = sorted(set(want_ids) - set(ids))
        errors.append(f"canary 编号应覆盖 00–{expected-1:02d} 且有序，缺：{missing[:8]}")
    questions = [c["question"] for c in cases]
    dup = {q for q in questions if questions.count(q) > 1}
    if dup:
        errors.append(f"重复的问句 {len(dup)} 条：{list(dup)[:3]}")

    hit_ref = hit_skill = hit_index = hit_kw = 0
    for c in cases:
        name = c["expect"]
        num = name.split("-", 1)[0]
        if num != c["id"]:
            errors.append(f"{c['id']}: 期望落点 {name} 的编号与 case id 不一致")
        if not (REF / name).is_file():
            errors.append(f"{c['id']}: 落点文件不存在 {name}")
            continue
        hit_ref += 1
        if name in skill:
            hit_skill += 1
        else:
            errors.append(f"{c['id']}: {name} 未在 SKILL.md 精确寻址表 / 路由表中点名")
        if name in index:
            hit_index += 1
        else:
            errors.append(f"{c['id']}: {name} 未在 80 全库速查表中点名")
        if len(c["question"]) < 8:
            errors.append(f"{c['id']}: 问句过短，不构成具体场景")
        body = (REF / name).read_text(encoding="utf-8")
        if any(k in body for k in c["keywords"]):
            hit_kw += 1
        else:
            warnings.append(f"{c['id']}: {name} 未命中关键词 {c['keywords']}（人工复核落点是否贴切）")

    print(f"Canary 回归：{len(cases)} 条 / 落点存在 {hit_ref} / SKILL.md 可达 {hit_skill} / 索引点名 {hit_index} / 关键词命中 {hit_kw}")
    for w in warnings:
        print(f"[提示] {w}")
    if args.emit_prompts:
        emit_prompts(cases, meta["version"], Path(args.emit_prompts))
    if errors:
        for e in errors[:20]:
            print(f"[失败] {e}", file=sys.stderr)
        if len(errors) > 20:
            print(f"[失败] ……另有 {len(errors)-20} 项", file=sys.stderr)
        print(f"校验失败：{len(errors)} 项", file=sys.stderr)
        return 1
    print("通过：每个场景都有存在且可达的文件落点")
    return 0


if __name__ == "__main__":
    sys.exit(main())
