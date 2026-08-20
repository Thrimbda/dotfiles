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
- Active Q6 uses 25449 MiB of 32607 MiB GPU memory and leaves 6629 MiB free.
- Direct reasoning and OpenCode Bash tool calls pass against the merged service.
- Q6-to-Q4-to-Q6, status, stop, start, and restart all pass; one `llama-server` remains resident.

## Operational State

Q6 is selected and healthy at 128K. Q4 remains available through `qwen-model q4`; `qwen-model q6` restores the preferred deployment. The final runtime state is healthy Q6.
