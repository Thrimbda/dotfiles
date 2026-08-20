# Delivery Walkthrough

**Mode:** implementation

## Change

Raise the Axiom Qwen service context from 65536 to 131072 tokens. All other inference, network, model, and reliability settings remain unchanged.

## Rationale

The GGUF advertises a native 262144-token context. A 128K service context doubles coding-session capacity without requiring RoPE overrides, while the existing Q4_0 K/V cache limits the expected VRAM increase.

## Evidence

- The complete Axiom NixOS closure builds successfully.
- The generated unit contains `--ctx-size 131072` and preserves one slot, Q4_0 K/V cache, full GPU offload, flash attention, and MTP depth 2.
- Change review found no blocking issues.

## Pending Deployment Evidence

After merge, switch from refreshed `origin/master`, prove the 131072-token persistent slot and GPU headroom, rerun API/restart checks, then align the global OpenCode context declaration.
