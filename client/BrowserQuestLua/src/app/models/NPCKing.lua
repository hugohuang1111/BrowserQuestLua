
local NPC = import(".NPC")
local NPCKing = class("NPCKing", NPC)

function NPCKing:ctor(args)
	args = args or {}
	args.image = "king.png"
	args.type = NPC.TYPE_KING
	args.sentences = {
		"Hi, I'm the King",
        "I run this place",
        "Like a boss",
        "I talk to people",
        "Like a boss",
        "I wear a crown",
        "Like a boss",
        "I do nothing all day",
        "Like a boss",
        "Now leave me alone",
        "Like a boss"
		}

	NPCKing.super.ctor(self, args)
end

return NPCKing
