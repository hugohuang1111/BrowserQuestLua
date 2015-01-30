
require("cocos.cocos2d.json")
local Entity = class("Entity")
local Utilitys = import(".Utilitys")
local Game = import(".Game").getInstance()


Entity.ANIMATION_IDLE_TIME = 0.2 	-- idle animation frame time
Entity.ANIMATION_MOVE_TIME = 0.1 	-- move animation frame time


Entity.TYPE_NONE = 0
Entity.TYPE_WARRIOR = 1

-- Mobs
Entity.TYPE_RAT = 101
Entity.TYPE_SKELETON = 102
Entity.TYPE_GOBLIN = 103
Entity.TYPE_OGRE = 104
Entity.TYPE_SPECTRE = 105
Entity.TYPE_CRAB = 106
Entity.TYPE_BAT = 107
Entity.TYPE_WIZARD = 108
Entity.TYPE_EYE = 109
Entity.TYPE_SNAKE = 110
Entity.TYPE_SKELETON2 = 111
Entity.TYPE_BOSS = 112
Entity.TYPE_DEATHKNIGHT = 113

-- armors
Entity.TYPE_FIREFOX = 201
Entity.TYPE_CLOTHARMOR = 202
Entity.TYPE_LEATHERARMOR = 203
Entity.TYPE_MAILARMOR = 204
Entity.TYPE_PLATEARMOR = 205
Entity.TYPE_REDARMOR = 206
Entity.TYPE_GOLDENARMOR = 207

-- objects
Entity.TYPE_FLASK = 301
Entity.TYPE_BURGER = 302
Entity.TYPE_CHEST = 303
Entity.TYPE_FIREPOTION = 304
Entity.TYPE_CAKE = 305

-- NPCs
Entity.TYPE_GUARD = 401
Entity.TYPE_KING = 402
Entity.TYPE_OCTOCAT = 403
Entity.TYPE_VILLAGEGIRL = 404
Entity.TYPE_VILLAGER = 405
Entity.TYPE_PRIEST = 406
Entity.TYPE_SCIENTIST = 407
Entity.TYPE_AGENT = 408
Entity.TYPE_RICK = 409
Entity.TYPE_NYAN = 410
Entity.TYPE_SORCERER = 411
Entity.TYPE_BEACHNPC = 412
Entity.TYPE_FORESTNPC = 413
Entity.TYPE_DESERTNPC = 414
Entity.TYPE_LAVANPC = 415
Entity.TYPE_CODER = 416

-- weapons
Entity.TYPE_SWORD1 = 501
Entity.TYPE_SWORD2 = 502
Entity.TYPE_REDSWORD = 503
Entity.TYPE_GOLDENSWORD = 504
Entity.TYPE_MORNINGSTAR = 505
Entity.TYPE_AXE = 506
Entity.TYPE_BLUESWORD = 507


Entity.VIEW_TAG_SPRITE = 101

Entity.ANCHOR = cc.p(0.5, 0.3)


function Entity:ctor(args)
	self.imageName_ = args.image
	self.id = 0
	self.type_ = 0

	cc.bind(self, "event")
	self:bindStateMachine_(args.states)
end

function Entity:bindStateMachine_(states)
	local baseState = {
		event = {
			{name = "start",  from = "none",   to = "idle" },
			{name = "kill",  from = "idle",   to = "death" }
		},

		callbacks = {
			onbeforeevent = handler(self, self.onBeforeEvent),
			onafterevent = handler(self, self.onAfterEvent),
			onenterstate = handler(self, self.onEnterState),
			onleavestate = handler(self, self.onLeaveState),
			onchangestate = handler(self, self.onChangeState)
		}
	}

	self.fsm_ = {}
	cc.load("statemachine")
	cc.bind(self.fsm_, "statemachine")

	self.fsm_:setupState(states)
}
end

function Entity:onBeforeEvent(event)
	-- body
end

function Entity:onAfterEvent(event)
	-- body
end

function Entity:onEnterState(event)
	-- body
end

function Entity:onLeaveState(event)
	-- body
end

function Entity:onChangeState(event)
	-- body
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
		:align(Entity.ANCHOR)

	return self.view_
end

function Entity:setType(entityType)
	self.type_ = entityType
end

function Entity:play(actionName)
	local result = self:getFrames_(actionName)
	local frames = result.frames
	if not frames then
		printError("Entity:play invalid action name:%s", actionName)
	end

	local sp = self.view_:getChildByTag(Entity.VIEW_TAG_SPRITE)
	sp:stopAllActions()

	sp:setFlippedX(result.flip)
	sp:playAnimationForever(display.newAnimation(frames, self:getAnimationTime(actionName)))
end

function Entity:getAnimationTime(actionName)
	local pos = string.find(actionName, "_")
	local action
	if pos then
		action = string.sub(actionName, 1, pos - 1)
	end

	if "idle" == action then
		return Entity.ANIMATION_IDLE_TIME
	elseif "walk" == action then
		return Entity.ANIMATION_MOVE_TIME
	elseif "atk" == action then
		return Entity.ANIMATION_MOVE_TIME
	else
		return Entity.ANIMATION_IDLE_TIME
	end
end

function Entity:walk(pos)
	-- body
end

function Entity:setMapPos(pos)
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


return Entity
