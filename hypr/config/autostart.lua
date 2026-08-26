-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
    -- Give Noctalia time to render before killing Plymouth
    hl.exec_cmd("sleep 3 && plymouth quit")
    hl.exec_cmd("xhost +SI:localuser:root")
end)
