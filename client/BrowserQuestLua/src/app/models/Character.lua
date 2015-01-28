
local Entity = import(".Entity")
local Orientation = import(".Orientation")
local Utilitys = import(".Utilitys")
local Character = class("Character", Entity)

function Character:ctor(args)
	Character.super.ctor(self, args)
	self.orientation_ = Orientation.DOWN
	self.path_ = {}
end

function Character:setAttackSpeed(speed)
	self.atkSpeed_ = speed
end

function Character:setWalkSpeed(speed)
	self.walkSpeed_ = speed
end

function Character:walkTo()

end

function Character:walkStep(dir)
	if self.isWalking then
		printInfo("Entity:walkStep is walking just return")
		return
	end

	local pos
	local cur = clone(self.curPos_)
	if Orientation.UP == dir then
		cur.y = cur.y - 1
	elseif Orientation.DOWN == dir then
		cur.y = cur.y + 1
	elseif Orientation.LEFT == dir then
		cur.x = cur.x - 1
	elseif Orientation.RIGHT == dir then
		cur.x = cur.x + 1
	end

	-- TODO check the cur pos is valid

	pos = cur
	local args = Utilitys.pos2px(pos)
	args.time = Entity.ANIMATION_DELAY
	args.onComplete = function()
		self.isWalking = false
		self:playIdle()
	end
	self.curPos_ = pos
	self.isWalking = true
	self.view_:moveTo(args)
	self:playWalk(dir)
end

function Character:playWalk(orientation)
	orientation = orientation or self.orientation_
	self.orientation_ = orientation
	if Orientation.UP == orientation then
		self:play("walk_up")
	elseif Orientation.DOWN == orientation then
		self:play("walk_down")
	elseif Orientation.LEFT == orientation then
		self:play("walk_left")
	elseif Orientation.RIGHT == orientation then
		self:play("walk_right")
	end
end

function Character:playIdle(orientation)
	orientation = orientation or self.orientation_
	if Orientation.UP == orientation then
		self:play("idle_up")
	elseif Orientation.DOWN == orientation then
		self:play("idle_down")
	elseif Orientation.LEFT == orientation then
		self:play("idle_left")
	elseif Orientation.RIGHT == orientation then
		self:play("idle_right")
	end
end

return Character
