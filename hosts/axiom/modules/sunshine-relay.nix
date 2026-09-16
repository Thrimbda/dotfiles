{ ... }:
{
  # Capture the NVIDIA device used by Hyprland; transport is configured in
  # config/wireguard/linux.nix.
  services.sunshine.settings.adapter_name = "/dev/dri/by-path/pci-0000:01:00.0-render";
}
