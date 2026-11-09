#!/usr/bin/env bash
# 本地安装到 WorkBuddy 用户级技能目录；默认不覆盖已有目录
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_name="$(basename "$repo_root")"
target_root="${HOME}/.workbuddy/skills"
target="${target_root}/${skill_name}"
force="${1:-}"

if [[ "$force" == "--force" ]]; then
  if [[ -d "$target" ]]; then
    backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
    cp -R "$target" "$backup"
    echo "已备份旧版本到：$backup"
    rm -rf "$target"
  fi
elif [[ -e "$target" ]]; then
  echo "目标已存在：$target" >&2
  echo "如需覆盖请执行：bash scripts/install-local.sh --force（会先自动备份）" >&2
  exit 1
fi

mkdir -p "$target_root"
cp -R "$repo_root" "$target"
echo "已安装：$target"
echo "重新打开 Agent 后生效；文件夹名与 SKILL.md 的 name 均为 ${skill_name}。"
