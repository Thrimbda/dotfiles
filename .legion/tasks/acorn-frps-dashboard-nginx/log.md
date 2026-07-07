# Log

- Entered Legion workflow from the request to expose the Acorn frps dashboard through nginx.
- User selected `frps-acorn.0xc1.wang` with nginx Basic Auth, not Cloudflare Access automation, for this task.
- Created worktree `/home/c1/dotfiles/.worktrees/acorn-frps-dashboard-nginx` on branch `legion/acorn-frps-dashboard-nginx` from `origin/master`.
- Initial config inspection found frps dashboard disabled (`server.extraConfig = {}`) and no nginx vhost for the dashboard.
- Wrote RFC and implementation plan for loopback-only frps dashboard exposure through Acorn nginx Basic Auth.
- RFC review passed with no blocking findings.
- Implemented Acorn frps dashboard `webServer` on `127.0.0.1:7500`, nginx vhost `frps-acorn.0xc1.wang`, and DNS-01 ACME cert config.
- Updated Legion wiki decisions with the frps dashboard loopback/nginx Basic Auth boundary.
- Expanded the contract to include Cloudflare DNS-only `A` record management for `frps-acorn.0xc1.wang`, because the user selected the concrete hostname route rather than config-only.
- Cloudflare DNS update succeeded: `frps-acorn.0xc1.wang` is a DNS-only `A` record to `8.159.128.125`.
- Targeted Nix assertions passed for frps dashboard loopback config, nginx proxy/auth config, ACME host/provider, and Acorn firewall non-exposure for TCP `7500`.
- `nix build` dry-run and `--no-link` build passed for `.#nixosConfigurations.acorn.config.system.build.toplevel`; `git diff --check` passed.
- Change review passed with no blocking findings. Security lens applied because the change exposes an operational dashboard.
- Recorded implementation-mode walkthrough and PR body from existing verification/review evidence.
- Completed Legion wiki writeback with task summary, index/log entries, current FRP decision, and Acorn deployment follow-up.
