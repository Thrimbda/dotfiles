# Summary

- Force a fresh Axiom-built output for the existing 1Ex portfolio adapter vendor source.
- Avoid the locally registered-but-missing prior adapter output without faking or force-deleting Nix store paths.
- Preserve the adapter protocol, Fund/source binding, authentication boundaries, and all Fund accounting state.

# Validation

- Fresh adapter release build completed from the tracked vendor source.
- All 10 adapter unit tests passed.
- No closure was transferred or activated; Acorn and Fund accounting remain unchanged pending a post-merge interactive deployment.

# Risk And Rollback

- This changes only the Nix package output identity.
- The prior Acorn generation remains unchanged until the post-merge deployment is explicitly run.
- No Fund event is created until a live source read and immediate Fund sample both succeed.
