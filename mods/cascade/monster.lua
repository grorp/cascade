local shared = ...

local Monster = {
    initial_properties = {
        visual = "cube",
        visual_size = vector.new(2.75, 2.75, 2.75),
        textures = {
            "cascade_monster_top.png",    "cascade_monster_top.png",
            "cascade_monster_side_1.png", "cascade_monster_side_2.png",
            "cascade_monster_side_3.png", "cascade_monster_side_4.png",
        },

        pointable = false,
        physical = true,
        collisionbox = {-1.375, -1.375, -1.375, 1.375, 1.375, 1.375},
    },
}

function Monster:on_activate()
    self.object:set_armor_groups({
        immortal = 1,
    })
end

local gravity = vector.new(0, -9.81, 0)

function Monster:on_step(dtime, moveresult)
    self.object:add_velocity(gravity * dtime)

    local target

    local candidates = minetest.get_objects_inside_radius(self.object:get_pos(), 50)
    for _, candidate in pairs(candidates) do
        if candidate:is_player() and (not target or
            vector.distance(self.object.get_pos(), candidate.get_pos()) <
            vector.distance(self.object.get_pos(), target.get_pos())
        ) then
            target = candidate
        end
    end

    if target then
        local attack_dir = vector.direction(self.object:get_pos(), target:get_pos())
        attack_dir.y = 0
        attack_dir = attack_dir:normalize()
        self.object:add_velocity(attack_dir * 5 * dtime)

        for _, collision in ipairs(moveresult.collisions) do
            if collision.type == "object" and collision.object == target then
                shared.fail(target)
                break
            end
        end
    end
end

minetest.register_entity("cascade:monster", Monster)
