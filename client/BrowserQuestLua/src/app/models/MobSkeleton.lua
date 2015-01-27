
local Mob = import(".Mob")
local MobSkeleton = class("MobSkeleton", Mob)

function MobSkeleton:ctor(args)
	args = args or {}
	args.image = "skeleton.png"
	args.type = Mob.TYPE_SKELETON

	self.super.ctro(self, args)
end

return MobSkeleton
