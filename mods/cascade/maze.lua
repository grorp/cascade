local shared = ...

minetest.set_mapgen_setting("mg_name", "singlenode", true)
minetest.set_mapgen_setting("mg_flags", "nobiomes, nocaves, nodecorations, nodungeons, light, noores", true)
minetest.register_alias_force("mapgen_singlenode", "air")

minetest.register_node("cascade:floor", {
    tiles = {"cascade_floor.png"},
    pointable = false,
})

minetest.register_node("cascade:wall", {
    tiles = {"cascade_wall.png"},
    pointable = false,
})

minetest.register_node("cascade:wall_invisible", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    pointable = false,
})

local function cell_to_string(cell)
    return tostring(cell.x) .. "," .. tostring(cell.y)
end

-- https://weblog.jamisbuck.org/2011/1/17/maze-generation-aldous-broder-algorithm
local function generate_maze(size)
    local ways = {}

    local cell = {x = math.random(1, size.x), y = math.random(1, size.y)}
    local done = {}
    done[cell_to_string(cell)] = true
    local remaining_count = size.x * size.y - 1

    local dirs = {
        {x = 1, y = 0},
        {x = -1, y = 0},
        {x = 0, y = 1},
        {x = 0, y = -1},
    }

    while remaining_count > 0 do
        local next_cell

        -- https://bost.ocks.org/mike/shuffle/
        for i = #dirs, 2, -1 do
            local j = math.random(1, i)
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

        if not done[cell_to_string(next_cell)] then
            ways[#ways + 1] = {cell, next_cell}

            done[cell_to_string(next_cell)] = true
            remaining_count = remaining_count - 1
        end

        cell = next_cell
    end

    return ways
end

local function write_maze(pos_min, pos_max, walls)
    local vm = minetest.get_voxel_manip()
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

    if walls then
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

        for y = pos_min.y + 5, pos_max.y do
            for x = pos_min.x, pos_min.x + 3 do
                reset(x, y, pos_min.z)
            end
            for z = pos_min.z, pos_min.z + 3 do
                reset(pos_min.x, y, z)
            end
        end

        local ways = generate_maze(
            {x = (pos_max.x - pos_min.x) / 4, y = (pos_max.z - pos_min.z) / 4}
        )

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

        for y = pos_min.y + 1, pos_max.y do
            for x = pos_max.x - 3, pos_max.x do
                reset(x, y, pos_max.z)
            end
            for z = pos_max.z - 3, pos_max.z do
                reset(pos_max.x, y, z)
            end
        end
    end

    vm:set_data(vm_data_new)
    vm:write_to_map()
end

if shared.storage:get_int("generated") ~= 1 then
    minetest.after(0, function()
        local checkpoints = {}

        local pos = vector.zero()

        local mazes = {
            {1, false},

            {6, true},
            {9, true},
            {12, true},
            {15, true},

            {1, false},
        }

        for _, maze in ipairs(mazes) do
            local size, walls = maze[1], maze[2]

            local pos_min = pos
            local pos_max = pos + vector.new(size * 4, 19, size * 4)

            write_maze(
                pos_min,
                pos_max,
                walls
            )
            checkpoints[#checkpoints + 1] = vector.new(
                pos_max.x - 2, pos_min.y + 1, pos_max.z - 2
            )

            pos = pos + vector.new(size * 4, -15, size * 4)
        end

        shared.checkpoints = checkpoints
        shared.storage:set_string("checkpoints", minetest.serialize(checkpoints))
        shared.storage:set_int("generated", 1)
    end)
else
    shared.checkpoints = minetest.deserialize(shared.storage:get_string("checkpoints"))
end
