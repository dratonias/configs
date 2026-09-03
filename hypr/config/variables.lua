-- Hyprland default apps

TERMINAL     = "alacritty"
FILE_MANAGER = "dolphin"
BROWSER      = "vivaldi"
CODE_EDITOR  = ""
CALCULATOR   = ""

-- Monitors
-- Workspace numbering is pinned to a FIXED device list so that a transient
-- or phantom output (e.g. an HDMI/DP connector briefly hotplugging, a Looking
-- Glass / waydroid virtual output) can never renumber workspaces upward.
-- Known outputs are hardcoded and matched against the live monitor set; the
-- live count is only used as a fallback if none of the known names are seen.
NUM_WPM = 3 -- Number of workspaces per monitor

-- Known physical layout: laptop panel and desktop triple, both ordered
-- left -> right (physical order).
LAPTOP_OUTPUTS   = { "eDP-1" }
DESKTOP_OUTPUTS  = { "DP-3", "DP-2", "HDMI-A-1" } -- left, middle, right

local function detected_outputs()
    -- Read DRM connector state from sysfs, not from the Hyprland IPC: when
    -- the config is first evaluated at startup Hyprland has not enumerated
    -- the outputs yet, so `hyprctl -j monitors` returns nothing and the
    -- fallback below picks the wrong machine type. Querying hyprctl from
    -- inside the config also deadlocks `hyprctl reload`.
    local names = {}
    local handle = io.popen("ls /sys/class/drm 2>/dev/null")
    if handle then
        for entry in handle:lines() do
            local name = entry:match("^card%d+%-(.+)$")
            if name then
                local f = io.open("/sys/class/drm/" .. entry .. "/status", "r")
                if f then
                    local status = f:read("*l")
                    f:close()
                    if status == "connected" then names[name] = true end
                end
            end
        end
        handle:close()
    end
    return names
end

-- Machine type used only when no known output is detected at all. Decided from
-- the SMBIOS chassis type (immediately readable, no Hyprland dependency).
local function is_laptop()
    local f = io.open("/sys/class/dmi/id/chassis_type", "r")
    if f then
        local n = tonumber(f:read("*l"))
        f:close()
        if n then
            -- portable/laptop nominal types: 8 portable, 9 laptop, 10 notebook,
            -- 11 handheld, 12 docking, 13 all-in-one, 14 sub-notebook,
            -- 21 convertible, 30 tablet, 31 convertible, 32 detachable
            return n == 8 or n == 9 or n == 10 or n == 11 or n == 12 or n == 13
                or n == 14 or n == 21 or n == 30 or n == 31 or n == 32
        end
    end
    return false
end

local live = detected_outputs()

-- Decide device: laptop if any known laptop output is actually connected,
-- else desktop triple if any of those is connected. Only then fall back to
-- what the live count reports (e.g. an unknown machine).
MONITORS = nil
if live["eDP-1"] or live["eDP-2"] or live["eDP-3"] then
    MONITORS = LAPTOP_OUTPUTS
elseif live["DP-3"] or live["DP-2"] or live["HDMI-A-1"] then
    MONITORS = DESKTOP_OUTPUTS
end

if MONITORS == nil then
    -- Unknown machine: fall back to the live count (name-only list kept below).
    MONITORS = {}
    for name in pairs(live) do table.insert(MONITORS, name) end
    table.sort(MONITORS)
    if #MONITORS == 0 then
        -- Nothing detected: pick the machine type instead of assuming desktop.
        MONITORS = is_laptop() and LAPTOP_OUTPUTS or DESKTOP_OUTPUTS
    end
end

-- Primary = physically middle monitor when there are 3+, otherwise the last one
PRIMARY_INDEX = #MONITORS >= 3 and math.ceil(#MONITORS / 2) or #MONITORS
PRIMARY_MONITOR = MONITORS[PRIMARY_INDEX]

-- Workspace order: main monitor first (ws 1..NUM_WPM), then the rest left -> right
-- e.g. 3 monitors: [middle, left, right]
WS_MONITORS = {}
do
    local rest = {}
    for i, name in ipairs(MONITORS) do
        if i == PRIMARY_INDEX then
            table.insert(WS_MONITORS, name)
        else
            table.insert(rest, name)
        end
    end
    for _, name in ipairs(rest) do table.insert(WS_MONITORS, name) end
end

TOTAL_WORKSPACES = #MONITORS * NUM_WPM
