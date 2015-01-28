
local Mob = import(".Mob")
local MobBoss = class("MobBoss", Mob)

function MobBoss:ctor(args)
	args = args or {}
	args.image = "boss.png"
	args.type = Mob.TYPE_BOSS

	MobBoss.super.ctro(self, args)
end

return MobBoss
