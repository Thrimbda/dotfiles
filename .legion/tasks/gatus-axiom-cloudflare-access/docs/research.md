# Research: Gatus Axiom Cloudflare Access

## Current Repo Evidence

- `hosts/acorn/modules/status.nix` currently enables Gatus on `acorn` and exposes it as `status.0xc1.space` through nginx/ACME.
- `hosts/axiom/default.nix` already runs `opencode-server` on `127.0.0.1:4096` and routes `opencode-axiom.0xc1.space` through `modules.services.cloudflared.extraConfig.ingress` on tunnel `home-axiom`.
- `modules.services.gatus` already supports loopback web binding, sqlite storage, Prometheus scrape config generation, and optional nginx domain exposure.
- Wiki current truth says `opencode-axiom.0xc1.space` Access uses Google IdP and exact-email allowlist `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`.

## Domain Choice

Options:

- `status-axiom.0xc1.space`: matches current service-host pattern (`opencode-axiom.0xc1.space`).
- `status.axiom.0xc1.space`: introduces a new host subdomain hierarchy not used by current opencode routes.

Conclusion: use `status-axiom.0xc1.space`.

## Access / Cloudflare Evidence

Prior task `axiom-charlie-opencode-access-google-oidc` verified the Cloudflare Access control-plane pattern:

- Access apps are self-hosted applications scoped to exact hostnames.
- Google IdP id was discovered through the API and used as the allowed/required login method.
- Policies were asserted to include exact email rules and no bypass/broad allow rules.
- The canonical Cloudflare API token source is `hosts/charlie/secrets/cloudflare-api-token.age`; plaintext staging must not be committed.

This task should reuse that verification style for `status-axiom.0xc1.space` rather than relying on DNS route creation alone.

## Design Implications

- Move the status page runtime to `axiom` so cloudflared can route to local loopback (`http://127.0.0.1:8080`) like opencode.
- Remove the old `acorn` public status route to avoid split public surfaces.
- Configure Cloudflare route/DNS and Access app/policy for `status-axiom.0xc1.space`.
- Keep runtime deployment as a manual post-merge step; repo/build/API verification is sufficient before PR merge.
