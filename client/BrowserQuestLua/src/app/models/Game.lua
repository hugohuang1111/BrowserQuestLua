
local Game = class("Game")
local AStar = import(".AStar")
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
	self.pathGrid_ = {}
end

function Game:setMap(map)
	self.map_ = map

	local mapSize = map:getMapSize()
	local tileSize = map:getTileSize()
	-- local scale = map:getScale()

	self.mapSize_ = mapSize
	self.tileSize_ = tileSize --cc.size(tileSize.width * scale, tileSize.height * scale)

	self:loadPathGrid_()
	self:addGridLayer_()
end

function Game:getMap()
	return self.map_
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

function Game:createPlayer(args)
	local player = require("app.models.Player").new(args)
	self.user_ = player

	self.map_:addChild(player:getView(), 200)

	return player
end

function Game:getPlayer()
	return self.user_
end

function Game:addEntity()
	
end

function Game:findPath(endPoint)
	local startPoint = self.user_:getMapPos()
	local path = AStar.findPath(startPoint, endPoint, self.pathGrid_, self.mapSize_.width, self.mapSize_.height)

	return path
end

function Game:loadPathGrid_()
	local layers = {
		"sand objects",
		"water",
		"lakes",
		"village boundaries",
		"village boundaries lvl 2",
		"river",
		"Houses layer 2",
		"Houses",
		"Big Rocks",
		"small rocks",
		"graveyard",
		"dead trees",
		"camps",
		"lava",
		"canyon",
		"Cliffs",
		"Cliffs 2",
		"totems",
		"cactus",
		"cave",
		"lava boundaries",
		"Trees2",
		"caveriver",
		"cavewalls",
		"indoor",
		"indoor objects",
		"forest lakes",
		"forest boundaries",
		"forest trees",
		"forest objects 1",
		"forest objects 2",
		"mase walls",
		"sea",
	}

	for i,v in ipairs(layers) do
		self:loadMapLayer_(v)
	end
end

function Game:loadMapLayer_(layerName)
	local layer = self.map_:getLayer(layerName)
	if not layer then
		return
	end

	local mapSize = self.mapSize_
	local grid = self.pathGrid_
	local line

	for y = 1, mapSize.height do
		grid[y] = grid[y] or {}
		line = grid[y]
		for x = 1, mapSize.width do
			if 0 ~= layer:getTileGIDAt(cc.p(x - 1, y - 1)) then
				line[x] = true
				-- printInfo("tile pos (%d,%d)", x, y)
			end
		end
	end
end

function Game:addGridLayer_()
	local node = cc.DrawNode:create()

	local startPoint = cc.p(0, 0)
	local endPoint = cc.p(0, self.tileSize_.height*self.mapSize_.height)
	for x=1,171 do
		startPoint.x = x * self.tileSize_.width
		endPoint.x = startPoint.x
		node:drawLine(startPoint, endPoint, cc.c4f(1, 0, 0, 1))
		for y=1,311 do
			node:drawLine(startPoint, endPoint, cc.c4f(1, 0, 0, 1))
		end
	end

	startPoint.x = 0
	endPoint.x = self.tileSize_.width * self.mapSize_.width
	for y = 1, 311 do
		startPoint.y = y * self.tileSize_.height
		endPoint.y = startPoint.y
		node:drawLine(startPoint, endPoint, cc.c4f(1, 0, 0, 1))
	end

	self.map_:addChild(node, 99)
end

return Game
