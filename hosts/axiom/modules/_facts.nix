{
  ant = {
    publicIp = "106.15.156.143";
    sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdwmQmH/JThlIxZz6nQ9RBBZLSIIkw8Xi0onBYU1RHF";
  };
  acorn = {
    publicIp = "8.159.128.125";
    sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6WwypfVtdA16Au8kXoCVJgkTDlvgu98sqA0Z04Ux3l";
    frpcDirectRouteUnit = "frpc-acorn-direct-route.service";
    frpcDirectRoutePriority = 8500;
  };
}
