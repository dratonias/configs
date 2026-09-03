-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Workspaces are distributed dynamically: NUM_WPM per connected monitor.
-- Numbering starts on the main (middle) monitor, then the rest left -> right
-- (see WS_MONITORS in variables.lua).

hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR })

for i, monitor in ipairs(WS_MONITORS) do
    for j = 1, NUM_WPM do
        local ws = (i - 1) * NUM_WPM + j
        hl.workspace_rule({ workspace = tostring(ws), monitor = monitor, default = true, persistent = true })
    end
end

-- For other layouts such as scrolling, see example below
-- hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true, layout = scroling })
