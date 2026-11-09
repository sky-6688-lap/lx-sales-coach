# Skill 版本证明

- Version: v2026.11.09.05
- Released: 2026-11-09 15:35 CST
- Release tag: v2026.11.09.05
- Display name: 乐享｜成交话术（副标题：先判卡在哪一步，再给能直接发出去的消息；机器标识 `lx-sales-coach` 不变）
- Source commit: 见仓库 main 分支与同 tag 的 Release
- Repository: https://github.com/sky-6688-lap/lx-sales-coach
- Machine-readable: version.json（更新时比对的唯一对象）

当用户要求更新本 Skill 时，Agent 应读取仓库 main 分支上的 `version.json`，比较其中的 `version` 与 `integrity.references` 两项与本地是否一致：**两项都一致**才回复「已更新到最新版本」，不一致回复「更新未成功」，不要用术语增加用户负担。

读取顺序按 `version.json` 的 `update.policy`：先读 `endpoint`（raw 域名，无限流）；若网络、SSL 或代理导致读不到，改读 `endpoint_fallback`（GitHub Contents API，公开仓库免鉴权，请求头见 `endpoint_fallback_headers`）；两者都失败才算「更新未成功」。**不要只试一次就下结论**。发布内容与 commit 以同名 Release tag 为准，版本文件不自引用 commit，避免循环依赖。

如果本地 `references/` 篇数少于 `version.json` 的 `integrity.references`，或本地 markdown 字符数明显低于 `integrity.min_chars`，说明安装不完整，应回复「安装不完整，请重新拉取完整包」，不要按残缺版继续使用。

本版本共 **97 篇 references、104 个 markdown、约 28.3 万字符**，内容全部独立编写。97 篇均可从 SKILL.md 逐状态精确寻址表、17 篇主链路的深挖指引或 80 全库速查表到达；80 索引的「按问题查文件」表也已覆盖全部 97 个编号；`python3 scripts/run-canary.py` 会给每篇一条业务问句并验证落点存在且可达。若某篇怎么都读不到，说明装的是旧版本。

配套工程能力：`scripts/verify-release.sh`（发布校验）、`scripts/run-canary.py`（97 条 canary）、`scripts/check-compat.py`（三平台静态兼容）、`.github/workflows/ci.yml`（push / PR 自动跑全部校验）、`scripts/run-platform-smoke.py` + `scripts/platform-smoke.sh`（真实调用本机 CLI 的语义触发实测，从 `--json` 事件提取实际读取的文件做硬判定，并检测串包）。

本版本在 Codex 桌面版 CLI 上做过**多轮真实触发实测**（含卸载原版后的 42 次全量回归与定向复测），据此补上了技能隔离声明、急救触发词、成品消息硬格式、「具体场景优先于状态大类」、「动笔前红线闸门」与「场景例外清单」，详见 `CHANGELOG.md` 与 `tests/platform-smoke.md`。静态脚本不替代 Agent 运行时的触发实测；本机无 Claude Code CLI，该平台仍标注为未实测。
