# Log

## 2026-08-22

- Confirmed through Billing Management that August Acorn ECS egress is billed as 186.27701 GB at 0.8 CNY/GB, totaling 149.02 CNY.
- Confirmed Acorn has no `vnstat` binary or local historical interface-accounting database.
- Confirmed its declarative NixOS target is `/home/c1/dotfiles#acorn`; the service will be deployed from Axiom only.
- Chose NixOS `services.vnstat` rather than external telemetry or process-level accounting because the immediate need is durable aggregate daily/monthly billing visibility without new public exposure.
- Evaluated the pinned Acorn NixOS options and confirmed `services.vnstat.enable` exists as a boolean option; RFC review passed.
- Enabled the native `services.vnstat` daemon in Acorn's existing platform module without changing networking or firewall settings.
- Evaluated the effective configuration as `true`, then built on Axiom and switched Acorn remotely with the mandated deployment command.
- Verified `vnstat.service` active and `ens5` registered. Its first interval has not completed, so historic output is correctly unavailable.
- Verified the existing public-service baseline remains active; an initial `frps-acorn` check was ignored because it is not the configured unit name, and the actual `auth-mini-gateway-frps-acorn` unit is active.
- Generated walkthrough artifacts from report data. The HTML preview remains local because it describes production service and traffic details.
