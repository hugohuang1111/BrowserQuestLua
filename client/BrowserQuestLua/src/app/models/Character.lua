
local Entity = import(".Entity")
local Orientation = import(".Orientation")
local Utilitys = import(".Utilitys")
local Character = class("Character", Entity)
local Schedule = cc.Director:getInstance():getScheduler()

Character.MOVE_STEP_TIME = 0.3
Character.COOL_DOWN_TIME = Character.ANIMATION_ATK_TIME * 4 + 0.3

Character.PATH_FINISH = "pathingFinish"

Character.VIEW_TAG_TALK = 103

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
	
	self.orientation_ = Orientation.DOWN
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
		self:playWalk(self.orientation_)
	elseif "atk" == event.to then
		self:playAtk()
	end
end

function Character:setAttackSpeed(speed)
	self.atkSpeed_ = speed
end

function Character:setWalkSpeed(speed)
	self.walkSpeed_ = speed
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
	Game:sendCmd("play.move", {id = self.id, from = origPos, to = destPos})
end

function Character:walkToPos(destPos, origPos)
	dump(destPos, "Character walkToPos dest:")
	dump(origPos, "Character walkToPos orig:")
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

	self.fllowEntity_:on("death",
		function()
			self:cancelFllow()
			printInfo("Character fllow is death %d", self.id)
			self:doEvent("stop")
			return true
		end, self.id, true)
	-- self.fllowEntity_:on("move",
	-- 	function()
	-- 		if not self.fllowEntity_ then
	-- 			return true
	-- 		end
	-- 		if not Game:isSelf(self) and self:distanceWith(self.fllowEntity_) > 10 then
	-- 			self:cancelFllow()
	-- 		else
	-- 			local pos = self.fllowEntity_:getMapPos()
	-- 			local path = Game:findPath(pos, self.curPos_)
	-- 			self:walkPath(path)
	-- 		end
	-- 	end, self.id, true)
	self.fllowEntity_:on("exit",
		function()
			printInfo("Character fllow is exit %d", self.id)
			self:cancelFllow()
			return true
		end, self.id, true)

	if self:distanceWith(self.fllowEntity_) > 1 then
		local pos = self.fllowEntity_:getMapPos()
		-- local path = Game:findPath(pos, self.curPos_)
		-- self:walkPath(path)
		self:walkToPosReq(pos)
	end

end

function Character:cancelFllow()
	self:cancelAttackReq()
	if not self.fllowEntity_ then
		return
	end
	self.fllowEntity_:removeEventListenersByTag(self.id)
	self.fllowEntity_ = nil
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
		return
	end

	if path[1].x == self.curPos_.x and path[1].y == self.curPos_.y then
		table.remove(path, 1)
	end

	if #path < 1 then
		return
	end

	-- dump(path, "walk path:")

	self.path_ = path

	if not self.isWalking_ then
		self:walkTo(table.remove(self.path_, 1))
	end
end

function Character:walkStep(dir, step)
	printInfo("Character walkStep")
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
	local origin = self.curPos_
	local destination = pos

	local args = Utilitys.pos2px(pos)
	args.time = Character.MOVE_STEP_TIME * step
	args.onComplete = handler(self, self.onWalkStepComplete_)
	self.curPos_ = pos
	self.isWalking_ = true
	self.view_:moveTo(args)

	self:doEvent("move", dir)

	if Game:isSelf(self) then
		-- Game:sendCmd("play.move", {id = self.id, from = origin, to = destination})
		self:dispatchEvent({name = "move"})
	end
end

function Character:onWalkStepComplete_()
	self.isWalking_ = false

	printInfo("id %d path count:%d", self.id, #self.path_)
	if 0 == #self.path_ then
		self:doEvent("stop")
	else
		printInfo("id %d fllow:%s", self.id, tostring(self.fllowEntity_))
		if self.fllowEntity_ then
			local dis = self:distanceWith(self.fllowEntity_)
			if dis > 1 then
				self:walkTo(table.remove(self.path_, 1))
			elseif 1 == dis then
				self:doEvent("stop")
				self:lookAt(self.fllowEntity_)
				printInfo("id %d fllow %s attack %s",
					self.id, tostring(self.fllowEntity_), tostring(self.attackEntity_))
				if self.attackEntity_ then
					self:attack()
				elseif self.talkEntity_ then
					self.talkEntity_:talk()
				elseif self.lootEntity_ then
					self:lootItem(self.lootEntity_)
				end
			end
		else
			self:walkTo(table.remove(self.path_, 1))
		end
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
			self.isCoolDown = true
			self:doEvent("stop")
			local handler
			handler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
				cc.Director:getInstance():getScheduler():unscheduleScriptEntry(handler)
				self.isCoolDown = false
				if self.fllowEntity_ then
					-- attack must be have fllowentity
					-- fllowentity is nil, needn't attack again
					self:attack()
				else
					self:playIdle()
				end
			end, self.COOL_DOWN_TIME, false)
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
	local disX = math.abs(entity.curPos_.x - self.curPos_.x)
	local disY = math.abs(entity.curPos_.y - self.curPos_.y)

	return disX + disY
end

function Character:attackIf(entity)
	if not entity or self.attackEntity_ == entity then
		printInfo("id %d attackif %s", self.id, tostring(entity))
		return
	end
	self:attack(entity)
end

function Character:attackMoveReq(entity)
	Game:sendCmd("play.attackMove", {sender = self.id, target = entity:getId()})
end

function Character:attackReq()
	local senderId = self.id
	local targetId = self.attackEntity_:getId()
	local userId = Game:getUser():getId()

	if userId == senderId or userId == targetId then
		Game:sendCmd("play.attack", {sender = senderId, target = targetId})
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

function Character:cancelAttackReq()
	if not self.attackHandle_ then
		return
	end
	Schedule:unscheduleScriptEntry(self.attackHandle_)
	self.attackHandle_ = nil
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
