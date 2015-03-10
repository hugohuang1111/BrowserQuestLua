
local NetMsgConstants = import("..network.NetMsgConstants")
local NetMsg = import("..network.NetMsg")
local Utilitys = import(".Utilitys")
local Types = import(".Types")
local Game = class("Game")
local AStar = import(".AStar")
local gInstance = nil

Game.new_ = Game.new
Game.new = nil

function Game.getInstance()
	if not gInstance then
		gInstance = Game.new_()
	end

	return gInstance
end

function Game:ctor()
	self.pathGrid_ = {}
	self.entitys_ = {}
	self.gameInfo_ = {}

	self:createNet()
	-- self:connect()
end

--[[ DATA STORG PART BEGIN ]]

function Game:loadData()
	local path = device.writablePath .. "browserquest.dat"
	local file = io.open(path)
	if not file then
		printInfo("game load data file not exist")
		return
	end

	local content = file:read("*a")	
	if content and string.len(content) > 0 then
		self.gameState = json.decode(content)
	end
	io.close(file)
end

function Game:saveData()
	local path = device.writablePath .. "browserquest.dat"
	local content = json.encode(self.gameState)

    local file = io.open(path, "w")
    if not file then
    	return
    end
    if not file:write(content) then
    	printError("Game:saveData write file fail")
    end
    io.close(file)
    file = nil
end

function Game:getPlayerData()
	if not self.gameState then
		return {nickName = Utilitys.genRandomName()}
	end

	return self.gameState.playerInfo
end

function Game:setPlayerData(playerData)
	self.gameState = self.gameState or {}
	self.gameState.playerInfo = playerData
end

--[[ DATA STORG PART END ]]


--[[ DATA NETWORK PART BEGIN ]]

function Game:createNet()
	self.net_ = require("app.network.Net").getInstance()
	self.net_:setAddr(SERVER_ADDR)
	self.net_:on(handler(self, self.netCallback))

	self.net_:launch()
end

function Game:netCallback(data)
	local str = tostring(data)
	if string.len(str) > 1000 then
		str = string.sub(str, 1, 1000)
	end
	-- printInfo("Game:netCallback data:%s", str)

	local msg = NetMsg.parser(data)
	if not msg:isOK() then
		printError("Game:netCallback netError:%d", msg:getError())
		return
	end

	local body = msg:getBody()
	local action = msg:getAction()
	printInfo("Game:netCallback action:%s", action)
	if "user.welcome" == action then
		self.gameState.playerInfo = body.playerInfo
		self.gameInfo_.entitysStatic = body.entitysStatic
		self.gameInfo_.onlinePlayers = body.onlinePlayers
		app:enterScene("GameScene")
		self:saveData()
	elseif "user.entry" == action then
		dump(body, "Game netCallback body:")
		if self.user_ and body.id ~= self.user_:getId() then
			self:createPlayer(body)
		else
			self.user_:setHealthPercent(body.healthPercent)
			self.onPlayerInfoChangeFunc_(self.user_)
		end
	elseif "user.bye" == action then
		local entity = self:findEntityById(body.id)
		if entity then
			self:removeEntity(entity)
		end
	elseif "user.reborn" == action then
		self.gameState.playerInfo = body
		self:createUser()

		app.curScene.camera_:look(self.user_, 1)
		self:onPlayerUIExit(handler(app.curScene, app.curScene.showRevive))
		self:onPlayerMove(handler(app.curScene, app.curScene.playerMoveHandler))

		local scene = cc.Director:getInstance():getRunningScene()
		local deadBg = app.curScene:getChildByTag(201)
		if deadBg then
			deadBg:removeSelf()
		end
	elseif "user.info" == action then
		local entity = self:findEntityById(body.id)
		if self:isSelf(entity) then
			self.user_:setHealthPercent(body.healthPercent)
			self.onPlayerInfoChangeFunc_(entity)
		end
	elseif "play.move" == action then
		-- if not self:isSelfCmd(msg) then
			-- if self.user_ and body.id ~= self.user_:getId() then
				local entity = self:findEntityById(body.id)
				printInfo("enity %s", tostring(entity))
				if entity then
					entity:doEvent("stop")
					entity:cancelAttackReq()
					entity:walkToPos(body.to, body.from)
				end
			-- end
		-- end
	elseif "play.dead" == action then
		local entity = self:findEntityById(body.id)
		printInfo("play entity %s user %s", tostring(entity), tostring(self.user_))
		-- self:removeEntity(entity)
		-- if entity.fllowEntity_ then
		-- 	entity.fllowEntity_.fllowEntity_ = nil
		-- end
		-- entity.fllowEntity_ = nil

		if entity then
			entity:doEvent("kill")
		end
	elseif "play.reborn" == action then
		self:createEntity(body)
	elseif "play.attackMove" == action then
		local target = self:findEntityById(body.target)
		local sender = self:findEntityById(body.sender)

		if not target then
			printInfo("Game attackMove target is nil %d", body.target)
			return
		end

		printInfo("Game attack entity sender:%d, target:%d", sender:getId(), target:getId())

		sender:attack(target)
	elseif "play.attack" == action then
		local target = self:findEntityById(body.target)
		local sender = self:findEntityById(body.sender)
		local userId = self.user_:getId()

		if not sender or not target then
			printInfo("Game netCallback sender or target is nil %d,%d", body.target, body.sender)
			return
		end
		if not sender.attackEntity_ then
			printInfo("Game netCallback sender's attackEntity_ is nil")
			return
		end

		if body.dead then
			return
		end

		if target then
			if body.target == userId or body.sender == userId then
				target:showReduceHealth(body.healthChange)
			end
			target:attackIf(sender)
		end

		if sender then
			sender:doEvent("attack",
				Utilitys.getOrientation(sender:getMapPos(), sender.attackEntity_:getMapPos()))
		end
	elseif "play.chat" == action then
		local player = self:findEntityById(body.id)
		if player then
			player:talkSentence(body.msg)
		end
		self.showWorldChat_(body)
	end
