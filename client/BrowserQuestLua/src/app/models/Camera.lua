
-- Camera会根据map的形状来移动镜头

--[[

地图的形状:

     X1             X2       X3

Y3   +-----------------------+
     |                       |
     |                       |
Y2   +               +-------+
     |               |(A)    (B)
     |               |
     |               |
     |               |
     |               |
     |               |
     |               |
Y1   +---------------+

A的位置:(93,  62)  从1开始计算,从左上为起点
B的位置:(114, 62)  从1开始计算,从左上为起点

]]
local Camera = class("Camera")

function Camera:ctor(map)
	self.map_ = map
	local mapSize = map:getMapSize()
	local tileSize = map:getTileSize()

	--YVals_ 以左下为起点
	self.YVals_ = {}
	self.YVals_[1] = 0
	self.YVals_[2] = (mapSize.height - 62)*tileSize.height
	self.YVals_[3] = mapSize.height*tileSize.height

	self.XVals_ = {}
	self.XVals_[1] = 0
	self.XVals_[2] = 93*tileSize.width
	self.XVals_[3] = 114*tileSize.width

	dump(self.XVals_, "XVals_:")
	dump(self.YVals_, "YVals_:")
end

function Camera:move(disX, disY)
	if self.bMove then
		return
	end
	-- self.bMove = true

	local disX = disX or 0
	local disY = disY or 0
	local posX, posY = self.map_:getPosition()

	-- print("input disY:" .. disY)
	if posX + disX > display.left then
		disX = display.left - posX
	elseif posX + self.XVals_[3] + disX < display.right then
		disX = display.right - posX - self.XVals_[3]
	end

	if posY + disY > display.bottom then
		disY = display.bottom - posY
	elseif posY + self.YVals_[3] + disY < display.top then
		disY = display.top - posY - self.YVals_[3]
	end
	-- print("disY1:" .. disY)

	--不能到的区域
	local noReachRect = cc.rect(posX + disX + 93*16, posY + disY, self.XVals_[3] - self.XVals_[2], self.YVals_[2])
	local screenRect = cc.rect(display.left, display.bottom, display.width, display.height)
	local intersectRect = cc.rectIntersection(noReachRect, screenRect)
	-- dump(noReachRect, "noReachRect:")
	-- dump(screenRect, "nscreenRect:")
	if (intersectRect.width > 0 and intersectRect.height > 0) then
		dump(intersectRect, "intersectRect:")
		if math.abs(disX) > intersectRect.width then
			if disX > 0 then
				disX = disX - intersectRect.width
			else
				disX = disX + intersectRect.width
			end
		elseif math.abs(disY) > intersectRect.height then
			if disY > 0 then
				disY = disY - intersectRect.height
			else
				disY = disY + intersectRect.height
			end
		else
			disX = 0
			disY = 0
		end
	end

	-- print("disY2:" .. disY)

	self.map_:setPosition(posX + disX, posY + disY)
end

return Camera
