let
  acorn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrC5k/qhfJUVkMG0Fr+RKEIf1VV9Q6eSWLcnP+NXiFR c.one@thrimbda.com";
  axiom = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbq2TSxnl6D4oEdKGNNk1C71QCPN+xPCvCT6KvPhsws axiom.local";
in {
  "frp-token.age".publicKeys = [ acorn axiom ];
}
