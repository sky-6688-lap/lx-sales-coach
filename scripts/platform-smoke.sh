#!/usr/bin/env bash
# 跨平台触发实测：只在本机确实存在对应 CLI 时才发起真实调用，不伪造结果。
# 用法：bash scripts/platform-smoke.sh [--run]
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
results="${repo_root}/tests/platform-smoke-results.md"
run="${1:-}"

PROMPT_1='客户说太贵了，怎么回？'
PROMPT_2='卖 2980 的求职陪跑，第二次聊，客户原话是「我再考虑一下」，接下来怎么回？'
PROMPT_3='2980 的陪跑，客户原话是「预算只有一半」，怎么接？'
PROMPT_4='别问了，先给我一句能发的。'

echo "=== 平台运行时探测 ==="
for cli in codex claude; do
  if command -v "$cli" >/dev/null 2>&1; then echo "  $cli: 可用 -> $(command -v "$cli")"; else echo "  $cli: 未安装"; fi
done
for d in "$HOME/.workbuddy/skills" "$HOME/.codex/skills" "$HOME/.claude/skills"; do
  if [[ -d "$d/lx-sales-coach" ]]; then echo "  已安装: $d/lx-sales-coach"; elif [[ -d "$d" ]]; then echo "  目录存在但未装本技能: $d"; else echo "  无目录: $d"; fi
done

echo
echo "=== 可复制的实测命令（按你的 CLI 版本调整参数） ==="
echo "  codex exec --skip-git-repo-check \"\${PROMPT}\""
echo "  claude -p \"\${PROMPT}\""
echo "  四条提示词与判定口径见 tests/platform-smoke.md 第三节"

if [[ "$run" != "--run" ]]; then
  echo
  echo "未加 --run：本次只做环境探测，没有生成任何实测结果。"
  exit 0
fi

executed=0
: > "$results"
{
  echo "# 平台触发实测记录"
  echo
  echo "- 生成时间：$(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "- 生成方式：scripts/platform-smoke.sh --run（真实调用本机 CLI）"
  echo "- 判定口径见 tests/platform-smoke.md"
  echo
} >> "$results"

i=0
for prompt in "$PROMPT_1" "$PROMPT_2" "$PROMPT_3" "$PROMPT_4"; do
  i=$((i+1))
  echo
  echo "--- 提示词 #$i：$prompt"
  if command -v codex >/dev/null 2>&1; then
    out="$(codex exec --skip-git-repo-check "$prompt" 2>&1)" || out="[CLI 返回非零] $out"
    { echo "## 提示词 #$i（Codex）"; echo; echo '```text'; echo "$prompt"; echo '```'; echo; echo '### 输出'; echo; echo '```text'; echo "$out"; echo '```'; echo; } >> "$results"
    echo "$out" | head -12
    executed=$((executed+1))
  elif command -v claude >/dev/null 2>&1; then
    out="$(claude -p "$prompt" 2>&1)" || out="[CLI 返回非零] $out"
    { echo "## 提示词 #$i（Claude Code）"; echo; echo '```text'; echo "$prompt"; echo '```'; echo; echo '### 输出'; echo; echo '```text'; echo "$out"; echo '```'; echo; } >> "$results"
    echo "$out" | head -12
    executed=$((executed+1))
  fi
done

echo
if [[ "$executed" -eq 0 ]]; then
  echo "本机没有可自动执行的 Codex / Claude Code 运行时，未产生实测结果。"
  echo "请在装有对应 CLI 的环境里重跑，或按 tests/platform-smoke.md 手工执行四条提示词。"
  rm -f "$results"
else
  echo "完成 $executed 次真实调用，原始输出已写入：$results"
  echo "请人工按 platform-smoke.md 的判定口径填写通过 / 可接受 / 失败。"
fi
