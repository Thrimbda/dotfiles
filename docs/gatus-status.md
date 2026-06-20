# Gatus Status Page Runbook

Gatus is the repo-managed status page and black-box monitoring entrypoint. It checks user-visible availability and exposes Prometheus metrics; application and infrastructure metrics still belong in Prometheus exporters and app metrics.

## Deployment Shape

- Host: `axiom`
- Public URL: `https://status-axiom.0xc1.space`
- Local Gatus URL: `http://127.0.0.1:8080`
- SQLite state: `/var/lib/gatus/gatus.db`
- Prometheus metrics: `http://127.0.0.1:8080/metrics`
- Nix config: `hosts/axiom/default.nix`
- Public transport: `home-axiom` cloudflared tunnel
- Public auth: Cloudflare Access, created with the then-current `opencode-axiom.0xc1.space` exact-email pattern

Cloudflare DNS/tunnel routing and Access policy for `status-axiom.0xc1.space` are configured through the Cloudflare control plane. Cloudflared is only the transport; Access is the authentication boundary.

## Adding an Endpoint

Add entries to `modules.services.gatus.endpoints` in `hosts/axiom/default.nix`.

Required fields:

- `name`: stable endpoint key, for example `vaultwarden-web`.
- `group`: dashboard group, for example `public`, `core`, `infra`, or `internal`.
- `url`: HTTP, TCP, ICMP, DNS, WebSocket, or gRPC target supported by Gatus.
- `interval`: probe interval such as `1m`.
- `conditions`: health checks such as `[STATUS] == 200`, `[RESPONSE_TIME] < 1000`, `[CONNECTED] == true`, or `[CERTIFICATE_EXPIRATION] > 336h`.
- `extra-labels`: at least `service`, `environment`, and `owner` for Prometheus queries.

Keep public status entries limited to public-safe services. Do not add private database, Redis, queue, or internal-only hostnames to the public status page in the first version.

## Local Validation

Run targeted checks before deploying:

```sh
nix build .#nixosConfigurations.axiom.config.system.build.toplevel
nix eval .#nixosConfigurations.axiom.config.services.gatus.settings.metrics
nix eval .#nixosConfigurations.axiom.config.services.prometheus.scrapeConfigs
nix eval .#nixosConfigurations.axiom.config.modules.services.cloudflared.extraConfig.ingress --json
```

If time and cache availability permit, also run:

```sh
nix flake check
```

## Prometheus Queries

Useful PromQL entrypoints:

```promql
gatus_results_endpoint_success
gatus_results_duration_seconds
gatus_results_total
gatus_results_certificate_expiration_seconds
```

The generated scrape job targets `127.0.0.1:8080` with `metrics_path = /metrics`.

## Troubleshooting

- Gatus service state: `systemctl status gatus.service`
- Gatus logs: `journalctl -u gatus.service -n 200 --no-pager`
- Cloudflared service state: `systemctl status cloudflared.service`
- Cloudflared logs: `journalctl -u cloudflared.service -n 200 --no-pager`
- Local status page: `curl -I http://127.0.0.1:8080`
- Local metrics: `curl http://127.0.0.1:8080/metrics`
- Tunnel ingress: check `modules.services.cloudflared.extraConfig.ingress` includes `status-axiom.0xc1.space`.
- Access policy: confirm the `status-axiom.0xc1.space` app uses Google IdP and its reviewed exact-email allowlist. Do not assume future `opencode-axiom.0xc1.space` allowlist changes automatically apply to the status page without a scoped Access-policy task.
- Prometheus scrape: query `up{job="gatus"}` and inspect `services.prometheus.scrapeConfigs`.

## Boundary

Gatus answers: "Can a user or external probe reach this endpoint and get an acceptable response?"

Prometheus answers: "What are the internal application and infrastructure metrics over time?"

Keep business metrics and host exporters out of Gatus unless they are represented as black-box availability endpoints.
