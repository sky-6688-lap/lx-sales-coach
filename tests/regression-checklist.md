# 发布前回归检查清单

> 每次改动 SKILL.md、references 或包级文件后逐项确认。`bash scripts/verify-release.sh`、`scripts/run-canary.py`、`scripts/check-compat.py` 覆盖机械检查项，其余需人工过一遍。

## 一、结构（脚本检查）

- [ ] `SKILL.md` frontmatter 完整，`name` 与文件夹名一致，`description` 含触发词且不超过 1024 字符。
- [ ] 必需文件齐全：README / VERSION / CHANGELOG / LICENSE / `version.json` / `agents/openai.yaml` / `.gitignore` / `.github/workflows/ci.yml` / tests / scripts。
- [ ] `references/` 共 97 篇，编号 00–96 连续，无缺号与重号；篇数与 `version.json` 的 `integrity.references` 一致。
- [ ] SKILL.md 的分组说明与精确寻址表、00-router.md 的分组地图、80-glossary-and-index.md 的索引、README 的分组区间四处同步。
- [ ] 97 篇全部可达：SKILL.md 逐状态精确寻址表、17 篇主链路末尾的「深挖指引」、80 全库速查表逐篇点名，三者齐全。
- [ ] `tests/canary-cases.json` 共 97 条，落点文件全部存在、编号与 case id 一致、在 SKILL.md 与 80 索引中均被点名、问句无重复。
- [ ] 内容规模不低于 `version.json` 声明的 `min_chars` / `min_bytes`（发布校验脚本检查）。
- [ ] 所有 markdown 相对链接目标存在，无悬空链接。
- [ ] 成品示例消息无超过 60 字者；门禁、四段式、急救例外三处口径在 SKILL.md / 00 / 14 / 17 / 20 中一致。
- [ ] 所有文件 UTF-8 编码、`.sh` 为 LF 行尾、无本机绝对路径、无占位待写段落。

## 二、路由（人工）

- [ ] 状态机 S0–S9 判定顺序不冲突；跨状态规则仍取「更靠前会阻断推进的」。
- [ ] S3 三个分支（05/06/07）的边界清晰，价格与决策不被混为一谈。
- [ ] 新增文件后，SKILL.md 精确寻址表、00-router 文件地图、17 篇深挖指引、80 索引、canary 数据、version.json 六处同步更新。
- [ ] 81–96 四个新维度（渠道 / 履约争议 / 关系类型 / 工作表）各有明确入口，不与 01–16 主链路重复抢路由。
- [ ] 一次只读 1–2 篇的原则没有被新规则破坏；工作表是产出物，不是要一起加载的材料。

## 三、输出格式（人工 + 抽样）

- [ ] 四段式默认齐全：一句判断 / 依据与风险 / 可直接发的消息 / 下一步与一条禁忌；用户说「简单说」时只保留第 1、3 段，第 3 段不能省。
- [ ] 引用块内是成品消息，≤3 条，每条一件事，单条 ≤60 字，占位符一律方括号 `[ ]`（不用 `【】`）。
- [ ] 消息风格六条逐条成立，尤其「不道歉式铺垫、不用感叹号、不开放式盘问」；不写「呀 / 呢 / 哦」等语气词，不写「我猜你是……」。
- [ ] 会话里还装着别的销售技能时，只从本包 `references/` 取材（案例 34）；「别问了」急救句能触发（案例 35）；点名具体场景时先进细分篇、工作表直接给表（案例 36）。
- [ ] 案例段：无真实案例时明说，模板示例标注为非真实案例。

## 四、红线（人工 + 脚本关键词）

- [ ] 不编案例、数据、成交率、客户反馈。
- [ ] 不承诺结果、不夸大、不教逼单、不制造稀缺与虚假由头。
- [ ] 健康 / 教育 / 金融表述合规；持牌职业与在职竞业边界在位。
- [ ] 不出现第三方品牌、人名、机构名、社群名；不夹带外部课程、专栏链接与承接模块。
- [ ] 不使用未经授权的客户原话、截图、个人信息；争议与工作表篇目里的隐私边界齐全。

## 五、可安装性（人工）

- [ ] 文件夹名未改；若改名，SKILL.md 的 `name` 已同步。
- [ ] README 三种安装方式可照做；`scripts/install-local.sh` 不覆盖已有目录（除非显式 --force）。
- [ ] VERSION、CHANGELOG、`version.json` 三者版本一致；`version.json` 的 `commit` 与发布 tag 对应。
- [ ] 在 WorkBuddy / Codex / Claude Code 里各触发一次：用一个带完整背景的谈单问题，确认自动加载并给出四段式结果；结果记入 `tests/platform-smoke-results.md`。
- [ ] 静态兼容检查已跑；**语义触发实测不能用静态脚本代替，未实测就如实标注未实测**。

## 六、版本记录

- [ ] 改动写入 CHANGELOG。
- [ ] VERSION 版本号递增，Released 时间与实际一致。
- [ ] `bash scripts/verify-release.sh`、`python3 scripts/run-canary.py`、`python3 scripts/check-compat.py` 全部通过后才打 tag 或推送。
- [ ] CI 在 push 后为绿色；Release 附件 zip 与工作区内容一致。
