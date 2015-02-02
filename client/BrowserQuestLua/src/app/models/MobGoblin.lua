
local Mob = import(".Mob")
local MobGoblin = class("MobGoblin", Mob)

function MobGoblin:ctor(args)
	args = args or {}
	args.image = "goblin.png"
	args.type = Mob.TYPE_GOBLIN

	MobGoblin.super.ctor(self, args)
end

return MobGoblin
