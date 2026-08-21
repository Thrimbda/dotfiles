# Verification Report: Lua Eval Monitor Reconciliation

## Scope

Validate that the monitor hotplug reconciler renders a Lua-compatible `hl.monitor` expression, invokes `hyprctl eval`, and still builds as part of the Axiom system closure.

## Results

| Check | Command | Result | Evidence |
| --- | --- | --- | --- |
| Nix evaluation | `nix eval --raw --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` | PASS | Produced `/nix/store/11n5mn1lgz56y05hf14dyiassbdjcj1d-nixos-system-axiom-26.05.7813.0dd31db7e6db.drv`. |
| Lua expression generation | Exact command below | PASS | Produced `hl.monitor({ output = "DP-4", mode = "3840x2160@240", position = "0x0", scale = 1.5 })`. |
| Lua syntax | Generated expression piped to `/nix/store/ghb3xqzqs015c1y15bvnaiwzs3vkaw1z-lua-5.2.4/bin/luac -p -` | PASS | Exit status 0. Host `luac` was absent, so the evaluated Nix Lua package supplied the parser. |
| Full Axiom closure on final rebased base | `nix build --no-link --print-out-paths --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel -L` | PASS | After rebase onto `origin/master` `ed6a0e04`, produced `/nix/store/3rhcwjc4l2bq1gw0rkf8kkp92d1kk6fm-nixos-system-axiom-26.05.7813.0dd31db7e6db`. |
| Generated helper inspection | Read `/nix/store/ihhzcdm6xxq4n2rbsx93b1y4lwmzqk10-hyprland-reconcile-monitors/bin/hyprland-reconcile-monitors` | PASS | The helper emits `hl.monitor(...)` at line 72 and calls `hyprctl eval` at line 83; no `keyword monitor` call remains. |
| Patch hygiene | `git diff --check` | PASS | No whitespace errors. |

## Executed Commands

```sh
nix eval --raw --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath

jq -nr --arg output "DP-4" --arg mode "3840x2160@240" --arg position "0x0" --argjson scale 1.5 \
  '"hl.monitor({ output = \($output | @json), mode = \($mode | @json), position = \($position | @json), scale = \($scale | tonumber) })"' \
  | /nix/store/ghb3xqzqs015c1y15bvnaiwzs3vkaw1z-lua-5.2.4/bin/luac -p -

nix build --no-link --print-out-paths --option eval-cache false .#nixosConfigurations.axiom.config.system.build.toplevel -L

git diff --check
```

## Why These Checks

The change is generated shell and jq code, so inspecting the Nix-built helper is stronger than checking source text alone. Parsing a representative emitted expression verifies the changed serialization form without sending a runtime monitor command to the active desktop. The full closure build verifies the module integrates with the Axiom configuration.

## Deferred Runtime Check

No `nixos-rebuild switch`, Hyprland restart, monitor power-cycle, or live `hyprctl eval` was run from this worktree. After deployment, confirm that a monitor reconcile/hotplug event no longer emits `keyword can't work with non-legacy parsers. Use eval.` and that the configured DP-4/DP-5 layout remains intact.

## Failure Notes

`luac` is not on the host PATH. This is an environment limitation, not a source failure; syntax validation used the Lua interpreter evaluated from the Axiom configuration.

The final closure build retried one transient Cachix TLS download failure and then completed successfully. No source or evaluation failure occurred.
