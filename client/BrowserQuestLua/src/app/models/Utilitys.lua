
local Utilitys = {}
local Game = import(".Game").getInstance()

function Utilitys.pos2px(pos)
	local tileSize = Game:getTileSize()
	local mapSize = Game:getMapSizePx()

	return cc.p(tileSize.width*pos.x - tileSize.width/2, mapSize.height - tileSize.height*pos.y + tileSize.height/2)
end

function Utilitys.px2pos(posPx)
	local tileSize = Game:getTileSize()
	local mapSize = Game:getMapSize()

	return cc.p(math.ceil(posPx.x/tileSize.width), mapSize.height + 1 - math.ceil(posPx.y/tileSize.height))
end

function Utilitys.genPathNode(path)
	local node = cc.DrawNode:create()
	local startPoint
	local endPoint

	for i,v in ipairs(path) do
		startPoint = Utilitys.pos2px(v)
		if path[i + 1] then
			endPoint = Utilitys.pos2px(path[i + 1])
			node:drawLine(startPoint, endPoint, cc.c4f(1, 0, 0, 1))
		end
	end

	return node
end

return Utilitys
