#!/usr/bin/env bash
# Cycle the internal panel + touchscreen 90 degrees clockwise per press.
set -u

HYP="/usr/bin/hyprctl"

info="$($HYP -j monitors 2>/dev/null | jq -r 'map(select(.name | test("^eDP"; "i"))) | .[0]' 2>/dev/null)"
if [ -n "$info" ] && [ "$info" != "null" ]; then
    OUT="$(jq -r .name <<<"$info")"
    SCALE="$(jq -r .scale <<<"$info")"
    T="$(jq -r .transform <<<"$info")"
fi
OUT="${OUT:-eDP-1}"
SCALE="${SCALE:-1.25}"
T="${T:-0}"

NT=$(( (T + 1) % 4 ))

"$HYP" eval "hl.monitor({ output=\"$OUT\", mode=\"preferred\", position=\"auto\", scale=$SCALE, transform=$NT })" >/dev/null 2>&1
"$HYP" eval "hl.config({ input = { touchdevice = { transform = $NT } } })" >/dev/null 2>&1