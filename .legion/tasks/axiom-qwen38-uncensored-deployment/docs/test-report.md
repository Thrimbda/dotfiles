# Verification Report

## Result

PASS. The package, NixOS closure, model artifact, merged system activation, persistent systemd service, CUDA runtime, MTP setup, automatic restart, and OpenAI-compatible API were verified.

## Commands And Evidence

### NixOS closure

```bash
nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel -L
```

Passed. The final closure is `/nix/store/hvx7gjycyvk4ajhri8nxgvhgz2fw26m1-nixos-system-axiom-26.05.7813.0dd31db7e6db`. This was chosen over evaluating only the service because it proves that the pinned package, CUDA dependencies, generated unit, and complete Axiom configuration compose successfully.

### llama.cpp package and CUDA device

```bash
/nix/store/iap2lg33815dfjgihp89yvqwnd4kgck1-llama-cpp-10472/bin/llama-server --version
/nix/store/iap2lg33815dfjgihp89yvqwnd4kgck1-llama-cpp-10472/bin/llama-server --list-devices
```

Passed. The binary reports build `10472`, commit `60eeeb6`, and detects `CUDA0: NVIDIA GeForce RTX 5090` with 32077 MiB.

### Model integrity

```bash
sha256sum /home/c1/.local/share/models/qwen3.8-27b/RVN-Q4_K_M-mtp.gguf
```

Passed. The local 16,998,720,736-byte file has SHA-256 `5df52200763806fad5c01add7b1be13e9ef96dd1932a41226632693aac321b7b`, matching the Hugging Face LFS object ID. The chat template exists at the configured path and is 8,952 bytes.

### Runtime and API

The generated `llama-server` command was started as a transient user service because the system switch requires interactive sudo authentication.

```bash
curl --fail http://127.0.0.1:8081/health
curl --fail http://127.0.0.1:8081/v1/models
curl --fail http://127.0.0.1:8081/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3.8-27b-uncensored","messages":[{"role":"user","content":"Reply with exactly: local inference works"}],"max_tokens":64,"temperature":0}'
```

Passed.

- `/health` returned `{"status":"ok"}`.
- `/v1/models` exposed `qwen3.8-27b-uncensored`.
- Chat completion returned `local inference works`, `finish_reason: stop`, and a separate `reasoning_content` field.
- Logs reported `creating MTP draft context`, `n_slots = 1`, `n_ctx_slot = 65536`, model loaded, and listening on `127.0.0.1:8081`.
- GPU memory usage rose from about 3 GiB to 21,049 MiB while the model was loaded, consistent with CUDA model offload.
- The transient test service was stopped after verification.

## Post-Merge Activation

```bash
cd /home/c1/dotfiles
sudo nixos-rebuild switch --flake .#axiom -L
```

Passed after PR #171 merged and the main workspace was refreshed to commit `593576f3`.

- `qwen3-8-27b.service` is enabled and active.
- The persistent unit loaded the model, created the MTP draft context, initialized one 65536-token slot, and listened on `127.0.0.1:8081`.
- GPU memory usage was 18,691 MiB with the persistent service loaded.
- The persistent API returned `persistent service works` with `finish_reason: stop` and a separate reasoning field.

### Restart recovery

```bash
kill -KILL 923128
```

Passed. systemd incremented `NRestarts` from 0 to 1, replaced PID `923128` with PID `1957381`, reloaded the model after the configured five-second delay, and restored `/health`. A post-restart completion returned `restart works`; logs again confirmed MTP and the 65536-token slot.

## Known Warnings

The existing Axiom configuration emits unrelated NixOS deprecation warnings during evaluation. `llama-server` also warns that no API key is configured and CORS allows all origins; the service is intentionally bound only to `127.0.0.1` per the approved contract.
