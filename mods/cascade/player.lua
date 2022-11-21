minetest.register_on_joinplayer(function(player)
    player:set_properties({
        visual = "cube",
        visual_size = vector.new(14/16, 30/16, 14/16),
        textures = {
            "cascade_player_top.png",   "cascade_player_top.png",
            "cascade_player_side.png",  "cascade_player_side.png",
            "cascade_player_front.png", "cascade_player_side.png",
        },
        pointable = false,

        physical = true,
        collisionbox = {
            -7/16, -15/16, -7/16,
             7/16,  15/16,  7/16,
        },

        -- https://github.com/minetest/minetest/blob/5.6.1/doc/lua_api.txt#L7643
        nametag_color = "#00000000",

        eye_height = 9/16 + 1/32, -- The exact eye height of the texture.
    })

    player:set_armor_groups({immortal = 1})

    player:hud_set_flags({
        basic_debug = false,
        breathbar = false,
        crosshair = false,
        healthbar = false,
        hotbar = false,
        minimap = false,
        minimap_radar = false,
        wielditem = false,
    })

    player:set_inventory_formspec("")
end)

minetest.chat_send_all = function() end
minetest.chat_send_player = function() end

minetest.register_on_chat_message(function()
    return true
end)
minetest.register_on_chatcommand(function()
    return true
end)
