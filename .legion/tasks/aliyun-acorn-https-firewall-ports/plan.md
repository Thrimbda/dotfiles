# Aliyun Acorn HTTPS Firewall Ports

## Task ID

`aliyun-acorn-https-firewall-ports`

## Goal

Keep the low-resource `aliyun-acorn` slimming from PR #112, but restore required public HTTPS staging for Vaultwarden/status and add the missing reverse SSH firewall ports `2223` and `2224`.

## Acceptance

- `aliyun-acorn` firewall allows TCP `443`, `2223`, and `2224` in addition to the required existing server ports.
- Public TCP `80` stays closed.
- `vault.0xc1.space` and `status-axiom.0xc1.wang` generate HTTPS-only nginx listeners on port `443`.
- ACME units are not generated during staging.
- Temporary TLS certificates are generated on-host outside the Nix store so nginx can start without ACME.
- Low-resource slimming from PR #112 remains intact.

## Non-Goals

- Do not re-enable ACME or force real certificate issuance before DNS/cutover is ready.
- Do not restore public HTTP on port `80`.
- Do not re-enable dev runtimes, Docker, desktop/media packages, or host `nix-ld`.

## Design

- Use nginx `onlySSL = true` for both staged auth-bearing vhosts.
- Provide explicit certificate/key paths under `/var/lib/nginx-selfsigned/<domain>/`.
- Generate missing self-signed certs in `nginx.preStart` before nginx config validation.
- Re-open firewall TCP `443`, `2223`, and `2224` while keeping TCP `80` absent.

## Risks

- Self-signed staging certificates are not production trust material; ACME must still be restored for real browser/client trust after DNS is correct.
- Public HTTPS exposes the staged auth surfaces, but not over cleartext. This is an intentional staging tradeoff requested by the user.
