# DSH 行动清单

针对环境：Windows 原生 · `DSH_HOME=D:\dsh` · CLI `0.1.0-rc.7` → 目标 `0.2.0-rc.2`

> 每步都给了可执行命令。带 ⚠️ 的是「先确认再动手」的地方。

---

## 阶段 0 · 备份与快照（约 10 分钟）

### ☐ 0.1 停止正在运行的 dsh web

升级会占用 `node_modules`，必须先停。

```powershell
Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object { $_.CommandLine -match 'dsh' } |
  Select-Object ProcessId, CommandLine
```

确认后逐个结束（注意：结束它们会关掉当前这个 GUI，请在外部终端操作）：

```powershell
Stop-Process -Id <pid>
```

### ☐ 0.2 备份 DSH_HOME（排除 node_modules，保持轻量）

```powershell
$ts = Get-Date -Format 'yyyyMMdd-HHmm'
robocopy D:\dsh "D:\dsh-backup-$ts" /E /XD node_modules .pnpm /NFL /NDL /NJH /NJS
```

至少要保住这几个文件：

- `D:\dsh\cordis.patch.yml`（你自定义的权限预设表）
- `D:\dsh\settings.yaml`（模型选择）
- `D:\dsh\profiles\web\package.json`（6 个 bundle 的清单）
- `D:\dsh\profiles\web\cordis.patch.yml`、`cordis.yml`、`pnpm-lock.yaml`
- `D:\dsh\storages\`

### ☐ 0.3 记录升级前状态，便于回滚对照

```powershell
dsh --version | Out-File "D:\dsh-backup-$ts\before-version.txt"
dsh --profile web --dump-config | Out-File "D:\dsh-backup-$ts\before-dump-config.yml"
Copy-Item "$env:APPDATA\npm\node_modules\@deepseek-ai\dsh\package.json" "D:\dsh-backup-$ts\before-cli-manifest.json"
```

### ☐ 0.4 记下你当前的自定义点（升级后要复查）

| 位置 | 内容 |
|---|---|
| `D:\dsh\cordis.patch.yml` | 权限预设表，新增 `auto-ask`，`defaultPreset: auto-ask` |
| `D:\dsh\settings.yaml` | `deepseek-official / deepseek-v4-flash`、`reasoningEffort: high` |
| `D:\dsh\profiles\web\package.json` | 6 个 bundle 的顺序 |
| `D:\dsh\profiles\web\cordis.patch.yml` | 空 `[]` |

---

## 阶段 1 · 选择升级路线（先决定，再动手）

### ⚠️ 决策点

| | 路线 A：官方 Windows 桌面端 | 路线 B：全局 npm |
|---|---|---|
| 安装 | 从 GitHub Releases 下载 Windows 安装包 | `npm install -g` |
| 依赖 | 内置 dsh，**不需要 Node/pnpm** | 需要 Node + 手工补 devDependencies |
| 插件管理 | 菜单栏内置 | 靠 `dsh plugin` 或脚本 |
| 打包缺陷 | **绕开**（自带 dsh） | 要靠 `dsh-safe-upgrade-v2.ps1` 打补丁 |
| 风险 | 新形态，行为待观察 | 已知脆，且 `latest` 标签是坏的 |

**建议走路线 A。** 理由：你已经为打包缺陷维护了一个 `dsh-safe-upgrade.ps1`，而 0.2.0-rc.2 的更新说明明确写了桌面端「无需另装 Node 或 pnpm」——这条就是为你这类环境准备的。

### ⚠️ 如果走路线 B，先看清这个坑

实测（2026-09-30）官方子包的 npm `latest` 标签指向**极旧的 0.0.1-rc.1**：

| 包 | `latest` | 真正的 0.2.0-rc.2 在哪 |
|---|---|---|
| `@deepseek-ai/dsh-base` | `0.0.1-rc.1` | `next` 标签 |
| `@deepseek-ai/dsh-llm` | `0.0.1-rc.1` | `next` 标签 |
| `@deepseek-ai/dsh-web-app` | `0.0.1-rc.1` | `next` 标签 |
| `@deepseek-ai/dsh-plugin-manager` | `0.1.6-alpha.2` | `next` 标签 |

所以你原来的 `dsh-safe-upgrade.ps1` 第 59 行 `npm install -g $toAdd`（不带版本号）**会把 dsh-base / dsh-llm / dsh-web-app 装成 0.0.1-rc.1**，装完直接起不来。这就是我写 v2 的原因。

好消息：0.2.0-rc.2 的 manifest 里 **115 个 `@deepseek-ai/dsh-*` 全部是精确版本** `0.2.0-rc.2`（没有 `^` 范围），所以照抄版本号即可，非常安全。

---

## 阶段 2 · 执行升级

### ☐ 2A 路线 A：官方桌面端

- ☐ 打开 `https://github.com/deepseek-ai/deepseek-harness/releases`，找 `v0.2.0-rc.2` 的 Windows 资产
- ☐ 下载并安装，按菜单栏的「管理 dsh 命令」把 `dsh` 装上
- ☐ 确认新 CLI 版本：`dsh --version` → 应为 `0.2.0-rc.2`
- ☐ 迁移旧配置：把阶段 0.2 备份里的 `cordis.patch.yml`、`settings.yaml`、profile 目录按需拷回
- ☐ 跳到阶段 3

