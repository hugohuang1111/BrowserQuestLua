
local Launcher = class("Launcher")

function Launcher:ctor(connect)
	printWarn("Launcher ctor entery")
	self.connect_ = connect
end

function Launcher:getsessionid(args)
	printInfo("Launcher htl:%s", json.encode(args))
	if not args.appName or "BrowerQuestLua" ~= args.appName then
		throw("invalid launcher command")
	end

    local session = self.connect_:newSession()
    session:save()

    return {sid = session:getSid()}
end

return Launcher
