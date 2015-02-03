
local NPC = import(".NPC")
local NPCAgent = class("NPCAgent", NPC)

function NPCAgent:ctor(args)
	args = args or {}
	args.image = "agent.png"
	args.type = NPC.TYPE_AGENT
	args.sentences = {
		"Do not try to bend the sword",
        "That's impossible",
        "Instead, only try to realize the truth...",
        "There is no sword."
		}


	NPCAgent.super.ctor(self, args)
end

return NPCAgent
