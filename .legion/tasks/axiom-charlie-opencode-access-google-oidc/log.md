# Axiom and Charlie Opencode Cloudflare Access Google OIDC - Log

## 2026-05-11

- Entered Legion workflow from the user request to protect axiom opencode cloudflared with Cloudflare Access using Google OIDC.
- Confirmed the primary target is `opencode-axiom.0xc1.space`.
- User expanded the allowlist and scope: allow `c1@ntnl.io` and `siyuan.arc@gmail.com`, and update `charlie` to match the same access policy.
- Created a new task because the prior axiom task explicitly treated Access policy as external follow-up / non-goal, while this task makes Access enforcement the primary deliverable.
- Git worktree envelope opened at `.worktrees/axiom-charlie-opencode-access-google-oidc` on branch `legion/axiom-charlie-opencode-access-google-oidc-access` from `origin/master`.
- RFC and research were written, and review-rfc initially passed.
- User then required the Cloudflare API credential to be written into age. Contract and RFC were updated to treat this as a repository config/ops age secret while avoiding global host deployment of the token.
- Updated review-rfc passed after the age secret requirement.
- Encrypted Cloudflare API credentials to `config/secrets/cloudflare-access.env.age` using the existing `hlissner@global` public age recipient; did not register it in `config/secrets/secrets.nix`.
- Cloudflare Access discovery found one Google IdP: `399adc69-d770-4685-8acf-cdea3acca230` (`Google`).
- Created Access app `opencode-axiom` for `opencode-axiom.0xc1.space` with Google-only `allowed_idps` and `auto_redirect_to_identity=true`.
- Created axiom allow policy `allow-c1-and-siyuan-google` for `c1@ntnl.io` and `siyuan.arc@gmail.com`, requiring Google `login_method`.
- Updated existing charlie policy `613fb592-a015-4208-839f-9238d5a92a85` to require the same Google `login_method` and keep the exact two-email allowlist.
- Updated docs to state that opencode Access apps must use Google IdP plus exact-email allowlist for both axiom and charlie.
- Verification passed: API assertions confirmed both hostnames have exactly one self-hosted app, Google-only `allowed_idps`, allow policy with the two exact emails, required Google login method, and no bypass/non-identity/broad allow policy.
- Removed plaintext staging file `/home/c1/dotfiles/cloudflare` after encrypting and using it.
- Wrote verification evidence to `docs/test-report.md`; interactive browser allow/deny checks remain manual follow-up.
- Initial review-change failed because `.legion/wiki/maintenance.md` still described axiom Access as pending. Updated wiki decisions/maintenance/log to reflect verified Google-only Access for both opencode hostnames and keep only manual browser smoke checks as follow-up.
- Final review-change passed with security lens applied.
- Generated `docs/report-walkthrough.md` and `docs/pr-body.md`.
- Completed wiki writeback by adding `.legion/wiki/tasks/axiom-charlie-opencode-access-google-oidc.md`, updating wiki index, and recording the writeback in wiki log.
