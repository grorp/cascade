cascade = {}
cascade.storage = minetest.get_mod_storage()

dofile(minetest.get_modpath("cascade") .. "/maze.lua")
dofile(minetest.get_modpath("cascade") .. "/player.lua")
dofile(minetest.get_modpath("cascade") .. "/game.lua")
