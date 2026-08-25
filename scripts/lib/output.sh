#!/bin/sh
# Cargo-style output for the installer scripts: a 12-column action verb in bold
# colour, then free-form detail. Colour is dropped when stdout is not a TTY or
# NO_COLOR is set.

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _SLY_R="$(printf '\033[0;31m')"
    _SLY_G="$(printf '\033[0;32m')"
    _SLY_Y="$(printf '\033[0;33m')"
    _SLY_C="$(printf '\033[0;36m')"
    _SLY_D="$(printf '\033[0;90m')"
    _SLY_B="$(printf '\033[1m')"
    _SLY_N="$(printf '\033[0m')"
else
    _SLY_R=""; _SLY_G=""; _SLY_Y=""; _SLY_C=""; _SLY_D=""; _SLY_B=""; _SLY_N=""
fi

sly_header() {
    if [ -n "${2:-}" ]; then
        printf '\n%s%s%s %s%s%s\n\n' "$_SLY_B" "$1" "$_SLY_N" "$_SLY_D" "$2" "$_SLY_N"
    else
        printf '\n%s%s%s\n\n' "$_SLY_B" "$1" "$_SLY_N"
    fi
}

sly_act() {
    printf '%s%12s%s %s\n' "$_SLY_G$_SLY_B" "$1" "$_SLY_N" "${2:-}"
}

# Key/value pair under an action, e.g. "DA user  diradmin".
sly_sub() {
    printf '             %s%s%s %s\n' "$_SLY_D" "$1" "$_SLY_N" "${2:-}"
}

sly_note() {
    printf '             %s%s%s\n' "$_SLY_D" "$1" "$_SLY_N"
}

sly_warn() {
    printf '%s%12s%s %s\n' "$_SLY_Y$_SLY_B" "warning:" "$_SLY_N" "$1" >&2
}

sly_err() {
    printf '%s%12s%s %s\n' "$_SLY_R$_SLY_B" "error:" "$_SLY_N" "$1" >&2
}

sly_finished() {
    printf '%s%12s%s %s\n' "$_SLY_G$_SLY_B" "Finished" "$_SLY_N" "${1:-}"
}

# A step that must not abort the installer — the DirectAdmin hook has to exit 0
# or the plugin is never registered — but whose failure the admin still needs to
# see. Replaces `cmd 2>/dev/null || true`, which hid a broken install behind a
# success message.
sly_try() {
    _sly_what="$1"; shift
    if "$@" 2>/dev/null; then
        return 0
    fi
    sly_warn "$_sly_what failed — the plugin may not work correctly"
    return 1
}
