# DSH 优质插件推荐清单

> 整理日期：2026-10-03 · 本机环境：DSH `0.2.0-rc.2`（Windows，Web 界面，profile = `D:\dsh\profiles\web`）
> 每个条目都做过**独立核验**：npm 上是否真实存在（版本 / 协议）、GitHub 仓库是否可达（Star / 最近推送 / 协议 / 是否归档）。核验不到的条目已剔除或标注。

---

## 0. 你当前已装的插件（避免重复推荐）

`@deepseek-ai/dsh-toolkit`、`@mattpocock-community/dsh-engineering-skills`、`dsh-file`（本地开发 `D:/1/plugins/dsh-file`）、`dsh-notify-win`、`dsh-share`、`dsh-usage-stats`、`dshmarket`

所以下面按「**能力空缺**」来推荐，不看热度堆砌。⭐ = 我认为最值得先装的。

---

## 1. 首选 8 个（补能力空缺，全部 npm 可装、维护活跃）

> **2026-10-03 更新：下面 8 个已全部装进 `web` profile 并通过 `--dump-config` 组合校验。**
> 实际落地版本：`dsh-better-sidebar@0.24.1`、`dsh-context@0.62.2`、`@liustack/modlens@3.26.5`、`dsh-free-search@0.6.6`、`dsh-mnemon@0.5.21`、`dsh-at-file@0.6.3`、`dsh-plugin-subscriptions@0.9.7`、`noatmark-dsh-plugin@0.1.0`。
> 卸载：`dsh plugin --profile web remove <包名>`。

| # | 插件 | 解决什么 | 安装命令 | 核验结果 |
|---|------|----------|----------|----------|
| 1 ⭐ | **dsh-better-sidebar** | 侧边栏底座：文件渲染编辑 / 终端 / Git / 侧边对话 / 子代理页面 | `dsh plugin --profile web add dsh-better-sidebar` | npm `0.24.1` · MIT · 仓库 2026-10-01 推送 · ★3976 |
| 2 ⭐ | **dsh-context** | 上下文透视：Panel / 浏览器 / 侧边栏 + `context` 命令，看组成、压缩、剪枝、演进 | `dsh plugin --profile web add dsh-context` | npm `0.62.3` · Apache-2.0 · 声明兼容 `0.2.0-rc.2` · ★1823 |
| 3 ⭐ | **@liustack/modlens** | 视觉：粘贴图片 → 结构化 JSON 证据（OCR / 版面 / 语义），给纯文本模型补眼睛 | `dsh plugin --profile web add @liustack/modlens` | npm `3.26.5` · MIT · ★4109 |
| 4 ⭐ | **dsh-free-search** | 免费联网搜索（DuckDuckGo 后端，免 key） | `dsh plugin --profile web add dsh-free-search` | npm `0.7.2` · MIT · `engines.dsh >= 0.1.7-rc.1` ✅ |
| 5 ⭐ | **dsh-mnemon** | 记忆：可组合、视图式三层记忆（自带 sources / strategies） | `dsh plugin --profile web add dsh-mnemon` | npm `0.5.23` · MIT · 仓库 2026-10-03 推送 |
| 6 ⭐ | **dsh-at-file** | Codex 风格 `@file` 提及：输入框搜工作区文件并附路径进提示词 | `dsh plugin --profile web add dsh-at-file` | npm `0.6.3` · MIT |
| 7 ⭐ | **dsh-plugin-subscriptions** | 把 ChatGPT(Codex) / Claude / Grok 订阅当 DSH 的 LLM provider（Web UI 内 OAuth，不用 API key） | `dsh plugin --profile web add dsh-plugin-subscriptions` | npm `0.9.7` · MIT |
| 8 ⭐ | **noatmark-dsh-plugin** | 文本卫生：净化不可信文本、扫隐形字符、清 LLM 格式、防 CSV 注入（配合不可信网页内容很实用） | `dsh plugin --profile web add noatmark-dsh-plugin` | npm `0.1.0` · MIT |

---

