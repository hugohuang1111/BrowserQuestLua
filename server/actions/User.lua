
local NetMsgConstants = import("...share.NetMsgConstants")
local NetMsg = import("...share.NetMsg")

local User = class("User")

function User:ctor(connect)
	self.connect_ = connect
end

function User:welcome(args)
	local msg = NetMsg.new()
	local playerInfo = args

	if not playerInfo.nickName or 0 == string.len(playerInfo.nickName) then
		msg:setError(NetMsgConstants.ERROR_NICKNAME_NULL)
		return msg:getData()
	end

	playerInfo.imageName = playerInfo.imageName or "clotharmor.png"
	playerInfo.weaponName = playerInfo.weaponName or "sword1.png"
	if string.len(playerInfo.nickName) > 10 then
		playerInfo.nickName = string.sub(playerInfo.nickName, 1, 10)
	end

	msg:setBody(playerInfo)
	return msg:getData()
end

return User
