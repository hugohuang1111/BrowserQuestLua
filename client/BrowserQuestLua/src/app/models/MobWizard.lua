
local Mob = import(".Mob")
local MobWizard = class("MobWizard", Mob)

function MobWizard:ctor(args)
	args = args or {}
	args.image = "wizard.png"
	args.type = Mob.TYPE_WIZARD

	MobWizard.super.ctro(self, args)
end

return MobWizard
