
local Mob = import(".Mob")
local MobEye = class("MobEye", Mob)

function MobEye:ctor(args)
	args = args or {}
	args.image = "eye.png"
	args.type = Mob.TYPE_EYE

	self.super.ctro(self, args)
end

return MobEye
