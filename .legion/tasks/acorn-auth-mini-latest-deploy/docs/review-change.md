# 变更审查

## 结论

实现范围符合计划：仅更新 `packages/auth-mini/default.nix` 中 Auth Mini 官方 release pin 的版本标识、asset ID 与固定输出 hash；未改变服务、数据库、secret、网络、Nginx 或 gateway 配置。

## 审查发现

- 当前生产版本：`latest-2026-07-24`。
- 目标版本：`latest-2026-08-23`。
- asset ID 是不可变的 GitHub release asset API ID；固定输出 SRI 与官方 asset SHA-256 一致，内容变化会令 Nix 构建失败。
- Axiom 上的匿名 GitHub API rate limit 可能影响没有既有 source cache 的首次重建；当前 Axiom 已有经官方 digest 验证的 fixed-output source，部署命令会在 Axiom 本地 build host 上复用它。长期重新构建仍依赖 GitHub API rate limit 恢复，未以可变下载 URL 替换 pin。

## 会话注意力摘要

- attention: decide
- 唯一需要的人类操作：在可交互、可信的 Axiom 终端中，运行计划中的 `nixos-rebuild switch ... --sudo --ask-sudo-password ...` 并在其正常 password prompt 中自行授权；不要将密码粘贴到 Cybion 对话、文件、环境变量或命令参数。
- 停止点：授权前不得执行远程 activation。
