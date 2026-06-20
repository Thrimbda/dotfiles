# RFC Review: C1ctl Hey Rust Migration

## Decision

PASS

## Review Scope

- `.legion/tasks/c1ctl-hey-rust-migration/plan.md`
- `.legion/tasks/c1ctl-hey-rust-migration/docs/research.md`
- `.legion/tasks/c1ctl-hey-rust-migration/docs/rfc.md`
- `.legion/tasks/c1ctl-hey-rust-migration/docs/implementation-plan.md`

## Findings

No blocking findings remain.

Earlier RFC blockers were resolved before implementation:

- `@rofi` is now an explicit Janet delegation boundary for call, `which`, and `help`; Rust must not resolve or execute Rofi scripts directly.
- Rust-executed dynamic scripts now have an explicit environment contract: `DOTFILES_HOME`, computed `PATH`, `HEYSCRIPT`, `HEYDRYRUN`, and `HEYDEBUG`.

## Residual Risks

- Resolver parity remains the highest implementation risk and must be covered by safe command checks.
- Env propagation should be tested for active dry-run/debug and normal unset cases where practical.
- High-impact mutating commands remain delegated in this slice, which is intentional and should be preserved during implementation.
