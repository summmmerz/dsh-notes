# DSH 升级后状态与修复记录

时间：2026-10-01 · 结果：`0.1.0-rc.7` → **`0.2.0-rc.2` 升级成功**，但引入了 3 处故障，已修 2 处。

---

## 一、升级对 DSH_HOME 的结构性改动

`D:\dsh` 的布局被重构了，不只是版本号变了：

| 变化 | 说明 |
|---|---|
| `D:\dsh` 本身变成了一个 profile | 新增 `package.json` / `cordis.yml` / `pnpm-lock.yaml`；`dsh web` **不使用**它，但它的 `package.json` 里还留着旧的 6 个 bundle |
| 设置改为**按 profile 存储** | `@deepseek-ai/dsh-settings` 现在是 `disabled: !ctx.get('profileContext')`；旧的家目录 `settings.yaml` 被改名成 `settings.yaml.imported` |
| 新增 `@deepseek-ai/dsh-authorization` | 授权与设置拆成两个插件 |
| 新增 `.credentials.yaml` | 凭据独立存储 |
| 新增 `profiles\web\.plugin-manager\` | 插件管理器日志目录（`dsh plugin` 操作会落盘） |
| `D:\dsh\cordis.patch.yml` **被重置为空模板** | 你的自定义权限预设被清空（见故障 2） |
| `D:\dsh\profiles\web\cordis.patch.yml` | 你自己把设置迁移进来了（模型 + baseURL），这个做法是对的 |

---

## 二、故障 1（已修）：内置 skill 系统被禁用

### 现象

```
dsh: disabling profile plugin row "skill-filesystem": Plugin
@deepseek-ai/dsh-skill-filesystem@0.0.1-rc.3 is incompatible with dsh 0.2.0-rc.2
```

连**内置**的 `skill-filesystem` 都被禁用了 —— 所以 skill 目录加载失效，可用 skill 只剩 1 个。

### 根因（一条完整的因果链）

1. `@mattpocock-community/dsh-engineering-skills@0.3.0` 的依赖写的是通配符：
   ```json
   "dependencies": { "@deepseek-ai/dsh-skill-filesystem": "*" }
   ```
2. `@deepseek-ai/dsh-skill-filesystem` 的 npm `latest` 标签指向**极旧的 `0.0.1-rc.3`**（真正的 `0.2.0-rc.2` 在 `next` 标签上）。
3. pnpm 把 `*` 解析成 `latest` = `0.0.1-rc.3`，且因为 `nodeLinker: hoisted` 把它**提升到 profile 顶层** `node_modules`。
4. Node 解析时先命中 profile 顶层的陈旧副本，**遮蔽**了 CLI 里正确的 `0.2.0-rc.2`。
5. 兼容性检查发现 `0.0.1-rc.3` 的 peerDeps 是 `^0.0.1-rc.3` 系列 → 判定不兼容 → 禁用该行。内置行也读同一个陈旧副本，一并被禁。

根因不在 DSH，而在**第三方 bundle 用 `*` 拉官方包 + 官方包 `latest` 标签陈旧 + pnpm 提升**三者叠加。

### 修复

在 `D:\dsh\profiles\web\pnpm-workspace.yaml` 加 override（注意：pnpm 11 已不再读取 `package.json` 里的 `pnpm` 字段，放那里会被静默忽略并告警）：

```yaml
overrides:
  '@deepseek-ai/dsh-skill-filesystem': 0.2.0-rc.2
