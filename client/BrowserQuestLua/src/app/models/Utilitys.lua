
local Utilitys = {}
local Game = import(".Game").getInstance()

function Utilitys.pos2px(pos)
	local tileSize = Game:getTileSize()
	local mapSize = Game:getMapSizePx()

	return cc.p(tileSize.width*pos.x + tileSize.width/2, mapSize.height - tileSize.height*pos.y + tileSize.height/2)
end

return Utilitys
