# RFC: FRP Agenix Deploy

## Decision

Add a reusable Linux-only `modules.services.frp` module that can enable `frps` and/or `frpc`. The module generates TOML templates with a token placeholder, then renders the real runtime TOML under `/run/frps` or `/run/frpc` immediately before service start by reading the agenix secret path.

## Alternatives Considered

- Put token directly in Nix TOML: rejected because it would place the credential in `/nix/store`.
- Use frp config files committed as host-local files: rejected because it duplicates module logic and still needs a safe token injection path.
- Use systemd environment variables only: rejected because frp TOML expects `auth.token`; runtime rendering is simpler and explicit.

## Implementation Boundary

- `aliyun-acorn` enables `modules.services.frp.server.enable` and opens TCP ports `7000` and `2225`.
- `axiom` enables `modules.services.frp.client`, connects to `8.159.128.125:7000`, and exposes local SSH as remote TCP `2225`.
- Remote TCP `2225` is chosen to avoid existing autossh reverse SSH reservations: `2222` for `charlie`, `2223` for `axiom`, and `2224` for `azar`.
- Each host has host-local `secrets.nix` and `frp-token.age`; both encrypted files contain the same token and both recipients so either host can decrypt.

## Rollback

- Disable `modules.services.frp.server.enable` on `aliyun-acorn` and remove TCP `7000` / `2225` from its firewall allow-list.
- Disable `modules.services.frp.client.enable` on `axiom`.
- Keep or remove age files depending on whether a future frp redeploy is expected; removing them has no runtime effect after services are disabled.

## Verification Plan

- Confirm both encrypted host-local age files decrypt to the same 96-character hex token using the available user identity without printing the token.
- Evaluate `path:/home/c1/dotfiles#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` and the corresponding `aliyun-acorn` path.
- Run dry-run builds for both host toplevels.
- Build and inspect the render scripts to confirm token is read from `/run/agenix/frp-token` and not embedded in store output.
- Run `frpc verify` and `frps verify` against the generated TOML templates.
