## Summary

- increase the Axiom local Qwen context from 64K to 128K
- retain Q4 KV cache, one slot, full CUDA offload, flash attention, and MTP depth 2
- keep the change within the GGUF-native 256K training context

## Verification

- complete Axiom NixOS closure builds successfully
- generated unit contains `--ctx-size 131072`
- review: PASS with no blocking findings

## Post-Merge Checks

- switch from refreshed `origin/master`
- verify 128K props/logs, health, chat, restart recovery, and GPU headroom
- update the global OpenCode model context to 131072 and run model/tool-call smoke tests

## Evidence

- `.legion/tasks/axiom-qwen38-128k-context/docs/test-report.md`
- `.legion/tasks/axiom-qwen38-128k-context/docs/review-change.md`
- `.legion/tasks/axiom-qwen38-128k-context/docs/report-walkthrough.md`
