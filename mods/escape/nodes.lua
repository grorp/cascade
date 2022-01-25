minetest.register_node("escape:floor", {
    tiles = {"escape_floor.png"},
})

minetest.register_node("escape:floor_broken", {
    tiles = {"escape_floor_broken.png"},
})

minetest.register_node("escape:wall", {
    tiles = {"escape_wall.png"},
})

minetest.register_node("escape:wall_broken", {
    tiles = {"escape_wall_broken.png"},
})

minetest.register_node("escape:invisible", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    pointable = false,
})
