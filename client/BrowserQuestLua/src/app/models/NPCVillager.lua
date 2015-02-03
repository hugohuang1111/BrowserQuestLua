
local NPC = import(".NPC")
local NPCGuard = class("NPCGuard", NPC)

function NPCGuard:ctor(args)
	args = args or {}
	args.image = "villager.png"
	args.type = NPC.TYPE_VILLAGER
	args.sentences = {
		"Howdy stranger. Do you like poetry?",
        "Roses are red, violets are blue...",
        "I like hunting rats, and so do you...",
        "The rats are dead, now what to do?",
        "To be honest, I have no clue.",
        "Maybe the forest, could interest you...",
        "or instead, cook a rat stew."
		}

	NPCGuard.super.ctor(self, args)
end

return NPCGuard
