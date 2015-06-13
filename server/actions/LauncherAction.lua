
local Launcher = class("Launcher")

function Launcher:ctor(connect)
	self.connect_ = connect
end

function Launcher:getsessionidAction(args)
	if not args.appName or "BrowerQuestLua" ~= args.appName then
		throw("invalid launcher command")
	end

    local session = self.connect_:newSession()
    session:save()

    return {sid = session:getSid()}
end

return Launcher