```

然后 `dsh plugin --profile web install`。

### 验证

| 检查项 | 结果 |
|---|---|
| profile 内 `dsh-skill-filesystem` 版本 | `0.2.0-rc.2` ✅ |
| 残留的 `0.0.1-rc.*` 包 | 无 ✅ |
| `cordis`（peer 要求 `~4.0.4`） | `4.0.4` ✅ |
| `dsh-fs` / `dsh-skill` / `dsh-home-paths` | 均为 `0.2.0-rc.2` ✅ |
| profile 组合结果 | 无任何 `incompatible` / `disabling` 告警 ✅ |

**这是根治，不是用豁免硬扛** —— 不需要 `allow-version`。（顺带确认：`dsh plugin` 只是把参数原样透传给 pnpm，CLI 里并没有 `allow-version` 子命令，错误信息给的那条路走不通。）

---

## 三、故障 2（已修）：自定义权限预设被清空

### 现象

`D:\dsh\cordis.patch.yml` 被升级重置成了空模板 `[]`。

### 为什么必须恢复

0.2.0 内置只剩 3 个预设，且 `danger-full-access` 是 **`approval: never`（完全不问）**：

```yaml
read-only:          sandbox: read-only          approval: ask
workspace-write:    sandbox: workspace-write    approval: ask
danger-full-access: sandbox: danger-full-access approval: never   # ← 比你原来的配置更危险
```

你原来的 `auto-ask` = 放开沙箱 **但保留确认**，比内置的 `danger-full-access` 更稳妥。不恢复的话，重启后要么退回过严的 `workspace-write`，要么在 UI 里选到"完全不问"的那个。

### 修复

已按升级前的原文恢复 `D:\dsh\cordis.patch.yml`，还原 4 个预设（含 `auto-ask`）并设 `defaultPreset: auto-ask`。已用 `--dump-config` 确认组合结果正确、中文显示正常。

> ⚠️ 这会把默认沙箱放回 `danger-full-access`（保留 approval: ask）。这是你升级前的自觉配置，如果现在想要更严的默认，把 `defaultPreset` 改成 `workspace-write` 即可。

---

## 四、故障 3（已修）：`dsh-file` 被拒

> **⚠️ 更正**：本节最初我判定为「Typert API 被移除、需改代码重写」。**那个结论是错的。**
> 我当时查的是「CLI 自身 manifest 的**直接**依赖」，而 Typert 是**传递依赖**，所以查漏了。
> 实际复核后：Typert 层在 0.2.0 里**完好存在**。详见 4.1。

### 4.1 `dsh-file` —— 只是 semver 范围问题（已修）

报错：
```
Plugin dsh-file@0.1.1 is incompatible with dsh 0.2.0-rc.2:
peerDependencies {"@deepseek-ai/dsh-typert-protocol":"^0.1.0-rc.6"}
```

**真实原因**：`^0.1.0-rc.6` 按语义化版本展开是 `>=0.1.0-rc.6 <0.2.0`，把 `0.2.0-rc.2` 排除在外了。纯粹是范围问题。

复核证据 —— Typert 在 0.2.0 里完全存在：

| 包 | CLI 内实际版本 |
|---|---|
| `@deepseek-ai/dsh-typert-protocol` | `0.2.0-rc.2` ✅ |
| `@deepseek-ai/dsh-typert-registry` | `0.2.0-rc.2` ✅ |
| `@deepseek-ai/dsh-typert-loader` | `0.2.0-rc.2` ✅ |
| `@deepseek-ai/dsh-api-gateway` | `0.2.0-rc.2` ✅ |
| `@deepseek-ai/dsh-api-remotes` | `0.2.0-rc.2` ✅ |

而且 API 面**完全没变**，`dsh-file` 用到的全部导出都还在：
`TypertRemoteService`（抽象类）、`Remote`（装饰器）、`TypertRemoteContribution`、`RemoteResult`、`TypertRemoteNamespaceMap`。

（顺带印证了老问题：`dsh-typert-protocol` 的 `latest` 标签停在 `0.1.0-rc.6`，真正的最新版在 `next`。）

**修复**：改 `D:\1\plugins\dsh-file` 的 peer 范围到 `^0.2.0-rc.2`，按 `AGENTS.md` 的 SemVer 要求把版本 `0.1.1` → `0.1.2`（README 徽章与 tarball 示例同步更新），重新构建、测试、装回 profile。

| 验证项 | 结果 |
|---|---|
| `npm install` 解析到的 typert-protocol | `0.2.0-rc.2` ✅ |
| `node build.mjs` | host + client 均产出 ✅ |
| `npm test` | 12/12 通过 ✅ |
| 装回 profile 后组合 | 无任何不兼容告警 ✅ |

### 4.2 `dsh-toolkit` —— 确实结构上排斥 0.2.0（保留但不启用）

它的 peerDependencies 是**上界封闭**的：

```
'@deepseek-ai/dsh-invariants': '>=0.0.1-rc.1 <0.2.0'
'@deepseek-ai/dsh-tools':      '>=0.0.1-rc.1 <0.2.0'
```

`<0.2.0` 明确排除 0.2.0，所以在作者放宽上界前装不上。这是**唯一一个真死**的。

处理：仍留在 `dependencies` 里（不占运行时，且作者修好后一条命令即可加回），但**不在 `bundles` 中**，所以不会加载。

### 4.3 `D:\dsh\package.json` —— 惰性残留（已对齐）

已验证：`dsh --dump-config` 不带 `--profile` 会直接报 `error: --profile <name> is required`，且只有 `web` 一个命名 profile。所以家目录那份 `package.json` **不是任何东西的启动目标**，是迁移留下的残留。

已把它的 bundles 对齐到与 `profiles/web` 一致的可用集合，消除"万一被读取就炸"的隐患。

### 4.4 `D:\dsh\settings.yaml.imported`

迁移残留（内容已进 profile 补丁），已归档到 `profile-backup-20261001-001006\`。

---

## 五、你已自行完成的迁移（确认无误）

`D:\dsh\profiles\web\cordis.patch.yml` 里你已按 release notes 要求改好了两处：

```yaml
- id: agent-default-model
  config:
    provider: deepseek-official
    model: deepseek-flash        # ← 原来 deepseek-v4-flash，因 0.2.0 把它移出默认列表
    reasoningEffort: high
