
local NetMsgConstants = import("..network.NetMsgConstants")
local NetMsg = import("..network.NetMsg")

local User = class("User")

function User:ctor(connect)
	self.connect_ = connect
end

function User:welcome(args)
	local msg = NetMsg.parser(args)
	local playerInfo = msg:getBody()
	msg:setBody(nil)

	if not playerInfo.nickName or 0 == string.len(playerInfo.nickName) then
		msg:setError(NetMsgConstants.ERROR_NICKNAME_NULL)
		return msg:getData()
	end

	local onLine = World:getOnlinePlayer()

	local player = World:getPlayerEntity(playerInfo.nickName, playerInfo.id)
	player:resetHealth()

	playerInfo = player:getPlayerInfo()

	local body = {}
	body.playerInfo = playerInfo
	body.entitysStatic = World:getEntitysStaticInfo()
	body.onlinePlayers = onLine

	msg:setBody(body)
	self.connect_:sendMessageToSelf(msg:getString())

	World:playerEntry(playerInfo.id)
end

function User:reborn(args)
	local msg = NetMsg.parser(args)
	local playerInfo = msg:getBody()
	msg:setBody(nil)

	if not playerInfo.id or 0 == playerInfo.id then
		msg:setError(NetMsgConstants.ERROR_NICKNAME_NULL)
		return msg:getData()
	end

	local player = World:getPlayerById(playerInfo.id)
	local pos = World:getRebornPos()
	player:setPos(pos)
	player:resetHealth()
	player:save()

	msg:setBody(player:getPlayerInfo())

	return msg:getData()
end

function User:info(args)
	local msg = NetMsg.parser(args)
	local body = msg:getBody()
	local entity = World:getEntity(body.id)
	if not entity then
		return
	end
	if body.pos then
		entity:setPos(body.pos)
	end
	if body.orientation then
		entity:setOrientation(body.orientation)
	end
	entity:save()
end

return User
