
local NPC = import(".NPC")
local NPCCoder = class("NPCCoder", NPC)

function NPCCoder:ctor(args)
	args = args or {}
	args.image = "coder.png"
	args.type = NPC.TYPE_CODER
	args.sentences = {
		"Hi! Do you know that you can also play BrowserQuest on your tablet or mobile?",
        "That's the beauty of cocos-lua!",
        "Give it a try..."
		}

	NPCCoder.super.ctor(self, args)
end

return NPCCoder
