local shared = {}
shared.storage = minetest.get_mod_storage()

local path = minetest.get_modpath("cascade")
assert(loadfile(path .. "/environment.lua"))(shared)
assert(loadfile(path .. "/maze.lua"))(shared)
assert(loadfile(path .. "/player.lua"))(shared)
assert(loadfile(path .. "/game.lua"))(shared)
