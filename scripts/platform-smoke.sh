#!/usr/bin/env bash
# 跨平台触发实测入口。真实判定逻辑在 run-platform-smoke.py：
# 自动发现 CLI（含未加入 PATH 的桌面版）、处理系统代理、关闭 stdin、
# 用空白工作目录避免读到源码、用 --json 事件提取实际读取的文件做硬判定。
#
#   bash scripts/platform-smoke.sh              # 只探测环境
#   bash scripts/platform-smoke.sh --run        # 对本机 CLI 跑全部 12 个用例
#   bash scripts/platform-smoke.sh T02 T04      # 只跑指定用例
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runner="${repo_root}/scripts/run-platform-smoke.py"

if [[ ! -f "$runner" ]]; then
  echo "缺少 $runner" >&2
  exit 1
fi

if [[ "${1:-}" == "--run" ]]; then
  shift
  exec python3 "$runner" "$@"
elif [[ $# -gt 0 ]]; then
  exec python3 "$runner" "$@"
else
  exec python3 "$runner" --detect-only
fi
