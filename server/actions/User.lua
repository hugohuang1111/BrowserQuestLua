
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

	local player = World:getPlayerEntity(playerInfo.nickName, playerInfo.id)

	playerInfo = player:getPlayerInfo()

	local body = {}
	body.playerInfo = playerInfo
	body.entitysStatic = World:getEntitysStaticInfo()

	msg:setBody(body)
	return msg:getData()
end

return User
