let
  ant = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdwmQmH/JThlIxZz6nQ9RBBZLSIIkw8Xi0onBYU1RHF";
in {
  "frp-token.age".publicKeys = [ ant ];
  "frps-tls-key.age".publicKeys = [ ant ];
}
