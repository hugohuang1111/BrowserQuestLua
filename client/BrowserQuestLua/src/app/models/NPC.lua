
local Character = import(".Character")
local NPC = class("NPC", Character)

NPC.ANIMATION_IDLE_TIME = 0.5 	-- idle animation frame time
NPC.ANIMATION_MOVE_TIME = 0.8 	-- move animation frame time

NPC.ANCHOR = cc.p(0.5, 0.4)

function NPC:ctor(args)
	NPC.super.ctor(self, args)

	self.aggroRange = 1
    self.isAggressive = true
    self.moveSpeed = 200
    self.atkSpeed = 100
    self.idleSpeed = 800
    self.walkSpeed = 200
end

return NPC
