let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrC5k/qhfJUVkMG0Fr+RKEIf1VV9Q6eSWLcnP+NXiFR c.one@thrimbda.com";
  allKeys = [ system ];
in
{
  "secret.age".publicKeys = allKeys;
}