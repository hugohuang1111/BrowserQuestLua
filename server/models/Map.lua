
local Map = class("Map")

function Map:ctor(path)
	printInfo("Map ctor path:" .. path)

	local file = io.open(path)
	local content = file:read("*a")

	self.map_ = json.decode(content)

	-- dump(self.map_, "Map:")
end

return Map
