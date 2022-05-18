local shared = {}
shared.storage = minetest.get_mod_storage()

loadfile(minetest.get_modpath("cascade") .. "/environment.lua")(shared)
loadfile(minetest.get_modpath("cascade") .. "/maze.lua")(shared)
loadfile(minetest.get_modpath("cascade") .. "/player.lua")(shared)
loadfile(minetest.get_modpath("cascade") .. "/game.lua")(shared)
