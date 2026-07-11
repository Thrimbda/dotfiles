#!/bin/sh
set -eu

rfkill_root='@rfkillSysfs@'
rfkill_command='@rfkillCommand@'

read_attribute() {
    attribute_value=
    IFS= read -r attribute_value < "$1"
}

entries=0
soft_blocked=0
hard_blocked=0

for type_file in "$rfkill_root"/*/type; do
    [ -e "$type_file" ] || continue
    read_attribute "$type_file" || continue
    [ "$attribute_value" = bluetooth ] || continue

    entry_dir=${type_file%/type}
    read_attribute "$entry_dir/soft" || continue
    case "$attribute_value" in
        0) ;;
        1) soft_blocked=1 ;;
        *)
            printf 'bluetooth-rfkill-finalize: entries=%s result=invalid-soft-state\n' "$entries" >&2
            exit 1
            ;;
    esac
    entries=$((entries + 1))

    if read_attribute "$entry_dir/hard" && [ "$attribute_value" = 1 ]; then
        hard_blocked=1
    fi
done

if [ "$entries" -eq 0 ]; then
    printf 'bluetooth-rfkill-finalize: entries=0 result=no-device\n'
    exit 0
fi

if [ "$soft_blocked" -eq 0 ]; then
    printf 'bluetooth-rfkill-finalize: entries=%s hard-blocked=%s result=already-unblocked\n' \
        "$entries" "$hard_blocked"
    exit 0
fi

printf 'bluetooth-rfkill-finalize: entries=%s hard-blocked=%s result=unblocking\n' \
    "$entries" "$hard_blocked"
"$rfkill_command" unblock bluetooth

remaining=0
verified_entries=0
for type_file in "$rfkill_root"/*/type; do
    [ -e "$type_file" ] || continue
    read_attribute "$type_file" || continue
    [ "$attribute_value" = bluetooth ] || continue

    entry_dir=${type_file%/type}
    read_attribute "$entry_dir/soft" || continue
    verified_entries=$((verified_entries + 1))
    case "$attribute_value" in
        0) ;;
        1) remaining=1 ;;
        *) remaining=1 ;;
    esac
done

if [ "$remaining" -ne 0 ]; then
    printf 'bluetooth-rfkill-finalize: entries=%s result=still-soft-blocked\n' \
        "$verified_entries" >&2
    exit 1
fi

printf 'bluetooth-rfkill-finalize: entries=%s result=unblocked\n' "$verified_entries"
