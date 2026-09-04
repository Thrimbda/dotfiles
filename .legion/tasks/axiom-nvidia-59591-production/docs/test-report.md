# Verification Report: Axiom NVIDIA 595.99.02 Production Driver

**Result:** PASS

## Evidence

| Claim | Command | Result |
| --- | --- | --- |
| The target closure builds | `nixos-rebuild build --flake .#axiom --no-link -L` | Exit 0; produced `/nix/store/li2hf423pb4fgb3x2h7cj70hwla5aadf-nixos-system-axiom-26.05.7813.0dd31db7e6db`. |
| The target host is Axiom | `hostname` | `axiom` |
| The selected configuration keeps open modules enabled | `nix eval --json .#nixosConfigurations.axiom.config.hardware.nvidia.open` | `true` |
| The running driver is the requested production version | `nvidia-smi --query-gpu=name,driver_version --format=csv,noheader` | `NVIDIA GeForce RTX 5090, 595.99.02` |
| The kernel uses NVIDIA for the RTX 5090 | `lspci -nnk -s 01:00.0` | `Kernel driver in use: nvidia` |
| The built generation is active | `readlink -f /run/current-system` | `/nix/store/li2hf423pb4fgb3x2h7cj70hwla5aadf-nixos-system-axiom-26.05.7813.0dd31db7e6db` |
| The system is healthy after reboot | `systemctl is-system-running` | `running` |
| The Wayland compositor started after reboot | `pgrep -a Hyprland` | Hyprland 0.56.1 process is running |

## Notes

- The build emitted upstream `nvidia-settings` GTK deprecation warnings but
  completed successfully.
- Suspend/resume and a CUDA compilation smoke test were not forced because
  they would disrupt the active workstation session. The driver loaded, GPU
  query, configured open module selection, and running system generation all
  passed.
