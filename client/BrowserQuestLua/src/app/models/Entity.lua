
require("cocos.cocos2d.json")
local Entity = class("Entity")
local Types = import(".Types")
local Utilitys = import(".Utilitys")
local Game = import(".Game").getInstance()

Entity.idx_ = 1

Entity.ANIMATION_IDLE_TIME = 0.2 	-- idle animation frame time
Entity.ANIMATION_MOVE_TIME = 0.1 	-- move animation frame time
Entity.ANIMATION_ATK_TIME  = 0.1 	-- attack animation frame time
Entity.ANIMATION_DEATH_TIME  = 0.1 	-- attack animation frame time

Entity.VIEW_TAG_SPRITE = 101

Entity.ANCHOR = cc.p(0.5, 0.5)

for k,v in pairs(Types) do
	Entity[k] = v
end

function Entity:ctor(args)
	self.imageName_ = args.image
	self.id = 0
	self.idx_ = Entity.idx_
	Entity.idx_ = Entity.idx_ + 1
	self.type_ = args.type

	cc.bind(self, "event")
	self:getView() -- create view

	self:bindStateMachine_(args.states)
end

function Entity:getIdx()
	return self.idx_
end

function Entity:setId(id)
	self.id = id
end

function Entity:getId()
	return self.id
end

function Entity:bindStateMachine_(states)
	local sm = cc.load("statemachine")

	local baseState = {
		events = {
			{name = "born",		from = "none",   		to = "idle" },
			{name = "kill",   	from = sm.WILDCARD,   	to = "death" }
		},

		callbacks = {
			onbeforeevent = handler(self, self.onBeforeEvent),
			onafterevent = handler(self, self.onAfterEvent),
			onenterstate = handler(self, self.onEnterState),
			onleavestate = handler(self, self.onLeaveState),
			onchangestate = handler(self, self.onChangeState)
		}
	}

	states = states or baseState
	states.callbacks = states.callbacks or {}
	states.callbacks.onbeforeevent = baseState.callbacks.onbeforeevent
	states.callbacks.onafterevent = baseState.callbacks.onafterevent
	states.callbacks.onenterstate = baseState.callbacks.onenterstate
	states.callbacks.onleavestate = baseState.callbacks.onleavestate
	states.callbacks.onchangestate = baseState.callbacks.onchangestate

	self.fsm_ = {}
	cc.bind(self.fsm_, "statemachine")

	self.fsm_:setupState(states)
	self:doEvent("born")
end

function Entity:onBeforeEvent(event)
	-- body
end

function Entity:onAfterEvent(event)
	printInfo("Entity:onAfterEvent state:" .. event.to)

	if "idle" == event.to then
		self:playIdle(self.orientation_)
	elseif "death" == event.to then
		self:dispatchEvent({name = "death"})
		self:playDeath()
	end
end

function Entity:onEnterState(event)
end

function Entity:onLeaveState(event)
	-- body
end

function Entity:onChangeState(event)
	-- body
end

function Entity:doEvent(eventName)
	if self.fsm_:canDoEvent(eventName) then
		self.fsm_:doEvent(eventName)
	else
		printError("Entity can't do event:" .. eventName)
	end
end

function Entity:getView()
	if self.view_ then
		return self.view_
	end

	self.view_ = display.newNode()

	self:loadJson_()

	-- cloth
	local texture = display.loadImage(app:getResPath(self.imageName_))
	local frame = display.newSpriteFrame(texture,
			cc.rect(0, 0, self.json_.width * app:getScale(), self.json_.height * app:getScale()))
	display.newSprite(frame):addTo(self.view_, 1, Entity.VIEW_TAG_SPRITE)
		:align(self.ANCHOR)

	self.view_:enableNodeEvents()
	self.view_.onExit = function()
		self:dispatchEvent({name = "exit"})
	end

	return self.view_
end

function Entity:setType(entityType)
	self.type_ = entityType
end

function Entity:getType()
	return self.type_
end

