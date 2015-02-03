
local NPC = import(".NPC")
local NPCGuard = class("NPCGuard", NPC)

function NPCGuard:ctor(args)
	args = args or {}
	args.image = "sorcerer.png"
	args.type = NPC.TYPE_SORCERER
	args.sentences = {
		"Ah... I had foreseen you would come to see me.",
        "Well? How do you like my new staff?",
        "Pretty cool, eh?",
        "Where did I get it, you ask?",
        "I understand. It's easy to get envious.",
        "I actually crafted it myself, using my mad wizard skills.",
        "But let me tell you one thing...",
        "There are lots of items in this game.",
        "Some more powerful than others.",
        "In order to find them, exploration is key.",
        "Good luck."
		}

	NPCGuard.super.ctor(self, args)
end

return NPCGuard
