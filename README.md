# DSH 折腾笔记

DeepSeek Harness（DSH）在 Windows 上的实战记录：环境体检、插件筛选、升级与修复、token 花费诊断。

> 环境：Windows + PowerShell 5.1 · DSH `0.2.0-rc.2` · profile `web`
> 记录时间：2026-10 初。DSH 迭代很快，**版本相关的结论请对照你本机的实际行为**。

## 文档

| 文档 | 内容 |
|---|---|
| [dsh-插件环境体检-2026-10-04.md](dsh-插件环境体检-2026-10-04.md) | 一次完整体检：bundle 组装、插件加载顺序、各插件版本与告警 |
| [dsh-环境体检与插件建议.md](dsh-环境体检与插件建议.md) | 由体检得出的结论与插件增减建议（含"与内置功能重叠"的判断） |
| [dsh-升级后状态与修复记录.md](dsh-升级后状态与修复记录.md) | 升级到 0.2.0-rc.2 后坏掉的东西、根因与修复 |
| [dsh-升级行动清单.md](dsh-升级行动清单.md) | 升级前/后的可执行清单（备份点、验证步骤、残留清理） |
| [dsh-token花费优化-2026-10-05.md](dsh-token花费优化-2026-10-05.md) | 用本机账本反解真实成本结构，找出"输出 token"这一主要成本项 |
| [dsh-plugin-推荐清单.md](dsh-plugin-推荐清单.md) | 逐条核验（npm 真实性 / GitHub 可达性 / 最近推送 / 许可证）后的插件推荐 |

## 脚本

| 脚本 | 用途 |
|---|---|
| [dsh-safe-upgrade.ps1](dsh-safe-upgrade.ps1) | 升级 `@deepseek-ai/dsh` 但**不丢运行时插件**：先备份、再升级、失败可回滚 |
| [dsh-safe-upgrade-v2.ps1](dsh-safe-upgrade-v2.ps1) | 上一版的改进版，覆盖面更全 |
| [dsh-shared-tree-repair.ps1](dsh-shared-tree-repair.ps1) | 修复 pnpm 共享依赖树被破坏后的 DSH 运行环境 |

三个脚本都是纯 PowerShell、无外部依赖。运行前请先读一遍——它们会改动 DSH 安装目录。

## 几条值得先看的结论

- **插件设置落盘在 profile 的 `cordis.patch.yml`**，以 id 定向写入；同一个 id 是**整行替换、不深合并**，改一个字段必须重述整行。
- **typert strict codec 必须带 `create()` 工厂**（0.2.0-rc.2 的 loader 会直接校验 `typeof codec.create !== 'function'`），内联 `schema` 对象已不被接受。
- **cost-meter 账本会截断**：`days[日期].sessions[]` 在高负载日只留 200 条，完整口径必须看 `days[].cost`；`includeSubagentCost=false` 时子代理花费只进聚合。
- **不要让模型"多写字"**：本机实测成本结构里输出 token 单价是缓存命中输入的 200 倍，减少冗余输出比压缩上下文更省钱。
- **`.bat` 必须全 ASCII + CRLF**：cmd.exe 按控制台 OEM 代码页解析，`chcp 65001` 救不了（解析在 chcp 生效之前就开始了）。
- **含中文的 `.ps1` 必须存 UTF-8 with BOM**：PowerShell 5.1 会把无 BOM 的中文按 GBK 解析并报出与源码无关的语法错误。

## 许可

[MIT](LICENSE)
