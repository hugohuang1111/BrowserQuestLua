
local Entity = import(".Entity")
local Orientation = import(".Orientation")
local Utilitys = import(".Utilitys")
local Character = class("Character", Entity)

Character.MOVE_STEP_TIME = 0.3

Character.PATH_FINISH = "pathingFinish"

function Character:ctor(args)
	Character.super.ctor(self, args)
	self.orientation_ = Orientation.DOWN
	self.path_ = {}
end

function Character:bindStateMachine()
	self.fsm_ = {}
	cc.load("statemachine")
	cc.bind(self.fsm_, "statemachine")

	local args = {
		event = {
			{name = "none", }
	}
}
end

function Character:setAttackSpeed(speed)
	self.atkSpeed_ = speed
end

function Character:setWalkSpeed(speed)
	self.walkSpeed_ = speed
end

function Character:walkTo(pos)
	if not pos then
		return
	end

	local orientation = Utilitys.getOrientation(self.curPos_, pos)
	if not orientation then
		-- the same, needn't walk
		print("Character:walkTo is same")
		return
	end

	self:walkStep(orientation)
end

function Character:walkPath(path)
	if path[1].x == self.curPos_.x and path[1].y == self.curPos_.y then
		table.remove(path, 1)
	end

	if #path < 1 then
		return
	end

	self.path_ = path

	if not self.isWalking_ then
		self:walkTo(table.remove(self.path_, 1))
	end
end

function Character:walkStep(dir, step)
	if self.isWalking_ then
		printInfo("Entity:walkStep is walking just return")
		return
	end

	local pos
	local cur = clone(self.curPos_)
	step = step or 1
	if Orientation.UP == dir then
		cur.y = cur.y - step
	elseif Orientation.DOWN == dir then
		cur.y = cur.y + step
	elseif Orientation.LEFT == dir then
		cur.x = cur.x - step
	elseif Orientation.RIGHT == dir then
		cur.x = cur.x + step
	end

	-- TODO check the cur pos is valid

	pos = cur
	local args = Utilitys.pos2px(pos)
	args.time = Character.MOVE_STEP_TIME * step
	args.onComplete = handler(self, self.onWalkStepComplete_)
	self.curPos_ = pos
	self.isWalking_ = true
	self.view_:moveTo(args)
	self:playWalk(dir)
end

function Character:onWalkStepComplete_()
	self.isWalking_ = false

	if 0 == #self.path_ then
		if self.onPathingFinish_ then
			self.onPathingFinish_()
		end
		self:playIdle()
	else
		self:walkTo(table.remove(self.path_, 1))
	end
end

function Character:onPathingFinish(callback)
	self.onPathingFinish_ = self.onPathingFinish_ or {}
	self.onPathingFinish_ = callback
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

function Character:fllow(entity)
	self.fllowEntity_ = entity
	local pos = entity:getMapPos()
	local path = Game:findPath(pos)
	self.walkPath(path)

	entity:on(Character.PATH_FINISH, function(event)
		self:fllow(event.target)
	end)
end

function Character:lookAt(entity)
	if not self.isWalking_ then
	end

	local orientation = Utilitys.getOrientation(self.curPos_, entity:getMapPos())
	self:playIdle(orientation)
end


return Character
