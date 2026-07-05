# Tasks: Axiom Autossh C1 Runtime Fix

- [x] Create stable Legion task contract.
- [x] Update Axiom autossh service to target remote `c1`.
- [x] Ensure service SSH host-key checking does not depend on stale user known-hosts state.
- [x] Align autossh endpoint-key healthcheck with the service remote user and known-hosts source.
- [x] Verify generated service command and healthcheck runner.
- [x] Verify Axiom NixOS toplevel build.
- [x] Run runtime smoke for remote `c1` authentication and reverse endpoint identity where possible.
- [x] Review change for scope and SSH security posture.
- [x] Produce walkthrough/PR body and update Legion wiki.
