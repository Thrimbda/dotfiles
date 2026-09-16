{ lib, host }:
let
  peers = builtins.fromJSON (builtins.readFile ./peers.json);
  relay = import ../relay.nix;
  addresses = if host == "charles" then [ "ant" "axiom" "charlie" ] else [ "ant" "charles" ];
in {
  inherit peers;
  address = "${peers.${host}.ip}/32";
  port = 51820;
  peerConfig = if host == "ant" then
    map (name: {
      inherit (peers.${name}) publicKey;
      allowedIPs = [ "${peers.${name}.ip}/32" ];
    }) [ "axiom" "charlie" "charles" ]
  else [{
    inherit (peers.ant) publicKey;
    allowedIPs = map (name: "${peers.${name}.ip}/32") addresses;
    endpoint = "${relay.publicIp}:51820";
    persistentKeepalive = 25;
  }];
}
