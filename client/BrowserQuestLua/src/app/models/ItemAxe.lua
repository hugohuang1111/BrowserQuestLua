
local Item = import(".Item")
local ItemAxe = class("ItemAxe", Item)

function ItemAxe:ctor(args)
	args = args or {}
	args.image = "item-axe.png"
	args.type = Item.TYPE_AXE


	ItemAxe.super.ctor(self, args)
end

return ItemAxe
