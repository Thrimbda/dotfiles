# Test Report: Axiom Host Policy Extraction

## 结论
PASS

## 执行命令

### Patch Sanity
```sh
git diff --check
```

结果: PASS，无输出。

证明力: 捕捉 whitespace 和 patch 格式问题，避免提交明显坏 diff。

### Focused Facts Eval
```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; in { hostLines = 387; renderedGatusEndpoints = map (e: { inherit (e) name group url conditions; labels = e.extra-labels; }) cfg.services.gatus.settings.endpoints; cloudflaredIngress = cfg.modules.services.cloudflared.ingress; sshdPolicy = cfg.systemd.services.sshd.serviceConfig; cloudflaredPolicy = cfg.systemd.services.cloudflared.serviceConfig; cloudflaredStartLimit = cfg.systemd.services.cloudflared.unitConfig.StartLimitIntervalSec; clashPolicy = cfg.systemd.services.clash-verge.serviceConfig; clashGuiPolicy = cfg.systemd.user.services."app-clash\\x2dverge@autostart".serviceConfig; userManagerPolicy = cfg.systemd.services."user@1000".serviceConfig; firewallExtra = cfg.networking.firewall.extraCommands; nmProfile = cfg.networking.networkmanager.ensureProfiles.profiles.enp14s0; zram = { inherit (cfg.zramSwap) enable algorithm memoryPercent memoryMax priority; }; logrotateCheck = cfg.services.logrotate.checkConfig; }'
```

结果: PASS。

关键事实:
- `hostLines = 387`
- Gatus endpoints: `opencode-axiom`, `vaultwarden-web`, `status-page`
- Cloudflared ingress: `opencode-axiom.0xc1.space`, `status-axiom.0xc1.space`, fallback `http_status:404`
- `sshd`, `cloudflared`, `clash-verge`, Clash GUI autostart, and `user@1000` resource/OOM policy evaluated as expected
- LAN firewall allow still renders `192.168.50.0/24` for TCP ports `5173,8765`
- NetworkManager profile for `enp14s0`, zram settings, and `services.logrotate.checkConfig = false` evaluated as expected

证明力: 直接验证本轮抽走的 host policy 是否仍由模块生成相同 effective facts。

### Full Axiom Build
```sh
nix build .#nixosConfigurations.axiom.config.system.build.toplevel
```

结果: PASS。

证明力: 最强本地验证，证明重构后的 Axiom NixOS module graph 能完整 evaluate/build 成系统 closure。

## 覆盖范围
- `hosts/axiom/default.nix` 从 PR #94 后的 451 行降到 387 行。
- 抽走 Gatus endpoint boilerplate、Cloudflared/SSH/Clash resource policy、Clash GUI drop-in、zram/logrotate/user manager/NM wired profile policy、LAN firewall iptables body。
- 保留行为事实：endpoint names/conditions/labels、Cloudflared ingress fallback、OOM/resource values、LAN CIDR/ports、zram values、NetworkManager `enp14s0` profile。

## 未执行
- 未执行 live deployment、service restart、firewall live packet test、Cloudflare browser smoke、Gatus HTTP probe、Clash GUI runtime smoke、NetworkManager link activation smoke。这些属于部署后检查。
