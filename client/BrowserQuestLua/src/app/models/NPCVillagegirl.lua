
local NPC = import(".NPC")
local NPCGuard = class("NPCGuard", NPC)

function NPCGuard:ctor(args)
	args = args or {}
	args.image = "villagegirl.png"
	args.type = NPC.TYPE_VILLAGEGIRL
	args.sentences = {
		"Hi there, adventurer!",
        "How do you like this game?",
        "It's all happening in a single web page! Isn't it crazy?",
        "It's all made possible thanks to WebSockets.",
        "I don't know much about it, after all I'm just a program."
		}

	NPCGuard.super.ctor(self, args)
end

return NPCGuard
