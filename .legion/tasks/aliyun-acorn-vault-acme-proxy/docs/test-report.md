# Test Report

## Result

Pass for repository configuration and Cloudflare edge state. Live origin ACME issuance remains deployment-time validation.

## Evidence

- Cloudflare API update:
  - `vault.0xc1.wang` A record: `content=8.159.128.125`, `ttl=1`, `proxied=true`.
- Cloudflare DoH:
  - `vault.0xc1.wang` resolves to Cloudflare edge IPs `104.21.58.171` and `172.67.162.78`.
- Cloudflare edge HTTPS:
  - `curl -I --resolve vault.0xc1.wang:443:104.21.58.171 https://vault.0xc1.wang/` returned `HTTP/2 200` and `server: cloudflare`.
  - `curl -I --resolve vault.0xc1.wang:443:172.67.162.78 https://vault.0xc1.wang/` returned `HTTP/2 200` and `server: cloudflare`.
- Certificate probe:
  - `openssl s_client -connect vault.0xc1.wang:443 -servername vault.0xc1.wang` showed issuer `C=US, O=Google Trust Services, CN=WE1`.
- Secret shape:
  - `age -d -i /home/c1/.ssh/id_ed25519 hosts/aliyun-acorn/secrets/cloudflare-dns.env.age | grep -q '^CF_DNS_API_TOKEN='` passed without printing the token.
- Nix eval:
  - `vault.0xc1.wang` vhost has `onlySSL=true`, `useACMEHost="vault.0xc1.wang"`, and Vaultwarden proxy locations.
  - ACME cert config has `dnsProvider="cloudflare"`, `environmentFile="/run/agenix/cloudflare-dns-env"`, `group="nginx"`, and `webroot=null`.
  - nginx self-signed preStart loops only over `status-axiom.0xc1.wang`.
  - `acme-order-renew-vault.0xc1.wang` service uses `/run/agenix/cloudflare-dns-env` and calls lego with `--dns cloudflare`.
- Build:
  - `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed.

## Not Covered

- The source host has not yet been deployed from this branch, so actual Let's Encrypt issuance on `aliyun-acorn` is not yet proven.
