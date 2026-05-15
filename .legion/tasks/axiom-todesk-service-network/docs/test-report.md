# Test Report: Enable ToDesk service networking on axiom

## Result

PASS. The axiom NixOS configuration evaluates with the expected ToDesk tmpfiles rule and systemd service. Live diagnostic evidence also shows `ToDesk_Service` holding an external HTTPS connection and the GUI connected to it over localhost.

## Commands

### Evaluate ToDesk service and tmpfiles config

Command:

```bash
nix eval --json --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; svc = cfg.systemd.services.todesk; in { tmpfiles = builtins.filter (rule: rule == "d /var/lib/todesk 0700 c1 users - -") cfg.systemd.tmpfiles.rules; service = { wantedBy = svc.wantedBy; after = svc.after; wants = svc.wants; user = svc.serviceConfig.User; workingDirectory = svc.serviceConfig.WorkingDirectory; execStart = svc.serviceConfig.ExecStart; restart = svc.serviceConfig.Restart; restartSec = svc.serviceConfig.RestartSec; }; }'
```

Output:

```json
{"service":{"after":["network-online.target"],"execStart":"/nix/store/mcys7wv6icyggvm9m2l8r9k2ykhh3zy7-todesk-4.7.2.0/bin/todesk service","restart":"on-failure","restartSec":"5s","user":"c1","wantedBy":["multi-user.target"],"wants":["network-online.target"],"workingDirectory":"/home/c1"},"tmpfiles":["d /var/lib/todesk 0700 c1 users - -"]}
```

Why this command: it directly proves the declarative claims made by the change without switching the live system.

Note: evaluation emitted the repository's existing `specialArgs.pkgs` warning; it did not affect the target values.

### Check live ToDesk socket behavior

Command:

```bash
ss -tunp | rg -i 'todesk|ToDesk'
```

Output excerpt:

```text
tcp ESTAB 198.18.0.1:37398 198.18.0.57:443 users:(("ToDesk_Service",pid=10096,fd=4))
tcp ESTAB 127.0.0.1:42912 127.0.0.1:35600 users:(("ToDesk",pid=54468,fd=26))
tcp ESTAB 127.0.0.1:35600 127.0.0.1:42912 users:(("ToDesk_Service",pid=10096,fd=8))
```

Why this command: it confirms the diagnosed runtime behavior behind the user-visible "no network" symptom: `ToDesk_Service` owns the external connection and the GUI talks to it locally.

## Not Run

- `nixos-rebuild switch`: intentionally skipped because the task scope is repository configuration and the user did not request a live switch.
- Full flake check: not necessary for this host-local systemd/tmpfiles change; targeted evaluation proves the affected configuration values.
