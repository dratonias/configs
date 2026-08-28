-- Hyprland default apps

TERMINAL     = "alacritty"
FILE_MANAGER = "dolphin"
BROWSER      = "vivaldi"
EDITOR       = "gnome-text-editor --new-window"
CALCULATOR   = "gnome-calculator"

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
    local names = {}
    local handle = io.popen("hyprctl -j monitors 2>/dev/null")
    if handle then
        local json = handle:read("*a")
        handle:close()
        if json and #json > 0 then
            for obj in json:gmatch("{(.-)}") do
                local name = obj:match('"name"%s*:%s*"([^"]+)"')
                if name then names[name] = true end
            end
        end
    end
    return names
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
        -- Nothing detected: default to the known desktop triple (this machine)
        MONITORS = { "DP-3", "DP-2", "HDMI-A-1" }
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
