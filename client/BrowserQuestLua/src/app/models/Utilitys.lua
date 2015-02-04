
local Orientation = import(".Orientation")
local Types = import(".Types")
local Utilitys = {}


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

function Utilitys.mod(x, y)
	local integral, fractional = math.modf(x/y)
	local remainder = x - y * integral

	if 0 == remainder then
		remainder = y
	end
	return remainder
end

function Utilitys.getRankByName(name)
	local Key = "TYPE_" .. string.upper(string.sub(name, 1, -5))

	return Types[Key]
end

function Utilitys.getOrientation(base, other)
	local orientation
	if other.x > base.x then
		orientation = Orientation.RIGHT
	elseif other.x < base.x then
		orientation = Orientation.LEFT
	elseif other.y < base.y then
		orientation = Orientation.UP
	elseif other.y > base.y then
		orientation = Orientation.DOWN
	end

	return orientation
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
