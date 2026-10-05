# DSH 运行环境体检 + 插件建议

体检时间：2026-09-30 · 机器：Windows（原生，非 WSL）· DSH_HOME=`D:\dsh`

---

## 一、环境现状

| 项目 | 实际值 |
|---|---|
| dsh CLI | **0.1.0-rc.7**（2026-08-17 发布），全局装在 npm prefix |
| npm `latest` | **0.2.0-rc.2**（2026-09-29 发布）|
| 启动方式 | `npx @deepseek-ai/dsh web` → node pid 7860，监听 `127.0.0.1:3080` |
| DSH_HOME | `D:\dsh`（`~/.dsh` 是旧位置残留）|
| profile | `D:\dsh\profiles\web`，6 个 bundle |
| loader 条目 | 133 个 |
| 模型 | `deepseek-official / deepseek-v4-flash`，`reasoningEffort: high` |
| 权限 | home patch 覆盖 preset 表，新增 `auto-ask`（danger-full-access + approval ask）并设为 defaultPreset |
| 工具链 | node 24.14.0 / npm 11.19.0 / pnpm 11.22.0 / git 2.56.0 |
| Web GUI | HTTP 200，正常 |

### profile 里装的 6 个 bundle

| bundle | 来源 | 备注 |
|---|---|---|
| `@deepseek-ai/dsh-base` | registry | 官方 |
| `@deepseek-ai/dsh-web-app` | registry | 官方 |
| `@deepseek-ai/dsh-toolkit` | `git+github.com/omdsh-dev/dsh-toolkit` | 第三方，上游 28⭐，最后推送 2026-09-10 |
| `dsh-notify-win` | npm `^0.1.1` | Windows toast |
| `dsh-file` | `file:D:/1/plugins/dsh-file` | 本地软链，VS Code 风格文件管理器 |
| `@mattpocock-community/dsh-engineering-skills` | `git+github.com/xiaoxiaosrm/dsh-mattpocock-skills` | 8⭐，最后推送 2026-09-05 |

---

## 二、可优化项（按优先级）

### P0 — DSH 本体落后 12 个版本

`0.1.0-rc.7` → `0.2.0-rc.2` 之间经过了
`rc.8, 0.1.1-rc.1/2, 0.1.2-alpha.2~5, 0.1.2-rc.1, 0.1.3-alpha.2, 0.1.5-alpha.1/2, 0.1.5-rc.1/2/3, 0.1.6-alpha.1/2, 0.1.7-alpha.1/2, 0.1.7-rc.1/2, 0.2.0-rc.1/2`。

**直接后果：当前生态里大量新插件要求比你新的 DSH，你装不上。**已确认的硬性要求：

| 插件 | 要求 |
|---|---|
| `genius-alray/dsh-model-picker` | Requires DSH **0.1.5-rc.2+** |
| `langyo/dsh-mobile-upgrade` | Requires DSH **0.1.5-rc.1** |
| `ruisenbai/dsh-annotation` | Requires DSH **0.1.6-alpha.2** |
| `whiteS18/dsh-bing-search` | 适配 **0.1.5-rc.1** |
| `wx-yss/dsh-composer-enter` | 针对 **0.1.5** |
| `WongYuYe/dsh-composer-recall` | 针对 **0.1.2-alpha.1** |
| `Aliww2468/dsh-client-ui-aqua-patched` | fork 修到 **0.1.2-rc.1** |

### P0 — 包装缺陷使升级很脆，但已有官方解法

`@deepseek-ai/dsh` 的发布清单**至今**把核心运行时包放在 `devDependencies`（已核对 0.2.0-rc.2：`dsh-llm`、`dsh-agent`、`dsh-session`、`dsh-host-webserver` 仍在 devDeps），所以 `npm i -g` 装不全、`dsh web` 起不来 —— 这正是 `dsh-safe-upgrade.ps1` 存在的原因。

**但 0.2.0-rc.2 的更新说明里有一条直接解决它**：

> macOS／Windows 桌面端可在菜单栏中管理和安装 dsh 命令，支持管理插件，无需另装 Node 或 pnpm。

→ 官方 Windows 桌面端内置 dsh 并管理插件，**可以彻底绕开全局 npm 的打包缺陷**，比继续维护 safe-upgrade 脚本更稳。

### P1 — `dsh-safe-upgrade.ps1` 自身有个真 bug

第 59 行：

```powershell
npm install -g $toAdd     # 不锁版本
```

manifest 里写的是 `^0.1.0-rc.7`，按 semver 其**上界是 0.2.0**。直接装 latest（=0.2.0-rc.2）会**越界混装**：CLI 与插件次版本不一致。应改成按 CLI 自身版本锁死：

