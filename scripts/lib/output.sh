#!/bin/sh
# output.sh — Cargo-style output helpers for Selynt Panel shell scripts.
#
# Mirrors `cargo build` formatting: a right-padded action verb in bold colour
# followed by free-form detail. Sub-items align under the detail column.
#
# Colour is auto-disabled when stdout is not a TTY or NO_COLOR is set.
#
# Public API:
#   sly_header "title"  [version]   one-line banner (bold)
#   sly_act "Verbing" "detail"      main action line   (green bold verb)
#   sly_sub "label" "value"         indented sub-item  (label right-aligned)
#   sly_note "free text"            continuation under last act
#   sly_warn "msg"                  warning            (yellow bold "warning:")
#   sly_err  "msg"                  error              (red bold "error:")
#   sly_finished "detail"           completion line    (green bold "Finished")
#
# The verb column is 12 chars wide — same as cargo's `Compiling`/`Finished`.

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

# Header — bold one-liner with optional subtitle. No banner art.
sly_header() {
    if [ -n "${2:-}" ]; then
        printf '\n%s%s%s %s%s%s\n\n' "$_SLY_B" "$1" "$_SLY_N" "$_SLY_D" "$2" "$_SLY_N"
    else
        printf '\n%s%s%s\n\n' "$_SLY_B" "$1" "$_SLY_N"
    fi
}

# Main action: bold green verb, 12-col right-padded, then detail.
sly_act() {
    printf '%s%12s%s %s\n' "$_SLY_G$_SLY_B" "$1" "$_SLY_N" "${2:-}"
}

# Sub-item under an action: 13-space gutter, dim label, value.
# Useful for key/value pairs like "DA user  diradmin".
sly_sub() {
    printf '             %s%s%s %s\n' "$_SLY_D" "$1" "$_SLY_N" "${2:-}"
}

# Free-form continuation note (dim) aligned under the act detail.
sly_note() {
    printf '             %s%s%s\n' "$_SLY_D" "$1" "$_SLY_N"
}

# Warning — yellow bold "warning:" verb.
sly_warn() {
    printf '%s%12s%s %s\n' "$_SLY_Y$_SLY_B" "warning:" "$_SLY_N" "$1" >&2
}

# Error — red bold "error:" verb.
sly_err() {
    printf '%s%12s%s %s\n' "$_SLY_R$_SLY_B" "error:" "$_SLY_N" "$1" >&2
}

# Completion — bold green "Finished" with detail (e.g. "install [0.4s]").
sly_finished() {
    printf '%s%12s%s %s\n' "$_SLY_G$_SLY_B" "Finished" "$_SLY_N" "${1:-}"
}
