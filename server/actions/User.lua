
local NetMsgConstants = import("..network.NetMsgConstants")
local NetMsg = import("..network.NetMsg")

local User = class("User")

function User:ctor(connect)
	self.connect_ = connect
end

function User:welcome(args)
	local msg = NetMsg.parser(args)
	local playerInfo = msg:getBody()

	printInfo("User:welcome id:%s", tostring(playerInfo.id))

	if not playerInfo.nickName or 0 == string.len(playerInfo.nickName) then
		msg:setError(NetMsgConstants.ERROR_NICKNAME_NULL)
		return msg:getData()
	end

	local onLine = World:getOnlinePlayer()

	local player = World:getPlayerEntity(playerInfo.nickName, playerInfo.id)

	playerInfo = player:getPlayerInfo()

	local body = {}
	body.playerInfo = playerInfo
	body.entitysStatic = World:getEntitysStaticInfo()
	body.onlinePlayers = onLine

	msg:setBody(body)
	self.connect_:sendMessageToSelf(msg:getString())

	World:playerEntry(playerInfo.id)
end

return User
