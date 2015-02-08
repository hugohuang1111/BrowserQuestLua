
local Map = class("Map")

function Map:ctor(path)
	local file = io.open(path)
	local content = file:read("*a")
	io.close(file)
	self.map_ = json.decode(content)
end

function Map:getStaticEntity()
	return self.map_.staticEntities
end

function Map:getPosByTileIdx(idx)
	local val = idx/self.map_.width
	local y = math.modf(val)
	local x = idx - self.map_.width * y

	return cc.p(x + 1, y + 1)
end

return Map
