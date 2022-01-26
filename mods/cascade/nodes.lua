minetest.register_node("cascade:floor", {
    tiles = {"cascade_floor.png"},
})

minetest.register_node("cascade:floor_broken", {
    tiles = {"cascade_floor_broken.png"},
})

minetest.register_node("cascade:wall", {
    tiles = {"cascade_wall.png"},
})

minetest.register_node("cascade:wall_broken", {
    tiles = {"cascade_wall_broken.png"},
})

minetest.register_node("cascade:invisible", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,

    pointable = false,
    walkable = true,
})
