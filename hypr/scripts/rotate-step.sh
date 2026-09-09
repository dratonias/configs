#!/usr/bin/env bash
# Cycle the currently focused monitor 90 degrees clockwise per press, then
# re-flow the layout so monitors stay flush (no gaps the cursor can't cross).
# The transform is applied in an order that avoids transient monitor overlap
# (the growing/rotating monitor is applied after neighbors move out of the way).
# On the laptop, also rotates the internal touchscreen to match.
set -u

HYP="/usr/bin/hyprctl"

# Compute the whole new layout from a single snapshot: bump the focused
# monitor's transform, pack all monitors flush left->right based on each one's
# post-transform logical width, then sort the application order: on a shrink
# apply the rotating monitor first, on a grow apply it last so the neighbor is
# already out of the way (prevents Hyprland's "overlap" notice).
plan="$("$HYP" -j monitors 2>/dev/null | jq -r '
    (.[] | select(.focused)) as $foc |
    (($foc.transform + 1) % 4) as $nt |
    ((if $foc.transform % 2 == 1 then ($foc.height / $foc.scale) else ($foc.width / $foc.scale) end)) as $oldlw |
    ((if $nt % 2 == 1 then ($foc.height / $foc.scale) else ($foc.width / $foc.scale) end)) as $newlw |
    (map(if .name == $foc.name then .transform = $nt else . end)) |
    sort_by(.x) |
    reduce .[] as $m (
        { acc: (.[0].x), out: [] };
        .acc as $a |
        ($m.transform % 2 == 1) as $swap |
        ($m.width / $m.scale) as $w |
        ($m.height / $m.scale) as $h |
        .out += [ [ $m.name, $a, $m.y, $m.transform, $m.scale, (if $swap then $h else $w end) ] ] |
        .acc = $a + (if $swap then $h else $w end)
    ) |
    (.out | map(select(.[0] == $foc.name)) | .[0]) as $frow |
    (.out | map(select(.[0] != $foc.name))) as $others |
    (if $newlw > $oldlw then $others + [$frow] elif $newlw < $oldlw then [$frow] + $others else .out end) |
    .[] | @tsv
' 2>/dev/null)"

[ -n "$plan" ] || exit 1

while IFS=$'\t' read -r name px py transform scale _lw; do
    "$HYP" eval "hl.monitor({ output=\"$name\", mode=\"preferred\", position=\"${px}x${py}\", scale=$scale, transform=$transform })" >/dev/null 2>&1
    if [ "$name" = "eDP-1" ] || [ "$name" = "eDP-2" ] || [ "$name" = "eDP-3" ]; then
        TOUCH_T="$transform"
    fi
done <<<"$plan"

if [ -n "${TOUCH_T:-}" ]; then
    "$HYP" eval "hl.config({ input = { touchdevice = { transform = $TOUCH_T } } })" >/dev/null 2>&1
fi