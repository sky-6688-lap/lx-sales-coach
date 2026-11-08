# Skill 版本证明

- Version: v2026.11.09.02
- Released: 2026-11-09 00:45 CST
- Release tag: v2026.11.09.02
- Source commit: 见仓库 main 分支与同 tag 的 Release
- Repository: https://github.com/sky-6688-lap/lx-sales-coach
- Machine-readable: version.json（更新时比对的唯一对象）

当用户要求更新本 Skill 时，Agent 应读取仓库 main 分支上的 `version.json`，比较其中的 `version` 与 `integrity.references` 两项与本地是否一致：**两项都一致**才回复「已更新到最新版本」，不一致回复「更新未成功」，不要用术语增加用户负担。`commit` 与 `released` 只用于追溯发布内容，不拿它们判断是否需要更新。

如果本地 `references/` 篇数少于 `version.json` 的 `integrity.references`，或本地 markdown 字符数明显低于 `integrity.min_chars`，说明安装不完整，应回复「安装不完整，请重新拉取完整包」，不要按残缺版继续使用。

本版本共 **97 篇 references、104 个 markdown、约 25.4 万字符**，内容全部独立编写。97 篇均可从 SKILL.md 逐状态精确寻址表、17 篇主链路的深挖指引或 80 全库速查表到达；`python3 scripts/run-canary.py` 会给每篇一条业务问句并验证落点存在且可达。若某篇怎么都读不到，说明装的是旧版本。

配套工程能力：`scripts/verify-release.sh`（发布校验）、`scripts/run-canary.py`（97 条 canary）、`scripts/check-compat.py`（三平台静态兼容）、`.github/workflows/ci.yml`（push / PR 自动跑全部校验）、`tests/platform-smoke.md` 与 `scripts/platform-smoke.sh`（三平台语义触发实测）。静态脚本不替代 Agent 运行时的触发实测，实测结果需自行记录。
