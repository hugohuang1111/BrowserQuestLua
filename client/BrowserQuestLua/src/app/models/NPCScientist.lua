
local NPC = import(".NPC")
local NPCGuard = class("NPCGuard", NPC)

function NPCGuard:ctor(args)
	args = args or {}
	args.image = "scientist.png"
	args.type = NPC.TYPE_SCIENTIST
	args.sentences = {
		"Greetings.",
        "I am the inventor of these two potions.",
        "The red one will replenish your health points...",
        "The orange one will turn you into a firefox and make you invincible...",
        "But it only lasts for a short while.",
        "So make good use of it!",
        "Now if you'll excuse me, I need to get back to my experiments..."
		}

	NPCGuard.super.ctor(self, args)
end

return NPCGuard
