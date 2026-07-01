# Test Report: Aliyun Acorn HTTPS Firewall Ports

## Scope

Validate that `aliyun-acorn` restores required public HTTPS staging and firewall ports without reintroducing ACME jobs, public HTTP, Docker, or development-heavy packages.

## Commands And Results

### Firewall Ports

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts
```

Result:

```json
[22,443,2222,2223,2224,2225,7000,34197]
```

### HTTPS Vhost Shape

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts --apply 'v: { status = { onlySSL = v."status-axiom.0xc1.wang".onlySSL; forceSSL = v."status-axiom.0xc1.wang".forceSSL; enableACME = v."status-axiom.0xc1.wang".enableACME; sslCertificate = v."status-axiom.0xc1.wang".sslCertificate; sslCertificateKey = v."status-axiom.0xc1.wang".sslCertificateKey; }; vault = { onlySSL = v."vault.0xc1.space".onlySSL; forceSSL = v."vault.0xc1.space".forceSSL; enableACME = v."vault.0xc1.space".enableACME; sslCertificate = v."vault.0xc1.space".sslCertificate; sslCertificateKey = v."vault.0xc1.space".sslCertificateKey; locations = builtins.attrNames v."vault.0xc1.space".locations; }; }'
```

Result: both vhosts evaluate with `onlySSL = true`, `enableACME = false`, and certificate/key paths under `/var/lib/nginx-selfsigned/<domain>/`.

### No ACME Or Docker Units

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.units --apply 'units: builtins.filter (name: builtins.match ".*acme.*|.*docker.*" name != null) (builtins.attrNames units)'
```

Result:

```json
[]
```

### Docker Remains Disabled

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.virtualisation.docker --apply 'd: { enable = d.enable; enableOnBoot = d.enableOnBoot; }'
```

Result:

```json
{"enable":false,"enableOnBoot":false}
```

### Full Build

```sh
nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel
```

Result: passed.

### Generated Nginx Config

Generated config inspected at `/nix/store/zw1pp21dm9dabyfai040xbg0qsg38r5i-nginx.conf`.

Result:

```nginx
listen 0.0.0.0:443 ssl ;
listen [::0]:443 ssl ;
server_name status-axiom.0xc1.wang ;

listen 0.0.0.0:443 ssl ;
listen [::0]:443 ssl ;
server_name vault.0xc1.space ;
```

No public `80` listener was generated.

### Nginx PreStart

```sh
nix eval --impure --raw .#nixosConfigurations.aliyun-acorn.config.systemd.services.nginx.preStart
```

Result: the generated preStart creates missing self-signed certificates for both staged domains before running `nginx -t`.

### Nginx State Directory

```sh
nix eval --impure --json .#nixosConfigurations.aliyun-acorn.config.systemd.services.nginx.serviceConfig --apply 's: { StateDirectory = s.StateDirectory or null; StateDirectoryMode = s.StateDirectoryMode or null; User = s.User; Group = s.Group; ProtectSystem = s.ProtectSystem; }'
```

Result:

```json
{"Group":"nginx","ProtectSystem":"strict","StateDirectory":"nginx-selfsigned","StateDirectoryMode":"0750","User":"nginx"}
```

## Skipped

- Remote `nixos-rebuild switch` is still skipped because the host was previously timing out during SSH banner exchange.

## Residual Risk

- Public HTTPS uses self-signed staging certificates until DNS/ACME cutover is ready. This preserves encrypted transport but is not production browser trust.
