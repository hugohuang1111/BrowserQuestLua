
local Net = class("Net")

local gInstance = nil

Net.new_ = Net.new
Net.new = nil


function Net.getInstance()
	if not gInstance then
		gInstance = Net.new_()
	end

	return gInstance
end

function Net:ctor()
	self.ws_ = nil
end

function Net:connect(addr)
	local ws = cc.WebSocket:create(addr)

	ws:registerScriptHandler(handler(self, self.wsOpen), cc.WEBSOCKET_OPEN)
    ws:registerScriptHandler(handler(self, self.wsMessage), cc.WEBSOCKET_MESSAGE)
    ws:registerScriptHandler(handler(self, self.wsClose), cc.WEBSOCKET_CLOSE)
    ws:registerScriptHandler(handler(self, self.wsError), cc.WEBSOCKET_ERROR)

    self.ws_ = ws
end

function Net:wsOpen()
	printInfo("Net ws open")
	self.openCB_()
end

function Net:wsMessage(data)
	printInfo("Net ws message")
	self.messageCB_(data)
end

function Net:wsClose()
	printInfo("Net ws close")
	self.closeCB_()
end

function Net:wsError(data)
	printInfo("Net ws error")
	self.errorCB_(data)
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

function Net:send(str)
	local ws = self.ws_
	ws:sendString(str)
end

return Net