```powershell
$ver = $manifest.version
npm install -g ($toAdd | ForEach-Object { "$_@$ver" })
```

### P1 — 插件生态已改变加载机制，本地插件需重新验证

更新说明中的两条关键变更：

- 「插件依赖解析模式调整为**运行时解析**，插件管理支持运行时卸载，请开发者检查插件加载和卸载逻辑」
- 「创造模式**移除原 Cordis 动态定义及运行工具**，调整为通过 Plugin Manager 安装持久化插件」

→ 你的 `dsh-file` 声明了 `peerDependencies: @deepseek-ai/dsh-typert-protocol ^0.1.0-rc.6`，升级后必须重新验证。

### P2 — HMR 被禁用

`cordis-plugin-hmr` 与 `client-hmr` 都 `disabled: true`。改插件/前端需重启 `dsh web`，不能热更。

### P2 — 配置与残留清理

- profile 层 patch `D:\dsh\profiles\web\cordis.patch.yml` 是空的 `[]`，所有覆盖都靠 home patch。建议把权限预设这类「机器级」之外的调优放进 profile 层，便于随 profile 迁移。
- `C:\Users\<user>\.dsh\sessions` 有 2 个空会话目录，是 DSH_HOME 迁到 `D:\dsh` 之前的残留，可删。
- `dsh-file` 仓库 `git status` 有 `M package-lock.json` 未提交。
- `@deepseek-ai/dsh` 目录里留了一个 `package.json.bak`，且 `package.json` 与它有两行差异（`dsh-tool-subagent`、`dsh-session` 行序不同）—— 说明装的时候被脚本改过 manifest。升级前建议以 registry 原始 manifest 为准。

### P3 — 无关但存在：卡巴斯基

`kav_report.txt` 显示持续「数据库已过期」与「找不到更新源」（2026-07-23 起）。与本任务无关，但说明安全软件定义库是旧的。

---

## 三、那份本地 `awesome-deepseek-harness.md` 不可信

**结论：不要按它装插件。**证据：

| 指标 | 数据 |
|---|---|
| 条目总数 | 1651 |
| 带 star 数据的条目 | **仅 43 条（2.6%）**，1608 条无任何热度信息 |
| star 数据失真 | 它写 `deepseek-harness` = 38,238⭐，**实时 API 是 240,925⭐** |
| 同上 | 它写 `zhu1090093659/dsh-web-ui` = 506⭐，同主体实际仓库 `dsh-web` = **8,217⭐**（2026-09-30 仍在推送）|
| 同上 | 它写 `omdsh-dev/DSH-better-sidebar` = 127⭐，实际 **3,922⭐** |
| 同名多主体集群 | **22 个**集群（≥3 个不同账号发同名仓库），**151 条**条目落在里面 |
| 最严重的集群 | **31 个**不同账号都叫 `deepseek-harness-desktop`；22 个 `dsh-desktop`；14 个 `dsh-plugins`；13 个 `dsh-launcher`；**10 个账号各发一个 `dsh-archive-manager`** |

这是一个低信噪比聚合页，特征是：star 快照严重过期、海量零热度同名刷量仓库、无收录标准。

### 权威替代

`awesome-dsh-plugin/awesome-dsh-plugin` —— **17,447⭐**，2026-09-29 更新，是社区策展清单：

- **4418 条**，23 个分类
- 有明确收录门槛：必须能 `dsh plugin add` 装上、描述与实际相符、归对分类、并**有人维护**；不满足的条目会被移除
- 官方推荐装法：`dsh plugin --profile web add dshmarket`（插件市场，一键装/升级）
- 聊天式查找：`dsh-find-plugin`
- 带明确安全警告：**装插件=在本机以你自己的权限运行第三方代码，工具审批不会沙箱化插件代码**，上清单 ≠ 安全审计

已存档到 `D:\1\awesome-dsh-plugin-canonical.md`（1.34 MB），可离线查阅。

---

## 四、值得装的插件（针对你的场景：原生 Windows + dsh web + pwsh 沙箱）

### 第一优先：先把「发现/管理/体检」这层装上

