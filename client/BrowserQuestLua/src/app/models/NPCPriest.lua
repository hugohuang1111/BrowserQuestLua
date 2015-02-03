
local NPC = import(".NPC")
local NPCGuard = class("NPCGuard", NPC)

function NPCGuard:ctor(args)
	args = args or {}
	args.image = "priest.png"
	args.type = NPC.TYPE_PRIEST
	args.sentences = {
		"Oh, hello, young man.",
        "Wisdom is everything, so I'll share a few guidelines with you.",
        "You are free to go wherever you like in this world",
        "but beware of the many foes that await you.",
        "You can find many weapons and armors by killing enemies.",
        "The tougher the enemy, the higher the potential rewards.",
        "You can also unlock achievements by exploring and hunting.",
        "Click on the small cup icon to see a list of all the achievements.",
        "Please stay a while and enjoy the many surprises of BrowserQuest",
        "Farewell, young friend."
		}

	NPCGuard.super.ctor(self, args)
end

return NPCGuard