- id: llm-deepseek
  baseURL: https://api.deepseek.com/anthropic   # ← 官方适配器现在仅用 Messages API
```

这两步正是破坏性变更清单里点名的，做得对。

`D:\dsh\settings.yaml.imported` 是迁移残留（内容已进 profile 补丁），可归档或删除。

---

## 六、当前状态与下一步

### ✅ 已完成

| # | 事项 | 状态 |
|---|---|---|
| 1 | 重启 `dsh web` | ✅ 已重启（新 pid 13336 / 22392） |
| 2 | 内置 skill 系统恢复 | ✅ 技能目录从 1 个 → **15 个**，与升级前一致 |
| 3 | mattpocock 的 25 个 skill 找回 | ✅ bundle 加回 `bundles`，技能全部重现 |
| 4 | 权限预设 `auto-ask` 恢复 | ✅ 组合结果正确，中文正常 |
| 5 | `dsh-file` 恢复 | ✅ 版本 `0.1.2`，peer 放宽到 `^0.2.0-rc.2`，12/12 测试通过 |
| 6 | `dsh-notify-win` 加回 | ✅ |
| 7 | 安装 `dshmarket` | ✅ 插件市场可用 |
| 8 | 安装 `dsh-share`、`dsh-usage-stats` | ✅ |
| 9 | 对齐 `D:\dsh\package.json` | ✅ |
| 10 | 归档 `settings.yaml.imported` | ✅ |

**当前 profile 的 8 个 bundle**（组合零告警）：

```
@deepseek-ai/dsh-base
@deepseek-ai/dsh-web-app
dsh-notify-win
@mattpocock-community/dsh-engineering-skills
dsh-file
dshmarket
dsh-share
dsh-usage-stats
```

### ☐ 待你确认

- ☐ 界面刷新后确认：设置页能打开 **dsh-market**、**自动运行（保留确认）** 预设为默认、`dsh-file` 文件管理器可用
- ☐ `reasoningEffort` 你已从 `high` 改成 `low` —— 确认是有意为之

### ⚠️ 一个重要的现实约束：生态还没跟上 0.2.0

我系统性预检了 25 个插件的 peer 范围，结论很明确：

| 状态 | 数量 | 代表 |
|---|---|---|
| **支持 0.2.0** | **5** | `dshmarket`、`dsh-better-sidebar`、`dsh-genui`、`dsh-share`、`dsh-usage-stats` |
| 不支持 | 12 | `dsh-find-plugin`、`dsh-plugin-scorecard`、`dsh-win-toolkit`、`dsh-windows-ocr`、`dsh-session-health`、`dsh-security-audit`、`dsh-insight`、`dsh-bash-terminal-ts`、`dsh-at-file`、`dsh-undo`、`dsh-usage-dashboard`、`dsh-window` |
| 未声明 dsh peer（检查器放行） | 8 | `dsh-notification`、`dsh-plugin-notify`、`dsh-browser` 等 |

原因都一样：peer 上界停在 `^0.1.7-alpha.1`，按 semver 等于 `<0.2.0`。最典型的是 `dsh-find-plugin`——作者**枚举了一长串范围**（rc.6 / rc.1 / alpha.2 / alpha.3 / alpha.5 / alpha.1 / 0.1.7-alpha.1），却偏偏没加 0.2.0。

**这不是插件坏，是 0.2.0-rc.2 才发布 1 天，生态来不及跟进。**被 DSH 兼容检查拦下是**正确行为**（它防止了不兼容代码静默崩溃）。

你有两条路：

- **A（推荐）等**：rc 周期推进很快，作者们会陆续补上 0.2.0。先用 `dshmarket` 逛，等目标插件更新
- **B 给豁免**：在插件管理器 UI 里对**确切版本**授予豁免。但豁免 = 你确认「明知可能崩也照跑」，只在你读过源码、确认 API 没变时使用（`dsh-file` 就是这种情况——我核实了 API 未变，所以直接改范围而不是给豁免）

**这意味着我之前推荐的那批 Windows 原生 / 体检类插件，现在一个都装不上**，需要等它们更新。

### ☐ 后续可选

- ☐ `dsh-better-sidebar`、`dsh-genui` 也声明支持 0.2.0，需要时可在 dsh-market 里一键装（注意 `dsh-better-sidebar` 与 `dsh-file` 在文件浏览上有功能重叠）
- ☐ `dsh-toolkit` 等作者放宽 `<0.2.0` 上界后再加回

---

## 七、本次新增文件

| 文件 | 用途 |
|---|---|
| `dsh-升级后状态与修复记录.md` | 本文件 |
| `profile-backup-20261001-000745\` | 修复**前**的 profile 配置快照 |
| `profile-backup-20261001-001006\` | 修复**后**的 profile 配置快照 |
| `dsh-safe-upgrade-v2.ps1` | 修正版升级脚本（已用不上了——升级已完成） |
| `dsh-升级行动清单.md` | 升级前的行动清单（历史参考） |
| `dsh-环境体检与插件建议.md` | 体检报告与插件分析 |
| `awesome-dsh-plugin-canonical.md` | 权威社区清单存档 |
| `dsh-release-notes-recent.md` | 官方 release notes |

---

## 八、这次故障给出的通用教训

**永远不要用 dist-tag 解析 `@deepseek-ai/*` 包。**

官方子包的 `latest` 标签是坏的（指向 `0.0.1-rc.1` 一类的远古版本），真正的最新版在 `next`：

| 包 | `latest` | 真实最新 |
|---|---|---|
| `@deepseek-ai/dsh-base` | `0.0.1-rc.1` | `0.2.0-rc.2`（next） |
| `@deepseek-ai/dsh-llm` | `0.0.1-rc.1` | `0.2.0-rc.2`（next） |
| `@deepseek-ai/dsh-web-app` | `0.0.1-rc.1` | `0.2.0-rc.2`（next） |
| `@deepseek-ai/dsh-skill-filesystem` | `0.0.1-rc.3` | `0.2.0-rc.2`（next） |

这个坑已经咬了你两次：一次是 `dsh-safe-upgrade.ps1` 的无版本安装，一次是 mattpocock 的 `"*"`。**凡涉及这些包，一律精确锁版本。**

---

## 九、第二个通用教训：prerelease 的 `^` 语义

这次 `dsh-file` 和生态里 12 个插件被拒，根因都是同一件事：

```
^0.1.0-rc.6   ≡   >=0.1.0-rc.6  <0.2.0
```

**prerelease 版本上的 `^` 不会跨越次版本号。** `^0.1.x` 的上界是 `0.2.0`，所以一旦运行时升到 `0.2.0-rc.2`，所有写 `^0.1.x` 的 peer 声明**全部失效**——哪怕 API 一行没改。

这解释了为什么 0.2.0 发布会一次性打断大半个生态。也解释了为什么 `dshmarket` 的作者要写成：

```
^0.1.0-rc.7 || ^0.1.1-rc.2 || ^0.1.2-alpha.2 || ^0.2.0-rc.1
```

——每个次版本都得**手动枚举一遍**。

**给插件作者的建议**：与其每次枚举，不如写 `>=0.1.0-rc.6 <0.3.0`。但注意 semver 的 prerelease 规则——范围里若不含对应 tuple 的 prerelease，`0.2.0-rc.2` 这类版本**仍不满足**。所以更稳妥的是显式列出目标 rc，或等正式版。

**给使用者的建议**：装插件前先看 peer 范围有没有覆盖你当前的运行时版本，别等启动时才被拦。

---

## 十、第三个问题：一直弹「DeepSeek Messages transport failed」

### 现象与证据

从会话日志（`D:\dsh\sessions\--D-1--\...\session.jsonl.zstd`，多帧 zstd）解出的真实错误：

```json
{"type":"assistant/chunk","data":{"chunk":{"type":"finish","reason":{"kind":"error",
  "failure":{"message":"DeepSeek API request to https://api.deepseek.com failed","code":"TRANSPORT"}}}}}
```

统计全部会话：

| 项 | 值 |
|---|---|
| TRANSPORT 事件总数 | **236** |
| 时间窗 | 2026-09-30 **23:10:02 → 23:37:51**（本地） |
| 错误里的 URL | **全部是 `https://api.deepseek.com`（根地址）** |
| 重试策略 | `["EMPTY_RESPONSE","RATE_LIMIT","SERVER","TIMEOUT","TRANSPORT"]`，maxRetries=2 |

因为 TRANSPORT 在重试名单里，每次失败会重试 2 次 → **一次用户操作弹出 3 个错误**，这就是「一直弹」的来源。

### 根因

两个事实撞在一起：

**1. 0.2.0 把官方 DeepSeek 适配器改成仅支持 Messages 协议**，端点必须是 `https://api.deepseek.com/anthropic`。代码里：

```js
/** Public API default; the internal endpoint comes from $DEEPSEEK_BASE_URL. */
const PUBLIC_BASE_URL = "https://api.deepseek.com/anthropic";
const BASE_URL_ENV = "DEEPSEEK_BASE_URL";
// 优先级：
const baseURL = config.baseURL ?? environment?.get(BASE_URL_ENV)?.value ?? "https://api.deepseek.com/anthropic";
```

**2. 你的机器上设了 `DEEPSEEK_BASE_URL=https://api.deepseek.com`**（Machine 级环境变量）—— 这正是 release notes 点名的「旧官方根地址」：

