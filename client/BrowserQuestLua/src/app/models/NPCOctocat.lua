
local NPC = import(".NPC")
local NPCOctocat = class("NPCOctocat", NPC)

function NPCOctocat:ctor(args)
	args = args or {}
	args.image = "octocat.png"
	args.type = NPC.TYPE_OCTOCAT
	args.sentences = {
		"Welcome to BrowserQuest!",
        "Want to see the source code?",
        "Search BrowserQuestLua on GitHub htlxyz"
		}

	NPCOctocat.super.ctor(self, args)
end

return NPCOctocat
