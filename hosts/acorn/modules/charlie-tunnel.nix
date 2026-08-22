{ lib, ... }:

let
  serviceUser = "tunnel-charlie";
in

{
  users.groups.${serviceUser} = {};

  users.users.${serviceUser} = {
    isSystemUser = true;
    group = serviceUser;
    openssh.authorizedKeys.keys = [
      ''restrict,port-forwarding,permitlisten="127.0.0.1:2222" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFD4bcuCw5DThq+uEjbgt5dsjTJbrGvnKbBdI+V8yyma charlie-tunnel''
    ];
  };

  services.openssh.extraConfig = lib.mkAfter ''
    Match User ${serviceUser}
      AuthenticationMethods publickey
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding remote
      GatewayPorts no
      KbdInteractiveAuthentication no
      MaxSessions 0
      PasswordAuthentication no
      PermitListen 127.0.0.1:2222
      PermitTTY no
      PermitUserRC no
      X11Forwarding no
  '';
}
