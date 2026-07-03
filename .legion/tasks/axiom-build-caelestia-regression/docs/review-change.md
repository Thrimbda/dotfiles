# Review Change

## 结论

PASS。

## Blocking Findings

无。

## Scope Check

- Axiom host-local package fixes、Docker module package option、Foot fontconfig package exposure、Janet/JPM rebuild guard 都在 task scope 内。
- 未提交用户主工作区已有的 `flake.lock` 修改。
- 未添加 `permittedInsecurePackages` 或其他 insecure allowlist。

## Security Lens

触发点：`modules/hey.nix` activation 会删除并重建 user-local JPM tree 里的 managed build artifacts。

判断：非阻塞。删除范围限定在 `${JANET_TREE}/build`、`${JANET_TREE}/lib` 和 `${JANET_TREE}/bin/hey`，这是当前模块本来就负责生成/使用的 Janet dependency tree；没有扩大到任意用户路径、权限提升、secret、network trust boundary 或 system service 权限。

## Non-blocking Notes

- 下一次 switch 后仍需要 live smoke：确认 `hey hook startup` 不再报 Janet ABI mismatch，`hyprland-session.target` active，Caelestia 自启动，Foot 字体恢复。
