local shared = ...

local function set_checkpoint(player, pos)
    local meta = player:get_meta()
    meta:set_string("checkpoint", minetest.serialize(pos))
end

local function get_checkpoint(player)
    local meta = player:get_meta()
    return minetest.deserialize(meta:get_string("checkpoint"))
end

local function place(player)
    player:set_pos(get_checkpoint(player) + vector.new(0, -0.5 + 0.9375, 0))
    player:set_look_vertical(0)
    player:set_look_horizontal(vector.dir_to_rotation(vector.new(1, 0, 1):normalize()).y)
end

minetest.register_on_newplayer(function(player)
    set_checkpoint(player, shared.checkpoints[1])
    place(player)
end)

local function fail(player)
    minetest.sound_play("cascade_fail", {to_player = player:get_player_name()})
    place(player)
end

local function win(player)
    local meta = player:get_meta()
    if meta:get_int("won") ~= 1 then
        minetest.sound_play("cascade_win", {to_player = player:get_player_name()})
        meta:set_int("won", 1)
    end
end

minetest.register_globalstep(function()
    local players = minetest.get_connected_players()
    local checkpoints = shared.checkpoints

    for _, player in ipairs(players) do
        local pos = player:get_pos()

        local a = {
            min = {x = pos.x - 0.4375, y = pos.y - 0.9375, z = pos.z - 0.4375},
            max = {x = pos.x + 0.4375, y = pos.y + 0.9375, z = pos.z + 0.4375},
        }

        for index, checkpoint in ipairs(checkpoints) do
            local b = {
                min = {x = checkpoint.x - 2.5, y = checkpoint.y - 1.5, z = checkpoint.z - 2.5},
                max = {x = checkpoint.x + 2.5, y = checkpoint.y + 3.5, z = checkpoint.z + 2.5},
            }
            local intersect = (
                a.min.x < b.max.x and a.max.x > b.min.x and
                a.min.y < b.max.y and a.max.y > b.min.y and
                a.min.z < b.max.z and a.max.z > b.min.z
            )

            if intersect then
                set_checkpoint(player, checkpoint)

                if index == #checkpoints then
                    win(player)
                end
            end
        end

        if pos.y < -120 then
            fail(player)
        end
    end
end)
