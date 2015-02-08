
local Entity = import(".Entity")
local Player = class("Player", Entity)

function Player:load(entityId)
	local ok = Player.super.load(self, entityId)

	if not ok then
		return false
	end

	local attr = self.attributes_
	local vals = self.redis_:command("HMGET", entityId, "armor", "weapon", "nickName")
	attr.armor = vals[1]
	attr.weapon = vals[2]
	attri.nickName = vals[3]
end

function Player:save()
	Player.super.save()

	local attr = self.attributes_
	self.redis_:command("HMSET", attr.id,
		"armor", attr.armor or "clotharmor.png",
		"weapon", attr.weapon or "sword1.png",
		"nickName", attr.nickName)
end

function Player:getPlayerInfo()
	local attr = self.attributes_
	local playerInfo = {}
	playerInfo.imageName = attr.armor
	playerInfo.weaponName = attr.weapon
	playerInfo.nickName = attr.nickName
	playerInfo.pos = attr.pos
	playerInfo.id = idCounter

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

return Player
