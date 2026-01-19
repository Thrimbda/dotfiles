# dual-cloudflared-topology - 上下文

## 会话进展 (2026-01-19)

### ✅ 已完成

- 更新 cloudflared 模块注释为双隧道拓扑
- atlas/charlie 配置加入独立 tunnel 占位与 tunnelName
- 更新 Zero Trust 与 macOS SSH 文档以说明双隧道流程


### 🟡 进行中

(暂无)


### ⚠️ 阻塞/待定

(暂无)


---

## 关键文件

(暂无)

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 采用 atlas 与 charlie 各自独立运行 cloudflared 的双隧道拓扑，并同步更新 Nix 配置与文档。 | 用户明确要求去除单点依赖，提高可用性。 | 继续单一 tunnel（不符合用户需求）；在 atlas 上做高可用/备份（仍存在耦合）。 | 2026-01-19 |

---

## 快速交接

**下次继续从这里开始：**

1. 在 atlas/charlie 分别运行 cloudflared-setup 生成 tunnel 与凭证
2. 补齐 tunnelId/credentialsFile 并部署 `sudo nixos-rebuild switch --flake .#atlas` / `sudo darwin-rebuild switch --flake .#charlie`
3. 在 Zero Trust 控制台创建两套浏览器 SSH 应用并验证 WARP 访问

**注意事项：**

- 文档与配置均已更新为双隧道模式，占位项需替换为真实 tunnel ID/凭证路径。

---

*最后更新: 2026-01-19 20:09 by Claude*
