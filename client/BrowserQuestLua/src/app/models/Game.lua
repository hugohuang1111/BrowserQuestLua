
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
end

function Game:addEntity()
	
end

return Game