### ☐ 2B 路线 B：用修正后的脚本

- ☐ 先用 `-DryRun` 看它打算做什么：

```powershell
cd D:\1
./dsh-safe-upgrade-v2.ps1 -DryRun
```

- ☐ 确认无误后正式执行（默认走 `next` 标签，即 0.2.0-rc.2）：

```powershell
./dsh-safe-upgrade-v2.ps1
```

脚本会：检查 dsh web 是否还在跑 → 备份 manifest → 装 CLI → 从新 manifest 读出版本号**逐个精确版本**补装运行时插件 → 校验实际版本 → 验证 profile 能 boot。

- ☐ 若脚本中途失败，回滚：把备份的 manifest 拷回，重装旧版本 CLI（`npm install -g @deepseek-ai/dsh@0.1.0-rc.7`），再从阶段 0.2 的备份恢复 `D:\dsh`。

### ⚠️ 2C 升级后必查的破坏性变更

| 变更 | 你要做什么 |
|---|---|
| **默认模型列表移除 V4 Flash** | 你的 `settings.yaml` 正是 `deepseek-v4-flash` → 进设置重选模型 |
| Agent 预设改由插件组合包声明，**旧目录预设需迁移** | 你用的是 `standard` 预设，确认它还在且能选 |
| 官方适配器**仅用 Messages API** | 若手配过官方根地址，删掉或改成 `https://api.deepseek.com/anthropic` |
| 新增插件版本兼容性检查 | profile 加载时会有新提示，留意「不兼容」告警 |
| 插件依赖改为**运行时解析** | `dsh-file` / `dsh-toolkit` 需重新验证加载与卸载 |
| 移除内置 E2B 执行后端 | 若有相关自定义配置要调整 |
| 弃用 `snapshotEvents`/`eventAt`/`ownEvents` | 若有插件/脚本用这些接口，需适配 |
| `Inspector` 不再默认包含 | Auto review 要从插件页单独开启 |
| pi-ai 升到 0.87.1，部分旧模型 ID 移除 | 已保存的模型选择可能要重选 |

---

## 阶段 3 · 重新装配 profile 的 6 个 bundle

⚠️ **逐个加，别一次性全开** —— 一次加一个，每次 `dsh --profile web --dump-config` 确认能 boot。

参考：[awesome-dsh-plugin 收录标准](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)要求「能 `dsh plugin add` 装上 + 描述属实 + 有人维护」，但**上清单 ≠ 安全审计**。

### ☐ 3.1 先加回官方与稳定项

```powershell
dsh plugin --profile web add @deepseek-ai/dsh-base
dsh plugin --profile web add @deepseek-ai/dsh-web-app
dsh plugin --profile web add dsh-notify-win
```

### ☐ 3.2 本地插件（`dsh-file`）—— 需要重新验证

```powershell
dsh plugin --profile web add "file:D:/1/plugins/dsh-file"
cd D:\1\plugins\dsh-file
npm run build
npm test
```

然后手工确认它的 `peerDependencies`：

- ☐ `@deepseek-ai/dsh-typert-protocol: ^0.1.0-rc.6` → 抬到新版本
- ☐ `@deepseek-ai/cordis: ^4.0.1` → 确认仍兼容
- ☐ 验证「运行时安装/卸载」下 gateway 能否正常注册与回收
- ☐ 顺手提交未提交的 `package-lock.json`

### ☐ 3.3 git 来源的两个第三方 bundle

```powershell
dsh plugin --profile web add "github:omdsh-dev/dsh-toolkit"
dsh plugin --profile web add "github:xiaoxiaosrm/dsh-mattpocock-skills"
```

