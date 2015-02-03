
local NPC = import(".NPC")
local NPCNyan = class("NPCNyan", NPC)

function NPCNyan:ctor(args)
	args = args or {}
	args.image = "nyan.png"
	args.type = NPC.TYPE_NYAN
	args.sentences = {
		"nyan nyan nyan nyan nyan",
        "nyan nyan nyan nyan nyan nyan nyan",
        "nyan nyan nyan nyan nyan nyan",
        "nyan nyan nyan nyan nyan nyan nyan nyan"
		}

	NPCNyan.super.ctor(self, args)
end

return NPCNyan
