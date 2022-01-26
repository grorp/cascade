minetest.register_on_newplayer(function(player)
    player:set_pos(vector.new(2, 111 + 0.5 + 0.875, 2))
end)

minetest.register_on_joinplayer(function(player)
    player:set_properties({
        visual = "cube",
        visual_size = vector.new(0.75, 1.75, 0.75),
        textures = {
            "cascade_player_1.png", "cascade_player_1.png",
            "cascade_player_2.png", "cascade_player_2.png",
            "cascade_player_2.png", "cascade_player_2.png",
        },
        eye_height = 0.625,

        pointable = true,
        selection_box = {-0.375, -0.875, -0.375, 0.375, 0.875, 0.375},
        physical = true,
        collisionbox = {-0.375, -0.875, -0.375, 0.375, 0.875, 0.375},
    })

    player:set_armor_groups({
        immortal = 1,
    })

    player:set_inventory_formspec("")

    player:hud_set_flags({
        crosshair = false,

        hotbar = false,
        wielditem = false,

        healthbar = false,
        breathbar = false,

        minimap = false,
        minimap_radar = false,
    })
end)

minetest.override_item("", {
    range = 0,
})
