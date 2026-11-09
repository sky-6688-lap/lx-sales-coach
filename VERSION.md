# Skill 版本证明

- Version: v2026.11.09.06
- Released: 2026-11-09 23:20 CST
- Release tag: v2026.11.09.06
- Display name: 乐享｜成交话术（副标题：先判卡在哪一步，再给能直接发出去的消息；机器标识 `lx-sales-coach` 不变）
- Source commit: 见仓库 main 分支与同 tag 的 Release
- Repository: https://github.com/sky-6688-lap/lx-sales-coach
- Machine-readable: version.json（更新时比对的唯一对象）

当用户要求更新本 Skill 时，Agent 应读取仓库 main 分支上的 `version.json`，比较其中的 `version` 与 `integrity.references` 两项与本地是否一致：**两项都一致**才回复「已更新到最新版本」，不一致回复「更新未成功」，不要用术语增加用户负担。

读取顺序按 `version.json` 的 `update.policy`：先读 `endpoint`（raw 域名，无限流）；若网络、SSL 或代理导致读不到，改读 `endpoint_fallback`（GitHub Contents API，公开仓库免鉴权，请求头见 `endpoint_fallback_headers`）；两者都失败才算「更新未成功」。**不要只试一次就下结论**。发布内容与 commit 以同名 Release tag 为准，版本文件不自引用 commit，避免循环依赖。

如果本地 `references/` 篇数少于 `version.json` 的 `integrity.references`，或本地 markdown 字符数明显低于 `integrity.min_chars`，说明安装不完整，应回复「安装不完整，请重新拉取完整包」，不要按残缺版继续使用。

本版本共 **99 篇 references、106 个 markdown、约 31.2 万字符**，内容全部独立编写。99 篇均可从 SKILL.md 逐状态精确寻址表、17 篇主链路的深挖指引或 80 全库速查表到达；80 索引的「按问题查文件」表也已覆盖全部 99 个编号；`python3 scripts/run-canary.py` 会给每篇一条业务问句并验证落点存在且可达。若某篇怎么都读不到，说明装的是旧版本。

配套工程能力：`scripts/verify-release.sh`（发布校验）、`scripts/run-canary.py`（99 条 canary）、`scripts/check-compat.py`（三平台静态兼容）、`.github/workflows/ci.yml`（push / PR 自动跑全部校验）、`scripts/run-platform-smoke.py` + `scripts/platform-smoke.sh`（真实调用本机 CLI 的语义触发实测，从 `--json` 事件提取实际读取的文件做硬判定，并检测串包）。

本版本在 Codex 桌面版 CLI 上做过**多轮真实触发实测**（含卸载原版后的 42 次全量回归与定向复测），据此补上了技能隔离声明、急救触发词、成品消息硬格式、「具体场景优先于状态大类」、「动笔前红线闸门」与「场景例外清单」，详见 `CHANGELOG.md` 与 `tests/platform-smoke.md`。静态脚本不替代 Agent 运行时的触发实测；本机无 Claude Code CLI，该平台仍标注为未实测。

## 本版新增的输出形态（v2026.11.09.06）

对照原版逐篇复核后新增两条运行时硬规则，只做加法、不删原有规则：

- **规则 16 三版本默认输出**：给客户的成品消息默认给 A 稳一稳 / B 说清楚 / C 往前一步三个不同版本，逐版可直接复制，标注写在引用块外，末尾给一句建议先发哪一版。用户明确「只要一句」才给 1 版，明确要更多最多 5 版。原「最多给 2 版」的上限已取消。
- **规则 17 温和语气红线**：三版逐版过，不否定、不质问、不比较、不施压、不教育、不句首硬转折；带着火气默读一遍；客户已有不满时三版整体降到 A 档。温和只改表达，不改边界。
- 新增 `references/97-three-version-messages.md` 与 `98-warm-tone-redlines.md`，并同步 00 / 14 / 15 / 16 / 17 / 19 / 20 / 21 / 60 / 75 / 78 / 80 / 92 共 13 篇既有方法文件；发布校验新增两条硬规则的一致性检查。

篇数 97 → 99、markdown 104 → 106，字符与字节下限同步上调；原版对照基准为 59 篇 / 155,595 字符 / 395,994 字节，本版仍显著高于原版。
