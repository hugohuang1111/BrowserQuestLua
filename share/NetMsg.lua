
local NetMsgConstants = import(".NetMsgConstants")
local NetMsg = class("NetMsg")

--[[

{
	err: 0	-- success
			1	-- general fail
			100	-- logic error
			101 -- nickname error
	desc: description of error
	body: connect
}

]]

function NetMsg.parser(data)
	if not data then
		return
	end

	local msg = NetMsg.new(data)

	return msg
end

function NetMsg.err(err)
	local msg = NetMsg.new()
	msg:setError(err)

	return msg
end

function NetMsg:ctor(data)
	if data then
		self.data_ = json.decode(data)
	else
		self.data_ = {}
		self.data_.err = NetMsgConstants.ERROR_SUCCESS
		self.data_.desc = "success"
	end
end

function NetMsg:isOK()
	if NetMsgConstants.ERROR_SUCCESS == self.data_.err then
		return true
	end
	return false
end

function NetMsg:getDesc()
	return self.data_.desc
end

function NetMsg:getBody()
	return self.data_.body
end

function NetMsg:setError(err)
	self.data_.err = err

	self:setDesc(err)
end

function NetMsg:setDesc(str)
	local types = type(str)
	if "string" == types then
		self.data_.desc = str
	elseif "number" == types then
		local err = str
		if NetMsgConstants.ERROR_SUCCESS == err then
			self.dataa_.desc = "success"
		elseif NetMsgConstants.ERROR_LOGIC == err then
			self.data_.desc = "logic error"
		elseif NetMsgConstants.ERROR_NICKNAME_NULL == err then
			self.data_.desc = "nickname is nil"
		else
			self.data_.desc = "fail"
		end
	end
end

function NetMsg:setBody(body)
	self.data_.body = body
end

function NetMsg:getString()
	return json.encode(self.data_)
end

function NetMsg:getData()
	return self.data_
end

return NetMsg
