# Test Report

## Verdict

PASS for code/config validation and Cloudflare state verification.

Live deployment is not validated yet because switching `aliyun-acorn` requires privileged sudo/root access outside this agent.

## Why These Checks

The change is declarative NixOS ingress configuration plus Cloudflare external state. The strongest low-cost evidence is targeted Nix evaluation for the exact route/auth/firewall claims, full affected-host toplevel builds, whitespace checks, and Cloudflare API reads for the live DNS/Access objects.

## Targeted Nix Assertions

Command:

```bash
nix eval .#nixosConfigurations.axiom.config.modules.services.frp.client.proxies --json | jq -c '.[] | select(.name == "axiom-opencode-http") | {name,type,localIP,localPort,remotePort}'
```

Result:

```json
{"name":"axiom-opencode-http","type":"tcp","localIP":"127.0.0.1","localPort":4096,"remotePort":18081}
```

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."opencode-axiom.0xc1.wang".locations."/"' --json --impure | jq '{proxyPass, proxyWebsockets, hasBasicAuthFile: has("basicAuthFile")}'
```

Result:

```json
{
  "proxyPass": "http://127.0.0.1:18081",
  "proxyWebsockets": true,
  "hasBasicAuthFile": true
}
```

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.aliyun-acorn.config.security.acme.certs."opencode-axiom.0xc1.wang".dnsProvider' --raw --impure
```

Result:

```text
cloudflare
```

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."opencode-axiom.0xc1.wang".useACMEHost' --raw --impure
```

Result:

```text
opencode-axiom.0xc1.wang
```

Command:

```bash
nix eval --expr 'let flake = builtins.getFlake (toString ./.); ports = flake.nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts or []; in builtins.elem 18081 ports' --impure
```

Result:

```text
false
```

## Toplevel Evaluation And Build

Command:

```bash
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run
```

Result: PASS. The dry-run completed evaluation and planned the Axiom toplevel derivation.

Command:

```bash
nix build .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel --dry-run
```

Result: PASS. The dry-run completed evaluation and included the expected `acme-order-renew-opencode-axiom.0xc1.wang.service`, `acme-opencode-axiom.0xc1.wang.service`, and `acme-renew-opencode-axiom.0xc1.wang.timer` units.

Command:

```bash
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

Command:

```bash
nix build .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel --no-link
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
curl ... /zones/$zone_id/dns_records?type=A\&name=opencode-axiom.0xc1.wang | jq '{success, result: [.result[] | {name, type, content, proxied, ttl}]}'
```

Result:

```json
{
  "success": true,
  "result": [
    {
      "name": "opencode-axiom.0xc1.wang",
      "type": "A",
      "content": "8.159.128.125",
      "proxied": true,
      "ttl": 1
    }
  ]
}
```

## Cloudflare Access

Command shape:

```bash
curl ... /accounts/$account_id/access/apps
curl ... /accounts/$account_id/access/apps/$app_id/policies
```

Result:

```json
{
  "app": [
    {
      "name": "opencode-axiom-wang",
      "domain": "opencode-axiom.0xc1.wang",
      "type": "self_hosted",
      "allowed_idps": [
        "399adc69-d770-4685-8acf-cdea3acca230"
      ],
      "auto_redirect_to_identity": true
    }
  ],
  "policies": [
    {
      "name": "allow-c1-siyuan-froggy-wang-google",
      "decision": "allow",
      "include": [
        { "email": { "email": "c1@ntnl.io" } },
        { "email": { "email": "siyuan.arc@gmail.com" } },
        { "email": { "email": "froggy2818@gmail.com" } },
        { "email": { "email": "wangpeiguangwpg@gmail.com" } }
      ],
      "require": [
        {
          "login_method": {
            "id": "399adc69-d770-4685-8acf-cdea3acca230"
          }
        }
      ],
      "exclude": []
    }
  ]
}
```

## Not Yet Validated Live

Live route behavior still requires both host switches:

```bash
nixos-rebuild switch --flake .#axiom
nixos-rebuild switch --flake .#aliyun-acorn --target-host c1@8.159.128.125 --use-remote-sudo --fast
```

Known blocker: the previous Acorn switch attempt copied the closure but activation stopped at remote sudo password/TTY. `root@8.159.128.125` key login was also denied. The task is ready for PR, but final live checks require privileged access.

After deployment, verify:

```bash
curl -I https://opencode-axiom.0xc1.wang
curl -kI --resolve opencode-axiom.0xc1.wang:443:8.159.128.125 https://opencode-axiom.0xc1.wang
```

Expected results: public request reaches Cloudflare Access before origin, direct origin request returns nginx Basic Auth `401`, and public direct TCP `18081` remains unreachable.
