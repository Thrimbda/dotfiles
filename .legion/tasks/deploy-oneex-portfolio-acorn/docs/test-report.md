# Verification Report

## Result

PASS for the Acorn deployment and public HTTPS API path. Direct-origin and ordinary-hostname checks both reach the bearer-protected application.

## Local Build

Command:

```sh
nix build .#nixosConfigurations.acorn.config.system.build.toplevel -L
```

Result: PASS. The complete Acorn closure built locally. The vendored adapter compiled with Rust 1.97 and its Nix check ran all 10 upstream tests successfully. The derivation applies only the verified `READ_TIMEOUT` change from 4.5 to 5.8 seconds.

## Source Provenance

A fresh SSH clone of `git@github.com:Thrimbda/1ex-portfolio.git` confirmed that the tracked vendor files exactly match commit `8dcf21f9a2549212bff4b380dc5daf3f5c1236f9` before the Nix build-time patch:

```text
Cargo.toml  e18a1c601937aa9c16254b742c05c89df46dc2adadd1b2ce4a7bb35c5afb0844
Cargo.lock  91848df6e08c1ed181cccdedb9d8aef903b0f0ab97597c2c3fddea47ae07577e
src/main.rs c6a3d999562d84367840434b7b1e5008c192e2ed28046850a265422e1b6fba00
```

This check was chosen over a local checkout comparison because the existing local checkout did not contain the pinned revision. It proves the tracked snapshot's upstream provenance; the full Nix build separately proves the narrow timeout substitution compiles and tests.

## Remote Activation

Command:

```sh
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```

Result: PASS. The closure was built locally, copied to Acorn, the age environment decrypted successfully, and `oneex-portfolio-adapter.service` started. No build was performed on Acorn.

## Service And TLS Boundary

- `oneex-portfolio-adapter.service`: `active/running`, dedicated `oneex-portfolio-adapter` user/group, exit status `0`.
- `nginx.service`: `active/running`.
- `acme-1ex-portfolio.0xc1.wang.service`: completed successfully.
- `ss -ltn '( sport = :8090 )'`: only `127.0.0.1:8090` listens.
- A direct SNI request to `8.159.128.125` for `https://1ex-portfolio.0xc1.wang/api/accounts` returned `401` without a bearer, proving nginx TLS proxying and application authentication remain active.

## Authenticated API

The bearer was derived in memory from the authorized Ed25519 identity and was never printed by validation commands.

Direct SNI HTTPS validation returned:

```text
direct_https_accounts_status=200
direct_https_positions_status=200
position_count=5
valuation_usd=28501.06309945
```

The valuation is live and changes between requests; it is evidence that the response is neither a false zero nor a partial empty portfolio.

## Cloudflare DNS And Public Hostname

The existing encrypted Cloudflare token performed an idempotent upsert:

```text
cloudflare_dns_action=created
cloudflare_dns_name=1ex-portfolio.0xc1.wang
cloudflare_dns_content=8.159.128.125
cloudflare_dns_proxied=false
cloudflare_dns_ttl=1
```

A subsequent provider API query returned exactly one matching A record. A final check confirmed propagation through both public recursive resolvers:

```text
Cloudflare DoH: 1ex-portfolio.0xc1.wang A 8.159.128.125
Google DoH:     1ex-portfolio.0xc1.wang A 8.159.128.125
```

An independent ordinary-hostname fetch of `https://1ex-portfolio.0xc1.wang/api/accounts` returned the expected `401`, proving the public DNS, certificate, nginx proxy, and application authentication boundary. This local environment maps normal hostnames through fake-IP `198.18.0.0/15`, so a direct local curl still receives a TLS EOF and is not used as public-route evidence.

## Rejected Alternative

`AUTH_BASE_URL=http://127.0.0.1:7777` was tested because local auth-mini accepts the registered key. 1Ex rejected the locally minted token immediately, so that environment override was removed and the default `https://auth.ntnl.io` issuer path was restored before final validation.
