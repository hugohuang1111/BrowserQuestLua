
local NetMsgConstants = import("..network.NetMsgConstants")
local NetMsg = import("..network.NetMsg")

local User = class("User")

function User:ctor(connect)
	self.connect_ = connect
end

function User:welcome(args)
	printInfo("User welcome entity")
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
	player:save()

	playerInfo = player:getPlayerInfo()

	local body = {}
	body.playerInfo = playerInfo
	body.entitysStatic = World:getEntitysStaticInfo()
	body.onlinePlayers = onLine

	msg:setBody(body)
	self.connect_:sendMessageToSelf(msg:getString())

	World:playerEntry(playerInfo.id)

	printInfo("User welcome exit")
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

function User:move(args)
	local msg = NetMsg.parser(args)
	local body = msg:getBody()
	local entity = World:getEntity(body.id)
	entity:setPos(body.to)
	if entity.getPlayerInfo then
		-- entity is player instance
		entity:healthChange(1)
	end
	entity:save()

	World:broadcast("user.move", body)
end

function User:attack(args)
	local msg = NetMsg.parser(args)
	local body = msg:getBody()

	local sender = World:getEntity(body.sender)
	local target = World:getEntity(body.target)
	local reduceBoold = -10 -- (10 + math.random(1, 10))
	local afterboold = target:healthChange(reduceBoold)
	body.healthChange = reduceBoold
	body.dead = (afterboold <= 0)

	World:broadcast("user.attack", body)

	if body.dead then
		if target:isMob() then
			World:broadcast("mob.dead", {id = body.target})
			target:reborn()
		else
			sender:setAttack(0)
			World:broadcast("user.dead", {id = body.target})
		end
	else
		local attackId = target:getAttack()
		if 0 == attackId then
			target:setAttack(body.sender)
			World:sendMsg("mob.attack", {sender = body.target, target = body.sender})
		end
	end
end

function User:cancelAttack(args)
	local msg = NetMsg.parser(args)
	local body = msg:getBody()

	local sender = World:getEntity(body.sender)
	local target = World:getEntity(body.target)
	target:setAttack(0)
end

return User
