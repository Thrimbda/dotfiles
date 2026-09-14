let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrC5k/qhfJUVkMG0Fr+RKEIf1VV9Q6eSWLcnP+NXiFR c.one@thrimbda.com";
in {
  "frp-token.age".publicKeys = [ key ];
  "screen-sharing-key.age".publicKeys = [ key ];
}
