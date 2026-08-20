# Delivery Walkthrough

**Mode:** implementation

## What Changed

- Pinned `llama.cpp` b10472 in the Axiom host configuration while retaining the nixpkgs package expression and enabling CUDA.
- Added `qwen3-8-27b.service`, bound to `127.0.0.1:8081`, for the selected local GGUF model and chat template.
- Configured 64K context, one slot, full GPU offload, flash attention, Q4 K/V cache, MTP depth 2, medium reasoning, and no Web UI.

## Why

The nixpkgs unstable package was older than the model's required MTP support. A source override keeps the dependency surface smaller than adopting the upstream flake while providing a reproducible current build. See `docs/rfc.md` and `docs/review-rfc.md`.

## Evidence

- The complete Axiom NixOS closure builds successfully.
- The pinned binary reports build 10472 / commit `60eeeb6` and detects the RTX 5090 CUDA device.
- The 16,998,720,736-byte model matches its upstream LFS SHA-256.
- The exact generated server command passed `/health`, `/v1/models`, and `/v1/chat/completions`; logs confirmed a 65536-token slot and MTP draft context.
- PR #171 merged, the main workspace was refreshed to merged commit `593576f3`, and the NixOS switch succeeded.
- The persistent service is enabled and active, uses about 18.7 GiB of GPU memory, and recovered successfully from a forced process failure.
- Review found no blocking correctness, scope, maintainability, or security issues.

Full commands and outputs are summarized in `docs/test-report.md`; the review decision is in `docs/review-change.md`.

## Deployment State

Deployment is complete. The API is available locally at `http://127.0.0.1:8081`; the configured model ID is `qwen3.8-27b-uncensored`.
