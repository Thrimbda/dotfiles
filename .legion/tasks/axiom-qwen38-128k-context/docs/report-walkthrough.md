# Delivery Walkthrough

**Mode:** implementation

## Change

Raise the Axiom Qwen service context from 65536 to 131072 tokens. All other inference, network, model, and reliability settings remain unchanged.

## Rationale

The GGUF advertises a native 262144-token context. A 128K service context doubles coding-session capacity without requiring RoPE overrides, while the existing Q4_0 K/V cache limits the expected VRAM increase.

## Evidence

- The complete Axiom NixOS closure builds successfully.
- The generated unit contains `--ctx-size 131072` and preserves one slot, Q4_0 K/V cache, full GPU offload, flash attention, and MTP depth 2.
- PR #173 merged and the switched persistent service reports 131072 with 11,595 MiB GPU headroom.
- Health, chat, MTP initialization, automatic restart recovery, and OpenCode text/tool calls pass.
- Change review found no blocking issues.

## Deployment State

Deployment is complete. The local API remains `http://127.0.0.1:8081`, and OpenCode uses the matching 131072-token context declaration.