end

function Game:sendCmd(action, data)
	local msg = NetMsg.new()

	msg:setBody(data)
	msg:setAction(action)

	self:send(msg:getData())
end

function Game:send(data)
	data.session = self.net_:getSessionId()
	self.net_:send(json.encode(data))
end

function Game:isSelfCmd(netMsg)
	return self.net_:getSessionId() == netMsg:getSession()
end

--[[ DATA NETWORK PART END ]]

function Game:onPlayerUIExit(callback)
	self.user_:on("exit", function() callback() end)
end

function Game:onPlayerMove(callback)
	self.user_:on("move", function() callback(self.user_) end)
end

function Game:onPlayerInfoChange(callback)
	self.onPlayerInfoChangeFunc_ = callback
end

function Game:onWorldChat(callback)
	self.showWorldChat_ = callback
end

function Game:getGameInfo()
	return self.gameInfo_
end

function Game:setMap(map)
	self.map_ = map

	local mapSize = map:getMapSize()
	local tileSize = map:getTileSize()
	-- local scale = map:getScale()

	self.mapSize_ = mapSize
	self.tileSize_ = tileSize --cc.size(tileSize.width * scale, tileSize.height * scale)

	self:loadPathGrid_()

	-- debug
	-- self:addGridLayer_()
end

function Game:getMap()
	return self.map_
end

function Game:getTileSize()
	return self.tileSize_
end

function Game:getMapSize()
	return self.mapSize_
end

function Game:getMapSizePx()
	return cc.size(self.mapSize_.width * self.tileSize_.width, self.mapSize_.height * self.tileSize_.height)
end

function Game:createEntitys()
	local gameInfo = self.gameInfo_
	local entitys = gameInfo.entitysStatic

	if not entitys then
		return
	end

	for i,entityInfo in ipairs(entitys) do
		self:createEntity(entityInfo)
	end
end

function Game:createEntity(entityInfo)
	local cls
	local key = Utilitys.getKeyByValue(Types, entityInfo.type)
	if not key then
		return
	end
	local name = string.ucfirst(string.lower(string.sub(key, 6)))
	if entityInfo.type > Types.TYPE_MOBS_BEGIN and entityInfo.type < Types.TYPE_MOBS_END then
		cls = require("app.models.Mob" .. name)
	elseif entityInfo.type > Types.TYPE_NPCS_BEGIN and entityInfo.type < Types.TYPE_NPCS_END then
		if string.len(name) > 3 and "NPC" == string.upper(string.sub(name, -3)) then
			name = string.sub(name, 1, -4)
		end
		cls = require("app.models.NPC" .. name)
	else
		printInfo("Game:createEntity unsupport entity:" .. name)
		return
	end
	local entity = cls.new()
	entity:setMapPos(entityInfo.pos)
	entity:setId(entityInfo.id)
	self:addObject(entity)
end

function Game:createUser()
	local playerInfo = self:getPlayerData()
	local player = self:createPlayer(playerInfo)
	player:setUser(true)
	self.user_ = player

	return player
end

function Game:createOnlinePlayers()
	local onlinePlayers = self.gameInfo_.onlinePlayers

	for i,v in ipairs(onlinePlayers) do
		self:createPlayer(v)
	end
end

