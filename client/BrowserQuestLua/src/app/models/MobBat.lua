
local Mob = import(".Mob")
local MobBat = class("MobBat", Mob)

function MobBat:ctor(args)
	args = args or {}
	args.image = "bat.png"
	args.type = Mob.TYPE_BAT

	MobBat.super.ctro(self, args)
end

return MobBat
