-- Axiom Hyprland root. Nix generates host facts under `custom/`,
-- `monitors.lua`, and `workspaces.lua`.
require("custom/env")
require("custom/execs")
require("custom/general")
require("custom/rules")
require("custom/keybinds")
require("workspaces")
require("monitors")
