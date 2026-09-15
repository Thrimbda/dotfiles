{ lib, pkgs, ... }:

{
  modules.agenix.sshKey = "/home/c1/.ssh/id_ed25519";
  # The base image carries no application credentials.
  modules.agenix.dirs = lib.mkForce [];

  # Replace the shared bootstrap password with key-only operator access.
  user.initialPassword = lib.mkForce null;
  user.hashedPassword = "!";
  users.users.root.initialPassword = lib.mkForce null;
  users.users.root.hashedPassword = "!";
  services.openssh.settings.PermitRootLogin = "no";
  security.sudo.extraRules = [{
    users = [ "c1" ];
    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
  }];


  nix.settings = {
    substituters = lib.mkBefore [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];
    max-jobs = 1;
    cores = 1;
    http-connections = 4;
  };

  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    nixos.enable = false;
  };

  virtualisation.docker.enableOnBoot = lib.mkForce false;

  boot = {
    growPartition = true;
    kernelParams = [ "console=ttyS0,115200n8" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  networking = {
    hostName = "ant";
    useDHCP = lib.mkForce false;
    firewall = {
      allowedTCPPorts = lib.mkForce [ 22 ];
      allowedUDPPorts = lib.mkForce [];
    };
  };

  systemd.network = {
    enable = true;
    networks."10-aliyun-dhcp" = {
      matchConfig.Name = "eth* ens* enp*";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
    };
  };

  services.cloud-init = {
    enable = true;
    network.enable = true;
    settings = {
      datasource_list = [ "AliYun" "NoCloud" "None" ];
      preserve_hostname = true;
      disable_root = true;
      users = [];
    };
  };

  services.vnstat.enable = true;

  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = lib.mkForce false;

  time.timeZone = "Asia/Shanghai";

  systemd.services."serial-getty@ttyS0".enable = lib.mkForce true;
  systemd.services."getty@tty1".enable = lib.mkForce true;
  systemd.services."autovt@".enable = lib.mkForce true;

  systemd.services.cloud-init.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
  systemd.services.cloud-config.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
  systemd.services.cloud-final.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
}
