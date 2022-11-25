local debug = {}

local map_id_to_obj = {}

minetest.register_entity("cascade:visual_aabb", {
    initial_properties = {
        visual = "cube",
        textures = {
            "cascade_debug.png", "cascade_debug.png",
            "cascade_debug.png", "cascade_debug.png",
            "cascade_debug.png", "cascade_debug.png",
        },
        pointable = false,
        physical = false,
        static_save = false,
    },

    on_deactivate = function(self)
        map_id_to_obj[self.id] = nil
    end,
})

function debug.visualize_aabb(id, box)
    local sbox_min, sbox_max = vector.sort(box.min, box.max)
    if not sbox_min:equals(box.min) or not sbox_max:equals(box.max) then
        error("GOT BROKEN AABB 😡")
    end
    local box_center = (box.min + box.max) / 2
    local box_size = box.max - box.min

    local old_obj = map_id_to_obj[id]

    if not old_obj then
        local obj = minetest.add_entity(box_center, "cascade:visual_aabb")
        obj:set_properties({ visual_size = box_size })
        obj:get_luaentity().id = id
        map_id_to_obj[id] = obj
    else
        old_obj:set_pos(box_center)
        old_obj:set_properties({ visual_size = box_size })
    end
end

return debug
