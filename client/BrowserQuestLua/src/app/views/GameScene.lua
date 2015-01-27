
local Game = import("..models.Game").getInstance()
local Camera = import("..models.Camera")
local Entity = import("..models.Entity")
local GameScene = class("GameScene", cc.load("mvc").ViewBase)


function GameScene:onCreate()
	-- self:createUI()
	self:createMap()
end

function GameScene:createUI()
	local guiNode = display.newNode():addTo(self)
	guiNode:setLocalZOrder(100)

	local resPath = app:getResPath("border.png")
	local sp = ccui.Scale9Sprite:create(resPath)
		:align(display.CENTER, display.cx, display.cy)
		:addTo(guiNode)
		:setContentSize(display.width, display.height)

	local bottom = display.newNode():addTo(guiNode)
	local bottomBg = display.newSprite("#bar-container.png")
    	:align(display.LEFT_BOTTOM, 0, 0)
    	:addTo(bottom)
    local blood = display.newSprite("#healthbar.png")
    	:align(display.LEFT_BOTTOM, 3, 4)
    	:addTo(bottom)
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
	self.camera_:move(-12*14, (250 - 314)*14)

	local entity = Entity.new("clotharmor.png")
	local player = entity:getView()
	entity:setMapPos(cc.p(36, 230))
	player:setLocalZOrder(110)
	map:addChild(player)
	entity:play("idle")
end


function GameScene:onTouchBegan(touch, event)
	return true
end

function GameScene:onTouchMoved(touch, event)
	local diff = touch:getDelta()
	self.camera_:move(diff.x, diff.y)
    -- local currentPosX, currentPosY= self.map_:getPosition()
    -- self.map_:setPosition(cc.p(currentPosX + diff.x, currentPosY + diff.y))
end

function GameScene:onTouchEnded(touch, event)
	-- body
end

function GameScene:onKeyPressed(keyCode, event)
	if cc.KeyCode.KEY_LEFT_ARROW == keyCode then
		dump(event, "event:")
	elseif cc.KeyCode.KEY_RIGHT_ARROW == keyCode then
	elseif cc.KeyCode.KEY_UP_ARROW == keyCode then
	elseif cc.KeyCode.KEY_DOWN_ARROW == keyCode then
	else
		print("keyCode:" .. keyCode)
	end
end

function GameScene:onKeyReleased(keyCode, event)
	if cc.KeyCode.KEY_LEFT_ARROW == keyCode then
		dump(event, "event:")
	elseif cc.KeyCode.KEY_RIGHT_ARROW == keyCode then
	elseif cc.KeyCode.KEY_UP_ARROW == keyCode then
	elseif cc.KeyCode.KEY_DOWN_ARROW == keyCode then
	else
		print("keyCode:" .. keyCode)
	end
end

return GameScene
