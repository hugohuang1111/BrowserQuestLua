
local Character = import(".Character")
local Mob = class("Mob", Character)

function Mob:ctor(args)
	Mob.super.ctor(self, args)

	self.aggroRange = 1
    slef.isAggressive = true
    slef.moveSpeed = 200
    slef.atkSpeed = 100
    slef.idleSpeed = 800
    slef.walkSpeed = 200
end

return Mob
