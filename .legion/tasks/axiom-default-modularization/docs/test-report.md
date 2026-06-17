# Test Report: Axiom Default Modularization

## Summary
PASS

## Commands
```sh
nix eval .#nixosConfigurations.axiom.config.networking.hostName --json
```

Result: PASS. Returned `"axiom"` after the module refactor was staged, proving Axiom still evaluates.

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; in { cloudflaredIngress = (builtins.fromJSON cfg.environment.etc."cloudflared/config.yml".text).ingress; gatusEndpointNames = map (endpoint: endpoint.name) cfg.modules.services.gatus.endpoints; reverseSshExec = cfg.systemd.services.autossh-reverse-ssh.serviceConfig.ExecStart; opencodeExec = cfg.systemd.services.opencode-server.serviceConfig.ExecStart; healthcheckTimers = builtins.attrNames cfg.systemd.timers; firewallTCP = cfg.networking.firewall.allowedTCPPorts; firewallUDP = cfg.networking.firewall.allowedUDPPorts; }'
```

Result: PASS. Key facts:
- Cloudflared ingress is `opencode-axiom`, `status-axiom`, then `http_status:404`.
- Gatus endpoint names are `opencode-axiom`, `vaultwarden-web`, `status-page`.
- Reverse SSH command still forwards `127.0.0.1:2223` to local port `22` on `8.159.128.125`.
- Opencode command remains `/home/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096`.
- Healthcheck timers include `autossh-reverse-ssh-healthcheck`, `clash-verge-healthcheck`, and `cloudflared-healthcheck`.
- Firewall output no longer includes the removed Axiom `7844/udp` or broad ephemeral ranges; remaining Steam/Clash-related ports come from enabled service modules.

```sh
nix build .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS. The final staged worktree builds Axiom's NixOS toplevel successfully.

## Why These Checks
- The facts eval directly proves the refactored module composition still emits the critical service wiring that moved out of `hosts/axiom/default.nix`.
- The toplevel build is the requested validation gate and proves the full Axiom system closure can be produced.

## Not Run
- No live deploy, suspend/hibernate, Cloudflare API, or real remote autossh connectivity test. These are outside scope and require the actual Axiom runtime/session or external services.