## 2. 视觉 / 多模态

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `@liustack/modlens` | 图像 → 结构化证据 | npm 同上 | 首选，热度与维护都最好 |
| `@anionex/dsh-vision-toolkit` | 带意图的图片问答、长截图 OCR、UI 还原、grounding、像素 diff | `dsh plugin --profile web add @anionex/dsh-vision-toolkit` | npm `0.1.46` · MIT · ★886；与 modlens 二选一即可 |

## 3. 联网搜索 / 抓取

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `dsh-free-search` | 免费搜索（DuckDuckGo） | npm 同上 | npm 可装，最省事 |
| `modsearch` | 免费搜索 + X 检索，返回结构化 JSON | `dsh plugin --profile web add github:liustack/modsearch` | 仓库声明 `@liustack/modsearch@5.10.5` **未发 npm**；npm 上同名 `modsearch` 是无关包，别装错 |
| `anysearch-dsh` | AnySearch 搜索 provider + 高级搜索工具 | `dsh plugin --profile web add github:anysearch-team/anysearch-dsh` | npm 未见同名包，只能走 github: |

## 4. 上下文 / 记忆 / 会话

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `dsh-context` | 上下文可视化与治理 | npm 同上 | 声明兼容你当前版本 |
| `billion-context` | 上下文压缩：小窗口（100K 够用）、省 token、超长会话 | `dsh plugin --profile web add billion-context` | npm `0.1.181` · MIT · ★489；与 dsh-context 互补 |
| `dsh-mnemon` | 三层记忆、可插拔来源/策略 | npm 同上 | 记忆类里维护最勤 |
| `graph-memory` | 知识图谱记忆，抽三元组、压上下文 | `dsh plugin --profile web add github:adoresever/graph-memory` | 仓库版本 `1.6.0-beta.17`（beta，谨慎）；npm 上同名包无 dsh 清单 |
| `dsh-memory-evolve` | 跨会话长期记忆 + 后台自我进化（五轨记忆、技能自进化、会话搜索） | `dsh plugin --profile web add github:csyangwen/dsh-memory-evolve` | ★351，未发 npm，github: 安装 |
| `dsh-plugin-session-import` | 导入 Claude Code / Codex 历史会话 | `dsh plugin --profile web add dsh-plugin-session-import` | npm `0.1.1` · MIT · ★7（小而专） |

