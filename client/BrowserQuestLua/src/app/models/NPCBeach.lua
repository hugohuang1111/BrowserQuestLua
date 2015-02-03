
local NPC = import(".NPC")
local NPCBeach = class("NPCBeach", NPC)

function NPCBeach:ctor(args)
	args = args or {}
	args.image = "guard.png"
	args.type = NPC.TYPE_BEACHNPC

	args.sentences = {
		"lorem ipsum dolor sit amet",
        "consectetur adipisicing elit, sed do eiusmod tempor"
		}

	NPCBeach.super.ctor(self, args)
end

return NPCBeach
