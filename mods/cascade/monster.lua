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

local GRAVITY = vector.new(0, -9.81, 0)
local MAX_TARGET_DISTANCE = 50
local MONSTER_ACCEL = 5
local MONSTER_DECEL = 5

function Monster:on_step(dtime, moveresult)
    self.object:add_velocity(GRAVITY * dtime)

    local target

    local candidates = minetest.get_objects_inside_radius(self.object:get_pos(), MAX_TARGET_DISTANCE)
    for _, candidate in ipairs(candidates) do
        if candidate:is_player() and (not target or
            vector.distance(self.object:get_pos(), candidate:get_pos()) <
            vector.distance(self.object:get_pos(), target:get_pos())
        ) then
            target = candidate
        end
    end

    if target then
        local attack_dir = vector.direction(self.object:get_pos(), target:get_pos())
        attack_dir.y = 0
        attack_dir = attack_dir:normalize()
        self.object:add_velocity(attack_dir * MONSTER_ACCEL * dtime)
    else
        local vel = self.object:get_velocity()
        local decel_dir = vector.new(-vel.x, 0, -vel.z):normalize()
        local decel = decel_dir * MONSTER_DECEL * dtime
        if math.abs(decel.x) > math.abs(vel.x) then
            decel.x = -vel.x
        end
        if math.abs(decel.z) > math.abs(vel.z) then
            decel.z = -vel.z
        end
        self.object:set_velocity(vel + decel)
    end

    for _, collision in ipairs(moveresult.collisions) do
        if collision.type == "object" and collision.object:is_player() then
            shared.player_fail(target)
            break
        end
    end
end

minetest.register_entity("cascade:monster", Monster)
