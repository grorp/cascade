local shared = ...

minetest.register_on_joinplayer(function(player)
    player:set_properties({
        visual = "cube",
        visual_size = vector.new(0.875, 1.875, 0.875),
        textures = {
            "cascade_player_top.png",   "cascade_player_top.png",
            "cascade_player_side.png",  "cascade_player_side.png",
            "cascade_player_front.png", "cascade_player_side.png",
        },
        pointable = false,

        physical = true,
        collisionbox = {
            -0.4375, -0.9375, -0.4375,
             0.4375,  0.9375,  0.4375,
        },

        -- https://github.com/minetest/minetest/blob/163d3547e65a6cea8a3e555557407e88d8e09183/doc/lua_api.txt#L7290
        nametag_color = "#00000000",

        eye_height = 0.59375, -- The exact eye height of the texture.
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

local chat_send_player = minetest.chat_send_player
function shared.message(player, text)
    chat_send_player(player:get_player_name(), text)
end

minetest.chat_send_all = function() end
minetest.chat_send_player = function() end

minetest.register_on_chat_message(function()
    return true
end)
minetest.register_on_chatcommand(function()
    return true
end)
