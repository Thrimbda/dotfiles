# Test Report: Axiom Cloudflared HTTP2 Transport Fix

## Summary

Status: PASS with one unrelated pre-existing flake check failure.

The targeted validation proves the current change does what it claims: axiom's generated `/etc/cloudflared/config.yml` now contains `"protocol":"http2"`, while the systemd cloudflared service still starts with `--config /etc/cloudflared/config.yml`. A dry-run of the axiom NixOS toplevel also evaluates successfully.

## Commands

### Generated cloudflared config

Command:

```bash
nix eval .#nixosConfigurations.axiom.config.environment.etc.\"cloudflared/config.yml\".text --raw
```

Result: PASS.

Relevant output:

```json
{"credentials-file":"/home/c1/.cloudflared/bc8b3291-de93-4f7f-807a-23f802ef021f.json","ingress":[{"hostname":"opencode-axiom.0xc1.space","service":"http://127.0.0.1:4096"},{"service":"http_status:404"}],"protocol":"http2","tunnel":"bc8b3291-de93-4f7f-807a-23f802ef021f","tunnelName":"home-axiom"}
```

Why this proves the claim: this is the exact Nix-generated text for `/etc/cloudflared/config.yml`, so it verifies the declarative runtime config will include `protocol: http2` without changing tunnel, credentials, hostname, or origin service.

### Cloudflared systemd ExecStart

Command:

```bash
nix eval .#nixosConfigurations.axiom.config.systemd.services.cloudflared.serviceConfig.ExecStart --raw
```

Result: PASS.

Relevant output:

```text
/nix/store/7ly3c849fym2q0lmc0895cs4yv7rxlf8-cloudflared-2025.11.1/bin/cloudflared --config /etc/cloudflared/config.yml tunnel run
```

Why this proves the claim: the service continues to consume the generated `/etc/cloudflared/config.yml`; no service command or credential path behavior changed.

### Axiom toplevel dry-run

Command:

```bash
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run
```

Result: PASS.

Relevant output:

```text
these 27 derivations will be built:
  /nix/store/mk8021qx7awfnwzd9yir6hl5mgbz06gg-etc-cloudflared-config.yml.drv
  /nix/store/9azl0p5iw90954kzfrdfn10395vr9866-nixos-system-axiom-25.11.20260203.e576e3c.drv
```

Why this proves the claim: axiom's NixOS system evaluates far enough to plan the toplevel build, including the generated cloudflared config derivation.

## Non-blocking Failure

Command:

```bash
nix flake check --no-build
```

Result: FAIL, unrelated to this change.

Relevant output:

```text
error: expected a string but found a path: /nix/store/...-source/install.zsh
at /nix/store/...-source/lib/nixos.nix:19:13:
  mkApp = program: {
    inherit program;
```

Assessment: this fails while checking `apps.x86_64-linux.install` and the existing `mkApp` helper shape. The current change only touches `hosts/axiom/default.nix` cloudflared `extraConfig`, and the targeted axiom eval/dry-run paths pass.

## Skipped Runtime Validation

- Did not edit `/etc/static/cloudflared/config.yml`; it is Nix-generated and points into `/nix/store`.
- Did not restart system `cloudflared.service`; current session lacks passwordless sudo.
- Did not stop the temporary user-level HTTP/2 connector because it is keeping the hostname reachable until the declarative fix is deployed.

## Follow-up After Merge/Deploy

1. Deploy the dotfiles change to axiom.
2. Restart `cloudflared.service` or allow NixOS activation to restart it.
3. Confirm `journalctl -u cloudflared` shows registered `protocol=http2` connections.
4. Confirm `https://opencode-axiom.0xc1.space` still returns Cloudflare Access login/redirect.
5. Stop the temporary user-level HTTP/2 connector if the system service is healthy.
