
local NPC = import(".NPC")
local NPCLava = class("NPCLava", NPC)

function NPCLava:ctor(args)
	args = args or {}
	args.image = "lavanpc.png"
	args.type = NPC.TYPE_LAVANPC
	args.sentences = {
		"lorem ipsum dolor sit amet",
        "consectetur adipisicing elit, sed do eiusmod tempor"
		}

	NPCLava.super.ctor(self, args)
end

return NPCLava
