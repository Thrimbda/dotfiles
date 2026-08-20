# Dotfiles Prune and Host Framework Extraction

## 目标

通过纯删除和边界收敛降低仓库认知负担：只保留本次 Legion task，删除过时 README，列出一次性 package modules，并把 Axiom/Acorn 的 Cloudflare、autossh、Caelestia 与跨主机服务机制从臃肿的 host default 中移到清晰模块边界。

## 问题

- `.legion/tasks` 长期保存大量已闭环 raw evidence，压过配置源码；用户要求清理 closed tasks，只保留本次任务。
- 根 `README.md` 已过时，且不再承担有效入口职责。
- 一些 option module 可能只有单 host、单 package 用途，增加无意义的 option surface。
- `hosts/axiom/default.nix` 接近 2000 行，混合 host facts、长脚本、桌面策略、远程连接和公共入口拓扑；`hosts/acorn/default.nix` 也混合云主机事实与服务 mechanics。

## 验收标准

- `.legion/tasks/` 最终只包含 `dotfiles-prune-host-frameworks`；`.legion/wiki/**` 保留。
- 根 `README.md` 删除，仓库运行入口不依赖它。
- 产出一次性 package module 清单，按“可内联 / 待确认 / 应保留”分类，并给出实际 host 使用证据；本任务不顺带批量删除这些模块。
- `hosts/axiom/default.nix` 收敛为主机清单、关键 facts、imports 与 hardware，不再内嵌 Cloudflare、autossh、Caelestia、Axiom-to-Acorn 拓扑的长 service/script 实现。
- `hosts/acorn/default.nix` 保留 Acorn 主机事实与启用意图；可复用 mechanics 进入共享模块，Acorn 专属组合进入 `hosts/acorn/modules/`。
- 复用并增强已有 `cloudflared`、`reverse-ssh`、`caelestia`、`frp` 等模块；只有现有模块确实缺少机制时才增加小 option，不新增聚合 DSL 或第二套框架。
- 现有域名、端口、tunnel ID、secret 路径、service user、systemd/launchd 行为、Axiom 桌面行为与 Acorn 构建安全约束保持不变。
- 完成静态检查和可承受的目标 host Nix 验证；不得在 Acorn 本机 build/eval/switch。

## 范围

- `.legion/tasks/**` 与本次任务文档。
- 根 `README.md`。
- `modules/**/*.nix` 中与 Cloudflare、reverse SSH、Caelestia、FRP/Acorn 连接机制直接相关的现有模块。
- `hosts/axiom/default.nix`、`hosts/axiom/modules/**`。
- `hosts/acorn/default.nix`、`hosts/acorn/modules/**`。
- 一次性 package module 的只读 inventory。

## 非目标

- 不删除或重写 `.legion/wiki/**`。
- 不升级 flake inputs，不改 `flake.lock`。
- 不改变公网拓扑、安全策略、凭据格式或 secret 内容。
- 不把所有 host 服务抽成通用编排框架，不引入 flake-parts/devos 或新的 profile DSL。
- 不在本任务批量内联/删除一次性 package modules；先给清单，由用户后续决定。
- 不借机重写 RustDesk、Hyprland、Caelestia 或 Auth Mini 的产品行为；允许把原实现机械搬到职责明确的模块。

## 假设与约束

- 初始确认是删除全部旧 task、只保留本次新 task。主线后来新增 active 的 `axiom-qwen38-q6-switcher` 时用户要求暂时保留；该任务在 `07816e00` 完成后重新适用 closed-task prune 规则。
- “抽成框架”解释为：共享模块拥有可复用 mechanics，host-local modules 组合具体拓扑，host default 只表达意图和 facts。
- Git 历史和 `.legion/wiki` 足以承担旧 task 的追溯与当前知识层。
- 所有修改在隔离 worktree 中通过 PR 交付；不在主工作区实现。

## 风险

- 大量 task 删除容易误删本次任务或 wiki，必须用路径白名单验证。
- 移动 Nix module 代码可能改变 import 顺序、option merge 或 Git-backed flake 可见性。
- Cloudflare、FRP、autossh 和 Auth Mini gateway 共同形成远程访问链，行为等价必须以生成配置、unit 和关键 option 为证据。
- Axiom 文件的主要体积还包含 RustDesk；只抽用户点名的边界可能仍不够小，因此允许机械移动 host-local RustDesk 实现，但不泛化其 API。

## 设计摘要

- 删除优先：先收缩 task/docs surface，不为历史材料新增归档层。
- Manifest-first host：Axiom/Acorn default 只保留 enablement、facts、imports 和 hardware。
- Mechanics-first modules：优先补齐现有 domain module；单 host 的复杂组合放在该 host 的 `modules/`，不假装跨 host 复用。
- Facts stay visible：域名、IP、端口和关联关系继续在 host-local composition 中可见，不藏进全局默认值。

## 阶段

1. Contract 与最小 RFC：确定删除白名单、模块边界和行为等价面。
2. Worktree 实现：prune、删除 README、生成 inventory、完成 host/module 抽取。
3. 验证与 review：检查路径白名单、Nix 生成结果和关键服务拓扑。
4. PR、walkthrough 与 wiki 写回。

---
*Created: 2026-08-20*
