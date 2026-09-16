# Sourced by UWSM before starting Hyprland. Match Sunshine's NVIDIA adapter.
axiom_nvidia_card=$(readlink -e /dev/dri/by-path/pci-0000:01:00.0-card)
if [ ! -c "$axiom_nvidia_card" ]; then
    printf '%s\n' 'Axiom: NVIDIA DRM device is unavailable' >&2
    return 1
fi
export AQ_DRM_DEVICES="$axiom_nvidia_card"

# Keep outputs attached to the integrated GPU available as secondary outputs.
axiom_amd_card=$(readlink -e /dev/dri/by-path/pci-0000:11:00.0-card)
if [ -c "$axiom_amd_card" ]; then
    export AQ_DRM_DEVICES="$AQ_DRM_DEVICES:$axiom_amd_card"
fi
unset axiom_nvidia_card axiom_amd_card
