{ lib, pkgs, ... }:

{
  assertions = [
    {
      assertion = pkgs.unstable.hyprland.version == "0.56.1";
      message = "Axiom's Hyprland monitor-loss guard is specific to Hyprland 0.56.1; review it before updating the package.";
    }
  ];

  programs.hyprland.package = lib.mkForce (
    pkgs.unstable.hyprland.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        ./hyprland-xwayland-floating-monitor-guard.patch
      ];
    })
  );
}
