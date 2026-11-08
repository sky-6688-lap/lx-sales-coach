# 跨平台触发实测（WorkBuddy / Codex / Claude Code）

> **边界先说清楚**：`scripts/check-compat.py` 只做静态兼容检查（frontmatter、接口文件、编码、行尾、路径），它**不能证明 Agent 真的会加载并触发这个技能**。语义触发必须在对应运行时里实际跑一遍。本机未安装 `codex` / `claude` CLI，因此下面标注为「待在对应环境执行」的项目，本包**没有伪造通过结果**。

## 一、本机已完成的静态检查

运行 `python3 scripts/check-compat.py`，覆盖：

- SKILL.md frontmatter：`name` 与目录名一致、符合 `[a-z0-9-]`、`description` 存在且 ≤1024 字符、`metadata.short-description` 存在。
- `agents/openai.yaml`：对照本机 `~/.codex/skills/.system/*/agents/openai.yaml` 的真实格式，检查 `interface` / `display_name` / `short_description` / `default_prompt`，以及 `$lx-sales-coach` 引用与 `name` 一致、图标路径不悬空。
- 全包 UTF-8、`.sh` 无 CRLF（Linux CI 可执行）、文档无本机绝对路径。
- 探测三个平台技能目录与 CLI 是否可用，只报告不判失败。

`agent_created: true` 是 WorkBuddy 专有字段，Codex / Claude Code 会忽略，属正常差异。

## 二、安装（三个平台各自的目录）

```bash
# WorkBuddy（本机已安装）
cp -R lx-sales-coach ~/.workbuddy/skills/

# Codex（本机 ~/.codex/skills 已存在）
cp -R lx-sales-coach ~/.codex/skills/

# Claude Code（本机无此目录，需要时先建）
mkdir -p ~/.claude/skills && cp -R lx-sales-coach ~/.claude/skills/
```

安装后**重开该平台的 Agent**，技能列表里应出现「乐享｜成交实战教练」。

## 三、四条必跑的触发提示词

每条都开一个新对话，避免上一轮上下文干扰状态判定。

| # | 提示词 | 期望行为 | 若不通过说明什么 |
|---|---|---|---|
| 1 | `客户说太贵了，怎么回？` | 先反问门禁四项，不给成品消息、不预设行业 | 门禁没生效，或 SKILL.md 没被加载 |
| 2 | `卖 2980 的求职陪跑，第二次聊，客户原话是「我再考虑一下」，接下来怎么回？` | 判 S3 决策分支，读 06（或 38），给四段式 + ≤3 条成品消息 | 状态机或四段式没生效 |
| 3 | `2980 的陪跑，客户原话是「预算只有一半」，怎么接？` | 命中细分篇 34，不是只给 05 的通用口径 | 精确寻址表 / 深挖指引没被读到 |
| 4 | `别问了，先给我一句能发的。` | 不回门禁，≤2 条带 `[占位]` 的成品消息 | 急救例外口径没统一 |

补充一条格式检查：`简单说，客户说再看看，怎么回？（背景同 #2）` 应只给「一句判断 + 成品消息」两段，且成品消息不能省。

批量版：`python3 scripts/run-canary.py --emit-prompts` 会生成 97 条分好批的提示词，可逐批验证每篇细分文件真的会被路由到。

## 四、结果记录表

把实际结果填到 `tests/platform-smoke-results.md`（该文件被 `.gitignore` 忽略，属本机记录）。

| 平台 | 安装成功 | 技能列表可见 | #1 门禁 | #2 四段式 | #3 细分篇 | #4 急救 | 实测日期 | 备注 |
|---|---|---|---|---|---|---|---|---|
| WorkBuddy |  |  |  |  |  |  |  |  |
| Codex |  |  |  |  |  |  |  |  |
| Claude Code |  |  |  |  |  |  |  |  |

判定口径：命中期望文件记「通过」；命中别的文件但判断合理记「可接受」并写原因；完全没读取本包文件记「失败」。

## 五、一键探测

```bash
bash scripts/platform-smoke.sh              # 只探测环境、打印可复制命令，不产生实测结果
bash scripts/platform-smoke.sh --run        # 对本机检测到的 CLI 实际执行，结果写入 results 文件
```

`--run` 只在 `codex` 或 `claude` CLI 确实存在时才会发起调用；两者都不存在时会明确告诉你「本机没有可自动执行的运行时」，**不会写任何假的通过记录**。CLI 参数按常见版本给出，若报参数未知，用 `codex exec --help` / `claude --help` 调整脚本里的命令模板。