function Entity:stopAllActions()
	local sp = self.view_:getChildByTag(Entity.VIEW_TAG_SPRITE)
	sp:stopAllActions()
end

function Entity:play(actionName, args)
	printInfo("Entity play actionName:%s", actionName)
	local result = self:getFrames_(actionName)
	local frames = result.frames
	if not frames then
		printError("Entity:play invalid action name:%s", actionName)
	end

	local sp = self.view_:getChildByTag(Entity.VIEW_TAG_SPRITE)
	sp:stopAllActions()

	sp:setFlippedX(result.flip)
	if args and args.isOnce then
		args.isOnce = false  -- remove used params
		sp:playAnimationOnce(display.newAnimation(frames, self:getAnimationTime(actionName)), args)
	else
		sp:playAnimationForever(display.newAnimation(frames, self:getAnimationTime(actionName)), args)
	end
end

function Entity:playIdle()
	self:play("idle")
end

function Entity:playDeath()
	self:setId(0) -- invalid id
	self:play("death",
		{
			removeSelf = true,
			onComplete = function()
				Game:removeEntity(self)
			end,
			isOnce = true
		})
end

function Entity:getAnimationTime(actionName)
	local pos = string.find(actionName, "_")
	local action = actionName
	if pos then
		action = string.sub(actionName, 1, pos - 1)
	end

	if "idle" == action then
		return self.ANIMATION_IDLE_TIME
	elseif "walk" == action then
		return self.ANIMATION_MOVE_TIME
	elseif "atk" == action then
		return self.ANIMATION_ATK_TIME
	elseif "death" == action then
		return self.ANIMATION_DEATH_TIME
	else
		return self.ANIMATION_IDLE_TIME
	end
end

function Entity:walk(pos)
	-- body
end

function Entity:setMapPos(pos)
	if not pos then
		return
	end
	self.curPos_ = pos
	self.view_:setPosition(Utilitys.pos2px(pos))
end

function Entity:getMapPos()
	return self.curPos_
end

function Entity:loadJson_()
	self.json_ = self:parseJson_(self.imageName_)
end

function Entity:getFrames_(aniType)
	return self:parseFrames_(self.imageName_, self.json_, aniType)
end

function Entity:parseJson_(imageName)
	local jsonFileName = "sprites/" .. string.gsub(imageName, ".png", ".json")
	local fileContent = cc.FileUtils:getInstance():getStringFromFile(jsonFileName)
	return json.decode(fileContent)
end

function Entity:parseFrames_(imageName, imageJson, aniType)
	aniType = aniType or "idle"

	local json = imageJson["animations"][aniType]
	local needFlip
	if "death" == aniType and not json then
		imageName = "death.png"
		imageJson = self:parseJson_(imageName)
		json = imageJson["animations"][aniType]
	end
	if not json then
		local spos, epos = string.find(aniType, "_")
		if spos then
			local newAniType = string.gsub(aniType, "(%a*)", function(str)
				if "left" == str then
					needFlip = true
					return "right"
				elseif "right" == str then
					needFlip = true
					return "left"
				elseif "up" == str then
					needFlip = true
					return "down"
				elseif "down" == str then
					needFlip = true
					return "up"
				end
			end)

			json = imageJson["animations"][newAniType]
		else
			local newAniType = aniType .. "_down"
			json = imageJson["animations"][newAniType]
		end
	end
	if not json then
		printError("Entity:getAnimation aniType:%s", aniType)
		return
	end

	local texture = display.loadImage(app:getResPath(imageName))
	local width = imageJson.width * app:getScale()
	local height = imageJson.height * app:getScale()

	local frames = {}
	for i=1,json.length do
		local frame = display.newSpriteFrame(texture,
			cc.rect(width * (i - 1), height * json.row, width, height))
        frames[#frames + 1] = frame
	end

	return {frames = frames, flip = needFlip}
end

function Entity:getImageSize()
	return cc.size(self.json_.width, self.json_.height)
end


return Entity
