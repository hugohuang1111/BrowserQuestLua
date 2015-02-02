
local Character = import(".Character")
local Mob = class("Mob", Character)

Mob.ANIMATION_IDLE_TIME = 0.8 	-- idle animation frame time
Mob.ANIMATION_MOVE_TIME = 0.8 	-- move animation frame time

Mob.ANCHOR = cc.p(0.5, 0.5)

function Mob:ctor(args)
	Mob.super.ctor(self, args)

	self.aggroRange = 1
    self.isAggressive = true
    self.moveSpeed = 200
    self.atkSpeed = 100
    self.idleSpeed = 800
    self.walkSpeed = 200
end

return Mob
