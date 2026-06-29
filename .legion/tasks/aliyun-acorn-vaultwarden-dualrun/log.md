# Log: Aliyun Acorn Vaultwarden Dual Run

## 2026-06-30

- User requested using Legion workflow to move Vaultwarden deployment configuration to `aliyun-acorn`.
- Entry gate: repository is Legion-managed via `.legion/`; current request is a non-trivial modification task, so workflow entered `brainstorm` first.
- Clarification: user selected staged dual-run, not immediate cutover. `acorn` should keep its current Vaultwarden config while `aliyun-acorn` gains a deployment config.
- Discovery: `hosts/acorn/modules/vaultwarden.nix` currently owns the service config and vhost for `vault.0xc1.space`; `modules/services/vaultwarden.nix` provides the shared service/fail2ban module.
- Discovery: `hosts/aliyun-acorn/default.nix` currently enables ssh/docker/fail2ban/frp/nginx only and has no Vaultwarden import or vhost.
- Secret blocker: local `/home/c1/.ssh/id_ed25519` public key matches the `aliyunAcorn` recipient in `hosts/aliyun-acorn/secrets/secrets.nix`, but cannot decrypt `hosts/acorn/secrets/vaultwarden-env.age`.
- Decision: do not copy the existing encrypted `vaultwarden-env.age` as-is to `aliyun-acorn`, because that would create a declaration that may build but fail to decrypt at activation.
- User provided `./acorn_id_ed25519` as the old acorn private key for decrypting the existing Vaultwarden secret. `ssh-keygen -y -f ./acorn_id_ed25519` matches the old `c1.siyuan@outlook.com` recipient in `hosts/acorn/secrets/secrets.nix`.
- Target encryption identity is `/home/c1/.ssh/id_ed25519`; its public key matches the `aliyunAcorn` recipient in `hosts/aliyun-acorn/secrets/secrets.nix`.
- Worktree envelope opened at `.worktrees/aliyun-acorn-vaultwarden-dualrun` on branch `legion/aliyun-acorn-vaultwarden-dualrun-vaultwarden` from `origin/master`.
- Design: wrote `docs/research.md` and `docs/rfc.md` for the dual-run deployment, secret re-encryption path, rollback, and verification strategy.
- Review: `review-rfc` passed with no blocking findings. Non-blocking notes emphasized using the correct agenix rules context, checking transient/private key material before staging, expanding shape checks, and keeping runtime cutover/data migration separate.
- Implementation: added `hosts/aliyun-acorn/modules/vaultwarden.nix`, imported it from `hosts/aliyun-acorn/default.nix`, and added `vaultwarden-env.age` to `hosts/aliyun-acorn/secrets/secrets.nix`.
- Implementation: re-encrypted Vaultwarden env by piping decrypt from `hosts/acorn/secrets/vaultwarden-env.age` with `./acorn_id_ed25519` into `agenix -e hosts/aliyun-acorn/secrets/vaultwarden-env.age` under the target secret rules context.
- Implementation check: `agenix -d vaultwarden-env.age -i /home/c1/.ssh/id_ed25519 > /dev/null` passed in `hosts/aliyun-acorn/secrets`, proving the new target secret decrypts with the `aliyunAcorn` identity without printing plaintext.
- Verification: `verify-change` wrote `docs/test-report.md`. Secret decryptability, targeted Nix shape checks, agenix rule checks, and `path:$PWD` toplevel build passed.
- Verification: after staging the intended new files so Git flake source includes them, plain `.#` evals and `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` passed.
- Review: `review-change` passed with security lens applied. No blocking findings. Residual risks remain live deploy checks, DNS/ACME readiness, and data migration/ownership during real traffic cutover.
- Delivery: `report-walkthrough` wrote `docs/report-walkthrough.md` and `docs/pr-body.md` from existing design, verification, and review evidence.
- Wiki: wrote `wiki/tasks/aliyun-acorn-vaultwarden-dualrun.md`, updated current Aliyun/Vaultwarden decisions, added an agenix host migration pattern, and recorded post-deploy maintenance checks.
