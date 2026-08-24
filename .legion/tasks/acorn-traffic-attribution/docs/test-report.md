# Test Report: Acorn Traffic Attribution

## Verdict

PASS

## Rationale

The configuration evaluation proves the sampler and timer are in the Acorn system graph. The mandated Axiom-to-Acorn switch proves the closure was built locally and activated remotely. Host checks prove retained root-only samples and the report's service/proxy delta calculations.

## Executed Checks

| Check | Result | Evidence |
| --- | --- | --- |
| Targeted Nix evaluation of sample `ExecStart`, timer interval, and FRP `IPAccounting` | PASS | Resolved the sampler executable, returned `5min`, and returned `true`. |
| Axiom-to-Acorn `nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L` | PASS | Built on Axiom, copied the closure, activated Acorn, and started `acorn-traffic-sample.timer`. The authorized password was supplied through standard input and is intentionally omitted. |
| `systemctl is-active acorn-traffic-sample.timer nginx frps rustdesk-relay sshd` | PASS | All five units returned `active`. |
| Two manual `systemctl start acorn-traffic-sample.service` triggers | PASS | Created root-owned sample files under `/var/lib/acorn-traffic-accounting/samples` with mode `0640`. |
| `sudo acorn-traffic-report` | PASS | Compared two samples and emitted service deltas plus `axiom-gatus-http`, `axiom-opencode-http`, `axiom-pi-web-http`, and `axiom-ssh` proxy deltas. |

## Notes

- The first deployment restart/reset boundary for FRPS and RustDesk relay is expected. New samples preserve that boundary instead of producing negative deltas.
- The report intentionally displays separate cgroup and FRP totals. Operators must not sum them because one forwarded flow may cross both local services.
