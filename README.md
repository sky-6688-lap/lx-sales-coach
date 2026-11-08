# 乐享｜成交实战教练 Skill

你会做，也不缺专业，但一到谈钱就卡住：客户问完价就没下文，说「考虑一下」之后不知道怎么接，报完价自己先心虚，明明聊得挺好就是收不到定金。

「乐享｜成交实战教练」是一份可以装进 Agent 使用的 skill。它不做销售培训，只陪你处理手上正在谈的那一单：先判断这单卡在哪一步，再给出一段能直接复制发出去的消息，以及发出去之后该看什么信号。

它属于乐享系列，是 [个人经验产品化 Skill](https://github.com/sky-6688-lap/lx-experience-productize-coach) 的下游环节：那边帮你把经验整理成可售卖的东西，这边帮你把它谈成。

## 它能帮你做什么

- **判状态**：把「客户不回」「说贵」「要考虑」这些模糊感受，落到具体的卡点上——是价值没说清、需求没确认、报价时机不对、异议没接住，还是节奏断了。
- **给成品消息**：不是「你先表达理解再讲价值」这种指令，是可以直接粘贴到聊天框里的原文，按条分好，连发不超过 3 条，单条不超过 60 字。
- **守边界**：信息不足先问三件事，不预设你的行业；不编案例、不承诺成交、不教逼单、不制造稀缺。
- **覆盖全链路**：从第一次开口、需求诊断、报价提案，到异议、跟进、沉默激活、定金，再到交付后的复购与转介绍。
- **覆盖渠道与争议**：微信语音、社媒私信、群与直播、电话；加需求、改期、退款、尾款、客户发火；熟人介绍、多人决策、老客复联。
- **给可填写的工作表**：一单一张卡、三档产品阶梯与一页报价表、每周经营数字、从零拼一条消息的填空模板。
- **出销售内容**：朋友圈、短文案、海报主文案的取材与批量成稿，同样受合规与表述规则约束。

## 它不做什么

- 不替你决定价格，也不保证「照做就能成交」。
- 不写夸大宣传、虚假限时、逼单话术，不帮你绕过行业合规或职业身份限制。
- 不代做销售页、投放、完整商业计划，不接购买或咨询承接。
- 不使用你没提供的客户信息，也不从旧对话里翻背景。

## 适合哪些人

- 卖咨询、陪跑、小课、方案、接单服务的经验变现者与一人公司。
- 已经有人来问、但转化率始终上不去的独立工作者。
- 方法不限定行业：卖实物、课程、服务都能用，前提是你能说清自己卖的是什么。

如果你手上还没有任何真实在谈的客户，只是想找一套「万能话术」，这份 skill 帮不上太多忙——它处理的是具体的一单，不是抽象的技巧。

## 如何安装

**方式一：Agent 从 GitHub 安装**（仓库：`https://github.com/sky-6688-lap/lx-sales-coach`）

> 帮我安装这个 skill：https://github.com/sky-6688-lap/lx-sales-coach

也可以从 Releases 下载 `lx-sales-coach.zip` 解压使用。更新到最新版：

> 请把已安装的 lx-sales-coach 更新到最新版，覆盖旧版本：https://github.com/sky-6688-lap/lx-sales-coach

**方式二：本地复制**

把整个 `lx-sales-coach` 文件夹放进对应目录，重开 Agent 即可：

```bash
# WorkBuddy
cp -R lx-sales-coach ~/.workbuddy/skills/

# Codex
cp -R lx-sales-coach ~/.codex/skills/

# Claude Code
cp -R lx-sales-coach ~/.claude/skills/
```

也可以直接运行 `bash scripts/install-local.sh` 安装到 WorkBuddy 用户级技能目录。

**方式三：不安装**

把 `SKILL.md` 整段贴进任意对话式 AI；需要深挖某一类问题时，再把 `references/` 里对应那篇贴给它。文件夹名不要改，改名需同步修改 `SKILL.md` 的 `name` 字段。

## 如何开始使用

安装后直接说人话，最好一句话带上背景（卖什么 / 价格档 / 上次停在哪 / 客户原话）：

> 卖的是 2980 的求职陪跑，第二次聊，客户说「我再考虑一下」，接下来怎么回？

> 报价 9800 的咨询方案，发过去三天没回，要不要再发一条？

> 客户说「别家比你便宜一半」，我该怎么接不显得心虚？

> 我不敢跟熟人收钱，一报价就先自己打折，怎么办？

> 按我这单的情况，帮我写 5 条不发硬广的朋友圈。

信息不全时它会先反问三件事；你明确说「别问了直接给」，它会给带占位符的通用版。

## 包里有什么

```
lx-sales-coach/
├── SKILL.md                     总入口：门禁 / 状态机 / 精确寻址表 / 回答格式 / 红线
├── README.md                    本文件
├── VERSION.md / CHANGELOG.md    版本与更新记录
├── version.json                 机器可读版本与完整性基线（自动更新比对对象）
├── LICENSE                     MIT
├── agents/openai.yaml           Agent 展示名与默认提示词
├── .github/workflows/ci.yml     push / PR 自动跑全部校验
├── references/                  97 篇按需加载的方法文件（编号 00–96）
├── tests/                       回归案例、检查清单、canary 数据、跨平台实测记录
└── scripts/                     发布校验、canary runner、兼容检查、安装与实测脚本
```

`references/` 采用按需加载：Agent 只读取当前状态对应的 1–2 篇，不会把整库塞进上下文。97 篇按五层组织——00 总路由、01–16 主链路总纲、17–75 细分场景与实战工具、76–80 总览与全库索引、81–96 渠道媒介 / 履约争议 / 关系类型 / 可填写工作表（与 SKILL.md、00-router.md 的分组一致）。SKILL.md 第四节有「逐状态精确寻址表」，17 篇主链路每篇末尾也有「深挖指引」，按问题反查用 `references/80-glossary-and-index.md`（含 97 篇逐篇速查表）。**每一篇都有可从状态机到达的路径**，不是写完就没人读的死文件。

内容规模：**97 篇 references / 104 个 markdown / 约 25.4 万字符 / 约 59 万字节**。全部方法文件均为本包独立编写，与任何第三方知识库、课程或专栏无关联，不含其原文；所有示例均标注为模板示例，不冒充真实案例。

## 工程化与验证

这套包不只是一堆文档，改动后会自己检查自己：

| 机制 | 文件 | 作用 |
|---|---|---|
| 机器可读版本 | `version.json` | 声明版本、篇数、字符与字节下限；Agent 更新时比对 `version` 与 `integrity.references`，不再靠人读 VERSION.md 猜新旧；raw 域名读不到时自动走 Contents API 备用端点 |
| 发布校验 | `scripts/verify-release.sh` | 结构 / frontmatter / 悬空链接 / 红线 / 版本一致 / 全库可达性 / 索引覆盖 / 深挖指引 / 成品消息长度 / 规则一致性 / 内容规模 |
| Canary 回归 | `tests/canary-cases.json` + `scripts/run-canary.py` | 每篇一条真实业务问句，硬检查落点存在、在精确寻址表与速查表中均被点名、问句不重复；`--emit-prompts` 生成可在 Agent 里逐条实测的提示词 |
| 持续集成 | `.github/workflows/ci.yml` | push / PR 时自动跑上面三项 + 兼容检查 + JSON 解析 |
| 跨平台兼容 | `scripts/check-compat.py` | 静态检查 frontmatter、Codex `agents/openai.yaml`、UTF-8、shell 行尾、无本机绝对路径 |
| 触发实测 | `tests/platform-smoke.md` + `scripts/platform-smoke.sh` | 三平台的一键 smoke 提示词与结果记录表；语义触发必须在对应运行时实测，静态脚本不伪造通过 |

本地一次跑完：

```bash
bash scripts/verify-release.sh
python3 scripts/run-canary.py
python3 scripts/run-canary.py --emit-prompts
python3 scripts/check-compat.py
bash scripts/platform-smoke.sh
```

`--emit-prompts` 生成的 `tests/canary-prompts.md` 和实测结果表属于本机记录，已在 `.gitignore` 中排除，不会混进发布包。

## 版本

当前版本 **v2026.11.09.02**，见 [VERSION.md](VERSION.md)；更新记录见 [CHANGELOG.md](CHANGELOG.md)。自动更新比对的是仓库 main 分支上的 `version.json`，不是本地文件的修改时间。
