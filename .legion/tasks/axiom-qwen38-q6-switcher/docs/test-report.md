# Verification Report

## Result

PARTIAL PASS. The complete Axiom closure, generated command/unit, bounded control command, and Q6 artifact integrity pass. Merged activation, Q6 GPU capacity, lifecycle controls, and Q6-Q4-Q6 switching remain runtime checks.

## Closure

```bash
nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel -L
```

Passed. The closure is `/nix/store/wk0yxm78x3bzx5lbmm9jb88gy4x8ay5j-nixos-system-axiom-26.05.7813.0dd31db7e6db`. The generated `qwen-model` also passed `writeShellApplication` ShellCheck.

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

## Pending Checks

- Merge and switch the configuration from refreshed `origin/master`.
- Confirm the default selection is Q6 and it loads at 128K with MTP and full CUDA offload.
- Record Q6 GPU usage/headroom and run health, chat, reasoning, and OpenCode tool-call checks.
- Exercise status, stop, start, restart, Q6-to-Q4, and Q4-to-Q6 paths.