> 如果手动配置了旧官方根地址，请移除该配置或改为 `https://api.deepseek.com/anthropic`

当时 profile 补丁里还没有 `baseURL`，于是落到 env 变量 → 请求打到根地址 → Messages 协议不匹配 → TRANSPORT。

### 已生效的修复

你在 `D:\dsh\profiles\web\cordis.patch.yml` 加的那行是**正确且优先级最高**的：

```yaml
- id: llm-deepseek
  name: '@deepseek-ai/dsh-llm-deepseek-api-key'
  config:
    baseURL: https://api.deepseek.com/anthropic
```

`config.baseURL ?? env ?? 默认` —— 配置排第一，所以现在生效的是 `/anthropic`。已用 `--dump-config` 确认。

### ⚠️ 仍需处理：建议删掉那个环境变量

它现在被 `config.baseURL` 压住了，但仍是**地雷**：任何没有显式配置 baseURL 的代码路径都会回落到这个错误的根地址。而且 release notes 明确要求移除它。

```powershell
# 需要管理员权限的 PowerShell
[Environment]::SetEnvironmentVariable('DEEPSEEK_BASE_URL', $null, 'Machine')
```

删掉后默认值（`PUBLIC_BASE_URL`）本来就是 `https://api.deepseek.com/anthropic`，行为不变但不再有隐患。

