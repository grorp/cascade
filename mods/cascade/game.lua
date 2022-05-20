local shared = ...

local t = minetest.get_translator("cascade")

local function set_checkpoint(player, pos)
    local meta = player:get_meta()
    meta:set_string("checkpoint", minetest.serialize(pos))
end

local function get_checkpoint(player)
    local meta = player:get_meta()
    return minetest.deserialize(meta:get_string("checkpoint"))
end

local function place(player)
    local box = player:get_properties().collisionbox
    player:set_pos(get_checkpoint(player) - vector.new(0, 0.5 + box[2], 0))
    player:set_look_vertical(0)
    player:set_look_horizontal(vector.dir_to_rotation(vector.new(1, 0, 1):normalize()).y)
end

minetest.register_on_newplayer(function(player)
    set_checkpoint(player, shared.checkpoints[1])
    place(player)
end)

local function fail(player)
    shared.message(player, t("You have failed."))
    place(player)
end

minetest.register_globalstep(function()
    local players = minetest.get_connected_players()
    local checkpoints = shared.checkpoints

    for _, player in ipairs(players) do
        local p_pos = player:get_pos()
        local p_box = player:get_properties().collisionbox

        local a = {
            min = {x = p_pos.x + p_box[1], y = p_pos.y + p_box[2], z = p_pos.z + p_box[3]},
            max = {x = p_pos.x + p_box[4], y = p_pos.y + p_box[5], z = p_pos.z + p_box[6]},
        }

        for _, checkpoint in ipairs(checkpoints) do
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
            end
        end

        if p_pos.y < -120 then
            fail(player)
        end
    end
end)
