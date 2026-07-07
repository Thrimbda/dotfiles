# Log

- Created task to switch `status-axiom.0xc1.wang` from staged self-signed TLS to Cloudflare DNS-01 ACME after the DNS `A` record was created.
- Updated `hosts/aliyun-acorn/default.nix` to set `onlySSL = true`, `useACMEHost = "status-axiom.0xc1.wang"`, and an ACME cert using the existing Cloudflare DNS environment secret.
- Updated `.legion/wiki/decisions.md` to record that `status-axiom.0xc1.wang` now uses DNS-01 ACME, not staged TLS.
- Validation passed: `aliyun-acorn` evaluates, dry-run build includes `acme-status-axiom.0xc1.wang.service` and `acme-renew-status-axiom.0xc1.wang.timer`, actual local build succeeds, and `git diff --check` passes.
- Deployment attempt copied the new system closure to `c1@8.159.128.125`, then failed at remote sudo because `c1` requires a password and root SSH is not available with the current key.
