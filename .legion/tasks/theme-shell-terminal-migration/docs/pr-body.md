## Summary

- move zsh prompt and tmux theme assets out of `modules/themes` into default `config/zsh` and `config/tmux`
- move terminal font ownership to `modules.desktop.term.font` and update Foot/runtime scripts to consume it
- remove obsolete `modules.theme.fonts.terminal`, Autumnal terminal overrides, and orphaned `autumnal-cli` shell/tmux assets

## Verification

- `rg 'modules/themes/autumnal/config/(zsh|tmux)|hey info theme fonts terminal|fonts\.terminal' modules config hosts`
- `git diff --name-status -- 'modules/themes/*/config/zsh/*' 'modules/themes/*/config/tmux*'`
- `nix eval --option eval-cache false --json .#nixosConfigurations.axiom.config.hey.info.term.font`
- `nix eval --option eval-cache false --raw '.#nixosConfigurations.axiom.config.home.configFile."foot/foot.local.ini".text'`
- `nix eval --option eval-cache false --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- `nix eval --option eval-cache false --raw .#nixosConfigurations.atlas.config.system.build.toplevel.drvPath`
- `nix eval --option eval-cache false --raw .#nixosConfigurations.acorn.config.system.build.toplevel.drvPath`
- `zsh -n config/zsh/.zshrc && zsh -n config/zsh/prompt.zsh && zsh -n config/hypr/bin/get-font.zsh && zsh -n config/hypr/bin/open-term.zsh`
- `git diff --check`

## Notes

- Darwin `charles` eval still fails on the existing unrelated `modules/dev/playwright.nix` / `programs.nix-ld` nix-darwin incompatibility.
- Legion evidence: `.legion/tasks/theme-shell-terminal-migration/`.
