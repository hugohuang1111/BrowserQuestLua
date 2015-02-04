
local Entity = import(".Entity")
local Item = class("Item", Entity)

Item.ANIMATION_IDLE_TIME = 0.5 	-- idle animation frame time
Item.ANIMATION_MOVE_TIME = 0.8 	-- move animation frame time

Item.ANCHOR = cc.p(0.5, 0.4)

function Item:ctor(args)
	Item.super.ctor(self, args)
end

return Item
