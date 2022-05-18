local shared = ...

minetest.register_on_joinplayer(function(player)
    player:set_properties({
        visual = "cube",
        visual_size = vector.new(0.75, 1.75, 0.75),
        textures = {
            "cascade_player_1.png", "cascade_player_1.png",
            "cascade_player_2.png", "cascade_player_2.png",
            "cascade_player_2.png", "cascade_player_2.png",
        },
        pointable = false,

        physical = true,
        collisionbox = {-0.375, -0.875, -0.375, 0.375, 0.875, 0.375},
        eye_height = 0.625,

        -- https://github.com/minetest/minetest/blob/163d3547e65a6cea8a3e555557407e88d8e09183/doc/lua_api.txt#L7290
        nametag_color = "#00000000",
    })

    player:set_armor_groups({
        immortal = 1,
    })

    player:set_inventory_formspec("")

    player:hud_set_flags({
        crosshair = false,

        hotbar = false,
        healthbar = false,
        breathbar = false,
        wielditem = false,

        minimap = false,
        minimap_radar = false,
    })
end)

minetest.chat_send_all = function() end
minetest.chat_send_player = function() end
minetest.register_on_chat_message(function()
    return true
end)
minetest.register_on_chatcommand(function()
    return true
end)
