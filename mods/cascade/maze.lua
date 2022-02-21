minetest.register_node("cascade:floor", {
    tiles = {"cascade_floor.png"},
    pointable = false,
})

minetest.register_node("cascade:floor_broken", {
    tiles = {"cascade_floor_broken.png"},
    pointable = false,
})

minetest.register_node("cascade:wall", {
    tiles = {"cascade_wall.png"},
    pointable = false,
})

minetest.register_node("cascade:wall_broken", {
    tiles = {"cascade_wall_broken.png"},
    pointable = false,
})

minetest.register_node("cascade:wall_invisible", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    pointable = false,
})

-- See https://weblog.jamisbuck.org/2011/1/17/maze-generation-aldous-broder-algorithm.
local function generate_maze(min_cell, max_cell)
    local maze = {}

    local function cell_to_string(cell)
        return tostring(cell.x) .. "," .. tostring(cell.y)
    end

    local cell
    local done_cells = {}
    local remaining_cells = (max_cell.x - min_cell.x + 1) * (max_cell.y - min_cell.y + 1)

    local start_cell = {x = math.random(min_cell.x, max_cell.x), y = math.random(min_cell.y, max_cell.y)}

    cell = start_cell
    done_cells[cell_to_string(start_cell)] = true
    remaining_cells = remaining_cells - 1

    local dirs = {
        {x = 1, y = 0},
        {x = -1, y = 0},
        {x = 0, y = 1},
        {x = 0, y = -1},
    }

    while remaining_cells > 0 do
        -- See https://bost.ocks.org/mike/shuffle/.
        for i = #dirs, 2, -1 do
            local j = math.random(1, i)
            dirs[i], dirs[j] = dirs[j], dirs[i]
        end

        local next_cell
        for _, dir in pairs(dirs) do
            next_cell = {x = cell.x + dir.x, y = cell.y + dir.y}
            if (
                next_cell.x >= min_cell.x and next_cell.y >= min_cell.y and
                next_cell.x <= max_cell.x and next_cell.y <= max_cell.y
            ) then
                break
            end
        end

        if not done_cells[cell_to_string(next_cell)] then
            maze[#maze + 1] = {cell, next_cell}

            done_cells[cell_to_string(next_cell)] = true
            remaining_cells = remaining_cells - 1
        end

        cell = next_cell
    end

    return maze
end

local function write_maze(min_pos, max_pos, walls)
    local vmanip = VoxelManip()
    local vmanip_min_pos, vmanip_max_pos = vmanip:read_from_map(min_pos, max_pos)
    local vmanip_area = VoxelArea:new({MinEdge = vmanip_min_pos, MaxEdge = vmanip_max_pos})
    local vmanip_data = vmanip:get_data()

    local vmanip_data_new = {}
    for index in pairs(vmanip_data) do
        vmanip_data_new[index] = vmanip_data[index]
    end

    local id_floor = minetest.get_content_id("cascade:floor")
    local id_floor_broken = minetest.get_content_id("cascade:floor_broken")

    local function floor(x, y, z)
        vmanip_data_new[vmanip_area:index(x, y, z)] = (
            math.random() < 0.9 and
            id_floor or
            id_floor_broken
        )
    end

    for x = min_pos.x, max_pos.x do
        for z = min_pos.z, max_pos.z do
            floor(x, min_pos.y, z)
        end
    end

    if walls then
        local maze = generate_maze(
            {x = 0, y = 0},
            {x = (max_pos.x - min_pos.x - 4) / 4, y = (max_pos.z - min_pos.z - 4) / 4}
        )

        local id_wall = minetest.get_content_id("cascade:wall")
        local id_wall_broken = minetest.get_content_id("cascade:wall_broken")
        local id_wall_invisible = minetest.get_content_id("cascade:wall_invisible")

        local function wall(x, y, z)
            local id
            if y < min_pos.y + 1 + 3 then
                id = (
                    math.random() < 0.9 and
                    id_wall or
                    id_wall_broken
                )
            else
                id = id_wall_invisible
            end
            vmanip_data_new[vmanip_area:index(x, y, z)] = id
        end

        for x = min_pos.x, max_pos.x - 4, 4 do
            for z = min_pos.z, max_pos.z - 4, 4 do
                for y = min_pos.y + 1, max_pos.y do
                    wall(x, y, z)

                    wall(x, y, z + 1)
                    wall(x, y, z + 2)
                    wall(x, y, z + 3)
            
                    wall(x + 1, y, z)
                    wall(x + 2, y, z)
                    wall(x + 3, y, z)
                end
            end
        end

        for y = min_pos.y + 1, max_pos.y do
            for x = min_pos.x, max_pos.x do
                wall(x, y, max_pos.z)
            end
            for z = min_pos.z, max_pos.z do
                wall(max_pos.x, y, z)
            end
        end

        local function reset(x, y, z)
            local index = vmanip_area:index(x, y, z)
            vmanip_data_new[index] = vmanip_data[index]
        end

        for y = min_pos.y + 1 + 3, max_pos.y do
            for x = min_pos.x, min_pos.x + 3 do
                reset(x, y, min_pos.z)
            end
            for z = min_pos.z, min_pos.z + 3 do
                reset(min_pos.x, y, z)
            end
        end

        for _, way in pairs(maze) do
            local middle_x = (
                min_pos.x + (way[1].x * 4) + (4 / 2) +
                min_pos.x + (way[2].x * 4) + (4 / 2)
            ) / 2
            local middle_z = (
                min_pos.z + (way[1].y * 4) + (4 / 2) +
                min_pos.z + (way[2].y * 4) + (4 / 2)
            ) / 2

            for y = min_pos.y + 1, max_pos.y do
               reset(middle_x, y, middle_z)
            
                reset(middle_x - 1, y, middle_z)
                reset(middle_x + 1, y, middle_z)
            
                reset(middle_x, y, middle_z - 1)
                reset(middle_x, y, middle_z + 1)
            end
        end

        for y = min_pos.y + 1, max_pos.y do
            for x = max_pos.x - 3, max_pos.x do
                reset(x, y, max_pos.z)
            end
            for z = max_pos.z - 3, max_pos.z do
                reset(max_pos.x, y, z)
            end
        end
    end

    vmanip:set_data(vmanip_data_new)
    vmanip:write_to_map()
end

if cascade.storage:get_int("generated") == 0 then
    minetest.after(0, function()
        local checkpoints = {}

        local pos = vector.new(0, 100, 0)

        local mazes = {
            {1, false},

            {5, true},
            {10, true},
            {15, true},
            {20, true},
            {25, true},

            {10, false},

            {1, false},
        }

        for _, maze in pairs(mazes) do
            local size, walls = maze[1], maze[2]

            local min_pos = pos
            local max_pos = pos + vector.new(size * 4, 15, size * 4)

            write_maze(
                min_pos,
                max_pos,
                walls
            )
            checkpoints[#checkpoints + 1] = vector.new(max_pos.x - (4 / 2), min_pos.y + 1, max_pos.z - (4 / 2))

            pos = pos + vector.new(size * 4, -12, size * 4)
        end

        cascade.storage:set_string("checkpoints", minetest.serialize(checkpoints))
        cascade.storage:set_int("generated", 1)
    end)
end