| 插件 | 理由 |
|---|---|
| `dsh-market/dsh-market` | 官方清单首推。设置页里浏览/搜索/一键装插件，含主题切换 |
| `awesome-dsh-plugin/dsh-find-plugin` | 让 agent 自己按关键词找插件，不用手翻清单 |
| `863683348/dsh-plugin-scorecard` | 对全生态 `dsh-plugin` topic 做**质量与安全评分**——正是解你这份困惑的药 |
| `863683348/dsh-plugin-audit` | 生态级插件健康审计（维护度打分）|
| `863683348/dsh-insight` | 描述就是「**哪些值得装**」：`plugin_guide` 按需求匹配插件 |
| `white-sand-grand/dsh-plugin-doctor` | 社区搜索 + 相似度分析 + 装/去重/自己写的决策 |
| `crTnT/dsh-plugin-suite#dsh-plugin-updater` | 已装插件的检查更新 / 备份 / 回滚 |

### Windows 原生（对口你这台机器）

| 插件 | 作用 |
|---|---|
| `Edge-Echo/dsh-win-toolkit` | Windows-native：剪贴板读写、系统通知、hosts 文件检查、网络诊断 |
| `lucifergzsz414/dsh-windows-native` | 把「原生 Windows（**非 WSL**）的 PowerShell、编码、文件系统、跨平台构建坑」注入 system prompt |
| `Pasumao/dsh-plugin-notify` | Windows 原生 toast + 系统托盘图标（与你在用的 `dsh-notify-win` 可对比）|
| `ZichengGurrr/dsh-window` | WebView2 原生桌面窗口（官方桌面端之外的轻量方案）|
| `SanYe-SanJiu/dsh-power-switch` | Windows-only 进程控制，侧栏按钮走 host 自身优雅退出路径 |
| `drscrewdriver/dsh-bash-terminal-ts` | 四后端 shell（PowerShell / Git Bash / WSL / MSYS2）+ 交互式 PTY |
| `deepseekbluefish/dsh-screenshot-plugin` | 微信式应用内截图选区，8 个缩放柄 |
| `maxwell-feng/dsh-windows-ocr` | 用 Windows 内置 OCR 引擎（`Windows.Media.Ocr`），**图片不出本机**，只把文字发给模型 |
| `wwwort/dsh-win-computer-use` | Windows-native computer use，一次批量调用做 find/click/type/read/wait |
| `jing-hy/computer-user` | Windows-only computer use，PowerShell + Win32 SendInput，9 个工具 |
| `runcat-tommy/dsh-windows-c-cleanup` | C 盘清理：规则扫描、五级安全分级、暂存区 + 回滚账本、UAC 提权 |

### 运维/可靠性（低成本高收益）

| 插件 | 作用 |
|---|---|
| `omdsh-dev/dsh-session-health` | 只读零依赖会话健康检查：多帧 zstd 会话文件的 撕裂/损坏/空 检测 |
| `omdsh-dev/dsh-security-audit` | 本地安全审计：配置、插件来源、会话、网络暴露的脱敏风险报告 |
| `Zhenyu98/dsh-context-doctor` | 上下文注入审计：量出 AGENTS.md 指令链、skill 目录、tool schema 的 token 成本，检测重复与冲突 |
| `f-infinite-z/dsh-plugin-ops` | 启动前健康门禁 + 修复：7 条静态扫描规则、故障归因 |
| `Dariandai/dsh-starter-pack` | 策展起步包：批量安装并配置 15 个已筛过的社区插件 |

> 注意：你的环境里 Hermes/pwsh 已由官方 `dsh-tool-pwsh` + `dsh-pwsh-sandbox` 覆盖，`dsh-bash-terminal-ts` 属于增量而非必需。

---

## 五、已过时 / 建议清理

### 1. DSH 本体 `0.1.0-rc.7` —— 最该处理的"过时"

不只是版本号旧：0.2.0 之前引入了**插件版本兼容性检查**（「插件安装和启动会检查与当前 DSH 版本的兼容性；不兼容时说明原因，并可对确切版本授予例外」），你现在的版本没有这个机制，装到不兼容插件时不会有明确提示，只会静默出错。

### 2. 本地 `awesome-deepseek-harness.md` —— 数据已过时且不可信

见第三节。建议删除或降级为「仅作灵感库」，不要当安装来源。

### 3. 依赖「动态 Cordis 插件」旧机制的插件

0.1.7+ 起：创造模式移除原 Cordis 动态定义及运行工具，改为通过 Plugin Manager 安装持久化插件。清单里大量标注 *"a dynamic Cordis plugin"* 的条目是按旧机制写的（例：`Monokuna-Hugo/dsh-kaoyan-english`、`Cassius0924/dsh-usage-dashboard`、`KevinWen7415/dsh-virtual-workspace`）。升级后行为不确定。

### 4. 为 0.1.6 及更早行为打的补丁插件 —— 将成为历史包袱

