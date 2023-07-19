-- Sprinting in Minecraft:
-- https://minecraft.fandom.com/wiki/Sprinting?oldid=2190082
-- Sprinting in MineClone 2:
-- https://git.minetest.land/MineClone2/MineClone2/src/commit/0942949c5da465c7886aa44cd0267d535658e9ea/mods/PLAYER/mcl_sprint

local PLAYER_WALK_SPEED = 1.125 -- 4.5 m/s
local PLAYER_RUN_SPEED = PLAYER_WALK_SPEED * 1.3 -- 5.85 m/s
local PLAYER_RUN_FOV = 1.15
local PLAYER_FOV_TRANSITION_DURATION = 0.15

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
        collisionbox = {-7/16, -15/16, -7/16, 7/16, 15/16, 7/16},

        eye_height = 9/16 + 1/32, -- The exact eye height of the texture.
        -- https://github.com/minetest/minetest/blob/5.6.1/doc/lua_api.txt#L7643
        nametag_color = "#00000000",
    })

    player:set_armor_groups({immortal = 1})

    player:set_physics_override({ speed = PLAYER_WALK_SPEED })

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

local map_name_to_running = {}

minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local ctrl = player:get_player_control()

        local should_run = ctrl.up and ctrl.aux1 and
            (not ctrl.down) and (not ctrl.sneak) and (not player:get_attach())

        if should_run and not map_name_to_running[name] then
            player:set_physics_override({ speed = PLAYER_RUN_SPEED })
            player:set_fov(PLAYER_RUN_FOV, true, PLAYER_FOV_TRANSITION_DURATION)
            map_name_to_running[name] = true
        elseif not should_run and map_name_to_running[name] then
            player:set_physics_override({ speed = PLAYER_WALK_SPEED })
            player:set_fov(0, true, PLAYER_FOV_TRANSITION_DURATION)
            map_name_to_running[name] = false
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    map_name_to_running[player:get_player_name()] = nil
end)
