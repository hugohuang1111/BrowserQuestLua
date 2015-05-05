
local NetMsg = import("..network.NetMsg")
local Map = import(".Map")
local Entity = import(".Entity")
local Player = import(".Player")
local RedisService = cc.load("redis").service
local JobService = cc.load("job").service
local BeansService = cc.load("beanstalkd").service
local World = class("World")

local Constant = import(".Constant")

function World:ctor(connect)
	self.connect_ = connect
	self.redis_ = RedisService:create(connect.config.redis)
    self.redis_:connect()

    self.player_ = {}
    self.attackIds_ = {}
end

function World:setMapPath(path)
	self.mapPath_ = path
end

function World:clearRedis()
	local redis = self.redis_
	redis:command("SET", Constant._MAP_LOAD_, "no")
end

function World:initMapIf()
	local redis = self.redis_
	-- redis:command("SET", Constant._MAP_LOAD_, "no")
	local isLoaded = redis:command("GET", Constant._MAP_LOAD_)
	local entitys = {}
	if not isLoaded or "no" == isLoaded then
		local map = Map.new(self.mapPath_)

		-- generate static entity
		local staticEntity = map:getStaticEntity()
		local idCounter = 1001

		for idx, name in pairs(staticEntity) do
			local p = map:getPosByTileIdx(idx)
			local entity = Entity.new()
			entity:setPos(p)
			entity:setRoamingArea(cc.rect(p.x, p.y, 1, 1))
			entity:setRedis(redis)
			entity:setId(idCounter)
			entity:setHealth(100)
			entity:setName(name)
			idCounter = idCounter + 1

			entity:save()
			entitys[#entitys + 1] = entity

			redis:command("SADD", Constant._REDIS_KEY_SETS_ENTITY_STATIC_, entity:getId())
		end

		-- generate roaming mobs
		-- local roamingArea = map:getRoamingArea()
		-- for i,area in ipairs(roamingArea) do
		-- 	local rect = cc.rect(area.x, area.y, area.width, area.height)
		-- 	for i=1, area.nb do
		-- 		local entity = Entity.new()
		-- 		entity:setRoamingArea(rect)
		-- 		entity:setRandomPos()
		-- 		entity:setRedis(redis)
		-- 		entity:setId(idCounter)
		-- 		entity:setHealth(100)
		-- 		entity:setName(area.type)

		-- 		idCounter = idCounter + 1

		-- 		entity:save()
		-- 		entitys[#entitys + 1] = entity

		-- 		redis:command("SADD", Constant._REDIS_KEY_SETS_ENTITY_STATIC_, entity:getId())
		-- 	end
		-- end

		-- launch game loop timer
		self:schedule("schedule.loop", self.connect_.config, 1)

		redis:command("SET", Constant._MAP_LOAD_, "yes")
	else
		local ids = redis:command("SMEMBERS", Constant._REDIS_KEY_SETS_ENTITY_STATIC_)
		for i,id in ipairs(ids) do
			local entity = Entity.new()
			entity:setRedis(redis)
			entity:load(id)

			entitys[#entitys + 1] = entity
		end
	end
	self.entitysStatic_ = entitys
end

function World:getRedis()
	return self.redis_
end

function World:getEntitysStaticInfo()
	local entitys = self.entitysStatic_

	local infos = {}
	for i,info in ipairs(entitys) do
		table.insert(infos, info:getAttribute())
	end

	return infos
end

function World:getEntityById(id)
	local entity = Entity.new()
	entity:load(id)

	return entity
end

function World:getRebornPos()
	return cc.p(math.random(32, 43), math.random(224, 232))
end

function World:getPlayerInfo(name, id)
	local entity = Player.new()
	local attr
	if id then
		entity:load(id)
	end
	local playerInfo = {}
	playerInfo.imageName = entity:getArmor() or "clotharmor.png"
	playerInfo.weaponName = entity:getWeapon() or "sword1.png"
	if string.len(name) > 10 then
		playerInfo.nickName = string.sub(name, 1, 10)
	end

	-- born position
	math.randomseed(os.time())
	playerInfo.pos = entity:getPos() or self:getRebornPos() -- cc.p(35, 230)

	local idCounter
	idCounter = entity:getId()
	if not idCounter then
		idCounter = self.redis_:command("INCR", Constant._REDIS_KEY_ID_COUNTER_)
		if 1 == idCounter then
			self.redis_:command("SET", Constant._REDIS_KEY_ID_COUNTER_, Constant.IDCounterBegin)
			idCounter = Constant.IDCounterBegin
		end
	end
	playerInfo.id = idCounter

	return playerInfo
end

function World:getPlayerEntity(name, id)
	local entity
	local attr
	if string.len(name) > 10 then
		name = string.sub(name, 1, 10)
	end
	if id then
		entity = Player.new()
		if not entity:load(id) then
			entity = self:newPlayer()
		end
	else
		entity = self:newPlayer()
	end
	entity:setNickName(name)
	entity:save()

	return entity
end

function World:newPlayer()
	local entity = Player.new()
	entity:setArmor("clotharmor.png")
	entity:setWeapon("sword1.png")
	math.randomseed(os.time())
	entity:setPos(cc.p(math.random(35, 45), math.random(223, 234)))

	local idCounter
	idCounter = self.redis_:command("INCR", Constant._REDIS_KEY_ID_COUNTER_)
	if 1 == idCounter then
		self.redis_:command("SET", Constant._REDIS_KEY_ID_COUNTER_, Constant.IDCounterBegin)
		idCounter = Constant.IDCounterBegin
	end
	entity:setId(idCounter)

	return entity
end

function World:newPlayerEntity(playerInfo)
	local entity = Player.new()
	entity:setPos(playerInfo.pos)
	entity:setRedis(self.redis_)
	entity:setId(playerInfo.id)
	entity:setHealth(100)
	entity:setType(Entity.TYPE_WARRIOR)
	entity:setArmor(playerInfo.imageName)
	entity:setWeapon(playerInfo.weaponName)

	entity:save()
	table.insert(self.player_, entity)
end

function World:getPlayerById(id)
	local player = Player.new()
	player:load(id)

	return player
end

function World:getEntity(id)
	local cls
	if id >= Constant.IDCounterBegin then
		cls = Player
	else
		cls = Entity
	end

	local entity = cls.new()
	entity:load(id)

	return entity
end

function World:setPlayerStatus(id, isOnline)
	if isOnline then
		self.redis_:command("SADD", Constant._REDIS_KEY_SETS_PLAYER_, id)
	else
		self.redis_:command("SREM", Constant._REDIS_KEY_SETS_PLAYER_, id)
	end
end

function World:getOnlinePlayer()
	local players = self.redis_:command("SMEMBERS", Constant._REDIS_KEY_SETS_PLAYER_)
	if not players then
		return
	end

	local playerInfos = {}
	local player = Player.new()
	for i,v in ipairs(players) do
		player:load(v)
		table.insert(playerInfos, player:getPlayerInfo())
	end

	return playerInfos
end

function World:addAttackEntity(id)
	table.insert(self.attackIds_, id)
end

function World:removeAttackEntity(id)
	local pos
	for i,v in ipairs(self.attackIds_) do
		if v == id then
			pos = i
			break
		end
	end
	table.remove(self.attackIds_, pos)
end

function World:clearAttack(playerId)
	for i,v in ipairs(self.attackIds_) do
		local entity = self:getEntity(v)
		if playerId == entity:getAttack() then
			entity:setAttack(0)
		end
	end
	self.attackIds_ = {}
end



function World:playerEntry(id)
	local playerId = id
	if not playerId then
		return
	end
	self.curPlayId_ = playerId
	self:setPlayerStatus(playerId, true)

	local player = Player.new()
	player:load(id)

	local msg = NetMsg.new()
	msg:setAction("user.entry")
	msg:setBody(player:getPlayerInfo())

	self.connect_:sendMessageToChannel(Constant._CHANNEL_ALL_, msg:getString())
end

function World:playerQuit(id)
	local playerId = id
	if not playerId then
		playerId = tonumber(self.curPlayId_)
	end
	self:setPlayerStatus(playerId, false)

	local msg = NetMsg.new()
	msg:setAction("user.bye")
	msg:setBody({id = playerId})

	self.connect_:sendMessageToChannel(Constant._CHANNEL_ALL_, msg:getString())

	self:clearAttack(playerId)
end

function World:playerMove(args)
	local msg = NetMsg.new()
	msg:setAction("play.move")
	msg:setBody(args)

	self.connect_:sendMessageToChannel(Constant._CHANNEL_ALL_, msg:getString())
end

function World:broadcast(action, args)
	local msg = NetMsg.new()
	msg:setAction(action)
	msg:setBody(args)
	self.connect_:sendMessageToChannel(Constant._CHANNEL_ALL_, msg:getString())
end

function World:broadcastNetMsg(action, netMsg)
	self.connect_:sendMessageToChannel(Constant._CHANNEL_ALL_, netMsg:getString())
end

function World:sendMsg(action, args)
	local msg = NetMsg.new()
	msg:setAction(action)
	msg:setBody(args)
	self.connect_:sendMessageToSelf(msg:getString())
end


function World:subscribeChannel()
    self.connect_:subscribeChannel(Constant._CHANNEL_ALL_, function(msg)
        self.connect_:sendMessageToSelf(msg)
        return true
    end)
end

function World:unsubscribeChannel()
    self.connect_:unsubscribeChannel(Constant._CHANNEL_ALL_)
end

function World:schedule(action, data, delay)
	local beans = BeansService.new(self.connect_.config.beanstalkd)
	beans:connect()
	local job = JobService.new(self.redis_, beans, self.connect_.config)
	job:add(action, data, delay)
end


return World
