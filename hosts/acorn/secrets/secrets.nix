let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjoe+lq7fVAdQRI2Q22H1cE1RjrNk6oRKaqa4uz6E5k c1.siyuan@outlook.com";
in {
  "vaultwarden-env.age".publicKeys = [key];
}
