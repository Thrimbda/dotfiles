## Summary

- deploy the standard Q6_K MTP model as Axiom's default 128K local Qwen
- keep Q4 available through a persistent `active.gguf` selection
- add `qwen-model {q4|q6|start|stop|restart|status}` with health-gated rollback

## Verification

- complete Axiom NixOS closure builds successfully
- generated `qwen-model` passes ShellCheck
- Q6 artifact size and SHA-256 match Hugging Face LFS metadata
- RFC review: PASS
- change review: PASS, including the fixed-target sudo boundary
- Q6 128K, MTP, full CUDA offload, direct API, reasoning, and OpenCode tool calls pass
- Q6 uses 25449 MiB GPU memory and leaves 6629 MiB free
- status/start/stop/restart and Q6-to-Q4-to-Q6 pass with one resident server

## Evidence

- `.legion/tasks/axiom-qwen38-q6-switcher/docs/rfc.md`
- `.legion/tasks/axiom-qwen38-q6-switcher/docs/review-rfc.md`
- `.legion/tasks/axiom-qwen38-q6-switcher/docs/test-report.md`
- `.legion/tasks/axiom-qwen38-q6-switcher/docs/review-change.md`
- `.legion/tasks/axiom-qwen38-q6-switcher/docs/report-walkthrough.md`
