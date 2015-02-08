
local Entity = import(".Entity")
local NPC = class("NPC", Entity)

function NPC:ctor(...)
	NPC.super.ctor(self, ...)

end

return NPC
