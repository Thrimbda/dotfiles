# Delivery Walkthrough

**Mode:** implementation

## Change

- Default the Axiom 128K Qwen service to the standard Q6_K MTP artifact through `active.gguf`.
- Retain Q4 as a fixed rollback/selection target.
- Add `qwen-model` for bounded model selection and service lifecycle control.

## Control Surface

`qwen-model` supports `q4`, `q6`, `start`, `stop`, `restart`, and `status`. Model switches validate the fixed artifact, replace the selection atomically, restart through sudo, wait for health, and restore the prior valid model on failure.

## Evidence

- Complete Axiom closure and ShellCheck pass.
- Generated service preserves 128K, full GPU offload, Q4 KV, flash attention, one slot, and MTP depth 2.
- Q6 file size and SHA-256 match upstream.
- RFC and implementation review both pass without blocking findings.

## Pending Deployment Evidence

After merge, switch from refreshed `origin/master`, prove Q6 full-GPU fit and API behavior, then exercise lifecycle controls and a Q6-Q4-Q6 round trip.
