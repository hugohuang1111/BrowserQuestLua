
local NetMsg = import("..network.NetMsg")
local Map = import(".Map")
local Entity = import(".Entity")
local Player = import(".Player")
local RedisService = cc.load("redis").service
local World = class("World")

local _MAP_LOAD_ = "ismapLoad"
local _REDIS_KEY_SETS_ENTITY_STATIC_ = "StaticEntitySets"
local _CHANNEL_ALL_ = "ChannelAll"
local _REDIS_KEY_SETS_PLAYER_ = "PlayerSets"
local _REDIS_KEY_ID_COUNTER_ = "IDCounter"
local IDCounterBegin = 100001

function World:ctor(connect)
	self.connect_ = connect
	self.redis_ = RedisService:create(connect.config.redis)
    self.redis_:connect()

    self.player_ = {}
end

function World:setMapPath(path)
	self.mapPath_ = path
end

function World:clearRedis()
	local redis = self.redis_
	redis:command("SET", _MAP_LOAD_, "no")
end

function World:initMapIf()
	local redis = self.redis_
	redis:command("SET", _MAP_LOAD_, "no")
	local isLoaded = redis:command("GET", _MAP_LOAD_)
	local entitys = {}
	if not isLoaded or "no" == isLoaded then
		printInfo("htl map load:%s", tostring(isLoaded))
		local map = Map.new(self.mapPath_)

		-- generate static entity
		local staticEntity = map:getStaticEntity()
		local idCounter = 1001

		for idx, name in pairs(staticEntity) do
			local p = map:getPosByTileIdx(idx)
			local entity = Entity.new()
			entity:setPos(p)
			entity:setRedis(redis)
			entity:setId(idCounter)
			entity:setHealth(100)
			entity:setName(name)
			idCounter = idCounter + 1

			entity:save()
			entitys[#entitys + 1] = entity

			redis:command("SADD", _REDIS_KEY_SETS_ENTITY_STATIC_, entity:getId())
		end

		redis:command("SET", _MAP_LOAD_, "yes")
	else
		local ids = redis:command("SMEMBERS", _REDIS_KEY_SETS_ENTITY_STATIC_)
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
	playerInfo.pos = entity:getPos() or cc.p(math.random(35, 40), math.random(220, 240)) -- cc.p(35, 230)

	local idCounter
	idCounter = entity:getId()
	if not idCounter then
		idCounter = self.redis_:command("INCR", _REDIS_KEY_ID_COUNTER_)
		if 1 == idCounter then
			self.redis_:command("SET", _REDIS_KEY_ID_COUNTER_, IDCounterBegin)
			idCounter = IDCounterBegin
		end
	end
	playerInfo.id = idCounter

	return playerInfo
end

function World:getPlayerEntity(name, id)
	local entity = Player.new()
	local attr
	if id then
		entity:load(id)
	else
		entity:setArmor("clotharmor.png")
		entity:setWeapon("sword1.png")
		if string.len(name) > 10 then
			playerInfo.nickName = string.sub(name, 1, 10)
		end
		entity:setNickName(name)
		math.randomseed(os.time())
		entity:setPos(cc.p(math.random(35, 45), math.random(223, 234)))

		local idCounter
		idCounter = self.redis_:command("INCR", _REDIS_KEY_ID_COUNTER_)
		if 1 == idCounter then
			self.redis_:command("SET", _REDIS_KEY_ID_COUNTER_, IDCounterBegin)
			idCounter = IDCounterBegin
		end
		entity:setId(idCounter)

		entity:save()
	end

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

function World:setPlayerStatus(id, isOnline)
	if isOnline then
		self.redis_:command("SADD", _REDIS_KEY_SETS_PLAYER_, id)
	else
		self.redis_:command("SREM", _REDIS_KEY_SETS_PLAYER_, id)
	end
end

function World:getOnlinePlayer()
	local players = self.redis_:command("SMEMBERS", _REDIS_KEY_SETS_PLAYER_)
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



function World:playerEntry(id)
	local playerId = id
	if not playerId then
		return
	end
	self.connect_:setConnectTag(playerId)
	self:setPlayerStatus(playerId, true)

	local player = Player.new()
	player:load(id)

	local msg = NetMsg.new()
	msg:setAction("user.entry")
	msg:setBody(player:getPlayerInfo())

	self.connect_:sendMessageToChannel(_CHANNEL_ALL_, msg:getString())
end

function World:playerQuit(id)
	local playerId = id
	if not playerId then
		playerId = self.connect_:getConnectTag()
	end
	self:setPlayerStatus(playerId, false)

	local msg = NetMsg.new()
	msg:setAction("user.bye")
	msg:setBody({id = id})

	self.connect_:sendMessageToChannel(_CHANNEL_ALL_, msg:getString())
end

function World:playerMove(args)
	local playerId = id
	if not playerId then
		playerId = self.connect_:getConnectTag()
	end

	local msg = NetMsg.new()
	msg:setAction("play.move")
	msg:setBody(args)

	self.connect_:sendMessageToChannel(_CHANNEL_ALL_, msg:getString())
end

function World:broadcast(action, args)
	local msg = NetMsg.new()
	msg:setAction(action)
	msg:setBody(args)
	self.connect_:sendMessageToChannel(_CHANNEL_ALL_, msg:getString())
end

function World:sendMsg(action, args)
	local msg = NetMsg.new()
	msg:setAction(action)
	msg:setBody(args)
	self.connect_:sendMessageToSelf(msg:getString())
end


function World:subscribeChannel()
    self.connect_:subscribeChannel(_CHANNEL_ALL_, function(msg)
        self.connect_:sendMessageToSelf(msg)
        return true
    end)
end

function World:unsubscribeChannel()
    self.connect_:unsubscribeChannel(_CHANNEL_ALL_)
end


return World
