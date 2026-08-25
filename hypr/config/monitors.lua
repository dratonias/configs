-- CachyOS Hyprland Configuration

------------------
---- MONITORS ----
------------------

-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Auto-detects the machine: laptop panel (eDP-*) vs desktop triple.
-- MONITORS is the connected-output list built in variables.lua.

local is_laptop = false
for _, name in ipairs(MONITORS) do
    if name:find("eDP", 1, true) then is_laptop = true end
end

if is_laptop then
    -- Laptop: internal panel, preferred mode, auto position
    hl.monitor({
        output   = "eDP-1",
        mode     = "preferred",
        position = "auto",
    })
else
    -- Desktop: ROG PG258Q (main, 240Hz), VG248 (left), BenQ GW2480 (right, rotated)
    hl.monitor({
        output   = "DP-2",
        mode     = "1920x1080@240",
        position = "1920x0",
        scale    = 1,
    })
    hl.monitor({
        output   = "DP-3",
        mode     = "1920x1080@119.98",
        position = "0x0",
        scale    = 1,
    })
    hl.monitor({
        output    = "HDMI-A-1",
        mode      = "1920x1080@60",
        position  = "3840x0",
        scale     = 1,
        transform = 3,
    })
end
