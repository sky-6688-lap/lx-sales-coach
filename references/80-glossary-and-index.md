# 80 术语表与全库索引

> 按「我遇到的问题」查文件。八十篇是查用的，不是读完的；找到对应行后只读那一到两篇。

## 一、术语表

| 词 | 在这套系统里的意思 |
|---|---|
| **门禁** | 给成品消息前必须拿到的四项：卖什么、价格带、关系进度、客户最近那句原话 |
| **占位版** | 用户明确说别问时给的通用短消息，用 `[ ]` 标出待替换项，≤2 条 |
| **状态机** | S0–S9，按「对方那头发生了什么」判定的十种状态，不是用户的心情 |
| **主状态 / 辅状态** | 跨状态问题里，取会阻断推进的那个为主，另一个最多辅读一篇 |
| **四段式** | 一句判断 / 依据与风险 / 可直接发的消息 / 下一步与一条禁忌 |
| **三格句** | 谁 → 从什么到什么 → 靠什么，用来压成一句话说清自己卖什么 |
| **报价三件套** | 做什么、交付什么与多久、下一步；数字不能单独出现 |
| **一页范围** | 六块：解决什么、拿到什么、怎么做、配合什么、不包含什么、费用与下一步 |
| **分类问句** | 把「贵 / 考虑」这类模糊阻力拆成两个具体选项的一句反问 |
| **真实由头** | 来自记录、可核对、不靠巧合的出现理由；编出来的不算 |
| **实质回复** | 回答了具体小问题、给了新信息、问了交付或时间；「嗯 / 好的」不算 |
| **止损线** | 三次无实质回复、对方明说不需要、或用户判断不值得投入，命中即停 |
| **伪需求** | 学习欲、比价、替别人问；不是拒绝，只是这周不投入制作时间 |
| **事实 / 推断** | 记录里的原话与时间 vs 标了依据与不确定性的可能原因 |
| **承接模块** | 「欢迎咨询」「私信领取」这类引流语，本 Skill 一律不写 |
| **占位符** | `[产品]`、`[价格]`、`[他的原话]` 等，缺一未替换就不算成品 |
| **深浅判断** | 只要一句能发的走急救层；要拆解的进对应模块；两边都要先短后深 |

## 二、按问题查文件（速查）

