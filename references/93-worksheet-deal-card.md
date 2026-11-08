# 93 工作表：一单一张卡（可填写档案）

> 补 [30-diagnosis-records.md](30-diagnosis-records.md)、[58-client-grading-and-time.md](58-client-grading-and-time.md)、[73-handover-templates.md](73-handover-templates.md)。前面 80 多篇给的是判断方法，这一篇给**承载判断的容器**：把每单的关键事实压进一张能填的卡片。所有示例均为**模板示例（非真实案例）**。

## 一、卡片模板（直接复制到笔记里用）

一单一张卡，不按客户建、也不按月份建。字段只留会影响下一句话的那些，多一格都会让人懒得填。

```text
【单号 / 名称】
【状态】S0 未接触 / S1 初聊 / S2 诊断 / S3 异议 / S4 跟进
        / S5 沉默 / S6 收口 / S7 已成交 / S8 急救 / S9 交付后
【卖什么】产品 + 交付形态：
【价格档】百元级 / 千元级 / 万元以上，或具体数字：
【上次停在哪】第几次接触，最后一句是我方哪句：
【客户原话】贴原句，不转述：
【他要的结果】用他自己的词：
【已试过什么 / 卡点】：
【我方判断】这单卡在哪一层：
【下一步】一个动作 + 时间点：
【下次自然由头】：
```

## 二、下半张：款项、范围与异常

```text
【范围原话】（含项 / 不含项 / 轮次 / 交付物形态）：
【报价与档位】原价 / 实报 / 让价换了多少范围：
【款项节点】定金 [金额][节点]｜尾款 [金额][节点]｜退还规则：
【时间线】约定 [日期] → 改期 [日期] → 交付 [日期]：
【范围变更】第几次 / 改了什么 / 谁确认 / 是否另计：
【异常与结论】发生了什么 → 核对结论 → 改了哪条流程：
【状态收尾】关闭日期 / 未关闭事项 / 可复联由头：
```

**填写规则**：范围原话和报价写「原文」，不写「大概」；变更必须带日期和确认人；异常栏只写事实与结论，不写情绪评价。这张卡以后要能交给别人接手，见 [73-handover-templates.md](73-handover-templates.md)。

## 三、五个高频字段怎么填才有用

| 字段 | 填了会怎样 | 常见错填 |
|---|---|---|
| 客户原话 | 下一句能接住他的词，见 [32-customer-language.md](32-customer-language.md) | 写成「他嫌贵」这种转述 |
| 上次停在哪 | 直接决定状态判定，见 [18-state-judgment-cases.md](18-state-judgment-cases.md) | 写「聊过几次」 |
| 他要的结果 | 区分真需求与随口一问，见 [29-fake-needs-in-detail.md](29-fake-needs-in-detail.md) | 填成我方产品名 |
| 范围原话 | 加需求、退款时唯一可核对的依据 | 只写「按之前说的」 |
| 下次自然由头 | 半年后复联不靠记性，见 [91-dormant-client-revisit.md](91-dormant-client-revisit.md) | 空着 |

> 卡片我按这单建了一张，范围那句贴的是原文，后面变更都往下记。

> 这单状态我改成 [状态] 了，下一步 [一个动作]，[时间] 再对一次。

## 四、卡片与主链路的对应

不用为每张卡读一整篇。按状态取对应文件，一次 1–2 篇，规则同 [00-router.md](00-router.md)。

| 卡片上出现的情况 | 去查 |
|---|---|
| 「客户原话」是价格类 | [05-objection-price.md](05-objection-price.md) / [33-objection-taxonomy.md](33-objection-taxonomy.md) |
| 「上次停在哪」已隔很久 | [09-silent-reactivation.md](09-silent-reactivation.md) / [45-silent-attribution.md](45-silent-attribution.md) |
| 准备写「下一步」 | [08-follow-up-rhythm.md](08-follow-up-rhythm.md) / [43-three-touchpoints.md](43-three-touchpoints.md) |
| 范围变更有新增 | [85-scope-creep.md](85-scope-creep.md) |
| 异常栏被填了 | [87-refund-and-dispute.md](87-refund-and-dispute.md) / [92-angry-client-recovery.md](92-angry-client-recovery.md) |
| 状态到 S7 之后 | [50-after-payment.md](50-after-payment.md) / [52-delivery-checkpoints.md](52-delivery-checkpoints.md) |

## 五、每周怎么用这张卡

**周一看三列**：状态、下一步、时间点。只挑「下一步已过期」和「状态停在 S4/S5 超过一周」的单处理，不要逐张重读。

**周五补两格**：把本周实际发生的客户原话和范围变更补进去，别攒到月底。四周复盘的记录表见 [74-weekly-review-examples.md](74-weekly-review-examples.md)，经营数字见 [95-worksheet-weekly-metrics.md](95-worksheet-weekly-metrics.md)。

**收尾时做一次归档**：确认款项关闭、异议关闭、可复联由头写好了，才把状态改成已结束。有未关闭事项就别标完成，见 [88-final-payment-and-invoice.md](88-final-payment-and-invoice.md)。

## 六、隐私与边界

卡片会存真实对话，所以：只记与这单有关的事实，不记身份信息、家庭情况、健康或财务细节；不把客户原话贴到公开文档或群里；转介绍相关的内容单独记，不向介绍人同步成交客户的卡片，见 [89-referral-from-friends.md](89-referral-from-friends.md)。要用客户评价做素材，另外走授权，见 [56-testimonials-and-authorization.md](56-testimonials-and-authorization.md)。

## 七、禁忌

1. 不把卡片做成几十栏的表；填不动的表等于没有。
2. 不用「意向高 / 感觉还行」代替行为证据，判断只写可观察信号。
3. 不事后补写范围或改报价记录来让卡片好看；变更要有日期与确认人。
4. 不把卡片当客户档案长期囤积无关信息，不向第三方转发原文。
5. 不因为填了卡就跳过门禁四项；卡片是记录，不是免问理由，见 [17-gate-playbook.md](17-gate-playbook.md)。

## 八、与主线怎么接

- 诊断记录表 → [30-diagnosis-records.md](30-diagnosis-records.md)；丢单归因 → [31-lost-deal-attribution.md](31-lost-deal-attribution.md)。
- 交接模板 → [73-handover-templates.md](73-handover-templates.md)；成套检查表 → [68-checklist-bundle.md](68-checklist-bundle.md)。
- 报价表与档位 → [94-worksheet-offer-ladder.md](94-worksheet-offer-ladder.md)；消息拼装 → [96-worksheet-message-builder.md](96-worksheet-message-builder.md)。
