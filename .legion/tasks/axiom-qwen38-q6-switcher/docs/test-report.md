# Verification Report

## Result

FULL PASS. Q6 is the active 128K MTP model, fits fully on the RTX 5090, serves direct and OpenCode requests, and retains 6629 MiB of GPU headroom. Every `qwen-model` lifecycle command and the Q6-to-Q4-to-Q6 round trip passed.

## Closure

```bash
nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel -L
```

Passed before both deployment PRs. The corrected closure is `/nix/store/rf1fg3cnzpqbp6jn22836kbzmpzns025-nixos-system-axiom-26.05.7813.0dd31db7e6db`; the activated system is `/nix/store/r227d59d11hhp8q7vq4aa186nyfy7jbd-nixos-system-axiom-26.05.7813.0dd31db7e6db`. The generated `qwen-model` also passed `writeShellApplication` ShellCheck.

## Generated Service And Command

- The service uses `active.gguf`, 131072 context, full GPU offload, flash attention, one slot, Q4_0 K/V cache, and MTP depth 2.
- `ExecStartPre` seeds an absent selection to the fixed Q6 artifact and rejects unavailable or non-link selections.
- `qwen-model` exposes only `q4`, `q6`, `start`, `stop`, `restart`, and `status`.
- Q4/Q6 targets and the systemd unit are fixed at build time; arbitrary paths and unit names are not accepted.
- Selection uses atomic link replacement, waits for health, and restores the previous valid target after failed activation.

## Q6 Artifact

```text
path:   /home/c1/.local/share/models/qwen3.8-27b/RVN-Q6_K-mtp.gguf
size:   22533850336 bytes
sha256: 4e47a0e41992de4bed56a3395f6c7e1adb760a1875ed84f836f67d65b2f646ef
```

Passed. Size and SHA-256 match the Hugging Face LFS metadata.

## Q6 Runtime

- `active.gguf` resolves to `RVN-Q6_K-mtp.gguf`; `qwen-model status` reports `selected: q6`, active service, and healthy endpoint.
- `/props` reports one slot with `n_ctx=131072`; the journal records MTP draft initialization and `n_ctx_slot=131072`.
- The service runs with `--n-gpu-layers all`. Q6 uses 25449 MiB of 32607 MiB total GPU memory, leaving 6629 MiB free.
- `nvidia-smi` reports one compute process: the single `llama-server`, using 25256 MiB excluding display overhead.
- Direct chat returned the exact requested response and non-empty reasoning content.
- OpenCode `medium` invoked the Bash tool and returned `/home/c1/dotfiles`.

## Model And Lifecycle Control

Passed interactively:

```bash
qwen-model q4
qwen-model status
qwen-model q6
qwen-model status
qwen-model stop
qwen-model start
qwen-model restart
qwen-model status
```

The command ended on healthy Q6. The system journal records successful loads for both quantizations and distinct stop/start/restart process lifecycles; only one `llama-server` is resident.

## Runtime Correction

The first post-merge `qwen-model q4` attempt exposed that adding `pkgs.sudo` to `runtimeInputs` selected the non-setuid Nix store binary. The command failed safely before changing `active.gguf`. PR #176 removed store sudo and changed the command to `/run/wrappers/bin/sudo`; activation and the complete runtime sequence then passed.