⚠️ 这两个上游都偏静默（`dsh-toolkit` 最后推送 2026-09-10，28⭐；mattpocock skills 2026-09-05，8⭐）。升级后若 boot 失败，**优先怀疑它们**，用 `dsh plugin --profile web remove` 摘掉验证。

### ☐ 3.4 每步之间的验证命令

```powershell
dsh --profile web --dump-config | Select-String 'disabled'   # 看有没有新的禁用项
dsh web
```

---

## 阶段 4 · 装新插件（按批次，逐个验证）

⚠️ **装任何插件前先确认来源**：npm 包名不一定等于清单里的 GitHub 仓库。用
`npm view <name> repository` 或 `npm view <name> homepage` 核对 owner。

### ☐ 4.1 第一批：发现与管理层（最高杠杆，先装这个）

装完之后你就不用再手翻任何清单了。

```powershell
dsh plugin --profile web add dshmarket              # 插件市场，设置页一键装/升级
dsh plugin --profile web add dsh-find-plugin        # 让 agent 按关键词找插件
dsh plugin --profile web add dsh-plugin-scorecard   # 全生态质量 + 安全评分
dsh plugin --profile web add dsh-insight            # 按需求匹配「哪些值得装」
dsh plugin --profile web add dsh-plugin-doctor      # 社区搜索 / 相似度 / 去重决策
```

已验证均在 npm 上：`dshmarket@1.66.6`、`dsh-find-plugin@0.4.0`、`dsh-plugin-scorecard@0.3.2`、`dsh-insight@0.1.0`、`dsh-plugin-doctor@0.1.1`。

### ☐ 4.2 第二批：Windows 原生（对口你这台机器）

```powershell
dsh plugin --profile web add dsh-win-toolkit        # 剪贴板/通知/hosts/网络诊断
dsh plugin --profile web add dsh-windows-ocr        # Windows 内置 OCR，图片不出本机
dsh plugin --profile web add dsh-bash-terminal-ts   # 四后端 shell + PTY
dsh plugin --profile web add dsh-plugin-notify      # Windows toast + 托盘
dsh plugin --profile web add computer-user          # Windows computer use
```

git-only（npm 上没有），用 `github:` 形式：

```powershell
dsh plugin --profile web add "github:lucifergzsz414/dsh-windows-native"   # 注入非 WSL 的 Windows 坑
dsh plugin --profile web add "github:wwwort/dsh-win-computer-use"
dsh plugin --profile web add "github:deepseekbluefish/dsh-screenshot-plugin"
dsh plugin --profile web add "github:SanYe-SanJiu/dsh-power-switch"
dsh plugin --profile web add "github:ZichengGurrr/dsh-window"             # WebView2 窗口（v0.0.4，很早期）
```

### ☐ 4.3 第三批：可靠性 / 体检

```powershell
dsh plugin --profile web add dsh-session-health     # zstd 会话撕裂/损坏检测
dsh plugin --profile web add dsh-security-audit     # 本地安全审计
dsh plugin --profile web add dsh-plugin-ops         # 启动前健康门禁 + 修复
dsh plugin --profile web add "github:Zhenyu98/dsh-context-doctor"        # 上下文 token 成本审计
dsh plugin --profile web add "github:crTnT/dsh-plugin-suite"             # 含插件更新器（备份/回滚）
```

### ☐ 4.4 每装一批后的验收

- ☐ `dsh --profile web --dump-config` 无新报错
- ☐ `dsh web` 能起，GUI 正常
- ☐ 挑一个该批次的核心功能点实测一次
- ☐ 任一出问题 → `dsh plugin --profile web remove <name>`，二分定位

---

## 阶段 5 · 清理过时项

### ☐ 5.1 停用/移除依赖旧机制的插件

「动态 Cordis 插件」在 0.1.7+ 已改为「通过 Plugin Manager 安装持久化插件」。若你之前装过清单里标注 *"a dynamic Cordis plugin"* 的条目，逐个确认是否仍工作。

### ☐ 5.2 别装这些（为旧版本行为打的补丁，升级后是负担）

| 插件 | 为什么 |
|---|---|
| `azazo1/dsh-deep-diving-back` | 恢复 **0.1.6 及更早**的状态行，新版本行为已变 |
| `kahomesl/dsh-chat-diff-summary-legacy` | 名字里就带 legacy |
| `Aliww2468/dsh-client-ui-aqua-patched` | fork 到 0.1.2-rc.1 才修好 |
| `Harzva/dsh-superterminal` | 针对 0.1.1-rc.2 |
| `WongYuYe/dsh-composer-recall` | 针对 0.1.2-alpha.1 |

