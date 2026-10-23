{ lib, ... }:

let
  accessServices = [
    "sshd"
    "autossh-reverse-ssh"
    "frpc"
    "NetworkManager"
    "systemd-resolved"
    "systemd-logind"
    "systemd-journald"
    "dbus-broker"
  ];
in
{
  # The parent must cover the eight services below plus Clash's 256M/1G
  # protection. Child MemoryMin/MemoryLow alone do not reserve this budget.
  systemd.slices.system.sliceConfig = {
    MemoryMin = "512M";
    MemoryLow = "2G";
  };

  systemd.services = lib.genAttrs accessServices (name: {
    serviceConfig = {
      MemoryAccounting = true;
      MemoryMin = "32M";
      MemoryLow = "128M";
      ManagedOOMPreference = "omit";

      # OpenSSH protects its listener with -1000 and restores the startup
      # value for connections. Starting it at -900 also protects every job
      # launched over SSH, so ordinary sessions must inherit zero instead.
      OOMScoreAdjust = lib.mkForce (if name == "sshd" then 0 else -900);
    } // lib.optionalAttrs (name == "sshd") {
      OOMPolicy = "continue";
    };
  });
}
