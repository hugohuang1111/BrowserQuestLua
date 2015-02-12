
local Camera = import("..models.Camera")
local Types = import("..models.Types")
local Entity = import("..models.Entity")
local Orientation = import("..models.Orientation")
local Utilitys = import("..models.Utilitys")
local GameScene = class("GameScene", cc.load("mvc").ViewBase)
local Scheduler = cc.Director:getInstance():getScheduler()

local GAMESCENE_EMOJI_TAG = 101
local GAMESCENE_WORLD_CHAT_TAG = 102

function GameScene:onCreate()
	self:createUI()
	self:createMap()
end

function GameScene:createUI()
	local guiNode = display.newNode():addTo(self)
	guiNode:setLocalZOrder(100)
	self.guiNode_ = guiNode

	local resPath = app:getResPath("border.png")
	local sp = ccui.Scale9Sprite:create(resPath)
		:align(display.CENTER, display.cx, display.cy)
		:addTo(guiNode)
		:setContentSize(display.width, display.height)

	local bottom = display.newNode():addTo(guiNode)
	local bottomBg = ccui.Scale9Sprite:createWithSpriteFrameName("bar-container.png", cc.rect(460, 7, 40, 20))
    	:align(display.CENTER_BOTTOM, display.cx, 0)
    	:addTo(bottom)
    local size = bottomBg:getContentSize()
    bottomBg:setContentSize(cc.size(display.width, size.height))

	local bloodFg = display.newSprite("#healthbar.png")
	local bloodSize = bloodFg:getContentSize()
	bloodSize.width = bloodSize.width - 12
	bloodSize.height = bloodSize.height - 6
    local blood = ccui.Scale9Sprite:create("img/common/blood.png")
    	:align(display.LEFT_BOTTOM, 3 + 6, 4 + 3)
    	:addTo(bottom)
    blood:setContentSize(bloodSize)
    self.bloodSize_ = bloodSize
    self.blood_ = blood

    bloodFg:align(display.LEFT_BOTTOM, 3, 4)
    	:addTo(bottom)

    local chatBtn = display.newSprite("#chatbtn.png")
    	:align(display.LEFT_BOTTOM, display.right - 120, 4)
    	:addTo(bottom)

    chatBtn:onClick(handler(self, self.showEmojiTable))
    
    self:showWorldChat()
end

function GameScene:createMap()
	local mapNode = display.newNode():addTo(self)
	mapNode:setLocalZOrder(10)

	-- register listener
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(handler(self, self.onTouchMoved), cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, mapNode)

    -- register keyboard listener
    listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(handler(self, self.onKeyPressed), cc.Handler.EVENT_KEYBOARD_PRESSED)
    listener:registerScriptHandler(handler(self, self.onKeyReleased), cc.Handler.EVENT_KEYBOARD_RELEASED)
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, mapNode)

	local map = cc.TMXTiledMap:create("maps/map.tmx"):addTo(mapNode)
	map:setScale(1)

	Game:setMap(map)

	self.map_ = map

	self.camera_ = Camera.new(map)
	-- create player
	local player = Game:createUser()
	self.camera_:look(player, 1)

	Game:onPlayerUIExit(handler(self, self.showRevive))
	Game:onPlayerMove(handler(self, self.playerMoveHandler))
	Game:onPlayerInfoChange(handler(self, self.playerInfoHandler))
	Game:onWorldChat(handler(self, self.addWorlChat))

	Game:createEntitys()
	Game:createOnlinePlayers()

	-- local rat = require("app.models.MobRat").new()
	-- rat:setMapPos(cc.p(17, 288))
	-- Game:addMob(rat)

	-- local guard = require("app.models.NPCGuard").new()
	-- guard:setMapPos(cc.p(16, 292))
	-- Game:addNPC(guard)
	-- guard:talkSentence_()

	-- local entity = require("app.models.ItemAxe").new()
	-- entity:setMapPos(cc.p(16, 293))
	-- Game:addObject(entity)
end

