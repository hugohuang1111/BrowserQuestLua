
local Types = import(".Types")
local Entity = class("Entity")
local Orientation = import(".Orientation")

for k,v in pairs(Types) do
	Entity[k] = v
end

function Entity:ctor(attribute)
	local t = type(attribute)
	if "string" == t then
		self.attributes_ = json.decode(attribute)
	elseif "table" == t then
		self.attributes_ = attribute
	else
		self.attributes_ = {}
		self.attributes_.healthMax = 100
		self.attributes_.health = self.attributes_.healthMax
		self.attributes_.type = Types.TYPE_NONE
		self.attributes_.pos = cc.p(0, 0)
		self.attributes_.roamingArea = cc.rect(0, 0, 0, 0)
		self.attributes_.orientation = Orientation.DOWN
	end
end

function Entity:getAttributeStr()
	return json.encode(self.attributes_)
end

function Entity:getAttribute()
	return self.attributes_
end

function Entity:save()
	local attr = self.attributes_
	local redis = self.redis_ or World:getRedis()
	self.redis_ = redis
	printInfo("Entity save orientation %s", tostring(attr.orientation))
	redis:command("HMSET", attr.id,
		"posX", attr.pos.x or 0,
		"posY", attr.pos.y or 0,
		"health", attr.health,
		"healthMax", attr.healthMax,
		"type", attr.type or Types.TYPE_NONE,
		"roamingX", attr.roamingArea.x or 0,
		"roamingY", attr.roamingArea.y or 0,
		"roamingW", attr.roamingArea.width or 0,
		"roamingH", attr.roamingArea.height or 0,
		"orientation", attr.orientation or Orientation.DOWN)
end

function Entity:load(entityId)
	local id = entityId or self.attributes_.id
	self.attributes_.id = tonumber(id)
	local redis = self.redis_ or World:getRedis()
	self.redis_ = redis
	local vals = redis:command("HMGET", id, "posX", "posY", "health", "healthMax", "type", "roamingX", "roamingY", "roamingW", "roamingH", "orientation")
	if not vals then
		return false
	end
	vals = self:transRedisNull(vals)
	local attr = self.attributes_
	attr.pos = cc.p(tonumber(vals[1] or 0), tonumber(vals[2] or 0))
	attr.health = tonumber(vals[3]) or attr.health
	attr.healthMax = tonumber(vals[4]) or attr.healthMax
	attr.type = tonumber(vals[5])
	attr.roamingArea = cc.rect(tonumber(vals[6] or 0), tonumber(vals[7] or 0), tonumber(vals[8] or 0), tonumber(vals[9] or 0))
	attr.orientation = tonumber(vals[10])
	if 0 == attr.orientation then
		attr.orientation = Orientation.DOWN
	end

	return true
end

function Entity:transRedisNull(val)
	local newV
	local types = type(val)

	local f = function(v)
		if "userdata: NULL" == tostring(v) then
			return nil
		else
			return v
		end
	end

	if "table" == types then
		for k,v in pairs(val) do
			val[k] = self:transRedisNull(v)
		end
		newV = val
	else
		newV = f(val)
	end

	return newV
end

function Entity:setRedis(redis)
	self.redis_ = redis
end

function Entity:getRedis()
	local redis = self.redis_ or World:getRedis()
	self.redis_ = redis
	return redis
end

function Entity:setName(name)
	local t = "TYPE_" .. name
	t = string.upper(t)
	self:setType(Types[t])
end

function Entity:setOrientation(orientation)
	self.attributes_.orientation = orientation
end

function Entity:setType(type)
	self.attributes_.type = type
end

function Entity:getType()
	return self.attributes_.type
end

function Entity:setRoamingArea(rect)
	self.attributes_.roamingArea = rect
end

function Entity:getRoamingArea()
	return self.attributes_.roamingArea
end

function Entity:isNPC()
	return self.attributes_.type > Types.TYPE_NPCS_BEGIN and self.attributes_.type < Types.TYPE_NPCS_END
end

function Entity:isMob()
	return self.attributes_.type > Types.TYPE_MOBS_BEGIN and self.attributes_.type < Types.TYPE_MOBS_END
end

function Entity:setPos(p)
	self.attributes_.pos = p
end

function Entity:getPos()
	return self.attributes_.pos
end

function Entity:setRandomPos()
	local rect = self.attributes_.roamingArea
	self.attributes_.pos = cc.p(math.random(rect.x, rect.x + rect.width), math.random(rect.y, rect.y + rect.height))
end

function Entity:setId(id)
	self.attributes_.id = id
end

function Entity:getId()
	return self.attributes_.id
end

function Entity:setAttack(id)
	if 0 == id then
		World:removeAttackEntity(self.attributes_.id)
	else
		World:addAttackEntity(self.attributes_.id)
	end
	self:getRedis():command("HMSET", self.attributes_.id, "attack", id or 0)
end

function Entity:getAttack()
	local vals = self:getRedis():command("HMGET", self.attributes_.id, "attack")
	return tonumber(vals and vals[1]) or 0
end

function Entity:setMaxHealth(max)
	self.attributes_.healthMax = max
end

function Entity:setHealth(health)
	self.attributes_.health = health
end

function Entity:resetHealth()
	self.attributes_.health = self.attributes_.healthMax
end

function Entity:healthChange(val)
	local redis = self.redis_ or World:getRedis()
	self.redis_ = redis
	self.attributes_.health = redis:command("HGET", self.attributes_.id, "health")
	self.attributes_.health = self.attributes_.health + val
	if self.attributes_.health > self.attributes_.healthMax then
		self.attributes_.health = self.attributes_.healthMax
	end

	redis:command("HSET", self.attributes_.id, "health", self.attributes_.health)

	return self.attributes_.health
end

function Entity:getInfo()
	local attr = self.attributes_
	local entityInfo = {}
	entityInfo.imageName = attr.armor
	entityInfo.pos = attr.pos
	entityInfo.id = attr.id
	entityInfo.type = attr.type
	entityInfo.orientation = attr.orientation

	return entityInfo
end

function Entity:reborn()
	self:setRandomPos()
	self.attributes_.health = self.attributes_.healthMax

	self:save()

	-- World:broadcast("mob.reborn", self:getInfo())
end

function Entity:isDead()
	return self.attributes_.health < 1
end

return Entity
