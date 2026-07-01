# Review Change

## Verdict

Ready.

## Findings

No findings.

## Review Notes

- The change keeps public `80` closed and uses DNS-01 instead of HTTP-01.
- `vault.0xc1.wang` is the only Vaultwarden hostname on `aliyun-acorn`; `vault.0xc1.space` is not reintroduced.
- `hosts/acorn` is unchanged.
- The Cloudflare token is committed only as an age-encrypted env file and was verified by variable-name shape without printing secret material.
- Cloudflare proxy is already live and edge HTTPS returns a trusted Cloudflare certificate.

## Residual Risk

- Source ACME issuance requires deploying this config to `aliyun-acorn`. Cloud Assistant is unavailable for this instance and earlier SSH as `c1` was rejected, so live origin validation may require console or restored SSH access.
