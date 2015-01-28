
local Mob = import(".Mob")
local MobSpectre = class("MobSpectre", Mob)

function MobSpectre:ctor(args)
	args = args or {}
	args.image = "spectre.png"
	args.type = Mob.TYPE_SPECTRE

	MobSpectre.super.ctro(self, args)
end

return MobSpectre
