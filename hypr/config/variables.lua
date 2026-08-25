-- Hyprland default apps

TERMINAL     = "alacritty"
FILE_MANAGER = "dolphin"
BROWSER      = "vivaldi"
EDITOR       = "gnome-text-editor --new-window"
CALCULATOR   = "gnome-calculator"

-- Monitors
-- Detect connected outputs dynamically (works on any machine with this conf).
-- Falls back to the known triple if hyprctl isn't reachable during config load.
NUM_WPM = 3 -- Number of workspaces per monitor

MONITORS = {}
do
    local handle = io.popen("hyprctl -j monitors 2>/dev/null")
    if handle then
        local json = handle:read("*a")
        handle:close()
        if json and #json > 0 then
            -- crude scan: each monitor object contains "name" ... "x": <num>
            for obj in json:gmatch("{(.-)}") do
                local name = obj:match('"name"%s*:%s*"([^"]+)"')
                local x = tonumber(obj:match('"x"%s*:%s*(-?%d+)'))
                if name then
                    table.insert(MONITORS, { name = name, x = x or 0 })
                end
            end
            table.sort(MONITORS, function(a, b) return a.x < b.x end)
        end
    end
end

if #MONITORS == 0 then
    -- Fallback: previous static layout (this machine)
    MONITORS = {
        { name = "DP-3",      x = 0 },
        { name = "DP-2",      x = 1920 },
        { name = "HDMI-A-1",  x = 3840 },
    }
end

-- Names only, ordered left -> right (physical order)
for i, m in ipairs(MONITORS) do MONITORS[i] = m.name end

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
