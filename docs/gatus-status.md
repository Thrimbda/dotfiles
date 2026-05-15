# Gatus Status Page Runbook

Gatus is the repo-managed status page and black-box monitoring entrypoint. It checks user-visible availability and exposes Prometheus metrics; application and infrastructure metrics still belong in Prometheus exporters and app metrics.

## Deployment Shape

- Host: `acorn`
- Public URL: `https://status.0xc1.space`
- Local Gatus URL: `http://127.0.0.1:8080`
- SQLite state: `/var/lib/gatus/gatus.db`
- Prometheus metrics: `http://127.0.0.1:8080/metrics`
- Nix config: `hosts/acorn/modules/status.nix`

DNS and ACME for `status.0xc1.space` must be confirmed during deployment. This repo configures the nginx vhost and certificate request, but it does not manage external DNS records.

## Adding an Endpoint

Add entries to `modules.services.gatus.endpoints` in `hosts/acorn/modules/status.nix`.

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
nix build .#nixosConfigurations.acorn.config.system.build.toplevel
nix eval .#nixosConfigurations.acorn.config.services.gatus.settings.metrics
nix eval .#nixosConfigurations.acorn.config.services.prometheus.scrapeConfigs
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
- Local status page: `curl -I http://127.0.0.1:8080`
- Local metrics: `curl http://127.0.0.1:8080/metrics`
- nginx vhost: check `services.nginx.virtualHosts."status.0xc1.space"` in evaluated config.
- ACME failures: check DNS for `status.0xc1.space` and `journalctl -u acme-status.0xc1.space.service`.
- Prometheus scrape: query `up{job="gatus"}` and inspect `services.prometheus.scrapeConfigs`.

## Boundary

Gatus answers: "Can a user or external probe reach this endpoint and get an acceptable response?"

Prometheus answers: "What are the internal application and infrastructure metrics over time?"

Keep business metrics and host exporters out of Gatus unless they are represented as black-box availability endpoints.
