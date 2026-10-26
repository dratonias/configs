-- Input configuration

hl.config({
    input = {
        -- sensitivity = -0.25,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = true,
        },
    },
    cursor = {
        -- Don't teleport the pointer to the newly focused window when focus
        -- changes without the mouse (keybinds, windows opening/closing,
        -- monitor focus). The cursor only moves when you move it.
        no_warps = true,
        -- Uncomment to enable software cursors; this can help with cursor display or behavior issues
        -- no_hardware_cursors = 1,
    },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })
