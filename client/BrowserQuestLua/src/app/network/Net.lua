
local Net = class("Net")

local gInstance = nil

Net.new_ = Net.new
Net.new = nil

Net.CMD_CONNECT 		= 1
Net.CMD_DISCONNECT 		= 2
Net.CMD_SEND			= 3


function Net.getInstance()
	if not gInstance then
		gInstance = Net.new_()
	end

	return gInstance
end

function Net:ctor()
	self.ws_ = nil

	self.sendCmds_ = {}
end

function Net:connect(addr, protocol)
	local addr = "ws://" .. self.addr_ .. "/socket"
	local ws = cc.WebSocket:createByAProtocol(addr, protocol)

	ws:registerScriptHandler(handler(self, self.wsOpen), cc.WEBSOCKET_OPEN)
    ws:registerScriptHandler(handler(self, self.wsMessage), cc.WEBSOCKET_MESSAGE)
    ws:registerScriptHandler(handler(self, self.wsClose), cc.WEBSOCKET_CLOSE)
    ws:registerScriptHandler(handler(self, self.wsError), cc.WEBSOCKET_ERROR)

    self.ws_ = ws
end

function Net:disconnect()
	if self.ws_ then
		self.ws_:close()
	end
end

function Net:wsOpen()
	printInfo("Net ws open")
	self:operCmd_()
	if self.openCB_ then
		self.openCB_()
	end
end

function Net:wsMessage(data)
	-- printInfo("Net ws message")
	if self.messageCB_ then
		self.messageCB_(data)
	end
	if self.callback_ then
		self.callback_(data)
	end
end

function Net:wsClose()
	self.ws_ = nil
	printInfo("Net ws close")
	if self.closeCB_ then
		self.closeCB_()
	end
end

function Net:wsError(data)
	printInfo("Net ws error")
	if self.errorCB_ then
		self.errorCB_(data)
	end
end

function Net:onOpen(callback)
	self.openCB_ = callback
end

function Net:onMessage(callback)
	self.messageCB_ = callback
end

function Net:onClose(callback)
	self.closeCB_ = callback
end

function Net:onError(callback)
	self.errorCB_ = callback
end

function Net:on(callback)
	self.callback_ = callback
end

function Net:setAddr(addr)
	self.addr_ = addr
end

function Net:getSessionId()
	return self.sessionId_
end

function Net:send(args)
	self:sendCmd(Net.CMD_SEND, args)
end

function Net:sendCmd(cmd, args)
	local d = {cmd = cmd, data = args}
	table.insert(self.sendCmds_, d)

	local scheduler = cc.Director:getInstance():getScheduler()
	local handler
	handler = scheduler:scheduleScriptFunc(function()
		scheduler:unscheduleScriptEntry(handler)
		self:operCmd_()
	end, 0.01, false)
end

function Net:operCmd_()
	while true do
		local cmd = self.sendCmds_[1]
		if not cmd then
			return
		end

		if Net.CMD_CONNECT == cmd.cmd then
			if not self.ws_ or cc.WEBSOCKET_STATE_CLOSED == self.ws_:getReadyState() then
				if self.protocol_ then
					self:connect(self.addr_, self.protocol_)
				else
					self:launch()
				end
				return
			end
		elseif Net.CMD_DISCONNECT == cmd.cmd then
			if self.ws_
				and (cc.WEBSOCKET_STATE_CONNECTING == self.ws_:getReadyState()
					or cc.WEBSOCKET_STATE_OPEN == self.ws_:getReadyState()) then
				self:disconnect()
			end
		elseif Net.CMD_SEND == cmd.cmd then
			if not self.ws_ then
				if self.protocol_ then
					self:connect(self.addr_, self.protocol_)
				else
					self:launch()
				end
				return
			elseif cc.WEBSOCKET_STATE_OPEN == self.ws_:getReadyState() then
				self:sendReal_(cmd.data)
				table.remove(self.sendCmds_, 1)
			else
				printInfo("Net operCmd error")
			end
		end
	end
end

function Net:sendReal_(data)
	printInfo("NET send real data:%s", data)
	self.ws_:sendString(data)
end

function Net:launch()
	local addr = "http://" .. self.addr_ .. "/api?action=launcher.getsessionid"

	local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xhr:open("POST", addr)

    local function onReadyStateChange()
    	local isSuccess = false
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
        	local resp = json.decode(xhr.response)
        	if resp or resp.sid then
        		self.sessionId_ = resp.sid
        		self.protocol_ = "quickserver-" .. self.sessionId_
            	self:connect(self.addr_, self.protocol_)
            	isSuccess = true
            else
        		printError("Net:Luanch fail, session id nil")
        	end
        else
            printError("Net:Luanch fail, http state:%d, status:%d", xhr.readyState, xhr.status)
        end
        if not isSuccess then
        	self.callback_({err = 1, description = "get session fail"})
        end
    end

    xhr:registerScriptHandler(onReadyStateChange)
    xhr:send("appName=BrowerQuestLua")
    self.isLaunching_ = true

end


return Net
