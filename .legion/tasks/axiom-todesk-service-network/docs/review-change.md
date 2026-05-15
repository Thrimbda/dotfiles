# Review: Enable ToDesk service networking on axiom

## Result

PASS. No blocking findings remain.

## Scope Review

- In scope: `hosts/axiom/default.nix` adds a host-local tmpfiles rule for ToDesk state.
- In scope: `hosts/axiom/default.nix` adds a host-local `systemd.services.todesk` unit that runs `${pkgs.todesk}/bin/todesk service` as `c1`.
- In scope: task-local Legion evidence under `.legion/tasks/axiom-todesk-service-network`.
- Not included: firewall changes, reusable module creation, package version changes, or live `nixos-rebuild switch`.

## Correctness Review

- The tmpfiles rule creates `/var/lib/todesk` with `0700 c1 users`, which is sufficient for both the GUI and service because both are run as `c1`.
- The service starts after and wants `network-online.target`, matching the remote connectivity dependency observed in diagnostics.
- The service uses the packaged `${pkgs.todesk}/bin/todesk service` entrypoint rather than reaching into Nix store internals.
- Restart policy is limited to `on-failure`, avoiding unnecessary restart churn for intentional stops.

## Security Lens

Applied because this change starts a remote desktop background service and manages ToDesk auth/private state.

- The state directory is restricted to `0700` to avoid exposing ToDesk-generated private/auth data to other local users.
- No inbound firewall ports are opened by this change.
- The service runs as `c1`, not root, matching the successful diagnostic and limiting privilege.

## Verification Review

- `docs/test-report.md` records targeted Nix evaluation proving the configured tmpfiles rule and systemd service fields.
- `docs/test-report.md` records live socket evidence showing `ToDesk_Service` owns the external HTTPS connection and the GUI connects locally.

## Residual Risks

- ToDesk is proprietary binary software; repository-level validation cannot prove vendor-side runtime behavior.
- Running the service as `c1` may not provide unattended pre-login remote access. That behavior is outside this task.
