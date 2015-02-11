
local NetMsgConstants = import("..network.NetMsgConstants")
local NetMsg = import("..network.NetMsg")
local Play = class("Play")

function Play:move(args)
	local msg = NetMsg.parser(args)
	local body = msg:getBody()
	local player = World:getPlayerById(body.id)
	player:setPos(body.to)
	player:save()

	World:broadcast("play.move", body)
end

function Play:attack(args)
	local msg = NetMsg.parser(args)
	local body = msg:getBody()

	local sender = World:getEntity(body.sender)
	sender:save()
	local target = World:getEntity(body.target)
	local reduceBoold = -(10 + math.random(1, 10))
	local afterboold = target:healthChange(reduceBoold)
	body.healthChange = reduceBoold
	body.dead = (afterboold <= 0)

	return msg:getData()
end

function Play:chat(args)
	local msg = NetMsg.parser(args)
	World:broadcastNetMsg("play.chat", msg)
end

return Play