| 我现在的问题 | 先读 | 深挖 |
|---|---|---|
| 不知道该问什么背景 | [17-gate-playbook.md](17-gate-playbook.md) | [28-question-bank.md](28-question-bank.md) |
| 状态判不准 / 判错了 | [00-router.md](00-router.md) | [18-state-judgment-cases.md](18-state-judgment-cases.md) |
| 消息写出来像模板 | [19-message-style-rewrites.md](19-message-style-rewrites.md) | [32-customer-language.md](32-customer-language.md) |
| 不知道四段式长什么样 | [20-four-part-answer-examples.md](20-four-part-answer-examples.md) | [77-conversation-anatomy.md](77-conversation-anatomy.md) |
| 说不清自己卖什么 | [01-value-and-positioning.md](01-value-and-positioning.md) | [22-one-sentence-examples.md](22-one-sentence-examples.md) |
| 第一句怎么发 | [23-first-contact-scenarios.md](23-first-contact-scenarios.md) | [72-group-and-public-scenarios.md](72-group-and-public-scenarios.md) |
| 不知道定多少钱 / 心虚 | [24-pricing-logic.md](24-pricing-logic.md) | [57-fear-of-charging-drills.md](57-fear-of-charging-drills.md) |
| 该不该报价、报早了 | [25-quote-timing.md](25-quote-timing.md) | [02-pricing-and-quote.md](02-pricing-and-quote.md) |
| 要写方案 / 提案 | [26-proposal-templates.md](26-proposal-templates.md) | [70-long-cycle-deals.md](70-long-cycle-deals.md) |
| 被还价 / 要涨价 | [27-discount-and-price-change.md](27-discount-and-price-change.md) | [37-haggling-scripts.md](37-haggling-scripts.md) |
| 不会问需求 / 聊完不知道他要什么 | [03-needs-diagnosis.md](03-needs-diagnosis.md) | [28-question-bank.md](28-question-bank.md) |
| 怀疑对方只是随便问问 | [29-fake-needs-in-detail.md](29-fake-needs-in-detail.md) | [13-operations.md](13-operations.md) |
| 想把聊天记下来 / 做复盘 | [30-diagnosis-records.md](30-diagnosis-records.md) | [31-lost-deal-attribution.md](31-lost-deal-attribution.md) |
| 这单为什么没成 | [04-chat-review.md](04-chat-review.md) | [69-failure-cases.md](69-failure-cases.md) |
| 客户说贵 / 预算 / 别家便宜 | [33-objection-taxonomy.md](33-objection-taxonomy.md) | 34 / 35 / 36 / 37 |
| 客户说考虑 / 商量 / 再看看 | [38-decision-variants.md](38-decision-variants.md) | [06-objection-decision.md](06-objection-decision.md) |
| 客户要保证 / 要案例 / 要方案 | [39-trust-and-guarantees.md](39-trust-and-guarantees.md) | [56-testimonials-and-authorization.md](56-testimonials-and-authorization.md) |
| 突然变冷 / 一直白问 | [40-coldness-and-free-asking.md](40-coldness-and-free-asking.md) | [07-objection-trust.md](07-objection-trust.md) |
| 不知道隔多久跟 | [42-rhythm-by-price-band.md](42-rhythm-by-price-band.md) | [65-followup-calendar.md](65-followup-calendar.md) |
| 跟进该写什么 | [41-followup-principles.md](41-followup-principles.md) | [46-reactivation-library.md](46-reactivation-library.md) |
| 追了几次该停了 | [44-stop-loss-and-reentry.md](44-stop-loss-and-reentry.md) | [47-followup-mistakes.md](47-followup-mistakes.md) |
| 客户不回，不知道为什么 | [45-silent-attribution.md](45-silent-attribution.md) | [09-silent-reactivation.md](09-silent-reactivation.md) |
| 聊挺好就是不定 | [48-close-three-sentences.md](48-close-three-sentences.md) | [10-close-and-deposit.md](10-close-and-deposit.md) |
| 定金 / 收款规则 | [49-deposit-rules.md](49-deposit-rules.md) | [51-no-pressure-closing.md](51-no-pressure-closing.md) |
| 收完钱第一句 | [50-after-payment.md](50-after-payment.md) | [52-delivery-checkpoints.md](52-delivery-checkpoints.md) |
| 续费 / 涨价怎么说 | [53-renewal-and-price-change.md](53-renewal-and-price-change.md) | [73-handover-templates.md](73-handover-templates.md) |
| 想请老客转介绍 | [54-referral-timing-and-scripts.md](54-referral-timing-and-scripts.md) | [55-referral-rewards-and-cps.md](55-referral-rewards-and-cps.md) |
| 不敢收钱 / 熟人打折 | [12-mindset.md](12-mindset.md) | [57-fear-of-charging-drills.md](57-fear-of-charging-drills.md) |
| 单子多顾不过来 | [58-client-grading-and-time.md](58-client-grading-and-time.md) | [68-checklist-bundle.md](68-checklist-bundle.md) |
| 没人来问 / 要发内容 | [59-inbound-content.md](59-inbound-content.md) | [61-content-templates.md](61-content-templates.md) |
| 只要一句能发的 | [14-quick-answers.md](14-quick-answers.md) | [60-quick-answers-extra.md](60-quick-answers-extra.md) |
| 发消息前想再检查 | [15-message-checklist.md](15-message-checklist.md) | [68-checklist-bundle.md](68-checklist-bundle.md) |
| 占位符不知道怎么换 | [66-scenario-replacements.md](66-scenario-replacements.md) | [63-chat-script-library.md](63-chat-script-library.md) |
| 想练手 / 想复盘四周 | [67-roleplay-drills.md](67-roleplay-drills.md) | [74-weekly-review-examples.md](74-weekly-review-examples.md) |
| 想系统练三十天 | [79-self-practice-plan.md](79-self-practice-plan.md) | [76-sales-system-overview.md](76-sales-system-overview.md) |
| 不确定某句能不能给 | [75-faq-for-agent.md](75-faq-for-agent.md) | [21-boundaries-and-compliance.md](21-boundaries-and-compliance.md) |
| 想知道为什么这么设计 | [78-principles-and-tradeoffs.md](78-principles-and-tradeoffs.md) | [76-sales-system-overview.md](76-sales-system-overview.md) |

## 三、按状态查主链路

| 状态 | 主链路 | 细分入口 |
|---|---|---|
| S0 价值没说清 | 01 | 22 / 23 / 32 |
| S1 需求没确认 | 03 | 28 / 29 / 30 |
| S2 到报价节点 | 02 | 24 / 25 / 26 |
| S3 有异议 | 05 / 06 / 07 | 33–40 / 64 |
| S4 已经沉默 | 08 / 09 | 41–47 / 65 |
| S5 临门一脚 | 10 | 48–51 |
| S6 已经成交 | 11 | 52–56 / 73 |
| S7 卡在自己 | 12 / 13 | 57–59 / 79 |
| S8 只要一句话 | 14 | 60 / 63 |
| S9 要出内容 | 16 | 59 / 61 |

## 四、维护规则

新增或改名文件后，必须同步更新三处：本索引、[00-router.md](00-router.md) 的文件地图、SKILL.md 的目录结构与路由表。校验脚本会检查编号连续性与所有相对链接；索引漏更新不会被脚本发现，属于人工检查项（见 [tests/regression-checklist.md](../tests/regression-checklist.md)）。

## 五、禁忌

最忌讳**拿着索引去通读**。找到那一行，读一到两篇，写完过 15 的自检，就够了。

相关：[00-router.md](00-router.md)（判定顺序）、[76-sales-system-overview.md](76-sales-system-overview.md)（系统总览）、[SKILL.md](../SKILL.md)（总入口）。
