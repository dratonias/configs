-- Auto-start config
-- Launched via Hyprland exec instead of XDG autostart for better control

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("plymouth quit")
    hl.exec_cmd("xhost +SI:localuser:root")

    -- Apps only auto-launch on the desktop; nothing on the laptop
    local is_laptop = false
    for _, name in ipairs(MONITORS) do
        if name:find("eDP", 1, true) then is_laptop = true end
    end

    if not is_laptop then
        -- Autostart apps
        hl.exec_cmd("uwsm app -- /home/timo/.config/discord/app-1.0.155/Discord")
        hl.exec_cmd("uwsm app -- /usr/bin/looking-glass-client")
        hl.exec_cmd("uwsm app -- spotify-launcher")
        hl.exec_cmd("uwsm app -- waydroid show-full-ui")
        hl.exec_cmd("uwsm app -- /opt/KopiaUI/kopia-ui")
        hl.exec_cmd("uwsm app -- coolercontrol")
        hl.exec_cmd('uwsm app -- "/usr/bin/syncthingtray-qt6" qt-widgets-gui --single-instance --wait')
        hl.exec_cmd("/home/timo/Sync/Repos/Mine/Scripts/linux/connect_headphones.sh")

        -- Launch Vivaldi on workspace 4 (subsequent windows follow focus)
        hl.exec_cmd("hyprctl dispatch workspace 4 && uwsm app -- vivaldi-stable")
    end

    if is_laptop then
        -- Sensor Fusion Hub accelerometer does not respond on this model
        -- (see amd-sfh-reload notes). Manual rotation: SUPER + R
    end

    -- Force the session to start on workspace 1
    hl.exec_cmd("hyprctl dispatch workspace 1")
end)
