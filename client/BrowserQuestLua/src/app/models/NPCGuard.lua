
local NPC = import(".NPC")
local NPCGuard = class("NPCGuard", NPC)

function NPCGuard:ctor(args)
	args = args or {}
	args.image = "guard.png"
	args.type = NPC.TYPE_GUARD
	args.sentences = {
		"Hello there",
        "We don't need to see your identification",
        "You are not the player we're looking for",
        "Move along, move along..."
		}

	NPCGuard.super.ctor(self, args)
end

return NPCGuard
