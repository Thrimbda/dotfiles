# RFC: Axiom NVIDIA 595.99.02 Production Driver

**Status:** Proposed

## Context

Axiom is a NixOS 26.05 workstation with an RTX 5090, Linux 6.12.103, and an
active Hyprland Wayland session. It currently loads NVIDIA beta driver
595.45.04 successfully. The shared `gpu/nvidia` profile selects
`config.boot.kernelPackages.nvidiaPackages.beta`, so modifying it would change
the driver selected for every host using that profile.

NVIDIA's Linux driver lookup lists 595.99.02 as the latest x86_64 production
display driver, released on 2026-08-27. The fixed NixOS 26.05 source exposes
only production 595.71.05, while the Nixpkgs production definition for
595.99.02 supplies the required source hashes.

Evidence:

- `nvidia-smi` reports 595.45.04 on Axiom; `lspci -nnk` reports the RTX 5090
  is bound to the `nvidia` kernel driver.
- `nix eval` reports 595.71.05 for the fixed NixOS 26.05 stable package and
  595.99.02 for current Nixpkgs production.
- NVIDIA driver lookup: <https://www.nvidia.com/Download/processFind.aspx?ctk=0&lang=en-us&lid=1&osid=12&qnfslb=01%3A&whql=>.
- Nixpkgs package update and hashes: <https://github.com/NixOS/nixpkgs/pull/557149>.

## Goals

- Install NVIDIA production driver 595.99.02 on Axiom.
- Preserve the current kernel, `hardware.nvidia.open = true`, Wayland
  modesetting, power-management, and CUDA integration.
- Keep the update reproducible without changing the system-wide Nixpkgs pin.
- Limit the driver selection change to Axiom.

## Non-goals

- Updating Acorn or any other NVIDIA host.
- Using NVIDIA's standalone `.run` installer.
- Moving Axiom to the new-feature 610 series or beta drivers.
- Refreshing the entire Nixpkgs baseline.

## Options

### Keep `nvidiaPackages.beta`

This retains the working 595.45.04 driver but does not meet the request for the
latest production release.

### Use the fixed input's `nvidiaPackages.stable`

This is a one-line selector change, but it installs 595.71.05, which is older
than the requested latest production release.

### Update the primary Nixpkgs input

This can eventually supply the new production package, but it changes the
system package baseline and creates unrelated update risk.

### Pin the production driver with the configured kernel package set

`config.boot.kernelPackages.nvidiaPackages.mkDriver` builds the selected
driver against Axiom's configured kernel package set. An Axiom-only override
can use the upstream 595.99.02 hashes while the shared profile remains
unchanged. This is the narrowest solution that meets the version requirement.

## Decision

Create `hosts/axiom/modules/nvidia-driver.nix` and import it from
`hosts/axiom/default.nix`. The module uses `lib.mkForce` because the shared
profile currently sets `hardware.nvidia.package` directly.

```nix
{ lib, config, ... }:

{
  hardware.nvidia.package = lib.mkForce (
    config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.99.02";
      sha256_64bit = "sha256-6HR3lYv3YwcFSTJL1a1slI66btIQ5EAFs+/4SUD24ew=";
      sha256_aarch64 = "sha256-CCqHZTN2KNOZ4yZp2rDcuRJp9pHfRw47k4m4dWnS/2w=";
      openSha256 = "sha256-T36x/jx8yQ8l3LFp1rZIrTfcSwbGy8YSAvXOUSptpb4=";
      settingsSha256 = "sha256-GYCcnxfKPrTCrsmd25sMyzfC5cqJQJx0c31haooyTYM=";
      persistencedSha256 = "sha256-VyKtF/HdHPQrHHK6opSO69M72LmnGZtauuchj9uuje8=";
    }
  );
}
```

The custom package stays tied to `config.boot.kernelPackages`; it therefore
does not introduce an ABI mismatch from importing an NVIDIA module packaged
for an unrelated kernel.

## Scope

- Add the Axiom-only module and its import.
- Record the production package source and fixed hashes.
- Evaluate, activate, reboot, and verify Axiom only.

## Verification

1. Evaluate the Axiom package version from the flake and require `595.99.02`.
2. Run `nixos-rebuild switch --flake .#axiom` on Axiom only.
3. Reboot to load the new kernel module.
4. After boot, require `nvidia-smi` to report `595.99.02` and `lspci -nnk` to
   show the RTX 5090 using `nvidia`.
5. Confirm the graphical session starts and record any runtime failure.

## Rollback

If the build fails, restore the previous source without activating it. If the
new driver fails after boot, select the previous NixOS generation in the boot
loader. For a persistent rollback, remove the Axiom-only module import and
module, redeploy the previous configuration, and reboot; the shared profile
then restores `nvidiaPackages.beta` (595.45.04).
