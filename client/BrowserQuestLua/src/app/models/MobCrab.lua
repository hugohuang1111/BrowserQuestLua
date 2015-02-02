
local Mob = import(".Mob")
local MobCrab = class("MobCrab", Mob)

function MobCrab:ctor(args)
	args = args or {}
	args.image = "crab.png"
	args.type = Mob.TYPE_CRAB
	MobCrab.super.ctor(self, args)
end

return MobCrab
