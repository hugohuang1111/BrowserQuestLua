
local Mob = import(".Mob")
local MobSnake = class("MobSnake", Mob)

function MobSnake:ctor(args)
	args = args or {}
	args.image = "snake.png"
	args.type = Mob.TYPE_SNAKE

	MobSnake.super.ctor(self, args)
end

return MobSnake
