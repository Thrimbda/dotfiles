#!/bin/sh
set -eu

root='@rfkillSysfs@'
writes='@writeLog@'
mode='@mode@'

[ "$#" -eq 2 ] && [ "$1" = unblock ] && [ "$2" = bluetooth ]
printf '%s %s\n' "$1" "$2" >> "$writes"

case "$mode" in
    fail) exit 1 ;;
    verify-fail) exit 0 ;;
    unblock|remove|add-blocked) ;;
    *) exit 64 ;;
esac

for type_file in "$root"/*/type; do
    [ -e "$type_file" ] || continue
    IFS= read -r type < "$type_file" || continue
    [ "$type" = bluetooth ] || continue
    if [ "$mode" = remove ]; then
        rm -rf "${type_file%/type}"
    else
        printf '0\n' > "${type_file%/type}/soft"
    fi
done

if [ "$mode" = add-blocked ]; then
    mkdir -p "$root/rfkill99"
    printf 'bluetooth\n' > "$root/rfkill99/type"
    printf '1\n' > "$root/rfkill99/soft"
    printf '0\n' > "$root/rfkill99/hard"
fi
