# Test Report: Aliyun Acorn 0xc1.wang Entry

Date: 2026-06-29

## Summary

PASS. The changed host configs evaluate, dry-run build, and expose the expected frp/nginx/security shape for the planned first slice.

## Commands

### Secret Shape

Command:

```sh
agenix -d -i /home/c1/.ssh/id_ed25519 nginx-status-htpasswd.age | perl -0ne 'exit($_ =~ m#^c1:\$apr1\$[A-Za-z0-9/.]{1,8}\$[A-Za-z0-9/.]+\n?\z# ? 0 : 1)'
agenix -d -i /home/c1/.ssh/id_ed25519 status-basic-auth-password.age | perl -0ne 'exit($_ =~ /^username=c1\npassword=[0-9a-f]{64}\n?\z/ ? 0 : 1)'
```

Result: PASS. Both age secrets decrypt with the expected format. Secret contents were not printed.

### Host Evaluation

Commands:

```sh
nix eval --raw path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath
nix eval --raw path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.axiom.config.system.build.toplevel.drvPath
```

Result: PASS.

- `aliyun-acorn`: `/nix/store/lv19w1l222d41lamjy10y2rmj4k6blii-nixos-system-aliyun-acorn-25.11.20260203.e576e3c.drv`
- `axiom`: `/nix/store/xqhilhkry194si6q3vz6skv2bs6ngsnq-nixos-system-axiom-25.11.20260203.e576e3c.drv`

### Dry-run Build

Commands:

```sh
nix build --dry-run path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.system.build.toplevel
nix build --dry-run path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS. Both dry-run builds completed and reported planned derivations/fetches without evaluation errors.

### FRP Config

Commands:

```sh
nix eval --json path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.axiom.config.modules.services.frp.client.proxies
nix build --no-link --print-out-paths --impure --expr '(builtins.getFlake "path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry").nixosConfigurations.axiom.config.systemd.services.frpc.serviceConfig.ExecStartPre'
frpc verify -c /nix/store/zx5qfd4c7bmyic52520999vhb84vl91k-frpc.toml
frps verify -c /nix/store/2lwaih24bp28g774jhvm4z3nikcc2yb0-frps.toml
```

Result: PASS.

- Evaluated proxies include existing `axiom-ssh` remote `2225` and new `axiom-gatus-http` remote `18080`.
- Generated `frpc.toml` contains `localIP = "127.0.0.1"`, `localPort = 8080`, `remotePort = 18080`, `type = "tcp"` for `axiom-gatus-http`.
- `frpc verify` and `frps verify` both reported syntax ok.

### Nginx and Firewall Shape

Commands:

```sh
nix eval --json path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."status-axiom.0xc1.wang".locations."/"
nix eval --json path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."status-axiom.0xc1.wang".forceSSL
nix eval --json path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."status-axiom.0xc1.wang".enableACME
nix eval --json path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."status-axiom.0xc1.wang".http2
nix eval --json path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts
nix eval --json path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.age.secrets.nginx-status-htpasswd.owner
nix eval --json path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.age.secrets.nginx-status-htpasswd.group
nix eval --raw path:/home/c1/dotfiles/.worktrees/aliyun-acorn-0xc1-wang-entry#nixosConfigurations.aliyun-acorn.config.age.secrets.nginx-status-htpasswd.path
```

Result: PASS.

- Location proxy pass is `http://127.0.0.1:18080`.
- `proxyWebsockets = true`.
- `basicAuthFile = /run/agenix/nginx-status-htpasswd`.
- `forceSSL = true`, `enableACME = true`, `http2 = true`.
- nginx htpasswd secret owner/group are both `nginx`.
- Firewall allowed TCP ports are `[22,80,443,2222,2225,7000,34197]`; `18080` is not public.

## Skipped / Post-deploy Checks

These require deployed hosts, DNS, and Aliyun security group state and were not run locally:

- ACME issuance for `status-axiom.0xc1.wang`.
- Public HTTPS Basic Auth behavior.
- Live frp connectivity from `axiom` Gatus to `aliyun-acorn` `127.0.0.1:18080`.
- External confirmation that `18080` is unreachable.
- SSH convenience check: `ssh -p 2225 c1@axiom.0xc1.wang`.
