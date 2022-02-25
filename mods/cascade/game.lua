local shared = ...

local t = minetest.get_translator("cascade")
local f = minetest.formspec_escape

local checkpoints_cached
local checkpoints = function()
    if not checkpoints_cached then
        checkpoints_cached = minetest.deserialize(shared.storage:get_string("checkpoints"))
    end
    return checkpoints_cached
end

local function set_checkpoint(player, checkpoint)
    local meta = player:get_meta()
    meta:set_string("checkpoint", minetest.serialize(checkpoint))
end

local function get_checkpoint(player)
    local meta = player:get_meta()
    return minetest.deserialize(meta:get_string("checkpoint"))
end

local function place(player)
    player:set_pos(get_checkpoint(player) + vector.new(0, -0.5 + 0.875, 0))
end

minetest.register_on_newplayer(function(player)
    local checkpoints = checkpoints()

    set_checkpoint(player, checkpoints[1])
    place(player)
end)

local function fail(player)
    local meta = player:get_meta()

    if meta:get_int("failed") == 0 then
        minetest.show_formspec(
            player:get_player_name(),
            "cascade:fail",
            "formspec_version[5]" ..
            "size[5,2.25]" ..
            "label[0.5, 0.625;" .. f(t("You have failed.")) .. "]" ..
            "button_exit[0.5,1.25;4,0.5;;" .. f(t("Try again")) .. "]"
        )
        meta:set_int("failed", 1)
    end
end

local function win()
    if shared.storage:get_int("won") == 0 then
        local players = minetest.get_connected_players()

        for _, player in pairs(players) do
            minetest.show_formspec(
                player:get_player_name(),
                "cascade:win",
                "formspec_version[5]" ..
                "size[5,2.25]" ..
                "label[0.5, 0.625;" .. f(t("You have made it!")) .. "]" ..
                "button_exit[0.5,1.25;4,0.5;;" .. f(t("Bye...")) .. "]"
            )
        end
        shared.storage:set_int("won", 1)
    end
end

minetest.register_on_player_receive_fields(function(player, formspec_name, formspec_fields)
    if formspec_name == "cascade:fail" and formspec_fields.quit then
        local meta = player:get_meta()

        if meta:get_int("failed") == 1 then
            place(player)
            meta:set_int("failed", 0)
        end
    end

    if formspec_name == "cascade:win" and formspec_fields.quit then
        if shared.storage:get_int("won") == 1 then
            minetest.disconnect_player(player:get_player_name(), t("N/A."))
        end
    end
end)

minetest.register_on_joinplayer(function(player)
    if shared.storage:get_int("won") == 1 then
        minetest.disconnect_player(player:get_player_name(), t("N/A."))
    end
end)

minetest.register_globalstep(function()
    local players = minetest.get_connected_players()

    if #players > 0 then
        local checkpoints = checkpoints()

        for _, checkpoint in pairs(checkpoints) do 
            for _, player in pairs(players) do
                if vector.distance(player:get_pos(), checkpoint) <= 2 then
                    set_checkpoint(player, checkpoint)
                end
            end
        end

        local do_win = true
        local last_checkpoint = checkpoints[#checkpoints]

        for _, player in pairs(players) do
            if vector.distance(player:get_pos(), last_checkpoint) > 2 then
                do_win = false
            end

            if player:get_pos().y < -100 then
                fail(player)
            end
        end

        if do_win then
            win()
        end
    end
end)
