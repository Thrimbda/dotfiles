# Log

- User requested Resend SMTP for Acorn auth-mini and supplied a plaintext API key as root file `resent_key`.
- Safe format check confirmed a non-empty 37-byte raw Resend key shape without printing its value.
- Resend API read-only domain query confirmed `0xc1.space` is verified in `ap-northeast-1`.
- User selected sender `auth@0xc1.space`.
- Official Resend docs confirm `smtp.resend.com`, username `resend`, API key password, and implicit TLS on port 465.
- Worktree: `.worktrees/auth-mini-resend-smtp`; branch: `legion/auth-mini-resend-smtp-config`; base: `origin/master` at `c8319af6`.
- User corrected the task risk classification to lightweight. Removed the formal RFC path and narrowed implementation to an age secret declaration plus one-time authenticated admin API configuration; no startup reconciliation subsystem will be added.
- Encrypted the raw key to `hosts/acorn/secrets/auth-mini-resend-api-key.age` for the Acorn SSH recipient and verified decrypt-roundtrip equality by hash without printing plaintext.
- Declared the secret as `auth-mini:auth-mini` mode `0400`.
- Authenticated to the loopback admin API with the existing Ed25519 admin key and configured `smtp.resend.com:465`, username `resend`, implicit TLS, sender `auth@0xc1.space`, display name `auth-mini`.
- Live `POST /email/start` for the existing admin email returned `200 {"ok":true}`; Acorn TCP connectivity to `smtp.resend.com:465` also passed.
