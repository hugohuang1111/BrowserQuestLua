
local Entity = import(".Entity")
local Orientation = import(".Orientation")
local Utilitys = import(".Utilitys")
local Character = class("Character", Entity)
local Schedule = cc.Director:getInstance():getScheduler()

Character.MOVE_STEP_TIME = 0.3
Character.COOL_DOWN_TIME = Character.ANIMATION_ATK_TIME * 4 + 0.3

Character.PATH_FINISH = "pathingFinish"

Character.VIEW_TAG_TALK = 103

Character.INVALID_DISTANCE = 10000

function Character:ctor(args)
	local sm = cc.load("statemachine")
	args.states = {
		events = {
			{name = "born",		from = "none",   		to = "idle" },
			{name = "move",		from = {"idle", "walk"},to = "walk" },
			{name = "attack",	from = "idle",   		to = "atk" },
			{name = "stop",		from = {"walk", "atk"}, to = "idle" },
			{name = "kill",   	from = sm.WILDCARD,   	to = "death" }
		}
	}
	
	self.orientation_ = args.orientation or Orientation.DOWN
	self.path_ = {}
	self.fllowHandler_ = {}
	self.sentences_ = args.sentences or {"hi, welcome to browser quest! -- from Quick Team"}
	self.showSentenceIdx_ = 1
	Character.super.ctor(self, args)
end

function Character:doEvent(eventName, orientation)
	if self.fsm_:canDoEvent(eventName) then

		self.orientation_ = orientation or self.orientation_
		self.fsm_:doEvent(eventName)
	end
end

function Character:onAfterEvent(event)
	Entity.onAfterEvent(self, event)

	if "walk" == event.to then
		self:dispatchEvent({name = "move"})
		self:playWalk(self.orientation_)
	elseif "atk" == event.to then
		self:playAtk()
	end
end

function Character:setOrientation(orientation)
	orientation = orientation or Orientation.DOWN
	if self.orientation_ ~= orientation then
		self:sendInfoToServer()
	end
	self.orientation_ = orientation
end

function Character:setAttackSpeed(speed)
	self.atkSpeed_ = speed
end

function Character:setWalkSpeed(speed)
	self.walkSpeed_ = speed
end

function Character:setAttackEntity(entity)
	if self.attackEntity_ == entity then
		printInfo("Character:setAttackEntity entity is same")
		return
	end

	if self.attackEntity_ then
		self.attackEntity_:removeEventListenersByTag(self.id)
	end

	self.attackEntity_ = entity

	self.attackEntity_:on("death",
		function()
			Utilitys.invokeFuncASync(handler(self, self.cancelAttack))
			return true
		end, self.id)
	self.attackEntity_:on("move",
		function()
			Utilitys.invokeFuncASync(handler(self, self.cancelAttack))
			return true
		end, self.id)
	self.attackEntity_:on("exit",
		function()
			Utilitys.invokeFuncASync(handler(self, self.cancelAttack))
			return true
		end, self.id)
end

function Character:getAttackEntity()
	return self.attackEntity_
end

function Character:setTalkEntity(entity)
	self.talkEntity_ = entity
end

function Character:setLootEntity(entity)
	self.lootEntity_ = entity
end

function Character:sendInfoToServer()
	if 0 == self.id then
		return
	end

	Game:sendCmd("user.info",
		{id = self.id,
		pos = self.curPos_,
		orientation = self.orientation_})
end

function Character:walk(pos)
	local path = Game:findPath(pos, self.curPos_)
	self:walkPath(path)
	self.fllowEntity_ = nil
end

function Character:walkToPosReq(destPos, origPos)
	Game:sendCmd("user.move", {id = self.id, from = origPos, to = destPos})
end

