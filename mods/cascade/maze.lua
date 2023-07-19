local shared = ...

minetest.set_mapgen_setting("mg_name", "singlenode", true)
minetest.set_mapgen_setting("mg_flags", "nocaves, nodungeons, light, nodecorations, nobiomes, noores", true)
minetest.register_alias_force("mapgen_singlenode", "air")

local stone_sounds = {
    footstep = {name = "default_hard_footstep", gain = 0.2},
}
local glass_sounds = {
    footstep = {name = "default_glass_footstep", gain = 0.2},
}

minetest.register_node("cascade:floor", {
    tiles = {"cascade_floor.png"},
    pointable = false,
    sounds = stone_sounds,
})

minetest.register_node("cascade:wall", {
    tiles = {"cascade_wall.png"},
    pointable = false,
    sounds = stone_sounds,
})

minetest.register_node("cascade:wall_invisible", {
    drawtype = "airlike",
    pointable = false,
    paramtype = "light",
    sunlight_propagates = true,
    sounds = glass_sounds,
})

local function cell_to_string(cell)
    return cell.x .. "," .. cell.y
end

-- https://weblog.jamisbuck.org/2011/1/17/maze-generation-aldous-broder-algorithm
local function generate_maze(size)
    local ways = {}

    local cell = {x = math.random(size.x), y = math.random(size.y)}
    local done_cells = {[cell_to_string(cell)] = true}
    local num_cells_remaining = size.x * size.y - 1

    local dirs = {
        {x = 1, y = 0},
        {x = -1, y = 0},
        {x = 0, y = 1},
        {x = 0, y = -1},
    }

    while num_cells_remaining > 0 do
        local next_cell

        -- https://bost.ocks.org/mike/shuffle/
        -- https://stackoverflow.com/a/68486276
        for i = #dirs, 2, -1 do
            local j = math.random(i)
            dirs[i], dirs[j] = dirs[j], dirs[i]
        end

        for _, dir in ipairs(dirs) do
            next_cell = {x = cell.x + dir.x, y = cell.y + dir.y}
            if (
                next_cell.x >= 1 and next_cell.x <= size.x and
                next_cell.y >= 1 and next_cell.y <= size.y
            ) then
                break
            end
        end

        if not done_cells[cell_to_string(next_cell)] then
            ways[#ways + 1] = {cell, next_cell}

            done_cells[cell_to_string(next_cell)] = true
            num_cells_remaining = num_cells_remaining - 1
        end

        cell = next_cell
    end

    return ways
end

local WALLS = {
    NO_WALLS = 1,
    OUTER_WALLS = 2,
    ALL_WALLS = 3,
}

local function write_maze(pos_min, pos_max, walls, num_monsters, ref_monster_positions)
    local vm = VoxelManip()
    local vm_pos_min, vm_pos_max = vm:read_from_map(pos_min, pos_max)
    local vm_data = vm:get_data()
    local vm_area = VoxelArea:new({MinEdge = vm_pos_min, MaxEdge = vm_pos_max})

    local vm_data_new = {}
    for index in ipairs(vm_data) do
        vm_data_new[index] = vm_data[index]
    end

    local function reset(x, y, z)
        local index = vm_area:index(x, y, z)
        vm_data_new[index] = vm_data[index]
    end

    local id_floor = minetest.get_content_id("cascade:floor")

    local function floor(x, y, z)
        local index = vm_area:index(x, y, z)
        vm_data_new[index] = id_floor
    end

    for x = pos_min.x, pos_max.x do
        for z = pos_min.z, pos_max.z do
            floor(x, pos_min.y, z)
        end
    end

    local size_cells = {
        x = (pos_max.x - pos_min.x) / 4,
        y = (pos_max.z - pos_min.z) / 4,
    }

    local id_wall = minetest.get_content_id("cascade:wall")
    local id_wall_invisible = minetest.get_content_id("cascade:wall_invisible")

    local function wall(x, y, z)
        local index = vm_area:index(x, y, z)
        if y <= pos_min.y + 4 then
            vm_data_new[index] = id_wall
        else
            vm_data_new[index] = id_wall_invisible
        end
    end

    if walls == WALLS.OUTER_WALLS then
        for y = pos_min.y + 1, pos_max.y do
            for x = pos_min.x, pos_max.x do
                wall(x, y, pos_min.z)
                wall(x, y, pos_max.z)
            end
            for z = pos_min.z, pos_max.z do
                wall(pos_min.z, y, z)
                wall(pos_max.z, y, z)
            end
        end
    end

    if walls == WALLS.ALL_WALLS then
        for x = pos_min.x, pos_max.x - 4, 4 do
            for z = pos_min.z, pos_max.z - 4, 4 do
                for y = pos_min.y + 1, pos_max.y do
                    wall(x, y, z)

                    wall(x + 1, y, z)
                    wall(x + 2, y, z)
                    wall(x + 3, y, z)

                    wall(x, y, z + 1)
                    wall(x, y, z + 2)
                    wall(x, y, z + 3)
                end
            end
        end

        for y = pos_min.y + 1, pos_max.y do
            for x = pos_min.x, pos_max.x do
                wall(x, y, pos_max.z)
            end
            for z = pos_min.z, pos_max.z do
                wall(pos_max.x, y, z)
            end
        end

        local ways = generate_maze(size_cells)

        for _, way in ipairs(ways) do
            local middle_x = (
                pos_min.x + (way[1].x - 1) * 4 + 2 +
                pos_min.x + (way[2].x - 1) * 4 + 2
            ) / 2
            local middle_z = (
                pos_min.z + (way[1].y - 1) * 4 + 2 +
                pos_min.z + (way[2].y - 1) * 4 + 2
            ) / 2

            for y = pos_min.y + 1, pos_max.y do
                reset(middle_x, y, middle_z)

                reset(middle_x - 1, y, middle_z)
                reset(middle_x + 1, y, middle_z)

                reset(middle_x, y, middle_z - 1)
                reset(middle_x, y, middle_z + 1)
            end
        end
    end

    if walls == WALLS.OUTER_WALLS or walls == WALLS.ALL_WALLS then
        for y = pos_min.y + 1, pos_max.y do
            for x = pos_max.x - 3, pos_max.x do
                reset(x, y, pos_max.z)
            end
            for z = pos_max.z - 3, pos_max.z do
                reset(pos_max.x, y, z)
            end
        end

        for y = pos_min.y + 5, pos_max.y do
            for x = pos_min.x, pos_min.x + 3 do
                reset(x, y, pos_min.z)
            end
            for z = pos_min.z, pos_min.z + 3 do
                reset(pos_min.x, y, z)
            end
        end

    end

    if num_monsters > 0 then
        local occupied_cells = {}

        local function is_cell_free(cell)
            for _, ocell in ipairs(occupied_cells) do
                if cell.x == ocell.x and cell.y == ocell.y then
                    return false
                end
            end
            return true
        end

        for _ = 1, num_monsters do
            local cell
            repeat
                cell = {x = math.random(size_cells.x), y = math.random(size_cells.y)}
            until is_cell_free(cell)
            table.insert(occupied_cells, cell)

            local world_pos = pos_min + vector.new(
                (cell.x - 1) * 4 + 2,
                0.5 + 22/16,
                (cell.y - 1) * 4 + 2
            )
            ref_monster_positions[world_pos:to_string()] = world_pos
        end
    end

    vm:set_data(vm_data_new)
    vm:write_to_map()
end

local function make_maze(pos, size, walls, num_monsters, ref_monster_positions, ref_checkpoints)
    local pos_min = pos
    local pos_max = pos + vector.new(size * 4, 19, size * 4)

    write_maze(
        pos_min,
        pos_max,
        walls,
        num_monsters,
        ref_monster_positions
    )

    table.insert(ref_checkpoints, vector.new(pos_max.x - 2, pos_min.y + 1, pos_max.z - 2))

    local next_pos = pos + vector.new(size * 4, -15, size * 4)
    return next_pos
end

local function make_initial_maze()
    shared.monster_positions = {}
    shared.checkpoints = {}

    local pos = make_maze(vector.zero(), 1, WALLS.NO_WALLS, 0,
            shared.monster_positions, shared.checkpoints)

    shared.next_maze = {
        pos = pos,
        size = 4,
    }
end

function shared.make_next_maze()
    -- This function may only be called if `shared.next_maze` is not nil.
    assert(shared.next_maze)
    assert(shared.monster_positions)
    assert(shared.checkpoints)

    local data = shared.next_maze
    local num_monsters = math.round((data.size * data.size) / (5 * 5))

    data.pos = make_maze(data.pos, data.size, WALLS.ALL_WALLS, num_monsters,
            shared.monster_positions, shared.checkpoints)

    data.size = data.size + 2
end

function shared.save()
    -- `shared.next_maze` can be nil if the world was created with an old version
    -- of Cascade.
    -- assert(shared.next_maze)
    assert(shared.monster_positions)
    assert(shared.checkpoints)

    shared.storage:set_string("next_maze",         minetest.serialize(shared.next_maze))
    shared.storage:set_string("monster_positions", minetest.serialize(shared.monster_positions))
    shared.storage:set_string("checkpoints",       minetest.serialize(shared.checkpoints))
end

if shared.storage:get_int("generated") ~= 1 then
    minetest.after(0, function()
        make_initial_maze()
        shared.save()
        shared.storage:set_int("generated", 1)
    end)
else
    -- `next_maze` can be nil if the world was created with an old version of
    -- Cascade, but nothing special is needed here because of that. The rest
    -- of the game can handle `shared.next_maze` being nil.
    shared.next_maze         = minetest.deserialize(shared.storage:get_string("next_maze"))
    -- `monster_positions` can be nil if the world was created with an old version
    -- of Cascade. Fall back to an empty table.
    shared.monster_positions = minetest.deserialize(shared.storage:get_string("monster_positions")) or {}
    shared.checkpoints       = minetest.deserialize(shared.storage:get_string("checkpoints"))
end