function GameScene:showRevive()
	local bg = display.newSprite("#parchment.png")
	bg:setTag(201)
	bg:align(display.CENTER, display.cx, display.cy)
	bg:setScaleX(0.1)
	bg:setLocalZOrder(101)
	bg:addTo(self)
	bg:scaleTo({scaleX = 1, scaleY = 1, time = 1, onComplete = function()
		local bounding = bg:getBoundingBox()
		local ttfConfig = {
			fontFilePath = "fonts/arial.ttf",
			fontSize = 24
			}
		local label = cc.Label:createWithTTF(ttfConfig, "You Are Dead!", cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		label:align(display.CENTER, bounding.width/2, bounding.height/2 + 10)
		label:setTextColor(cc.c4b(0, 0, 0, 250))
		label:addTo(bg)

		ccui.Button:create("buttonRevive.png", "buttonRevive.png", "buttonRevive.png", ccui.TextureResType.plistType)
		    :align(display.CENTER, bounding.width/2, bounding.height/2 - 30)
		    :addTo(bg)
		    :onTouch(function(event)
		        if "ended" == event.name then
		            local playerData = Game:getPlayerData()
		            local player = Game:getUser()
		            playerData.imageName = player.imageName_
		            playerData.weaponName = player.weaponName_
		            playerData.nickName = player.name_
		            playerData.pos = player.curPos_
		            playerData.id = player.id
		            Game:sendCmd("user.reborn", playerData)
		        end
		    end)
		end})
end

function GameScene:playerMoveHandler(user)
	if not user or not user:getView() then
	end
	local view = user:getView()
	local pos = view:convertToWorldSpace(cc.p(0, 0))
	if pos.x < display.width/3 or pos.x > display.width/3*2
		or pos.y < display.height/3 or pos.y > display.height/3*2 then
		self.camera_:look(user, 1)
	end
end

function GameScene:playerInfoHandler(user)
	local healthPercent = user:getHealthPercent()
	if not healthPercent or healthPercent < 0 then
		return
	end
	local size = clone(self.bloodSize_)
	size.width = size.width * healthPercent
    self.blood_:setContentSize(size)
end

function GameScene:showEmojiTable()
	local guiNode = self.guiNode_
	local node
	node = guiNode:getChildByTag(GAMESCENE_EMOJI_TAG)
	if node then
		node:setVisible(true)
	else
		node = display.newNode()
		local width = 5
		local height = 3
		local gridSize = cc.size(34, 34)
		for y=1, height do
			for x=1, width do
				local imgName = "emoji/" .. ((y - 1) * width + x) .. ".jpg"
				local img = display.newSprite(imgName)
				local rect = img:getBoundingBox()
				node:addChild(img)
				img:align(display.LEFT_BOTTOM, gridSize.width * (x - 1), gridSize.height * (y - 1))
			end
		end
		guiNode:addChild(node)
		node:setTag(GAMESCENE_EMOJI_TAG)
		node:setPosition(display.right - gridSize.width * width, 34)

		node:onClick(function(touch)
			local pos = node:convertToNodeSpace(touch:getLocation())
			local line = math.ceil(pos.y/gridSize.height)
			if line > height then
				line = height
			end
			if line < 1 then
				line = 1
			end
			local row = math.ceil(pos.x/gridSize.width)
			if row > width then
				row = width
			end
			if row < 1 then
				row = 1
			end
			local idx = (line - 1) * width + row

			-- send chat 
			Game:sendCmd("play.chat", {id = Game:getUser():getId(), name = Game:getUser():getNickName(), msg = "emoji:" .. idx})
			node:setVisible(false)
		end)
	end
end

function GameScene:showWorldChat()
	local guiNode = self.guiNode_
	local bgNode

	bgNode = ccui.Scale9Sprite:create("img/common/chatbg.png")
	local bgSize = cc.size(250, 34 * 5 + 20) -- only show last five chat
	bgNode:setContentSize(bgSize)
	bgNode:align(display.LEFT_BOTTOM, 8, 34)
	bgNode:addTo(guiNode)

	local clip = cc.ClippingRectangleNode:create()
	local space = 20
	bgSize.width = bgSize.width - space * 2
	bgSize.height = bgSize.height - space
	clip:setClippingRegion(bgSize)
	clip:align(display.LEFT_BOTTOM, 8 + space, 34)
	clip:addTo(guiNode)
	clip:setTag(GAMESCENE_WORLD_CHAT_TAG)
end

function GameScene:addWorlChat(args)
	local guiNode = self.guiNode_
	local node = guiNode:getChildByTag(GAMESCENE_WORLD_CHAT_TAG)

	local lineNode = display.newNode()
	local ttfConfig = {
			fontFilePath = "fonts/fzkt.ttf",
			fontSize = 36
			}
	local account
	if args.name then
		account = args.name .. ": "
	else
		account = "[anonymous]: "
	end
	local name = cc.Label:createWithTTF(ttfConfig, account, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		:align(display.LEFT_BOTTOM, 0, 0)
		:addTo(lineNode)
	local nameSize = name:getContentSize()
	local idx = string.match(args.msg, "emoji:(%d+)")
	local msg = display.newSprite("emoji/" .. idx .. ".jpg")
		:align(display.LEFT_BOTTOM, nameSize.width, 0)
		:addTo(lineNode)

	node:removeChildByTag(5)
	for i=5, 1, -1 do
		local child = node:getChildByTag(i)
		if child then
			local posX, posY = child:getPosition()
			child:setPositionY(posY + 34)
			child:setTag(i + 1)
		end
	end

	lineNode:setTag(1)
	lineNode:addTo(node)
end


function GameScene:onTouchBegan(touch, event)
	return true
end

function GameScene:onTouchMoved(touch, event)
	local diff = touch:getDelta()

	local dis = diff.x * diff.x + diff.y * diff.y
	if dis > 50 then
		self.isMoving = true
		self.camera_:move(diff.x, diff.y)
	end
end

function GameScene:onTouchEnded(touch, event)
	if self.isMoving then
		self.isMoving = false
		return
	end

	local pos = touch:getLocation()
	local mapPospx = Game:getMap():convertToNodeSpace(pos)
	local mapPos = Utilitys.px2pos(mapPospx)

	local entitys = Game:findEntityByPos(mapPos)
	local entity = entitys[1]

	if entity then
		local entityType = entity:getType()
		if entity.TYPE_MOBS_BEGIN < entityType and entityType < entity.TYPE_MOBS_END then
			Game:getUser():attack(entity)
		elseif entity.TYPE_NPCS_BEGIN < entityType and entityType < entity.TYPE_NPCS_END then
			Game:getUser():talk(entity)
		elseif (entity.TYPE_ARMORS_BEGIN < entityType and entityType < entity.TYPE_ARMORS_END)
			or (entity.TYPE_WEAPONS_BEGIN < entityType and entityType < entity.TYPE_WEAPONS_END) then
			Game:getUser():loot(entity)
			-- Game:getUser():changeWeapon("axe.png")
		end
	else
		Game:getUser():walk(mapPos)
		-- local drawNode = Utilitys.genPathNode(path)
		-- Game:getMap():removeChildByTag(111)
		-- Game:getMap():addChild(drawNode, 100, 111)
	end
end

function GameScene:onKeyPressed(keyCode, event)
	-- scheduleScriptFunc(unsigned int handler, float interval, bool paused)
	local player = Game.getInstance():getUser()
	if cc.KeyCode.KEY_LEFT_ARROW == keyCode then
		player:walkStep(Orientation.LEFT)
	elseif cc.KeyCode.KEY_RIGHT_ARROW == keyCode then
		player:walkStep(Orientation.RIGHT)
	elseif cc.KeyCode.KEY_UP_ARROW == keyCode then
		player:walkStep(Orientation.UP)
	elseif cc.KeyCode.KEY_DOWN_ARROW == keyCode then
		player:walkStep(Orientation.DOWN)
	else
		print("keyCode:" .. keyCode)
	end
end

function GameScene:onKeyReleased(keyCode, event)
	if cc.KeyCode.KEY_LEFT_ARROW == keyCode then
	elseif cc.KeyCode.KEY_RIGHT_ARROW == keyCode then
	elseif cc.KeyCode.KEY_UP_ARROW == keyCode then
	elseif cc.KeyCode.KEY_DOWN_ARROW == keyCode then
	else
		print("keyCode:" .. keyCode)
	end
end


return GameScene
