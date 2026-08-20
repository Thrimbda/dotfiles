# RFC: Axiom Qwen3.8 Uncensored Deployment

## Status

Proposed

## Context

Axiom has an RTX 5090 with 32 GB VRAM and an existing NixOS-managed NVIDIA
stack. The selected model is
`0bserverx/Qwen3.8-27B-Heretic-Abliterated-Uncensored-GGUF`, specifically
`RVN-Q4_K_M-mtp.gguf`. It needs a llama.cpp build at least as new as b10440
for embedded MTP speculative decoding. The currently pinned unstable nixpkgs
package is b10133.

Port 8080 is already occupied by Gatus, so the local API will use port 8081.

## Options

### Use the upstream llama.cpp flake

This provides a ready-made CUDA output, but also introduces the upstream
flake's nixpkgs and flake-parts inputs. It expands dependency resolution and
has already encountered unauthenticated GitHub API rate limiting.

### Override the existing nixpkgs package source

Reuse the current `pkgs.unstable.llama-cpp` package expression, enable its CUDA
backend, and replace only the source revision and source-dependent hashes with
a known compatible llama.cpp tag. This keeps the dependency graph aligned with
the existing system and limits the change to Axiom.

### Use a container or Python serving stack

Ollama, vLLM, or a CUDA container could serve the model, but each adds runtime
layers and configuration without improving this single-user GGUF deployment.

## Decision

Use the existing nixpkgs llama.cpp package definition with CUDA enabled and
pin its source to llama.cpp b10472. b10472 is newer than the b10440 MTP floor
and is the version used by the selected model publisher's validation.

Run `llama-server` directly as user `c1` under a systemd service with:

- model path `/home/c1/.local/share/models/qwen3.8-27b/RVN-Q4_K_M-mtp.gguf`
- repository-provided `chat_template.jinja`
- localhost port 8081 and alias `qwen3.8-27b-uncensored`
- one 64K context slot
- full CUDA offload and flash attention
- Q4 K/V cache
- embedded MTP speculative decoding with draft depth 2
- medium reasoning effort by default

The model and template remain mutable local data and are downloaded once with
the Hugging Face CLI. They are not copied into the Nix store.

## Verification

1. Evaluate the Axiom service command and package path from the flake.
2. Build and switch `.#axiom` on Axiom.
3. Confirm `qwen3-8-27b.service` is active after a restart.
4. Confirm `/health` and `/v1/chat/completions` respond on port 8081.
5. Inspect service logs for CUDA device discovery, full layer offload, and
   `draft-mtp` activation.
6. Inspect `nvidia-smi` while the service is loaded to confirm GPU residency.

## Rollback

Remove the Axiom-local llama.cpp source override and the
`qwen3-8-27b.service` definition, then switch the previous NixOS
configuration. The model directory is independent data and can remain on disk
or be deleted separately. No schema, network, or persistent service data
migration is involved.

## Non-Goals

- Public or LAN exposure
- Authentication or TLS
- Open WebUI, reverse proxy, or containers
- Vision input
- Multi-user batching
- Automatic model updates or downloads during system activation
