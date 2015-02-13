
local Mob = import(".Mob")
local MobBat = class("MobBat", Mob)

Mob.ANIMATION_IDLE_TIME = 0.3

function MobBat:ctor(args)
	args = args or {}
	args.image = "bat.png"
	args.type = Mob.TYPE_BAT

	MobBat.super.ctor(self, args)
end

return MobBat
