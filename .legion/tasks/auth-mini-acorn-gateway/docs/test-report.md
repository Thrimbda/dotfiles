# Test Report: Auth Mini Gateway on Acorn

## Result

PASS for repository-level validation. Live DNS, ACME issuance, auth-mini admin bootstrap, browser login, and protected-service smoke checks remain post-deploy operations.

## Why These Checks

- Package builds prove both upstream runtimes are buildable from the declared Nix sources and hashes.
- Acorn toplevel build proves the NixOS module graph, systemd units, agenix secret declarations, nginx config generation, and package references compose.
- Targeted `nix eval` checks prove the specific security-sensitive shape: loopback ports, per-origin gateway config, no backend firewall exposure, protected nginx `auth_request`, and unchanged Vaultwarden proxying.
- Generated nginx config inspection proves the final rendered server blocks match the intended vhost names and auth wiring, not just the intermediate Nix attrsets.

## Commands Run

### Package Builds

```bash
nix-build --no-out-link -E 'with import <nixpkgs> {}; callPackage ./packages/auth-mini {}'
```

Result: PASS. Built `/nix/store/khhqaxzg4v56p2imgs3q0bsk3012knw2-auth-mini-latest-2026-07-05`.

```bash
nix-build --no-out-link -E 'with import <nixpkgs> {}; callPackage ./packages/auth-mini-gateway {}'
```

Result: PASS. Built `/nix/store/1w86wrq4brj1cw91bfh8rp6k017iqmjb-auth-mini-gateway-0.1.0-unstable-2026-07-09`; upstream Rust tests ran in the package build and passed `11 passed`.

### Acorn Toplevel Build

```bash
nix build --impure --no-link .#nixosConfigurations.acorn.config.system.build.toplevel
```

Result: PASS after two implementation fixes:

- Removed duplicate `age.secrets.auth-mini-gateway-env.file`, because agenix already derives the file from `hosts/acorn/secrets/secrets.nix` for same-name secrets.
- Fixed nginx vhost attr keys to use full hostnames from `instance.hostName` instead of internal names such as `status-axiom`.

### Host Eval

```bash
nix eval --raw .#nixosConfigurations.acorn.config.networking.hostName
```

Result: PASS, returned `acorn`.

### Firewall Shape

```bash
nix eval --json .#nixosConfigurations.acorn.config.networking.firewall.allowedTCPPorts
```

Result: PASS, returned `[22,443,2222,2223,2224,2225,7000,34197]`. New backend ports `7777` through `7781` are not public firewall ports.

### Gateway Service Shape

```bash
nix eval --json '.#nixosConfigurations.acorn.config.systemd.services.auth-mini-gateway-status-axiom.environment'
```

Result: PASS. The status instance uses `HOST=127.0.0.1`, `PORT=7779`, `GATEWAY_DB=/var/lib/auth-mini-gateway/status-axiom.sqlite`, `GATEWAY_PUBLIC_BASE_URL=https://status-axiom.0xc1.wang`, and auth-mini issuer/public URL `https://auth.0xc1.wang`.

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.systemd.services.auth-mini.serviceConfig.ExecStart'
```

Result: PASS. `auth-mini` starts with `--host 127.0.0.1 --port 7777 --db /var/lib/auth-mini/auth-mini.sqlite`.

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.systemd.services.auth-mini-gateway-opencode-axiom.serviceConfig.EnvironmentFile'
```

Result: PASS. Gateway instances read `/run/agenix/auth-mini-gateway-env`.

### Secret Shape

```bash
agenix -d auth-mini-gateway-env.age -i /home/c1/.ssh/id_ed25519 > /dev/null
```

Result: PASS. The new secret decrypts for the Acorn identity without printing plaintext.

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.age.secrets.auth-mini-gateway-env'
```

Result: PASS. Owner/group are `auth-mini-gateway`, mode is `0400`, and runtime path is `/run/agenix/auth-mini-gateway-env`.

### nginx Shape

```bash
nix eval --impure --json --expr 'builtins.attrNames ((builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.services.nginx.virtualHosts)'
```

Result: PASS. Returned full vhost names:

```json
["auth-gateway.0xc1.wang","auth.0xc1.wang","frps-acorn.0xc1.wang","opencode-axiom.0xc1.wang","status-axiom.0xc1.wang","vault.0xc1.wang"]
```

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.services.nginx.virtualHosts."status-axiom.0xc1.wang".locations."/"'
```

Result: PASS. Root location proxies to `http://127.0.0.1:18080`, keeps `proxyWebsockets=true`, has `basicAuthFile=null`, and includes `auth_request /_auth`.

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.services.nginx.virtualHosts."opencode-axiom.0xc1.wang".locations."/"'
```

Result: PASS. Root location proxies to `http://127.0.0.1:18081`, keeps `proxyWebsockets=true`, has `basicAuthFile=null`, and includes `auth_request /_auth`.

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.services.nginx.virtualHosts."frps-acorn.0xc1.wang".locations."/"'
```

Result: PASS. Root location proxies to `http://127.0.0.1:7500`, has `basicAuthFile=null`, and includes `auth_request /_auth`.

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.services.nginx.virtualHosts."status-axiom.0xc1.wang".locations."= /_auth"'
```

Result: PASS. Internal check location proxies to `http://127.0.0.1:7779/auth/check` and sets `X-Original-URI`, `X-Forwarded-Proto`, `X-Forwarded-Host`, and cookie forwarding for the auth subrequest.

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.services.nginx.virtualHosts."auth-gateway.0xc1.wang".locations."= /login".proxyPass'
```

Result: PASS. Canonical gateway login route proxies to `http://127.0.0.1:7778/login`.

```bash
nix eval --impure --json --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.acorn.config.services.nginx.virtualHosts."vault.0xc1.wang".locations."/".proxyPass'
```

Result: PASS. Vaultwarden still proxies to `http://127.0.0.1:8000`.

Generated nginx config path from the nginx unit:

```text
/nix/store/1fqmasixhp19ifi7x1hh7yx6cx0fb2qa-nginx.conf
```

Manual inspection of that generated config confirmed:

- `auth.0xc1.wang` proxies to `127.0.0.1:7777`.
- `auth-gateway.0xc1.wang` exposes gateway routes on `127.0.0.1:7778`.
- `status-axiom.0xc1.wang`, `opencode-axiom.0xc1.wang`, and `frps-acorn.0xc1.wang` render full server blocks with `auth_request /_auth` and per-origin gateway ports `7779`, `7780`, and `7781`.
- `vault.0xc1.wang` remains the Vaultwarden proxy to `127.0.0.1:8000` and websocket route to `127.0.0.1:3012`.

### Whitespace Check

```bash
git diff --check
```

Result: PASS.

## Post-Deploy Checks Not Run Locally

- Create/verify DNS-only Cloudflare records for `auth.0xc1.wang` and `auth-gateway.0xc1.wang` pointing to Acorn.
- Switch the Acorn host and verify the new systemd services are active.
- Verify ACME issuance for the two new hostnames.
- Bootstrap auth-mini admin, then configure issuer `https://auth.0xc1.wang` and RP ID `auth.0xc1.wang`.
- Confirm unauthenticated access to status/opencode/frps redirects to auth-mini login.
- Confirm an allowlisted user can access each protected service after login.
- Confirm a denied user receives `403`.
- Confirm Opencode WebSocket behavior after login.
