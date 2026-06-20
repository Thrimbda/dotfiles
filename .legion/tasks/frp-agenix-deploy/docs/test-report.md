# Test Report: FRP Agenix Deploy

## Result

PASS

## Commands

### Initial Validation

- `token_a="$(env -C hosts/aliyun-acorn/secrets RULES=/home/c1/dotfiles/.worktrees/frp-agenix-deploy/hosts/aliyun-acorn/secrets/secrets.nix agenix -d frp-token.age -i /home/c1/.ssh/id_ed25519)" && token_b="$(env -C hosts/axiom/secrets RULES=/home/c1/dotfiles/.worktrees/frp-agenix-deploy/hosts/axiom/secrets/secrets.nix agenix -d frp-token.age -i /home/c1/.ssh/id_ed25519)" && [[ "$token_a" == "$token_b" ]] && [[ "$token_a" =~ ^[0-9a-f]{96}$ ]] && printf 'host-local frp token ok\n'`
  - Result: `host-local frp token ok`
  - Purpose: proves both host-local encrypted files decrypt to the same high-entropy token shape without printing the secret.
- `nix eval --raw path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
  - Result: `/nix/store/h3nl2ksgh8xd7b7x6qq7ic5bz7vgacyx-nixos-system-axiom-25.11.20260203.e576e3c.drv`
- `nix eval --raw path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath`
  - Result: `/nix/store/1a74ixzg4sn20pc8mwa2w06jrcsfy447-nixos-system-aliyun-acorn-25.11.20260203.e576e3c.drv`
- `nix build --dry-run path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.axiom.config.system.build.toplevel`
  - Result: PASS. Nix reported the derivations that would build. One Hyprland Cachix narinfo request timed out once and retried, but the dry-run completed successfully.
- `nix build --dry-run path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`
  - Result: PASS. Nix reported the derivations and paths that would be built/fetched.
- `nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy"; in flake.nixosConfigurations.axiom.config.systemd.services."frpc".serviceConfig.ExecStartPre'`
  - Result: `/nix/store/2i93x574mx5d17g5fqd0swgcig9kz7wl-render-frpc-config`
- `nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy"; in flake.nixosConfigurations.aliyun-acorn.config.systemd.services."frps".serviceConfig.ExecStartPre'`
  - Result: `/nix/store/jcr34q244wxb0w5zjgjnd4x94r3mnwc3-render-frps-config`
- Render script inspection:
  - `frpc`: script reads `token_path=/run/agenix/frp-token`, uses template `/nix/store/f33nf6pd4jcii3jrcy16ldgqr01kvb23-frpc.toml`, writes `/run/frpc/frpc.toml`.
  - `frps`: script reads `token_path=/run/agenix/frp-token`, uses template `/nix/store/2lwaih24bp28g774jhvm4z3nikcc2yb0-frps.toml`, writes `/run/frps/frps.toml`.
  - Purpose: confirms token is not embedded in the store script and is injected only at runtime.
- Template inspection:
  - `frpc` template contains `serverAddr = "8.159.128.125"`, `serverPort = 7000`, `auth.token = "@FRP_TOKEN@"`, and the `axiom-ssh` TCP proxy to remote `2225`.
  - `frps` template contains `bindAddr = "0.0.0.0"`, `bindPort = 7000`, and `auth.token = "@FRP_TOKEN@"`.
- `nix shell nixpkgs#frp -c frpc verify -c /nix/store/f33nf6pd4jcii3jrcy16ldgqr01kvb23-frpc.toml`
  - Result: `frpc: the configuration file /nix/store/f33nf6pd4jcii3jrcy16ldgqr01kvb23-frpc.toml syntax is ok`
- `nix shell nixpkgs#frp -c frps verify -c /nix/store/2lwaih24bp28g774jhvm4z3nikcc2yb0-frps.toml`
  - Result: `frps: the configuration file /nix/store/2lwaih24bp28g774jhvm4z3nikcc2yb0-frps.toml syntax is ok`
- `git diff --check`
  - Result: PASS, no output after marking `*.age` files as binary in `.gitattributes` so encrypted bytes are not parsed as text whitespace.

### Re-validation After Review Fix

