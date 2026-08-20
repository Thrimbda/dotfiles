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
- Review found no blocking correctness, scope, maintainability, or security issues.

Full commands and outputs are summarized in `docs/test-report.md`; the review decision is in `docs/review-change.md`.

## Pending Deployment Step

The PR is intentionally merged before activation. After refreshing the main workspace to merged `origin/master`, run `sudo nixos-rebuild switch --flake .#axiom -L` from `/home/c1/dotfiles`, then verify the persistent system unit, health endpoint, chat completion, logs, and GPU telemetry.
