local shared = ...
-- local debug = dofile(minetest.get_modpath("cascade") .. "/debug.lua")

local function set_checkpoint(player, pos)
    local meta = player:get_meta()
    meta:set_string("checkpoint", minetest.serialize(pos))
end

local function get_checkpoint(player)
    local meta = player:get_meta()
    return minetest.deserialize(meta:get_string("checkpoint"))
end

local function place(player)
    player:set_pos(get_checkpoint(player) + vector.new(0, -0.5 + 15/16, 0))
    player:set_look_vertical(0)
    player:set_look_horizontal(
        vector.dir_to_rotation(vector.new(1, 0, 1):normalize()).y
    )
end

minetest.register_on_newplayer(function(player)
    set_checkpoint(player, shared.checkpoints[1])
    place(player)
end)

function shared.fail(player)
    local meta = player:get_meta()
    local last_fail = tonumber(meta:get_string("last_fail"))
    local now = minetest.get_us_time()
    if not last_fail or now - last_fail > 500000 then
        minetest.sound_play("cascade_fail", {to_player = player:get_player_name()})
        place(player)
        meta:set_string("last_fail", tostring(now))
    end
end

local function win(player)
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

minetest.register_globalstep(function()
    local players = minetest.get_connected_players()
    local checkpoints = shared.checkpoints

    local monster_positions_modified = false

    for _, player in ipairs(players) do
        local player_pos = player:get_pos()

        for key, monster_pos in pairs(shared.monster_positions) do
            if vector.distance(player_pos, monster_pos) <= shared.MONSTER_RADIUS then
                minetest.add_entity(monster_pos, "cascade:monster")
                shared.monster_positions[key] = nil
                monster_positions_modified = true
            end
        end

        local player_aabb = {
            min = player_pos - vector.new(7/16, 15/16, 7/16),
            max = player_pos + vector.new(7/16, 15/16, 7/16),
        }
        -- debug.visualize_aabb("p_" .. player:get_player_name(), player_aabb)

        for check_index, check_pos in ipairs(checkpoints) do
            local check_aabb = {
                min = check_pos - vector.new(2.5, 1.5, 2.5),
                max = check_pos + vector.new(2.5, 3.5, 2.5),
            }
            -- debug.visualize_aabb("c_" .. check_index, check_aabb)

            if aabbs_intersect(player_aabb, check_aabb) then
                -- io.write("\a"); io.flush()

                set_checkpoint(player, check_pos)
                if check_index == #checkpoints then
                    win(player)
                end
            end
        end

        if player_pos.y < -120 then
            shared.fail(player)
        end
    end

    if monster_positions_modified then
        shared.storage:set_string("monster_positions", minetest.serialize(shared.monster_positions))
    end
end)
