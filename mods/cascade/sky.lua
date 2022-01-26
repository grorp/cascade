minetest.register_globalstep(function()
    minetest.set_timeofday(0.4) -- Results in nice shadows.
end)

minetest.register_on_joinplayer(function(player)
    player:set_sky({
        type = "plain",
        base_color = "#cd6093",

        clouds = true,
    })

    player:set_clouds({
        color = "#dff6f5",
        density = 0.5,

        height = 100,
        thickness = 10,
        speed = vector.new(0, 0, 10),
    })

    player:set_sun({
        visible = false,
        sunrise_visible = false,
    })

    player:set_moon({
        visible = false,
    })

    player:set_stars({
        visible = false,
    })
end)