- `nix eval --raw path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
  - Result: `/nix/store/d58wwh52pcv94c42g60hwdg3ivf9af98-nixos-system-axiom-25.11.20260203.e576e3c.drv`
- `nix eval --raw path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath`
  - Result: `/nix/store/mhksqgjs1b7c5ma64adrj3bhwi9f9npy-nixos-system-aliyun-acorn-25.11.20260203.e576e3c.drv`
- `nix eval --json 'path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.axiom.config.systemd.services."frpc".after'`
  - Result: `["network-online.target"]`
- `nix eval --json 'path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.aliyun-acorn.config.systemd.services."frps".after'`
  - Result: `["network-online.target"]`
- `nix build --dry-run path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.axiom.config.system.build.toplevel`
  - Result: PASS. Nix reported the derivations that would build.
- `nix build --dry-run path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`
  - Result: PASS. Nix reported the derivations and paths that would be built/fetched.
- `git diff --check`
  - Result: PASS, no output.

### Re-validation After Port Conflict Fix

- Context: wiki current truth and `hosts/azar/default.nix` showed existing autossh ownership of remote port `2224`, so the frp SSH proxy was moved to `2225`.
- `nix eval --raw path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
  - Result: `/nix/store/akd3n1hr4dlxn1f5jjr74d0fqbg9gzpq-nixos-system-axiom-25.11.20260203.e576e3c.drv`
- `nix eval --raw path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath`
  - Result: `/nix/store/103jbgh7sxvh6gjck5mxln0i9vdls0xs-nixos-system-aliyun-acorn-25.11.20260203.e576e3c.drv`
- `nix eval --json 'path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.axiom.config.modules.services.frp.client.proxies'`
  - Result: `[ { "name": "axiom-ssh", "type": "tcp", "localIP": "127.0.0.1", "localPort": 22, "remotePort": 2225 } ]`
- `nix eval --json 'path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts'`
  - Result: `[22,80,443,2225,7000,34197]`
- `nix build --dry-run path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.axiom.config.system.build.toplevel`
  - Result: PASS. Nix reported the derivations that would build.
- `nix build --dry-run path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`
  - Result: PASS. Nix reported the derivations and paths that would be built/fetched.
- `nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/frp-agenix-deploy"; in flake.nixosConfigurations.axiom.config.systemd.services."frpc".serviceConfig.ExecStartPre'`
  - Result: `/nix/store/1n8qiz4i6yiwpqz86nqq94s7dkymarr9-render-frpc-config`
- Updated `frpc` template inspection:
  - `/nix/store/ai3662y338lnzfmhh74979jqv3pdwnxx-frpc.toml` contains `remotePort = 2225` for `axiom-ssh`.
- `nix shell nixpkgs#frp -c frpc verify -c /nix/store/ai3662y338lnzfmhh74979jqv3pdwnxx-frpc.toml`
  - Result: `frpc: the configuration file /nix/store/ai3662y338lnzfmhh74979jqv3pdwnxx-frpc.toml syntax is ok`
- `nix shell nixpkgs#frp -c frps verify -c /nix/store/2lwaih24bp28g774jhvm4z3nikcc2yb0-frps.toml`
  - Result: `frps: the configuration file /nix/store/2lwaih24bp28g774jhvm4z3nikcc2yb0-frps.toml syntax is ok`
- `git diff --check`
  - Result: PASS, no output.

## Skipped Or Limited

- Direct decryption with `/etc/ssh/ssh_host_ed25519_key` was not run because the current user cannot read that private key. The axiom public key is present as an age recipient in both host-local `secrets.nix` files.
- Runtime network reachability and service health on the two physical hosts were not tested locally; this requires deployment after merge.

## Why These Checks

The change is primarily NixOS service generation plus secret handling. Eval/dry-run proves both affected host configurations instantiate; frp's own `verify` proves the generated TOML syntax; render-script inspection verifies the most important security claim that token material is not stored in Nix store output. The second eval/dry-run pass proves the review fix removing the nonexistent age secret unit dependency did not regress either host configuration. The final port-conflict validation proves the frp proxy now uses `2225` and avoids the existing `azar` autossh `2224` reservation.
