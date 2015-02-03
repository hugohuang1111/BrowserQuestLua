
local NPC = import(".NPC")
local NPCDesert = class("NPCDesert", NPC)

function NPCDesert:ctor(args)
	args = args or {}
	args.image = "desertnpc.png"
	args.type = NPC.TYPE_DESERTNPC
	args.sentences = {
		"One does not simply walk into these mountains...",
        "An ancient undead lord is said to dwell here.",
        "Nobody knows exactly what he looks like...",
        "...for none has lived to tell the tale.",
        "It's not too late to turn around and go home, kid."
		}

	NPCDesert.super.ctor(self, args)
end

return NPCDesert
