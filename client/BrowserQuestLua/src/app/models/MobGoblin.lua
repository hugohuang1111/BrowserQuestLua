
local Mob = import(".Mob")
local MobGoblin = class("MobGoblin", Mob)

function MobGoblin:ctor(args)
	args = args or {}
	args.image = "goblin.png"
	args.type = Mob.TYPE_GOBLIN

	self.super.ctro(self, args)
end

return MobGoblin
