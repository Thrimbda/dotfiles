# Test Report

## Verdict

PASS for code/config validation and Cloudflare DNS state verification.

Live deployment is not validated yet because Acorn activation requires privileged sudo/root access outside this agent.

## Why These Checks

The change is a declarative Acorn ingress change plus Cloudflare DNS external state. The strongest direct evidence is targeted Nix evaluation for the dashboard listener, nginx proxy/auth boundary, ACME config, firewall non-exposure, full Acorn toplevel validation, diff hygiene, and Cloudflare DNS readback.

## Targeted Nix Assertions

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.acorn.config.modules.services.frp.server.extraConfig.webServer' --json --impure
```

Result:

```json
{"addr":"127.0.0.1","port":7500}
```

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.acorn.config.services.nginx.virtualHosts."frps-acorn.0xc1.wang".locations."/"' --json --impure | jq '{proxyPass, hasBasicAuthFile: has("basicAuthFile")}'
```

Result:

```json
{
  "proxyPass": "http://127.0.0.1:7500",
  "hasBasicAuthFile": true
}
```

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.acorn.config.services.nginx.virtualHosts."frps-acorn.0xc1.wang".useACMEHost' --raw --impure
```

Result:

```text
frps-acorn.0xc1.wang
```

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.acorn.config.security.acme.certs."frps-acorn.0xc1.wang".dnsProvider' --raw --impure
```

Result:

```text
cloudflare
```

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); ports = flake.nixosConfigurations.acorn.config.networking.firewall.allowedTCPPorts or []; in builtins.elem 7500 ports' --impure
```

Result:

```text
false
```

## Build And Diff Hygiene

Command:

```bash
nix build .#nixosConfigurations.acorn.config.system.build.toplevel --dry-run
```

Result: PASS. The dry-run included the expected `acme-frps-acorn.0xc1.wang` units, updated nginx config, and updated frps config derivations.

Command:

```bash
nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link
```

Result: PASS.

Command:

```bash
git diff --check
```

Result: PASS.

## Cloudflare DNS

Command shape:

```bash
curl ... /zones/$zone_id/dns_records?type=A\&name=frps-acorn.0xc1.wang | jq '{success, result: [.result[] | {name, type, content, proxied, ttl}]}'
```

Result:

```json
{
  "success": true,
  "result": [
    {
      "name": "frps-acorn.0xc1.wang",
      "type": "A",
      "content": "8.159.128.125",
      "proxied": false,
      "ttl": 1
    }
  ]
}
```

## Not Yet Validated Live

Live behavior still requires switching Acorn:

```bash
nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --use-remote-sudo --fast --use-substitutes
```

Known blocker: previous Acorn activation attempts reached closure copy but stopped at remote sudo password/TTY, and root SSH key login was denied.

After deployment, verify:

```bash
ssh c1@8.159.128.125 'ss -lntp | grep -E ":(7000|7500|2225|18080|18081)"'
curl -kI --resolve frps-acorn.0xc1.wang:443:8.159.128.125 https://frps-acorn.0xc1.wang
curl --max-time 10 -I http://8.159.128.125:7500
```

Expected results: `7500` listens only on `127.0.0.1`, HTTPS origin returns nginx Basic Auth `401`, and public direct TCP `7500` is unreachable.
