# Q6 128K Model Selection And Control

## Status

Proposed for review.

## Context

Axiom currently runs one Q4_K_M Qwen service at 128K with full CUDA offload. Runtime measurement leaves 11,595 MiB free. The standard Q6_K MTP artifact is 22,533,850,336 bytes, about 5.15 GiB larger than Q4, so it is expected to fit while preserving useful headroom.

The service currently hardcodes the Q4 path. The operator also lacks one bounded command for selecting quantization and controlling model residency.

## Decision

Keep one `qwen3-8-27b.service` and make `${HOME}/.local/share/models/qwen3.8-27b/active.gguf` its only model path.

- If `active.gguf` is absent, `ExecStartPre` seeds it to the fixed Q6 path.
- If it already selects Q4 or Q6, activation preserves that operator choice.
- `ExecStartPre` fails if the selected target is unavailable or `active.gguf` is not a valid link to a readable model.
- The service remains loopback-only on port 8081 with 128K context, one slot, Q4_0 K/V cache, full GPU offload, flash attention, and MTP depth 2.

Install `qwen-model` as a host command with these subcommands:

| Command | Behavior |
|---|---|
| `qwen-model q4` | Atomically select the fixed Q4 artifact and restart the service |
| `qwen-model q6` | Atomically select the fixed Q6 artifact and restart the service |
| `qwen-model start` | Start the selected model service |
| `qwen-model stop` | Stop the service and release model VRAM |
| `qwen-model restart` | Restart the selected model and wait for health |
| `qwen-model status` | Show selected quantization, service state, and health |

The selector accepts no arbitrary model path or systemd unit. Before changing the link it validates the fixed target and obtains sudo authorization. Selection uses a temporary link plus atomic rename. It then restarts the service and waits up to three minutes for `/health`.

If a Q4/Q6 switch does not become healthy, the command restores the previous valid selection and restarts it. A failed rollback is reported without hiding the original failure.

## Alternatives

### Hardcode Q6

Smallest configuration change, but every rollback to Q4 requires another NixOS change and switch. Rejected because the user explicitly requested an operator command.

### Separate Q4 And Q6 Services

Makes selection visible as systemd units, but creates duplicate service definitions, port contention, and a path to simultaneous VRAM residency. Rejected.

### Arbitrary Model Path Argument

More flexible but expands the privileged restart wrapper and weakens reproducibility. Rejected; only the two verified artifacts are in scope.

## Artifact Handling

- Q4: `RVN-Q4_K_M-mtp.gguf`
- Q6: `RVN-Q6_K-mtp.gguf`
- Selection: `active.gguf`
- Template: `chat_template.jinja`

All remain mutable user data outside the Nix store. The Q6 download must match SHA-256 `4e47a0e41992de4bed56a3395f6c7e1adb760a1875ed84f836f67d65b2f646ef`.

## Verification

1. Build the complete Axiom closure and inspect the generated command and package.
2. Download Q6 and verify exact size and SHA-256.
3. Merge and switch from refreshed `origin/master`.
4. Confirm default Q6 selection, 131072 context, MTP initialization, health, chat, tools, and GPU memory with no CPU fallback/OOM.
5. Exercise `status`, `stop`, `start`, and `restart`.
6. Switch Q6 to Q4 and back to Q6, verifying health, selected link, process replacement, and GPU memory each time.
7. Confirm OpenCode keeps the existing logical model ID and 131072 context.

## Rollback

Run `qwen-model q4`. If the command itself is unavailable, point `active.gguf` back to the fixed Q4 artifact and restart `qwen3-8-27b.service`. The Q6 file can remain on disk or be removed after rollback verification; no Nix rollback is required unless the control command or service indirection is defective.
