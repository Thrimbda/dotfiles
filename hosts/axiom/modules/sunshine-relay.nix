{ ... }:
{
  # Capture the NVIDIA device used by Hyprland; transport is configured in
  # config/wireguard/linux.nix.
  services.sunshine.settings.adapter_name = "/dev/dri/by-path/pci-0000:01:00.0-render";
  # Resolve PCI paths before Hyprland starts: card numbers change at boot and
  # literal PCI paths contain colons, which AQ_DRM_DEVICES treats as separators.
  home.configFile."uwsm/env-hyprland.d/10-render-device.sh".source = ./sunshine-gpu-env.sh;

  # UWSM recreates graphical-session.target on compositor recovery. Pull the
  # host session services in without depending on a one-shot desktop hook.
  systemd.user.targets.hyprland-session.wantedBy = [ "graphical-session.target" ];

}
