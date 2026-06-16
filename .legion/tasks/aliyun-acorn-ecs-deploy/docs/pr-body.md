## Summary

- Fix the nested `hosts/aliyun-acorn/image` flake lock so `aliyun-image` evaluates and builds with the current dotfiles input graph.
- Expand `hosts/aliyun-acorn/README.md` into a guarded Alibaba Cloud ECS custom-image deployment runbook.
- Record Legion research, RFC, validation, review, and walkthrough evidence for the deployment path.

## Verification

- PASS: `nix eval --raw './hosts/aliyun-acorn/image#aliyun-image.system'`
- PASS: `nix build --dry-run './hosts/aliyun-acorn/image#aliyun-image'`
- PASS: `nix build --no-link './hosts/aliyun-acorn/image#aliyun-image'`
- PASS: built output `/nix/store/44yiwbiq8qipv1hnsl75lh8kid8k4g4z-nixos-disk-image/nixos-aliyun-acorn.qcow2`
- PASS: `git diff --check`
- PASS: sensitive-pattern scan found no secret values

## Notes

- Live Aliyun upload/import/`RunInstances` was not run. Those steps create or depend on cloud-side resources and require explicit confirmation of bucket, network, security group, instance type, SSH CIDR, cost/dry-run result, and cleanup policy.
- Change review passed with security lens applied; see `.legion/tasks/aliyun-acorn-ecs-deploy/docs/review-change.md`.
