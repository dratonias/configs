-- Auto-start config
-- Launched via Hyprland exec instead of XDG autostart for better control
--
-- Apps start on a fixed workspace with `silent` so no monitor flickers while
-- the session boots. Window/workspace rules pin each workspace to its monitor
-- (see workspaces.lua, NUM_WPM = 3):
--   main/DP-2: ws 1-3 | left/DP-3: ws 4-6 | right/HDMI-A-1: ws 7-9

if not IS_LAPTOP then
    local function find_media_windows()
        local discord, spotify
        local tiled = 0
        for _, window in ipairs(hl.get_workspace_windows(7)) do
            if window.mapped and not window.hidden and not window.floating then
                tiled = tiled + 1
                if window.class == "discord" then discord = window end
                if window.class:lower() == "spotify" then spotify = window end
            end
        end
        if tiled == 2 then return discord, spotify end
    end

    local function media_layout_matches(discord, spotify)
        local vertical = math.abs(discord.at.x - spotify.at.x) <= 2
        local ratio = discord.size.y / (discord.size.y + spotify.size.y)
        return vertical and discord.at.y < spotify.at.y and math.abs(ratio - 0.678) < 0.005
    end

    local function arrange_media_windows(discord, spotify)
        local focused = hl.get_active_window()
        local workspace = hl.get_active_workspace()
        local side_workspace = discord.monitor.active_workspace
        hl.dispatch(hl.dsp.focus({ window = "address:" .. discord.address }))
        if math.abs(discord.at.x - spotify.at.x) > 2 then
            hl.dispatch(hl.dsp.layout("togglesplit"))
        elseif discord.at.y > spotify.at.y then
            hl.dispatch(hl.dsp.window.swap({ direction = "up" }))
        end
        -- Dwindle's ratio is twice the top child's share, not a percentage.
        hl.dispatch(hl.dsp.layout("splitratio 1.356 exact"))
        if side_workspace and side_workspace.id ~= 7 then
            hl.dispatch(hl.dsp.focus({ workspace = side_workspace.id }))
        end
        if focused then
            hl.dispatch(hl.dsp.focus({ window = "address:" .. focused.address }))
        elseif workspace then
            hl.dispatch(hl.dsp.focus({ workspace = workspace.id }))
        end
    end

    local pair, stable, attempts = nil, 0, 0
    local function reconcile_media_layout()
        local discord, spotify = find_media_windows()
        if not discord or not spotify then
            pair, stable, attempts = nil, 0, 0
            return
        end
        local current = discord.stable_id .. ":" .. spotify.stable_id
        if current ~= pair then pair, stable, attempts = current, 0, 0 end
        -- Once verified, leave manual adjustments alone until the pair changes.
        if stable >= 3 then return end
        if discord.fullscreen ~= 0 or spotify.fullscreen ~= 0 or discord.group or spotify.group
            or discord.workspace.tiled_layout ~= "dwindle" then return end
        if media_layout_matches(discord, spotify) then
            stable = stable + 1
            return
        end
        if attempts >= 10 then
            if attempts == 10 then
                print("Discord/Spotify: placement retry limit reached; check workspace 7 geometry")
                attempts = attempts + 1
            end
            return
        end
        stable, attempts = 0, attempts + 1
        arrange_media_windows(discord, spotify)
    end

    hl.timer(reconcile_media_layout, { timeout = 1000, type = "repeat" })
end

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemd-cat --identifier=noctalia noctalia")
    hl.exec_cmd("plymouth quit")
    hl.exec_cmd("xhost +SI:localuser:root")

    -- Apps only auto-launch on the desktop; nothing on the laptop
    -- (IS_LAPTOP is defined in variables.lua)
    if not IS_LAPTOP then
        -- Background / tray apps
        hl.exec_cmd("uwsm app -- /opt/KopiaUI/kopia-ui")
        hl.exec_cmd('uwsm app -- syncthingtray-qt6 --wait')
        hl.exec_cmd("/home/timo/Sync/Repos/Mine/Scripts/linux/connect_headphones.sh")
        hl.exec_cmd("gdbus wait --session --timeout 120 org.kde.StatusNotifierWatcher && uwsm app -- arch-update --tray")
        hl.exec_cmd("uwsm app -- /home/timo/.local/bin/twitch-notify")
        hl.exec_cmd("uwsm app -- coolercontrol")

        -- Gui apps
        hl.exec_cmd("uwsm app -- waydroid show-full-ui", { workspace = "9 silent" })
        hl.exec_cmd("uwsm app -- looking-glass-client", { workspace = "3 silent" })
        hl.exec_cmd("uwsm app -- vivaldi-stable", { workspace = "4 silent" })
        hl.exec_cmd("uwsm app -- discord", { workspace = "7 silent" })
        hl.exec_cmd("uwsm app -- spotify-launcher", { workspace = "7 silent" })

    end

    -- Startup windows are created asynchronously, so focus ws 1 after them.
    hl.exec_cmd([[sleep 3 && hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = 1 }))']])
end)
