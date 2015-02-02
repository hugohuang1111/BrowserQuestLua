
local Mob = import(".Mob")
local MobRat = class("MobRat", Mob)



function MobRat:ctor(args)
	args = args or {}
	args.image = "rat.png"
	args.type = Mob.TYPE_RAT

	MobRat.super.ctor(self, args)
end

return MobRat
