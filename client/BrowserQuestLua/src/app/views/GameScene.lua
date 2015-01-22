
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

	local map = cc.TMXTiledMap:create("maps/map.tmx"):addTo(mapNode)

end

return GameScene