### 🔐 顺带发现的安全问题（建议处理）

`DEEPSEEK_API_KEY` 也是 **Machine 级环境变量，明文存放**：

- Machine 级环境变量对本机任何进程可读，恶意程序可随手取走
- 更糟的是：排查过程中它被打印进了本次会话日志（该日志是明文 zstd 存储的）

建议：
1. **轮换这个 key**（到 DeepSeek 开放平台重新生成）
2. 删掉 Machine 级变量：`[Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', $null, 'Machine')`
3. 把新 key 存进 DSH 的凭据存储 —— **Web 界面 → 设置 → Models 页面**会写入 `$DSH_HOME/.credentials.yaml`

**注意**：`D:\dsh\.credentials.yaml` 目前**只有一条浏览器 session 授权，没有 DeepSeek key**。但这**不等于没有 key** —— 凭据解析有一个环境层，优先级如下（来自 `dsh-credentials-local` 官方文档）：

| 位置 | 可写？ | 优先级 |
|---|---|---|
| **启动时的环境（`DEEPSEEK_API_KEY=… dsh`）** | 否 | **最高，压过一切** |
| 存储文件 `$DSH_HOME/.credentials.yaml` | 是 | 次之 |
| 项目 `.env`（`<cwd>/.env`） | 否 | 再次 |
| 主目录 `.env`（`$DSH_HOME/.env`） | 否 | 最低 |

`llm-deepseek-api-key` 的 `resolveApiKey` 调用 `ctx.credentials.resolve(ref)`，而 `credentials-local` 的 `resolve` 会**先读启动环境快照**（`getFrom(ref, ["process"])`）。所以你机器上那个 Machine 级 `DEEPSEEK_API_KEY` **是生效的，而且优先级最高** —— 这也解释了为什么对话一直正常。

> ⚠️ 更正：我此前根据 `resolveApiKey` 里的 `else` 分支断定「环境变量是死代码」，**那个判断是错的**。那个 `else` 只在凭据服务未组合时才走；服务组合时，环境变量是经由凭据服务内部的环境层读到的。

**由此推出一个很实际的操作约束**：官方文档明确写着——

> 启动环境提供的密钥是**只读**的——`DEEPSEEK_API_KEY=… dsh` 在本轮运行中优先，保存或移除它都会被拒绝。请先在启动 shell 中清除该变量。

也就是说：**只要 Machine 级 `DEEPSEEK_API_KEY` 还在，你就无法通过 Models 页面保存新 key**（`set` 会被拒绝，因为环境层遮蔽了存储）。要改用存储管理，必须先删掉环境变量再重启。

