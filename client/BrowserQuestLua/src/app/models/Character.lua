
local Entity = import(".Entity")
local Orientation = import(".Orientation")
local Utilitys = import(".Utilitys")
local Character = class("Character", Entity)

Character.MOVE_STEP_TIME = 0.3
Character.COOL_DOWN_TIME = 0.3

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
	local bHandler = true

	if "walk" == event.to then
		self:playWalk(self.orientation_)
	elseif "idle" == event.to then
		self:playIdle()
	elseif "atk" == event.to then
		self:playAtk()
	elseif "death" == event.to then
		self:playDeath()
	else
		bHandler = false
	end

	if not bHandler then
		Character.super.onAfterEvent(self, event)
	end
end

function Character:setAttackSpeed(speed)
	self.atkSpeed_ = speed
end

function Character:setWalkSpeed(speed)
	self.walkSpeed_ = speed
end

function Character:walk(pos)
	local path = Game:findPath(pos, self.curPos_)
	self:walkPath(path)
	self.fllowEntity_ = nil
end

function Character:fllow(entity)
	self.fllowEntity_ = entity or self.fllowEntity_

	if not self.fllowEntity_ then
		return
	end

	if self:distanceWith(self.fllowEntity_) > 1 then
		local pos = self.fllowEntity_:getMapPos()
		local path = Game:findPath(pos, self.curPos_)
		self:walkPath(path)
	end

	self.fllowEntity_:on("exit",
		function()
			self.fllowEntity_ = nil
		end)
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
		Game:sendCmd("play.move", {id = self.id, from = origin, to = destination})
		self:dispatchEvent({name = "move"})
	end
end

function Character:onWalkStepComplete_()
	self.isWalking_ = false

	if 0 == #self.path_ then
		if self.onPathingFinish_ then
			self.onPathingFinish_()
		end
		self:doEvent("stop")
	else
		if self.fllowEntity_ then
			local dis = self:distanceWith(self.fllowEntity_)
			if dis > 1 then
				self:walkTo(table.remove(self.path_, 1))
			elseif 1 == dis then
				self:doEvent("stop")
				self:lookAt(self.fllowEntity_)
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

function Character:onPathingFinish(callback)
	self.onPathingFinish_ = self.onPathingFinish_ or {}
	self.onPathingFinish_ = callback
end

function Character:playWalk(orientation)
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
				self:attack()
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

	Game:sendCmd("play.attack", {sender = self.id, target = self.attackEntity_:getId()})
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
			Game:removeEntity(self)
		end}
	self:play("death", args)
end

function Character:distanceWith(entity)
	local disX = math.abs(entity.curPos_.x - self.curPos_.x)
	local disY = math.abs(entity.curPos_.y - self.curPos_.y)

	return disX + disY
end

function Character:attackIf(entity)
	if not entity or self.attackEntity_ == entity then
		return
	end
	self:attack(entity)
end

function Character:attack(entity)
	self:fllow(entity)
	self.attackEntity_ = entity or self.attackEntity_

	if not self.attackEntity_ then
		printInfo("id %d attackentity is nil", self.id)
		return
	end

	if 1 == self:distanceWith(self.attackEntity_) then
		if not self.isCoolDown then
			self:doEvent("attack", Utilitys.getOrientation(self.curPos_, self.attackEntity_:getMapPos()))
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
	local handle
	label.handle = schedule:scheduleScriptFunc(function()
		schedule:unscheduleScriptEntry(label.handle)
		label.handle = nil
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
