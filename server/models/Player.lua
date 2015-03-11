
local Entity = import(".Entity")
local Player = class("Player", Entity)

function Player:ctor(...)
	Player.super.ctor(self, ...)

	self.attributes_.armor = "clotharmor.png"
	self.attributes_.weapon = "sword1.png"
	self.attributes_.nickName = "unknow"

	self.attributes_.healthMax = 500
	self.attributes_.health = self.attributes_.healthMax
end

function Player:load(entityId)
	local ok = Entity.load(self, entityId)

	if not ok then
		return false
	end

	local attr = self.attributes_
	local vals = self.redis_:command("HMGET", entityId, "armor", "weapon", "nickName")
	vals = self:transRedisNull(vals)
	attr.armor = vals[1]
	attr.weapon = vals[2]
	attr.nickName = vals[3]
	attr.id = entityId

	return true
end

function Player:save()
	Player.super.save(self)

	local attr = self.attributes_
	self.redis_:command("HMSET", attr.id,
		"armor", attr.armor or "clotharmor.png",
		"weapon", attr.weapon or "sword1.png",
		"nickName", attr.nickName)
end

function Player:getPlayerInfo()
	local attr = self.attributes_
	local playerInfo = {}
	playerInfo.imageName = attr.armor or "clotharmor.png"
	playerInfo.weaponName = attr.weapon or "sword1.png"
	playerInfo.nickName = attr.nickName
	playerInfo.pos = attr.pos
	playerInfo.id = tonumber(attr.id)
	playerInfo.healthPercent = attr.health/attr.healthMax
	playerInfo.orientation = attr.orientation

	return playerInfo
end

function Player:setNickName(name)
	self.attributes_.nickName = name
end

function Player:getNickName()
	return self.attributes_.nickName
end

function Player:getWeapon()
	return self.attributes_.weapon
end

function Player:setWeapon(weapon)
	self.attributes_.weapon = weapon
end

function Player:getArmor()
	return self.attributes_.armor
end

function Player:setArmor(armor)
	self.attributes_.armor = armor
end

function Player:reborn()
	-- Player reborn by user
end

function Player:healthChange(val)
	local after = Player.super.healthChange(self, val)

	World:sendMsg("user.info", {id = self.attributes_.id, healthPercent = self.attributes_.health/self.attributes_.healthMax})

	return after
end


return Player
