-- `cascade_old_time_speed` might still be set if there has been a crash.
if not minetest.settings:get("cascade_old_time_speed") then
    minetest.settings:set("cascade_old_time_speed", minetest.settings:get("time_speed"))
end
minetest.settings:set("time_speed", 0)

minetest.register_on_shutdown(function()
    minetest.settings:set("time_speed", minetest.settings:get("cascade_old_time_speed"))
    minetest.settings:remove("cascade_old_time_speed")
end)

local FIXED_TIMEOFDAY = 0.4

local function reset_timeofday()
    if minetest.get_timeofday() ~= FIXED_TIMEOFDAY then
        minetest.set_timeofday(FIXED_TIMEOFDAY)
    end
    minetest.after(5, reset_timeofday)
end

reset_timeofday()

minetest.register_on_joinplayer(function(player)
    player:set_sky({
        type = "plain",
        base_color = "#cd6093",
        clouds = true,
    })

    player:set_clouds({
        density = 0.5,
        height = -10.5,
        thickness = 10,
        speed = vector.new(1, 0, 1):normalize() * 2,
        color = "#dff6f5",
    })

    player:set_sun({
        visible = true,
        texture = "", -- ignore "sun.png" provided by texture packs
        tonemap = "", -- whatever
        sunrise = "", -- whatever
        sunrise_visible = false,
    })

    player:set_moon({
        visible = false,
    })

    player:set_stars({
        visible = false,
    })

    player:set_lighting({
        shadows = {
            intensity = 0.4,
        },
    })

    -- For whatever reason, this prevents a delay before the sun appears in
    -- the right place.
    minetest.set_timeofday(FIXED_TIMEOFDAY)
end)
