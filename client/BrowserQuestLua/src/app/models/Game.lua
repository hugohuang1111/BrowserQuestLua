
local Game = class("Game")
local gInstance = nil

Game.new_ = Game.new
Game.new = nil

function Game.getInstance()
	if not gInstance then
		gInstance = Game.new_()
	end

	return gInstance
end

function Game:ctor()
end

function Game:setMap(map)
	self.map_ = map

	local mapSize = map:getMapSize()
	local tileSize = map:getTileSize()
	-- local scale = map:getScale()

	self.mapSize_ = mapSize
	self.tileSize_ = tileSize --cc.size(tileSize.width * scale, tileSize.height * scale)
end

function Game:getTileSize()
	return self.tileSize_
end

function Game:getMapSize()
	return self.mapSize_
end

function Game:getMapSizePx()
	return cc.size(self.mapSize_.width * self.tileSize_.width, self.mapSize_.height * self.tileSize_.height)
end

function Game:getPlayer()
	-- body
end

function Game:addEntity()
	
end

return Game
