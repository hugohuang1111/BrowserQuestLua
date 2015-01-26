
local Camera = import("..models.Camera")
local Entity = import("..models.Entity")
local GameScene = class("GameScene", cc.load("mvc").ViewBase)


function GameScene:onCreate()
	self:createUI()
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

	local map = cc.TMXTiledMap:create("maps/map.tmx"):addTo(mapNode)

	self.map_ = map

	self.camera_ = Camera.new(map)
	-- self.camera_:move(-12*16, (250 - 314)*16)

	local entity = Entity.new("clotharmor.png")
	local player = entity:getView()
	player:setPosition(cc.p(200, 200))
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

return GameScene