function Game:createPlayer(playerInfo)
	local player = require("app.models.Player").new({
		image = playerInfo.imageName,
		weaponName = playerInfo.weaponName,
		name = playerInfo.nickName
		})
	player:setMapPos(playerInfo.pos)
	player:setId(playerInfo.id)

	self.map_:addChild(player:getView(), 201)
	self:addEntity(player)

	return player
end

function Game:getUser()
	return self.user_
end



function Game:isSelf(entity)
	if entity == self.user_ then
		return true
	end
	return false
end

function Game:addMob(mob)
	self.map_:addChild(mob:getView(), 200)
	self:addEntity(mob)
end

function Game:addNPC(npc)
	self.map_:addChild(npc:getView(), 200)
	self:addEntity(npc)
end

function Game:addObject(entity)
	self.map_:addChild(entity:getView(), 200)
	self:addEntity(entity)
end

function Game:addEntity(entity)
	self.entitys_[entity:getIdx()] = entity
end

function Game:removeEntity(entity)
	printInfo("remove entity id:%d, type:%d", entity.id, entity.type_)
	entity:getView():removeSelf()
	self.entitys_[entity:getIdx()] = nil
end

function Game:findEntityByPos(p)
	local entitys = {}
	for k, v in pairs(self.entitys_) do
		if v.curPos_.x == p.x and v.curPos_.y == p.y then
			table.insert(entitys, v)
		end
	end

	return entitys
end

function Game:findEntityById(id)
	for k,v in pairs(self.entitys_) do
		if v:getId() == id then
			return v
		end
	end
end



function Game:findPath(endPoint, startPoint)
	startPoint = startPoint or self.user_:getMapPos()
	local path = AStar.findPath(startPoint, endPoint, self.pathGrid_, self.mapSize_.width, self.mapSize_.height)

	if not path then
		path = self:findIncompletePath_(endPoint)
	end

	return path
end

function Game:findIncompletePath_(endPoint)
	local startPoint = self.user_:getMapPos()
	local perfectPath = AStar.findPath(startPoint, endPoint, nil, self.mapSize_.width, self.mapSize_.height)
	if not perfectPath then
		return
	end

	local pos
	local path
	for i = #perfectPath, 1, -1 do
		pos = perfectPath[i]
		if not self.pathGrid_[pos.y][pos.x] then
			path = AStar.findPath(startPoint, pos, self.pathGrid_, self.mapSize_.width, self.mapSize_.height)
			if path then
				break
			end
		end
	end

	return path
end

function Game:loadPathGrid_()
	local layers = {
		"sand objects",
		"water",
		"lakes",
		"village boundaries",
		"village boundaries lvl 2",
		"river",
		"Houses layer 2",
		"Houses",
		"Big Rocks",
		"small rocks",
		"graveyard",
		"dead trees",
		"camps",
		"lava",
		"canyon",
		"Cliffs",
		"Cliffs 2",
		"totems",
		"cactus",
		"cave",
		"lava boundaries",
		"Trees2",
		"caveriver",
		"cavewalls",
		"indoor",
		"indoor objects",
		"forest lakes",
		"forest boundaries",
		"forest trees",
		"forest objects 1",
		"forest objects 2",
		"mase walls",
		"sea",
	}

	for i,v in ipairs(layers) do
		self:loadMapLayer_(v)
	end
end

function Game:loadMapLayer_(layerName)
	local layer = self.map_:getLayer(layerName)
	if not layer then
		return
	end

	local mapSize = self.mapSize_
	local grid = self.pathGrid_
	local line

	for y = 1, mapSize.height do
		grid[y] = grid[y] or {}
		line = grid[y]
		for x = 1, mapSize.width do
			if 0 ~= layer:getTileGIDAt(cc.p(x - 1, y - 1)) then
				line[x] = true
				-- printInfo("tile pos (%d,%d)", x, y)
			end
		end
	end
end

function Game:addGridLayer_()
	local node = cc.DrawNode:create()

	local startPoint = cc.p(0, 0)
	local endPoint = cc.p(0, self.tileSize_.height*self.mapSize_.height)
	for x=1,171 do
		startPoint.x = x * self.tileSize_.width
		endPoint.x = startPoint.x
		node:drawLine(startPoint, endPoint, cc.c4f(1, 0, 0, 1))
		for y=1,311 do
			node:drawLine(startPoint, endPoint, cc.c4f(1, 0, 0, 1))
		end
	end

	startPoint.x = 0
	endPoint.x = self.tileSize_.width * self.mapSize_.width
	for y = 1, 311 do
		startPoint.y = y * self.tileSize_.height
		endPoint.y = startPoint.y
		node:drawLine(startPoint, endPoint, cc.c4f(1, 0, 0, 1))
	end

	self.map_:addChild(node, 99)
end

return Game
