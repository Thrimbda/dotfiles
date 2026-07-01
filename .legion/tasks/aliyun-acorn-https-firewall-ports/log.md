# Log: Aliyun Acorn HTTPS Firewall Ports

## 2026-07-01

- User clarified that `443` cannot be omitted for Vaultwarden/status staging.
- User also requested adding firewall TCP ports `2223` and `2224`.
- Opened worktree `.worktrees/aliyun-acorn-https-firewall-ports` on branch `legion/aliyun-acorn-https-firewall-ports` from `origin/master`.
- Tested `addSSL = true` without certificate paths; Nix evaluation fails because `sslCertificate` has no value. Therefore the fix cannot simply add `addSSL`.
- Implemented explicit HTTPS-only staging using nginx `onlySSL = true`, certificate/key paths under `/var/lib/nginx-selfsigned/<domain>/`, and `nginx.preStart` self-signed certificate generation before config validation.
- Added `StateDirectory = "nginx-selfsigned"` to `nginx.service` so the nginx service sandbox can write/read the generated staging certs under `ProtectSystem=strict`.
- Updated firewall TCP ports to `[22 443 2222 2223 2224 2225 7000 34197]`; port `80` remains absent.

## Verification Evidence

- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts` -> `[22,443,2222,2223,2224,2225,7000,34197]`.
- Vhost eval confirmed both staged vhosts have `onlySSL = true`, `enableACME = false`, and explicit self-signed certificate paths.
- `nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.units --apply 'units: builtins.filter (name: builtins.match ".*acme.*|.*docker.*" name != null) (builtins.attrNames units)'` -> `[]`.
- Docker remains disabled with `{ enable = false; enableOnBoot = false; }`.
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed.
- Generated nginx config contains only `listen 0.0.0.0:443 ssl` / `listen [::0]:443 ssl` for `status-axiom.0xc1.wang` and `vault.0xc1.space`; no public `80` listener was generated.
- Generated nginx preStart creates missing self-signed certs before running `nginx -t`.
- Nginx serviceConfig includes `StateDirectory = "nginx-selfsigned"` and `StateDirectoryMode = "0750"`.
