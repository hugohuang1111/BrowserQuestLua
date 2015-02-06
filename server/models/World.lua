
local Map = import(".Map")
local World = class("World")


function World:ctor(path)
	printInfo("World ctor+++++++++++++++++++++++++++++++++++")
	local map = Map.new(path)	
end


return World