function Character:walkToPos(destPos, origPos)
	if origPos then
		printInfo("Character:walkToPos (%d,%d) to (%d,%d)", origPos.x or 0, origPos.y or 0, destPos.x, destPos.y)
	else
		printInfo("Character:walkToPos current Position to (%d,%d)", destPos.x, destPos.y)
	end

	self:setMapPos(origPos)
	local path = Game:findPath(destPos, self.curPos_)
	self:walkPath(path)
end

function Character:fllow(entity)
	self.fllowEntity_ = entity or self.fllowEntity_

	if not self.fllowEntity_ then
		printInfo("id %d fllow nil", self.id)
		return
	end

	printInfo("Character %d fllow %d", self.id, self.fllowEntity_.id)

	self.fllowEntity_:on("death",
		function()
			self:cancelFllow()
			printInfo("Character fllow is death %d", self.id)
			self:doEvent("stop")
			return true
		end, self.id)
	self.fllowEntity_:on("move",
		function()
			self:cancelFllow()
			return true
		end, self.id)
	self.fllowEntity_:on("exit",
		function()
			printInfo("Character fllow is exit %d", self.id)
			self:cancelFllow()
			return true
		end, self.id)

	if self:distanceWith(self.fllowEntity_) > 1 then
		local pos = self.fllowEntity_:getMapPos()
		self:walkToPosReq(pos)
	end

end

function Character:cancelFllow()
	self:cancelAttackReqAuto()
	if not self.fllowEntity_ then
		return
	end
	local fllowEntity = self.fllowEntity_
	self.fllowEntity_:removeEventListenersByTag(self.id)
	self.fllowEntity_ = nil

	fllowEntity:cancelFllow()
end

function Character:lookAt(entity)
	if not self.isWalking_ then
	end

	local orientation = Utilitys.getOrientation(self.curPos_, entity:getMapPos())
	self.orientation_ = orientation or self.orientation_
end

function Character:getStateByOrientation(state)
	local pos = string.find(state, "_")
	local newState = state
	if not pos and "death" ~= newState then
		if Orientation.DOWN == self.orientation_ then
			newState = newState .. "_down"
		elseif Orientation.UP == self.orientation_ then
			newState = newState .. "_up"
		elseif Orientation.LEFT == self.orientation_ then
			newState = newState .. "_left"
		elseif Orientation.RIGHT == self.orientation_ then
			newState = newState .. "_right"
		end
	end

	return newState
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
	if not path then
		printInfo("Character:walkPath path is nil")
		return
	end

	if path[1].x == self.curPos_.x and path[1].y == self.curPos_.y then
		table.remove(path, 1)
	end

	if #path < 1 then
		printInfo("Character:walkPath path length is 0")
		return
	end

	self.path_ = path

	if not self.isWalking_ then
		self:walkTo(table.remove(self.path_, 1))
	end
end

function Character:walkStep(dir, step)
	if self.isWalking_ then
		printInfo("Character:walkStep is walking just return")
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

	pos = cur
	local origin = self.curPos_
	local destination = pos

	local args = Utilitys.pos2px(pos)
	args.time = Character.MOVE_STEP_TIME * step
	args.onComplete = handler(self, self.onWalkStepComplete_)
	self.curPos_ = pos
	self.isWalking_ = true
	self.view_:moveTo(args)

	self:doEvent("move", dir)
end

