
local NetMsgConstants = import("..network.NetMsgConstants")
local NetMsg = import("..network.NetMsg")
local Play = class("Play")

function Play:move(args)
	local msg = NetMsg.parser(args)
	local body = msg:getBody()
	local player = World:getPlayerById(body.id)
	player:setPos(body.to)
	player:save()

	-- World:playerMove(args)
end

function Play:attack(args)
	local msg = NetMsg.parser(args)
	local body = msg:getBody()

	local player = World:getPlayerById(body.sender)
	player:save()
	local mob = World:getEntityById(body.target)
	local reduceBoold = -(10 + math.random(1, 10))
	local afterboold = mob:healthChange(reduceBoold)

	printInfo("HTL Play attack boold:%d", afterboold)
	body.healthChange = reduceBoold
	body.dead = (afterboold <= 0)
	World:sendMsg(msg:getAction(), body)
end

return Play