### ☐ 5.3 处理那份不可信的本地清单

`D:\1\awesome-deepseek-harness.md`（343 KB / 1651 条）的问题：

- 只有 43 条有 star 数据，1608 条无任何热度信息
- star 快照严重失真：写 `deepseek-harness` = 38,238⭐，实时 API 是 **240,925⭐**
- 22 个同名集群：**31 个账号都叫 `deepseek-harness-desktop`**，10 个账号各发一个 `dsh-archive-manager`

☐ 建议重命名为 `awesome-deepseek-harness.UNVERIFIED.md`，或直接删除
☐ 改用已存档的 `D:\1\awesome-dsh-plugin-canonical.md`（4418 条，有收录门槛）

### ☐ 5.4 目录与仓库卫生

- ☐ 删掉迁移前的残留会话目录：`C:\Users\<user>\.dsh\sessions`（2 个空目录）
- ☐ 清理 `@deepseek-ai\dsh` 目录里遗留的 `package.json.bak`
- ☐ 提交 `D:\1\plugins\dsh-file` 的 `package-lock.json`
- ☐ 旧的 `D:\1\dsh-safe-upgrade.ps1` 归档或删除，改用 `dsh-safe-upgrade-v2.ps1`

### ☐ 5.5 可选：重新开启 HMR

`cordis-plugin-hmr` 与 `client-hmr` 目前 `disabled: true`，改插件要重启。若你经常调插件，可在 profile 层打开。**注意**：本会话提到客户端插件热更还需要 `pnpm run dev:web` 在跑同一 checkout，否则要刷新页面。

---

## 阶段 6 · 验收

### ☐ 6.1 基础

```powershell
dsh --version                                  # 期望 0.2.0-rc.2
dsh --profile web --dump-config | Measure-Object -Line
dsh web                                        # GUI 能起，127.0.0.1:3080
```

### ☐ 6.2 关键功能回归

- ☐ 新会话能创建、标题能生成
- ☐ 模型能选中并正常回话（**重点：V4 Flash 已从默认列表移除**）
- ☐ pwsh 工具正常（`dsh-tool-pwsh` + `dsh-pwsh-sandbox`）
- ☐ 权限预设 `auto-ask` 仍生效（danger-full-access + approval ask）
- ☐ `dsh-file` 文件管理器能打开、能编辑
- ☐ 通知类插件能弹（`dsh-notify-win` 或新装的 `dsh-plugin-notify`）

### ☐ 6.3 记录新基线

```powershell
$ts = Get-Date -Format 'yyyyMMdd-HHmm'
dsh --profile web --dump-config | Out-File "D:\1\after-upgrade-dump-$ts.yml"
npm ls -g --depth=0 | Out-File "D:\1\after-upgrade-global-$ts.txt"
```

---

## 一页速览

| 阶段 | 关键动作 | 为什么 |
|---|---|---|
| 0 | 停服务 → 备份 `D:\dsh` → 存 dump | 可回滚 |
| 1 | 选路线 A（官方桌面端）| 绕开 devDependencies 打包缺陷 |
| 2 | 升级 + 复查 9 项破坏性变更 | V4 Flash 被移除、预设机制变更 |
| 3 | 逐个加回 6 个 bundle，重验 `dsh-file` | 一次全开会让归因变难 |
| 4 | 装 dsh-market 系 → Windows 原生 → 体检类 | 先解决「怎么选插件」 |
| 5 | 清旧机制插件 + 弃用不可信清单 | 去掉历史包袱和噪声源 |
| 6 | 回归测试 + 存新基线 | 下次升级有对照 |

---

## 附：本次产出的文件

| 文件 | 用途 |
|---|---|
| `dsh-升级行动清单.md` | 本清单 |
| `dsh-safe-upgrade-v2.ps1` | 修正版升级脚本（精确版本，修掉 v1 的 0.0.1-rc.1 陷阱）|
| `dsh-环境体检与插件建议.md` | 体检报告与完整插件分析 |
| `awesome-dsh-plugin-canonical.md` | 权威社区清单存档（4418 条）|
| `dsh-release-notes-recent.md` | 官方 release notes（0.1.5-rc.2 → 0.2.0-rc.2）|
