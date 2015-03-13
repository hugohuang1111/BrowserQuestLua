
local ngx_thread_spawn = ngx.thread.spawn
local BeansTalkdService = cc.load("beanstalkd").service
local Timer = class("Timer")

function Timer:ctor(cfg, session)
	local talk = BeansTalkdService:create(cfg)
	talk:connect()
	local ok, err = talk:command("use", session or "timer")
	if not ok then
		printInfo("Timer:ctor fail use tube:%s", err)
	end

	self.beanstalkd_ = talk
	self.tube_ = session
	self.jobs_ = {}
end

function Timer:start()
	self.isRunning = true
	local getJob = function()
		while self.isRunning do
			local id, err = self.beanstalkd_:command("reserve")
			if not id then
				printInfo("Timer:getJob fail:%s", err)
				return
			end
			local func = self:getFunc(id)
			func()
			self.beanstalkd_:command("delete", id)
		end
	end

	local thread = ngx_thread_spawn(getJob)
    printInfo("Timer:start spawn subscribe thread \"%s\"", tostring(thread))
end

function Timer:stop()
	self.isRunning = false
	self.beanstalkd_:setKeepAlive(0, 100)
	self.beanstalkd_:close()
end

function Timer:perform(func, delay)
	local id = self:addJob_()
	if not id then
		return
	end
	local job = {
		id = id,
		func = func}
	table.insert(self.jobs_, job)
end

function Timer:addJob_(delay)
	local talk = self.beanstalkd_
	local id, err = talk:command("put", "timer", nil, delay)
	if not id then
		printInfo("Timer:addJob_ put job fail:%s", err)
		return
	end
	return id
end

function Timer:getFunc(id)
	for i,v in ipairs(self.jobs_) do
		if v.id == id then
			return v.func
		end
	end

	return
end


return Timer
