-- Look and feel configuration

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 0,
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            active_border = {
                colors = { PRIMARY, PRIMARY_DARK },
                angle = 45,
            },
        },
    },
    group = {
        col = {
            border_active = BLUE,
            border_inactive = GREY,
            border_locked_active = RED,
            border_locked_inactive = GREY,
        },
        groupbar = {
            col = {
                active = PRIMARY,
                inactive = GREY,
                locked_active = RED,
                locked_inactive = GREY,
            },
        },
    },
})