function Character:onWalkStepComplete_()
	self.isWalking_ = false

	printInfo("Character:onWalkStepComplete_ %d path count:%d", self.id, #self.path_)
	if 0 == #self.path_ then
		self:doEvent("stop")

		if Game:isSelf(self) then
			self:sendInfoToServer()
		end
		if 1 == self:distanceWith(self.attackEntity_) then
			self:attackReqAuto()
		elseif 1 == self:distanceWith(self.talkEntity_) then
			self:talk()
		elseif 1 == self:distanceWith(self.lootEntity_) then
			self:lootItemReq()
		end
	else
		self:walkTo(table.remove(self.path_, 1))
	end
end

function Character:playWalk(orientation)
	printInfo("Character play walk")
	local orientation = self.orientation_
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
	local orientation = orientation or self.orientation_
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

function Character:playAtk(orientation)
	local args = {
		isOnce = true,
		onComplete = function()
			self:doEvent("stop")
		end}
	local orientation = orientation or self.orientation_
	if Orientation.UP == orientation then
		self:play("atk_up", args)
	elseif Orientation.DOWN == orientation then
		self:play("atk_down", args)
	elseif Orientation.LEFT == orientation then
		self:play("atk_left", args)
	elseif Orientation.RIGHT == orientation then
		self:play("atk_right", args)
	end

	-- Game:sendCmd("play.attack", {sender = self.id, target = self.attackEntity_:getId()})
end

function Character:stopAtk()
	self:doEvent("stop")
	self.fllowEntity_ = nil
	self.attackEntity_ = nil
end

function Character:playDeath()
	if not Game:isSelf(self) then
		self:setId(0) -- invalid id
	end
	local args = {
		isOnce = true,
		onComplete = function()
			printInfo("Character play death %d", self.id)
			Game:removeEntity(self)
		end}
	self:play("death", args)
	self:cancelFllow()
end

function Character:distanceWith(entity)
	if not entity then
		return Character.INVALID_DISTANCE -- 10000 is bigger than map size
	end

	local disX = math.abs(entity.curPos_.x - self.curPos_.x)
	local disY = math.abs(entity.curPos_.y - self.curPos_.y)

	return disX + disY
end

function Character:attackIf(entity)
	if self.attackHandle_ then
		local id = 0
		if entity then
			id = entity:getId()
		end
		printInfo("Character:attackIf attacking ignore other attacker %d", id)
		return
	end

	self:attack(entity)
end

function Character:attackMoveReq(entity)
	Game:sendCmd("play.attackMove", {sender = self.id, target = entity:getId()})
end

function Character:attackReq()
	if not self.attackEntity_ then
		printInfo("Character:attackReq attackEntity_ is nil %d", self.id)
		return
	end

	local senderId = self.id
	local targetId = self.attackEntity_:getId()
	local userId = Game:getUser():getId()

	if 0 == targetId then
		printInfo("Character:attackReq target is invalid")
		return
	end

	if userId == senderId or userId == targetId then
		Game:sendCmd("user.attack", {sender = senderId, target = targetId})
	else
		printInfo("ERROR Character:attackReq have't userid")
	end
end

function Character:attackReqAuto()
	if self.attackHandle_ then
		return
	end

	local attackHandle = Schedule:scheduleScriptFunc(function()
		self:attackReq()
	end, Character.COOL_DOWN_TIME, false)
	self.attackHandle_ = attackHandle
end

function Character:cancelAttackReqAuto()
	if not self.attackHandle_ then
		return
	end
	Schedule:unscheduleScriptEntry(self.attackHandle_)
	self.attackHandle_ = nil
end

function Character:cancelAttack()
	if not self.attackEntity_ then
		printInfo("Character:cancelAttack attackEntity_ is nil")
		return
	end
	self:cancelAttackReqAuto()
	self:doEvent("stop")
	self.attackEntity_:removeEventListenersByTag(self.id)
	self:cancelAttackReq()
	self.attackEntity_ = nil
end

function Character:cancelAttackReq()
	if not self.attackEntity_ then
		printInfo("Character:cancelAttackReq attackEntity_ is nil %d", self.id)
		return
	end

	local senderId = self.id
	local targetId = self.attackEntity_:getId()
	local userId = Game:getUser():getId()

	if 0 == targetId then
		printInfo("Character:cancelAttackReq target is invalid")
		return
	end

	if userId == senderId or userId == targetId then
		Game:sendCmd("user.cancelAttack", {sender = senderId, target = targetId})
	else
		printInfo("ERROR Character:cancelAttackReq have't userid")
	end
end

function Character:attack(entity)
	self:fllow(entity)
	self.attackEntity_ = entity or self.attackEntity_

	if not self.attackEntity_ then
		printInfo("id %d attackentity is nil", self.id)
		return
	end

	if 1 == self:distanceWith(self.attackEntity_) then
		printInfo("Character attack entity %d, %d", self.id, self.attackEntity_.id)
		if not self.isCoolDown then
			self:attackReqAuto()
		else
			print("Character:attack in cool down time")
		end
	end
end

function Character:talk(entity)
	self:fllow(entity)
	self.talkEntity_ = entity or self.talkEntity_

	if not self.talkEntity_ then
		return
	end
	if 1 == self:distanceWith(self.talkEntity_) then
		self.talkEntity_:talkSentence()
	end
end

function Character:talkSentence(sentence)
	if sentence then
		self:showSentence_(sentence)
	else
		self:showSentence_(self.sentences_[self.showSentenceIdx_])
		self.showSentenceIdx_ = Utilitys.mod(self.showSentenceIdx_ + 1, #self.sentences_)
	end

	self:setDisappearTimer_()
end

function Character:showSentence_(sentence)
	local content
	local idx = string.match(sentence, "emoji:(%d+)")
	if idx then
		content = display.newSprite("emoji/" .. tostring(idx) .. ".jpg")
	else
		local ttfConfig = {
			fontFilePath = "fonts/fzkt.ttf",
			fontSize = 14
			}
		content = cc.Label:createWithTTF(ttfConfig, sentence, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		content:align(display.CENTER)
	end
	local bg = self:getBubble_()
	bg:setOpacity(255)
	bg:removeAllChildren()
	bg:addChild(content)

	local size = content:getContentSize()
	size.width = size.width + 10
	size.height = size.height + 10
	bg:setContentSize(size)
	content:setPosition(cc.p(size.width/2, size.height/2))
end

function Character:disappearSentence_()
	local bubble = self:getBubble_()
	bubble:fadeout({time = 0.5, removeSelf = true})
end

function Character:setDisappearTimer_()
	if self.bubbleAction_ then
		transition.removeAction(self.bubbleAction_)
		self.bubbleAction_ = nil
	end

	local bubble = self:getBubble_()
	local action = transition.fadeOut(bubble, {
		delay = 3,
		time = 0.5,
		onComplete = function()
			bubble:removeAllChildren()
			self.bubbleAction_ = nil
		end
		})
	self.bubbleAction_ = action
end

function Character:getBubble_()
	local bg = self.view_:getChildByTag(Character.VIEW_TAG_TALK)
	if not bg then
		bg = ccui.Scale9Sprite:create("img/common/talkbg.png")
		self.view_:addChild(bg)
		bg:setTag(Character.VIEW_TAG_TALK)
		bg:setPositionY(self.json_.height + 40)
	end

	return bg
end

function Character:showReduceHealth(val)
	printInfo("Character showReduceHealth")
	local ttfConfig = {
		fontFilePath = "fonts/arial.ttf",
		fontSize = 24
		}
	local label = cc.Label:createWithTTF(ttfConfig, tostring(val), cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
	label:setTextColor(cc.c4b(250, 0, 0, 250))

	label:addTo(self.view_)
	label:setPositionY(self.json_.height + 10)

	local time = 1
	local fadeOut = cc.FadeOut:create(time)
	local moveBy = cc.MoveBy:create(time, {y = 20})
	local action = cc.Spawn:create(fadeOut, moveBy)
	label:runAction(action)

	-- remove label after time + 1
	local schedule = cc.Director:getInstance():getScheduler()
	label.handle = schedule:scheduleScriptFunc(function()
		if label.handle then
			schedule:unscheduleScriptEntry(label.handle)
			label.handle = nil
		end
		label:removeSelf()
	end, time + 1, false)

	label:enableNodeEvents()
	label.onExit = function()
		if label.handle then
			schedule:unscheduleScriptEntry(label.handle)
			label.handle = nil
		end
	end
end


return Character
