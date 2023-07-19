local shared = ...
-- local debug = dofile(minetest.get_modpath("cascade") .. "/debug.lua")

local function player_set_checkpoint(player, pos)
    local meta = player:get_meta()
    meta:set_string("checkpoint", minetest.serialize(pos))
end

local function player_get_checkpoint(player)
    local meta = player:get_meta()
    return minetest.deserialize(meta:get_string("checkpoint"))
end

local function player_place(player)
    player:set_pos(player_get_checkpoint(player) + vector.new(0, -0.5 + 15/16, 0))
    player:set_look_vertical(0)
    player:set_look_horizontal(
        vector.dir_to_rotation(vector.new(1, 0, 1):normalize()).y
    )
end

minetest.register_on_newplayer(function(player)
    player_set_checkpoint(player, shared.checkpoints[1])
    player_place(player)
end)

function shared.player_fail(player)
    local meta = player:get_meta()
    local last_fail = tonumber(meta:get_string("last_fail"))
    local now = minetest.get_us_time()
    if not last_fail or now - last_fail > 500000 then
        minetest.sound_play("cascade_fail", {to_player = player:get_player_name()})
        player_place(player)
        meta:set_string("last_fail", tostring(now))
    end
end

-- Only there not to break old, non-infinite worlds. Not used anymore by new
-- worlds.
local function player_win(player)
    local meta = player:get_meta()
    if meta:get_int("won") ~= 1 then
        minetest.sound_play("cascade_win", {to_player = player:get_player_name()})
        meta:set_int("won", 1)
    end
end

local function aabbs_intersect(a, b)
    return
        a.min.x <= b.max.x and
        a.max.x >= b.min.x and
        a.min.y <= b.max.y and
        a.max.y >= b.min.y and
        a.min.z <= b.max.z and
        a.max.z >= b.min.z
end

local MAPGEN_TRIGGER_DISTANCE = 64

minetest.register_globalstep(function()
    local players = minetest.get_connected_players()
    local should_save = false

    for _, player in ipairs(players) do
        local player_pos = player:get_pos()

        -- `shared.next_maze` can be nil if the world was created with an old
        -- version of Cascade.
        if shared.next_maze and
                vector.distance(player_pos, shared.next_maze.pos) <= MAPGEN_TRIGGER_DISTANCE then
            shared.make_next_maze()
            should_save = true
        end

        for key, monster_pos in pairs(shared.monster_positions) do
            if vector.distance(player_pos, monster_pos) <= MAPGEN_TRIGGER_DISTANCE then
                print("spawning monster")
                minetest.add_entity(monster_pos, "cascade:monster")
                shared.monster_positions[key] = nil
                should_save = true
            end
        end

        local player_aabb = {
            min = player_pos - vector.new(7/16, 15/16, 7/16),
            max = player_pos + vector.new(7/16, 15/16, 7/16),
        }
        -- debug.visualize_aabb("p_" .. player:get_player_name(), player_aabb)

        for check_index, check_pos in ipairs(shared.checkpoints) do
            local check_aabb = {
                -- 0.1 m smaller in each direction to prevent activating the
                -- checkpoint through walls.
                min = check_pos - vector.new(2.4, 1.4, 2.4),
                max = check_pos + vector.new(2.4, 3.4, 2.4),
            }
            -- debug.visualize_aabb("c_" .. check_index, check_aabb)

            if aabbs_intersect(player_aabb, check_aabb) then
                player_set_checkpoint(player, check_pos)

                -- `shared.next_maze` will be nil if this is an old, non-infinite
                -- world.
                if not shared.next_maze and check_index == #shared.checkpoints then
                    player_win(player)
                end

                -- io.write("\a"); io.flush()
            end
        end

        -- `shared.next_maze` can be nil if the world was created with an old
        -- version of Cascade.
        local min_y = shared.next_maze and (shared.next_maze.pos.y - 256) or -120
        if player_pos.y < min_y then
            shared.player_fail(player)
        end
    end

    if should_save then
        shared.save()
    end
end)
