# Test Report: Aliyun Acorn Low-Resource Rebuild Fix

## Scope

Validate that `aliyun-acorn` keeps the required server services while removing development/desktop-heavy components, avoiding staged ACME units, avoiding public HTTP exposure for auth-bearing vhosts, and reducing on-host rebuild pressure.

## Why These Checks

- Nix eval checks directly prove the generated system shape without deploying to the currently unreachable host.
- The toplevel build proves the slimmed configuration is realizable.
- Closure size comparison proves the change materially reduces download/store pressure on a low-resource machine.
- A remote `nixos-rebuild switch` was intentionally skipped because SSH to `8.159.128.125` still times out during banner exchange after the prior dry-run attempt.

## Commands And Results

### Vaultwarden Remains Enabled

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.enable
```

Result: `true`

### Staged ACME Units Removed

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.units --apply 'units: builtins.filter (name: builtins.match ".*(vault|status-axiom).*acme.*|.*acme.*(vault|status-axiom).*" name != null) (builtins.attrNames units)'
```

Result: `[]`

### SSH Uses Normal Daemon Mode

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.openssh --apply 's: { enable = s.enable; startWhenNeeded = s.startWhenNeeded; extraConfig = s.extraConfig; }'
```

Result:

```json
{"enable":true,"extraConfig":"","startWhenNeeded":false}
```

### Nix Resource Limits Applied

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.nix.settings --apply 's: { maxJobs = s.max-jobs or null; cores = s.cores or null; httpConnections = s.http-connections or null; }'
```

Result:

```json
{"cores":1,"httpConnections":4,"maxJobs":1}
```

### User Packages Slimmed

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.user.packages --apply 'ps: builtins.map (p: p.name or "unknown") ps'
```

Result:

```json
["editorconfig-core-c-0.12.9","lazygit-0.56.0","neovim-0.11.5"]
```

### Docker Fully Disabled

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.virtualisation.docker --apply 'd: { enable = d.enable; enableOnBoot = d.enableOnBoot; }'
```

Result:

```json
{"enable":false,"enableOnBoot":false}
```

### Nix-LD Disabled

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.programs.nix-ld.enable
```

Result: `false`

### Generated Units Shape

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.units --apply 'units: { acme = builtins.filter (name: builtins.match ".*acme.*" name != null) (builtins.attrNames units); docker = builtins.filter (name: builtins.match ".*docker.*" name != null) (builtins.attrNames units); sshd = builtins.filter (name: builtins.match ".*ssh.*" name != null) (builtins.attrNames units); }'
```

Result:

```json
{"acme":[],"docker":[],"sshd":["sshd-keygen.service","sshd.service","sshd@.service"]}
```

### Nginx Staging Flags

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts --apply 'v: { status = { forceSSL = v."status-axiom.0xc1.wang".forceSSL; enableACME = v."status-axiom.0xc1.wang".enableACME; listen = v."status-axiom.0xc1.wang".listen; }; vault = { forceSSL = v."vault.0xc1.space".forceSSL; enableACME = v."vault.0xc1.space".enableACME; listen = v."vault.0xc1.space".listen; locations = builtins.attrNames v."vault.0xc1.space".locations; }; }'
```

Result:

```json
{"status":{"enableACME":false,"forceSSL":false,"listen":[{"addr":"127.0.0.1","extraParameters":[],"port":80,"proxyProtocol":false,"ssl":false}]},"vault":{"enableACME":false,"forceSSL":false,"listen":[{"addr":"127.0.0.1","extraParameters":[],"port":80,"proxyProtocol":false,"ssl":false}],"locations":["/","/notifications/hub","/notifications/hub/negotiate"]}}
```

### Public HTTP/HTTPS Firewall Closed

Command:

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts
```

Result:

```json
[22,2222,2225,7000,34197]
```

### Generated Nginx Listeners

Command:

```sh
nix eval --impure --raw .#nixosConfigurations.aliyun-acorn.config.systemd.services.nginx.serviceConfig.ExecStart
```

Result included generated config path `/nix/store/wlvc8c7f43kani18w9wkfxxycscs28ys-nginx.conf`.

Manual inspection of that generated config showed:

```nginx
listen 127.0.0.1:80 ;
server_name status-axiom.0xc1.wang ;

listen 127.0.0.1:80 ;
server_name vault.0xc1.space ;
```

### Full Build

Command:

```sh
nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel
```

Result: passed after the local-only vhost/firewall update.

### Closure Size

Slim branch command:

```sh
nix path-info --impure -Sh .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel
```

Result after the low-resource and local-only vhost changes: `3.2 GiB`

PR #111 baseline command from main checkout:

```sh
nix path-info --impure -Sh .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel
```

Result: `5.5 GiB`

Net reduction: about `2.3 GiB`.

## Skipped

- Remote `nixos-rebuild switch` on `aliyun-acorn` was skipped. The host still times out during SSH banner exchange, and further remote attempts could worsen load.

## Residual Risks

- `vault.0xc1.space` and `status-axiom.0xc1.wang` are local-only HTTP vhosts in this staged config until DNS/cutover re-enables public ports and TLS/ACME.
- If Docker is unexpectedly used manually on `aliyun-acorn`, those workloads will need a separate explicit service decision before deployment.
