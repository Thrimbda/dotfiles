{ modulesPath, ... }:

{
  imports = [ "${modulesPath}/virtualisation/disk-image.nix" ];

  image = {
    baseName = "nixos-ant";
    format = "qcow2";
    efiSupport = true;
  };

  virtualisation.diskSize = 8192;
}