| 插件 | 明确写着 |
|---|---|
| `azazo1/dsh-deep-diving-back` | 恢复 **DSH 0.1.6 及更早** 的蓝色「深度思考」状态行 |
| `kahomesl/dsh-chat-diff-summary-legacy` | 名字里就带 **legacy** |
| `Aliww2468/dsh-client-ui-aqua-patched` | fork 到 **0.1.2-rc.1** 才修好 |
| `Harzva/dsh-superterminal` | 针对 **0.1.1-rc.2** |
| `ruisenbai/dsh-annotation` | Requires **0.1.6-alpha.2**（低于你要升到的版本，反而要确认是否已跟进）|

### 5. 你自己的 `dsh-file` 插件

- `peerDependencies` 写 `@deepseek-ai/dsh-typert-protocol: ^0.1.0-rc.6`
- 0.2.0 改了插件**依赖解析时机**（→ 运行时解析）与启停逻辑
- `dist/` 已从版本控制移出，靠 `prepublishOnly` 构建
→ 升级后需重新验证加载/卸载，并考虑抬 peer 版本上界。

### 6. `dsh-safe-upgrade.ps1`

思路（重装 manifest 里的 devDeps）在 0.2.0-rc.2 仍然必要，但脚本本身不锁版本（见 P1）。若改用官方 Windows 桌面端，此脚本可整体废弃。

---

## 六、升级到 0.2.0-rc.2 的破坏性变更清单

来自官方 release notes（已存 `D:\1\dsh-release-notes-recent.md`，覆盖 0.1.5-rc.2 → 0.2.0-rc.2）：

**会影响你的**

| 变更 | 影响 |
|---|---|
| 插件安装/启动检查 DSH 版本兼容性，不兼容可对确切版本授权例外 | profile 加载时会有新提示；旧插件可能被判不兼容 |
| Agent 预设改由插件组合包声明和安装，**旧目录预设需迁移** | 你用的是 `standard` 预设 |
| 官方 DeepSeek 适配器**仅用 Messages API**，移除 Chat Completions 与 `protocol` 选项 | 手配过旧官方根地址的要删掉，或改为 `https://api.deepseek.com/anthropic` |
| **默认模型列表移除 V4 Flash** 和 V4 Flash Vision Exp | 你的 `settings.yaml` 正是 `deepseek-v4-flash`，可能要重选 |
| 第三方模型目录升到 pi-ai 0.87.1，部分旧模型 ID 被移除 | 已保存的模型选择可能需要重新选 |
| 插件依赖解析改为运行时解析，支持运行时卸载 | 插件作者需检查加载/卸载逻辑 |
| 无法读取的可选插件包不再直接中止 Profile 加载 | 是好事，但会掩盖坏插件——配合 `dsh-plugin-ops` 体检 |

**其他**

- 移除内置 E2B 执行后端，相关自定义配置需调整
- 弃用 Session 同步历史接口 `snapshotEvents`、`eventAt`、`ownEvents`
- `Inspector` 不再默认包含，需单独安装（Auto review 从插件页开启）
- 仅存于 custom events 的附件不再被自动读取/导出，插件需适配
- Node PTC 改用独立进程执行，`process.env` 为空，依赖旧执行环境的代码需适配
- Windows 沙箱权限脚本改为经授权一次完成诊断与修复，保留修改前备份和恢复命令

---

## 七、建议执行顺序

1. **备份** `D:\dsh`（至少 `profiles/web/package.json`、`cordis.patch.yml`、`settings.yaml`、`storages/`）。
2. **优先评估官方 Windows 桌面端**——内置 dsh 与插件管理，免 Node/pnpm，直接消除 devDependencies 打包缺陷和 safe-upgrade 脚本的维护负担。
3. 若坚持全局 npm 路线：先修 `dsh-safe-upgrade.ps1` 的版本锁定，再升到 `0.2.0-rc.2`。
4. 升级后**逐个重装** profile 的 6 个 bundle，先不要一次性全开。
5. 装 `dsh-market` + `dsh-plugin-scorecard` + `dsh-plugin-doctor`，之后靠它们而不是本地那份 md 来选插件。
6. 处理第五节的历史包袱插件，并重新验证 `dsh-file`。
7. 删掉 `C:\Users\<user>\.dsh\sessions` 残留。

---

## 附：本次新增的本地文件

| 文件 | 内容 |
|---|---|
| `dsh-环境体检与插件建议.md` | 本报告 |
| `awesome-dsh-plugin-canonical.md` | 权威社区清单全量存档（4418 条，1.34 MB）|
| `dsh-release-notes-recent.md` | 官方 release notes（0.1.5-rc.2 → 0.2.0-rc.2，含中英对照）|
