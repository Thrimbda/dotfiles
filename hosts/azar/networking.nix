{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "100.96.0.2"
 "100.96.0.3"
 ];
    defaultGateway = "10.251.240.1";
    defaultGateway6 = "";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="10.251.254.205"; prefixLength=20; }
        ];
        ipv6.addresses = [
          { address="fe80::216:3eff:fe01:5b82"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "10.251.240.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = ""; prefixLength = 128; } ];
      };
      
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="00:16:3e:01:5b:82", NAME="eth0"
    ATTR{address}=="02:42:ca:e6:73:e1", NAME="docker0"
  '';
}