## 5. 界面 / 交互增强

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `dsh-better-sidebar` | 侧边栏底座（三方页可注册） | npm 同上 | 想再装侧边栏类插件，先装它 |
| `dsh-genui` | 在回复里内联渲染交互组件：图表、表单、测验、mermaid、3D、回传事件 | `dsh plugin --profile web add dsh-genui` | npm `0.2.1` · MIT（仓库 `lhuans/dsh-genui`） |
| `@nagi-ovo/dsh-visualize` | 对话内生成交互式可视化卡片 | `dsh plugin --profile web add @nagi-ovo/dsh-visualize` | npm `0.1.4` · BSD-3 |
| `dsh-at-file` | `@file` 提及补齐 | npm 同上 | 高频好用 |
| `@deepseek-harness-tui/dsh-tui` | 终端 UI（像素鲸鱼、鼠标交互），npm 一键装 | `dsh plugin --profile tui add @deepseek-harness-tui/dsh-tui` | npm `0.12.0` · MIT · ★3976；**属 TUI profile，装到 web profile 没用** |
| `huiliyi37/dsh-tianshu-tui` | 另一套 TUI：流式 Markdown、16+ 主题、slash 命令、LSP 诊断 | `dsh plugin --profile tui add github:huiliyi37/dsh-tianshu-tui` | ★282，无 npm；同样是 TUI profile |
| 皮肤 / 主题 | 透明玻璃、海洋动态、鲸鱼娘挂件等 | 见 [dshbase 皮肤页](https://www.dshbase.com/zh/themes/) | 纯外观，注意与现有 CSS 兼容 |

## 6. 多代理 / 任务编排 / 代码质量

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `@nanmicoder/dsh-agent-teams` | AgentTeams：多代理团队 | `dsh plugin --profile web add @nanmicoder/dsh-agent-teams` | npm `0.1.22` · MIT · ★1900 |
| `toolclub/dsh-agent-team-gui` | 多模型工作流团队：动态 lead 规划、DAG、Run Center、Token 洞察 | `dsh plugin --profile web add github:toolclub/dsh-agent-team-gui` | ★281，无 npm |
| `dsh-taskboard`（shengsheng90/DSH-taskboard） | 原生本地任务板：SQLite 项目、Agent 认领/复核、原生 Web UI | `dsh plugin --profile web add github:shengsheng90/DSH-taskboard` | ★330；⚠️ npm 上的 `dsh-taskboard` 指向另一个仓库（cloader），别指望同一个 |
| `dashi-taskboard` | 可嵌入的现代任务面板 | `dsh plugin --profile web add github:chuspeeism/dashi-taskboard` | 包名实为 `codex-taskboard`，同时服务 Codex/DSH |
| `dsh-routing-suite` | 注意力工程 / 推理模式路由（injector + router 预设） | `dsh plugin --profile web add github:yjh051108/dsh-routing-suite` | ★6999，热度高；包名 `@dsh-external/dsh-super-injector`，未发 npm；属于"深度改行为"类，先读文档 |
| `brooks-lint` | 代码审查（12 本经典工程书视角、严重度标注） | `dsh plugin --profile web add github:hyhmrright/brooks-lint` | ★1500 · MIT；和已有 engineering-skills 有部分重叠 |
| `dsh-fail-logger` | 记录失败调用便于排错 | `dsh plugin --profile web add dsh-fail-logger` | npm `0.5.2` · MIT · ★10（实用小工具） |

## 7. 文档 / 办公 / 科研

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `dsh-univer-office` | 在 DSH 里预览/创建/编辑表格、文档、幻灯片（Univer 驱动） | `dsh plugin --profile web add dsh-univer-office` | npm `0.3.6` · Apache-2.0 · ★462 |
| `dsh-latex-tools` | LaTeX 相关工具链 | `dsh plugin --profile web add dsh-latex-tools` | npm `0.1.2` · MIT · ★10（README 少，先小范围试） |
| `easyeda-agent` | 嘉立创 EDA 原理图/PCB 自动化（CLI + Skill + MCP） | `dsh plugin --profile web add github:zhoushoujianwork/easyeda-agent` | ★581，硬件向 |

## 8. 模型接入 / 账号 / 成本

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `dsh-plugin-subscriptions` | 订阅当 provider（Codex / Claude / Grok） | npm 同上 | 想省 API 费最值 |
| `treg`（repo `superdesigndev/treg`） | "代理工具的 OpenRouter"，工具聚合 | `dsh plugin --profile web add github:superdesigndev/treg` | 包名 `treg-dsh`，未发 npm · ★4085 |
| `dsh-cost-meter` | **官方账户余额** + 会话/模型成本、token、预算、provider 余额、套餐额度 | `dsh plugin --profile web add dsh-cost-meter` | ✅ **2026-10-03 已装**（`1.8.6`）· MIT · ★368 · 周下载 31,807 · 声明兼容 `0.2.0-rc.2` |

### 8.1 余额 / 费用显示类插件对比（2026-10-03 调研）

npm 上这类插件非常卷（20+ 个近亲 + 一堆 fork），判断标准用**周下载量 + 最近推送 + 是否声明兼容你的版本**，别只看 Star：

| 包名 | 形态 | 周下载 | 结论 |
|---|---|---|---|
| **`dsh-cost-meter`** | 侧边栏顶部/设置页显示官方余额（总额/赠金/充值）+ 三段进度条 + 各类 Coding Plan 额度 + 会话成本 | **31,807** | ✅ 已选装：量级、维护度、功能完整度都第一 |
| `dsh-damage-pulse` | 右下角鲸鱼娘余额监控：待机/扣费/复苏动画、峰谷计费、飘字 | 3,553 | 想要"会动"的余额挂件选它（v4.2.3，MIT，★237） |
| `@alanzhao/dsh-balance-monitor` | 渠道感知余额/用量卡片（DeepSeek + 火山方舟 Agent Plan 额度条） | 1,552 | 多 provider 额度条需求 |
| `@shawnkung/dsh-balance-monitor` | 侧边栏余额与用量监控，支持 DeepSeek / Kimi / 智谱 GLM / TeamoRouter | 1,025 | 多 provider 平衡之选 |
| `dsh-balance-plugin` | 侧边栏底部一行余额（图标+金额，变价飘动） | 705 | 最克制、最不打扰 |
| `dsh-balance`（TwotwoPiggy） | 输入框下方统计条显示余额 + 本次对话估算消耗 | 382 | 与自带统计条融合得最好 |
| `dsh-balance-monitor`（yuntaojinghong） | 余额监控 + 低于阈值自动暂停任务 + 一键充值 | 124 | 想要"余额见底自动止损"选它 |
| `github:MeteorNOX/DeepSeek-Balance-Whale-Widget` | 右下角鲸鱼挂件显示 DeepSeek 余额（★3928） | — | 最热但**未发 npm**，只能 `github:` 安装（构建风险），且与 `dsh-damage-pulse` 定位重复 |

> 这些插件都通过 DSH 凭据（host 侧）调用 `https://api.deepseek.com/user/balance`，**API key 不出宿主进程**；`dsh-cost-meter` 在 `dshhub.permissions.network` 里明确列出了它要访问的域名（含 api.deepseek.com 与各家额度接口），这点比其他同类透明。
> 注意：`dsh-usage-stats`（你已装）是**历史用量分析**，不看账户余额，二者互补不冲突。

## 9. 安全 / 审计（含攻击面工具，仅授权场景）

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `noatmark-dsh-plugin` | 文本卫生、隐形字符扫描 | npm 同上 | 防提示注入的实际价值高 |
| `api-relay-audit` | 审计 API 中转/LLM 代理：提示注入、换模型、工具调用改写、SSE 异常、密钥泄漏 | `dsh plugin --profile web add github:toby-bridges/api-relay-audit` | 包名 `dsh-api-relay-audit@2.4.1` · AGPL-3.0 · 未发 npm · ★865 |
| `dsh-pentest` | 渗透测试模式（CloverSecLabs） | `dsh plugin --profile web add github:howmp/dsh-pentest` | 包名 `@howmp/dsh-pentest@0.1.0-rc.34` · 无协议声明 · ★587；⚠️ 仅授权测试 |
| `Tencent/BrowserSkill` | 让 Agent 用你**已登录的真实浏览器**（CLI + 扩展） | 见仓库 README | ★8083 · MIT；非纯 dsh 包，装法与普通插件不同 |

## 10. 互通 / 迁移 / 移动端 / 侧边生态

| 插件 | 作用 | 安装 | 备注 |
|------|------|------|------|
| `dsh-claude-marketplace` | 直接加载你已有的 `.claude` skills 与 commands | `dsh plugin --profile web add dsh-claude-marketplace` | npm `0.1.0` · MIT · ★1（作者仓库小，但代码极简、风险低） |
| `dsh-im` | 扫码把 IM 机器人接到 DSH（飞书/微信/钉钉/企微/QQ/Slack/TG/Discord/WhatsApp） | `dsh plugin --profile web add dsh-im` | npm `1.0.5` · MIT · ★1589 |
| `dsh-pocket` / iOS·Android 客户端 | 手机远程访问 / 移动端界面 | 见各自仓库 | 按设备需求选，注意远程访问的安全配置 |
| `dsh-browser`（仓库 `omdsh-dev/dsh-browser`）+ `dsh-ads`（Nagi-ovo） | Chrome 侧边栏操控浏览器 / 2005 门户风恶搞 | `dsh plugin --profile web add dsh-browser` | 仓库 ★759 · MIT · 2026-10-01 推送；npm 包无 `dsh` 清单字段，装完用 `list` 确认是否被识别 |
| `dshbase-catalog` | 插件目录插件：装一次后让 Agent 自己从目录里找并装插件 | `dsh plugin --profile web add dshbase-catalog` | npm `0.3.46`；你已有 `dshmarket`，二者功能重叠 |

## 11. 生态周边（不是"一个 dsh 插件"，但常被一起用）

这些是独立记忆/运行时系统，通过 MCP 或 SDK 接入，**不要**当成 npm 插件直接 `dsh plugin add`：

- `volcengine/OpenViking` ★39159（AGPL-3.0）— 自进化上下文数据库：Agent 记忆 + 知识 RAG + Skills
- `EverMind-AI/EverOS` ★13330（Apache-2.0）— 可移植记忆层，Markdown 原生
- `MemTensor/MemOS` ★11684（Apache-2.0）— 记忆 OS，混合检索、跨任务技能复用
- `zilliztech/memsearch` ★2709（MIT，Python）— Markdown + Milvus 的统一记忆层
- `mnemon-dev/mnemon` ★607（Apache-2.0，Go）— 图上召回、单二进制持久记忆

---

## 12. 安装 / 卸载 / 排错速查

```powershell
# 安装（会写进 profile 的 package.json：dependencies + dsh.profile.bundles）
dsh plugin --profile web add <包名 或 github:owner/repo>

# 看已装清单
dsh plugin --profile web list

# 卸载
dsh plugin --profile web remove <包名>

# 装完重启 Web 界面才会加载
dsh web
```

排错要点：

1. **优先 npm 包，慎用 `github:`**。社区对 ~900 个插件的批量审计里：551 通过、198 运行失败、164 安装失败——失败大头是「依赖版本不存在」「prepare/build 脚本失败（依赖未发布的 `@deepseek-ai/*`）」。`github:` 安装要现场构建，踩坑概率明显更高。
2. 装完先 `dsh plugin --profile web list`，再重启 `dsh web`；Web 侧插件（`dsh.client.platform = web`）必须重启页面。
3. 一次别装多个大改行为的插件（路由注入、上下文压缩、记忆、侧边栏底座）。**加一个 → 重启 → 观察一轮**，出问题好定位。
4. 安全上：`dsh plugin add` 等于让第三方代码在你的机器上、以你的权限运行（多数插件还能读写工作区）。来源不明的先用一次性 profile 试：`dsh rescue --from-default-profile web` 建一个干净 profile，再 `dsh plugin --profile rescue add <包名>`，确认无异常后再装进 `web`。
5. profile 别装错：`web` 界面用的插件装进 `web`；TUI 插件装进 `tui`（`dsh plugin --profile tui add ...`）；`headless` 用于一次性任务。
6. 版本兼容：本机 `0.2.0-rc.2`。插件 package.json 里 `dsh.compatibility.dshReleases` 会标 `compatible / unknown`，`unknown` 不代表不能用，但属于未验证。

## 13. 持续找新插件的入口

- [dshbase 插件目录](https://www.dshbase.com/zh/plugins/directory/)（7,797 条，带 L1–L4 实测与信任等级）· [审计方法](https://www.dshbase.com/zh/audit/)
- [awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)（★17668 精选列表）
- [bruc3van/awesome-dsh-plugin](https://github.com/bruc3van/awesome-dsh-plugin)（人工剔除蹭标签项目）
- [Zhiyuan-Fan/Awesome-DeepSeek-Harness-Plugins](https://github.com/Zhiyuan-Fan/Awesome-DeepSeek-Harness-Plugins)、[libukai/awesome-deepseek-harness](https://github.com/libukai/awesome-deepseek-harness)
- GitHub 话题：[`dsh-plugin`](https://github.com/topics/dsh-plugin)（按 Star / 最近推送筛）
- 本机已装的 `dshmarket` 本身就是可视化插件市场，可直接在里面逛与一键装

> 说明：以上"优质"= **仓库真实可达 + 近期有推送 + 有明确协议 + npm 可装（或清单字段完整）**，不代表我审过其源码安全性，也不代表它一定和你当前 DSH 版本完全兼容。dshbase 明确写着「上架不等于背书」——同理，这份清单只做初筛。
