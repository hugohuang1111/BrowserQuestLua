
local NPC = import(".NPC")
local NPCForest = class("NPCForest", NPC)

function NPCForest:ctor(args)
	args = args or {}
	args.image = "forestnpc.png"
	args.type = NPC.TYPE_FORESTNPC
	args.sentences = {
		"lorem ipsum dolor sit amet",
        "consectetur adipisicing elit, sed do eiusmod tempor"
		}

	NPCForest.super.ctor(self, args)
end

return NPCForest
