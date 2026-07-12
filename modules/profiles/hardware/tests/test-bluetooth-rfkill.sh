#!/bin/sh
set -eu

source_script=$1
fake_source=$2
fixture="$PWD/sys/class/rfkill"
write_log="$PWD/rfkill-writes"
finalizer="$PWD/bluetooth-rfkill-finalize"
fake_rfkill="$PWD/rfkill"

reset_fixture() {
    rm -rf "$PWD/sys"
    mkdir -p "$fixture"
    : > "$write_log"
}

add_entry() {
    entry="$fixture/rfkill$1"
    mkdir -p "$entry"
    printf '%s\n' "$2" > "$entry/type"
    printf '%s\n' "$3" > "$entry/soft"
    printf '%s\n' "$4" > "$entry/hard"
}

build_case() {
    mode=$1
    sed \
        -e "s|@rfkillSysfs@|$fixture|g" \
        -e "s|@writeLog@|$write_log|g" \
        -e "s|@mode@|$mode|g" \
        "$fake_source" > "$fake_rfkill"
    chmod +x "$fake_rfkill"
    sed \
        -e "s|@rfkillSysfs@|$fixture|g" \
        -e "s|@rfkillCommand@|$fake_rfkill|g" \
        "$source_script" > "$finalizer"
    chmod +x "$finalizer"
    if grep -q '@rfkill\|@writeLog\|@mode' "$fake_rfkill" "$finalizer"; then
        printf 'unsubstituted test placeholder\n' >&2
        exit 1
    fi
}

assert_no_writes() {
    [ ! -s "$write_log" ]
}

reset_fixture
add_entry 0 wlan 1 0
cp "$fixture/rfkill0/soft" "$PWD/wlan-soft.before"
build_case unblock
"$finalizer"
assert_no_writes
cmp "$PWD/wlan-soft.before" "$fixture/rfkill0/soft"

reset_fixture
add_entry 0 bluetooth 0 0
add_entry 1 wlan 1 0
cp "$fixture/rfkill1/soft" "$PWD/wlan-soft.before"
build_case unblock
"$finalizer"
assert_no_writes
cmp "$PWD/wlan-soft.before" "$fixture/rfkill1/soft"

reset_fixture
add_entry 0 bluetooth 1 1
add_entry 1 bluetooth 0 0
add_entry 2 wlan 1 0
cp "$fixture/rfkill2/soft" "$PWD/wlan-soft.before"
build_case unblock
"$finalizer"
[ "$(wc -l < "$write_log")" -eq 1 ]
[ "$(cat "$write_log")" = "unblock bluetooth" ]
[ "$(cat "$fixture/rfkill0/soft")" -eq 0 ]
[ "$(cat "$fixture/rfkill1/soft")" -eq 0 ]
cmp "$PWD/wlan-soft.before" "$fixture/rfkill2/soft"

reset_fixture
add_entry 0 bluetooth 1 0
add_entry 1 wlan 1 0
cp "$fixture/rfkill1/soft" "$PWD/wlan-soft.before"
build_case fail
if "$finalizer"; then
    printf 'expected rfkill command failure\n' >&2
    exit 1
fi
cmp "$PWD/wlan-soft.before" "$fixture/rfkill1/soft"

reset_fixture
add_entry 0 bluetooth 1 0
add_entry 1 wlan 1 0
cp "$fixture/rfkill1/soft" "$PWD/wlan-soft.before"
build_case remove
"$finalizer"
[ ! -e "$fixture/rfkill0" ]
cmp "$PWD/wlan-soft.before" "$fixture/rfkill1/soft"

reset_fixture
add_entry 0 bluetooth 1 0
add_entry 1 wlan 1 0
cp "$fixture/rfkill1/soft" "$PWD/wlan-soft.before"
build_case add-blocked
if "$finalizer"; then
    printf 'expected newly-added blocked entry verification failure\n' >&2
    exit 1
fi
cmp "$PWD/wlan-soft.before" "$fixture/rfkill1/soft"

reset_fixture
add_entry 0 bluetooth 1 0
add_entry 1 wlan 1 0
cp "$fixture/rfkill1/soft" "$PWD/wlan-soft.before"
build_case verify-fail
if "$finalizer"; then
    printf 'expected post-unblock verification failure\n' >&2
    exit 1
fi
cmp "$PWD/wlan-soft.before" "$fixture/rfkill1/soft"
