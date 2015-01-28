
local Mob = import(".Mob")
local MobDeathknight = class("MobDeathknight", Mob)

function MobDeathknight:ctor(args)
	args = args or {}
	args.image = "deathknight.png"
	args.type = Mob.TYPE_DEATHKNIGHT

	MobDeathknight.super.ctro(self, args)
end

return MobDeathknight
