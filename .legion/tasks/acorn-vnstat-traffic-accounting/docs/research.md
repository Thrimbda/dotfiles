# Research: Acorn Traffic Accounting

## Evidence

- Billing Management reports Acorn's August ECS item as outbound traffic: 186.27701 GB at 0.8 CNY/GB, or 149.02 CNY.
- July outbound traffic for the same host was 91.561855 GB and 73.25 CNY.
- Acorn's current public services include RustDesk relay/signal, FRP, Nginx, Vaultwarden, and authentication gateways. Existing socket observations cannot prove historic byte attribution.
- `vnstat --days` is not present on the host, so no local per-interface history exists.
- The Acorn NixOS configuration is declared in `hosts/acorn/`, with platform settings in `hosts/acorn/modules/platform.nix`.

## Deployment Constraint

Acorn must not build its own NixOS closure. Build and activation must run from Axiom using:

```sh
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
```

## Options

1. Enable `vnstat` locally.
   - Captures durable aggregate totals for each network interface without opening a port.
   - Cannot attribute traffic to individual processes and starts collecting only after activation.
2. Add process-level accounting or eBPF telemetry.
   - Could attribute future traffic more precisely.
   - Adds complexity, retention and operational decisions beyond the billing-monitoring need.
3. Use platform flow logs or external telemetry.
   - Could offer longer retention and remote visualization.
   - Adds cloud resources, cost, credentials, and data handling scope.

The first option is the smallest reversible solution for detecting future aggregate egress spikes.
