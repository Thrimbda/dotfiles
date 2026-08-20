## Summary

- increase the Axiom local Qwen context from 64K to 128K
- retain Q4 KV cache, one slot, full CUDA offload, flash attention, and MTP depth 2
- keep the change within the GGUF-native 256K training context

## Verification

- complete Axiom NixOS closure builds successfully
- generated unit contains `--ctx-size 131072`
- review: PASS with no blocking findings

## Deployment

PR #173 merged and the NixOS switch succeeded. The persistent service reports 131072, health/chat/restart recovery pass, and the RTX 5090 retains 11,595 MiB free. OpenCode now declares 131072 and passes text plus tool-call smoke tests.

## Evidence

- `.legion/tasks/axiom-qwen38-128k-context/docs/test-report.md`
- `.legion/tasks/axiom-qwen38-128k-context/docs/review-change.md`
- `.legion/tasks/axiom-qwen38-128k-context/docs/report-walkthrough.md`
