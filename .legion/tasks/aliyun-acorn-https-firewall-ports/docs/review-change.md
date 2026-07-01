# Review Change: Aliyun Acorn HTTPS Firewall Ports

## Decision

PASS

## Security Lens

Applied. This change exposes auth-bearing staged vhosts over public HTTPS while keeping public HTTP closed.

## Findings

No blocking findings.

## Confirmed

- Public TCP `443` is restored and TCP `80` remains closed.
- TCP `2223` and `2224` are added to the host firewall.
- `vault.0xc1.space` and `status-axiom.0xc1.wang` generate HTTPS-only nginx listeners.
- ACME units are still absent, avoiding activation-time certificate issuance.
- Self-signed certificate material is generated on-host under `/var/lib/nginx-selfsigned`, not committed or stored in the Nix store.
- `nginx.service` owns `StateDirectory = "nginx-selfsigned"`, so the generated cert path is writable inside the unit sandbox.
- Docker and low-resource slimming remain intact.

## Residual Risk

- Self-signed staging certs are not production-trusted certs. DNS/ACME cutover remains a follow-up.
