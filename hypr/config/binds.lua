local mainMod = "SUPER"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

-- Monitors in physical order (left -> right), detected dynamically in variables.lua
local MONITOR_ORDER = MONITORS

local function neighbor_monitor(offset)
    local active = hl.get_active_monitor()
    if active == nil then return PRIMARY_MONITOR end
    local name = active.name
    for i, monitor_name in ipairs(MONITOR_ORDER) do
        if monitor_name == name then
            local next_index = ((i - 1 + offset) % #MONITOR_ORDER) + 1
            return MONITOR_ORDER[next_index]
        end
    end
    return PRIMARY_MONITOR
end

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation (left half: state)
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + G",           hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + B",           hl.dsp.layout("togglesplit"))

-- Change focus
hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + Tab",   hl.dsp.exec_cmd(noctCall .. "window-switcher"))

-- Focus previous / next monitor (ladder: SHIFT = move window to monitor)
hl.bind(mainMod .. " + ALT + Left",  function() hl.dispatch(hl.dsp.focus({ monitor = neighbor_monitor(-1) })) end)
hl.bind(mainMod .. " + ALT + Right", function() hl.dispatch(hl.dsp.focus({ monitor = neighbor_monitor(1) })) end)
hl.bind(mainMod .. " + U",           function() hl.dispatch(hl.dsp.focus({ monitor = neighbor_monitor(-1) })) end)
hl.bind(mainMod .. " + O",           function() hl.dispatch(hl.dsp.focus({ monitor = neighbor_monitor(1) })) end)
hl.bind(mainMod .. " + SHIFT + U",   function() hl.dispatch(hl.dsp.window.move({ monitor = neighbor_monitor(-1) })) end)
hl.bind(mainMod .. " + SHIFT + O",   function() hl.dispatch(hl.dsp.window.move({ monitor = neighbor_monitor(1) })) end)

-- Move active window (ladder: SHIFT = move window)
hl.bind(mainMod .. " + SHIFT + Up",                   hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Down",                 hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + Left",                 hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + Right",                hl.dsp.window.move({ direction = "r" }))

-- Focus with right-hand keys (ladder: SHIFT = move window)
hl.bind(mainMod .. " + J",           hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + K",           hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + I",           hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L",           hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + J",   hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + K",   hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + I",   hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L",   hl.dsp.window.move({ direction = "r" }))

-- Move active window to previous / next monitor (ladder: SHIFT + ALT = move window to monitor)
hl.bind(mainMod .. " + SHIFT + ALT + Left",           function() hl.dispatch(hl.dsp.window.move({ monitor = neighbor_monitor(-1) })) end)
hl.bind(mainMod .. " + SHIFT + ALT + Right",          function() hl.dispatch(hl.dsp.window.move({ monitor = neighbor_monitor(1) })) end)

-- Move active window to workspace by number (absolute, follows the workspace's home monitor)
for i = 1, TOTAL_WORKSPACES do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind(mainMod .. " + Minus", function() zoomfunction(-0.3) end, { repeating = true})
hl.bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind(mainMod .. " + code:86", function() zoomfunction(0.3) end, { repeating = true })


------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + Y",          hl.dsp.exec_cmd(launchPrefix .. EDITOR))
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
hl.bind("XF86Calculator",           hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + A",          hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center notifications"))
hl.bind(mainMod .. " + R",          hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"))
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(noctCall .. "panel-toggle session"))
-- TODO: session lock (was SUPER + L) still needs a bind

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctCall .. "volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctCall .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctCall .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(noctCall .. "mic-mute"),    { locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(noctCall .. "media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(noctCall .. "media previous"), { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctCall .. "brightness-down"), { locked = true, repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + C",          hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind(mainMod .. " + S",          hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))
hl.bind(mainMod .. " + D",          hl.dsp.exec_cmd(noctCall .. "screenshot-region"))

-- Theming and Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))

-- Clipboard
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd(noctCall .. "panel-toggle clipboard"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on workspace number
for i = 1, TOTAL_WORKSPACES do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end

-- Named gaming workspace
hl.bind(mainMod .. " + udiaeresis",  hl.dsp.focus({ workspace = "name:gaming" }))
hl.bind(mainMod .. " + adiaeresis",  hl.dsp.window.move({ workspace = "name:gaming" }))

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down",           hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up",             hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
