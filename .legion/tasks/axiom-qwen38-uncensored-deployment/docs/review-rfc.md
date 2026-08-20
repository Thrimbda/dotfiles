# RFC Review: Axiom Qwen3.8 Uncensored Deployment

## Decision

PASS

## Findings

No blocking findings.

The design is implementable with the existing Axiom NVIDIA stack, has a
bounded host-only scope, and defines observable verification for package
compatibility, service health, GPU offload, MTP activation, and API behavior.
Rollback removes only an Axiom-local package override and service definition;
the external model artifact has no migration coupling.

## Suggestions

- Resolve and record the exact b10472 source and npm dependency hashes during
  implementation rather than adding the upstream llama.cpp flake.
- Make service startup conditional on both the model and chat template being
  present so an interrupted download does not create a restart loop.
