minetest.register_on_joinplayer(function(player)
    player:override_day_night_ratio(1)

    player:set_sky({
        type = "plain",
        base_color = "#cd6093",

        clouds = true,
    })

    player:set_clouds({
        color = "#dff6f5",
        height = -10.5,
        thickness = 10,
        speed = vector.new(1, 0, 1):normalize() * 2,
        density = 0.5,
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
