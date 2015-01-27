
local Mob = import(".Mob")
local MobSkeleton2 = class("MobSkeleton2", Mob)

function MobSkeleton2:ctor(args)
	args = args or {}
	args.image = "skeleton2.png"
	args.type = Mob.TYPE_SKELETON2

	self.super.ctro(self, args)
end

return MobSkeleton2
