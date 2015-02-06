
local NetMsgConstants = import("..network.NetMsgConstants")
local NetMsg = import("..network.NetMsg")

local User = class("User")

function User:ctor(connect)
	self.connect_ = connect
end

function User:welcome(args)
	local msg = NetMsg.parser(args)
	local playerInfo = msg:getBody()

	if not playerInfo.nickName or 0 == string.len(playerInfo.nickName) then
		msg:setError(NetMsgConstants.ERROR_NICKNAME_NULL)
		return msg:getData()
	end

	playerInfo.imageName = playerInfo.imageName or "clotharmor.png"
	playerInfo.weaponName = playerInfo.weaponName or "sword1.png"
	if string.len(playerInfo.nickName) > 10 then
		playerInfo.nickName = string.sub(playerInfo.nickName, 1, 10)
	end

	-- born position
	playerInfo.pos = cc.p(35, 230)

	msg:setBody(playerInfo)
	return msg:getData()
end

return User
