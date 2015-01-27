
local Entity = import(".Entity")
local Character = class("Character", Entity)

function Character:ctor(args)
	self.super.ctor(self, args)
end

function Character:setAttackSpeed(speed)
	self.atkSpeed_ = speed
end

function Character:setWalkSpeed(speed)
	self.walkSpeed_ = speed
end

return Character
