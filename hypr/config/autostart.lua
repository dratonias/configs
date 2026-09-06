-- Auto-start config
-- Launched via Hyprland exec instead of XDG autostart for better control
--
-- Apps start on a fixed workspace with `silent` so no monitor flickers while
-- the session boots. Window/workspace rules pin each workspace to its monitor
-- (see workspaces.lua, NUM_WPM = 3):
--   main/DP-2: ws 1-3 | left/DP-3: ws 4-6 | right/HDMI-A-1: ws 7-9

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
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
        hl.exec_cmd("uwsm app -- twitch-notify")
        hl.exec_cmd("uwsm app -- apollo")
        hl.exec_cmd("uwsm app -- coolercontrol")

        -- Gui apps
        hl.exec_cmd("uwsm app -- waydroid show-full-ui", { workspace = "9 silent" })
        hl.exec_cmd("uwsm app -- looking-glass-client", { workspace = "3 silent" })
        hl.exec_cmd("uwsm app -- vivaldi-stable", { workspace = "4 silent" })
        hl.exec_cmd([[uwsm app -- discord & while ! hyprctl clients -j | jq -e '.[] | select(.class == "discord")' >/dev/null; do sleep 0.1; done; uwsm app -- spotify-launcher &]], { workspace = "7 silent" })
        hl.exec_cmd([[while ! hyprctl clients -j | jq -e '.[] | select(.class == "Spotify")' >/dev/null; do sleep 0.1; done; hyprctl eval 'hl.dispatch(hl.dsp.focus({ window = "class:Spotify" })); hl.dispatch(hl.dsp.window.swap({ direction = "down" })); hl.dispatch(hl.dsp.focus({ window = "class:Spotify" })); hl.dispatch(hl.dsp.layout("splitratio 0.356")); hl.dispatch(hl.dsp.focus({ workspace = 1 }))']])

    end

    -- Startup windows are created asynchronously, so focus ws 1 after them.
    hl.exec_cmd([[sleep 3 && hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = 1 }))']])
end)
