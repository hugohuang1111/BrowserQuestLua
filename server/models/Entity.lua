
local Types = import(".Types")
local Entity = class("Entity")

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
	redis:command("HMSET", attr.id,
		"posX", attr.pos.x or 0,
		"posY", attr.pos.y or 0,
		"health", attr.health,
		"healthMax", attr.healthMax,
		"type", attr.type or Types.TYPE_NONE)
end

function Entity:load(entityId)
	local id = entityId or self.attributes_.id
	self.attributes_.id = id
	local redis = self.redis_ or World:getRedis()
	self.redis_ = redis
	local vals = redis:command("HMGET", id, "posX", "posY", "health", "healthMax", "type")
	if not vals then
		return false
	end
	vals = self:transRedisNull(vals)
	local attr = self.attributes_
	attr.pos = cc.p(tonumber(vals[1] or 0), tonumber(vals[2] or 0))
	attr.health = tonumber(vals[3])
	attr.healthMax = tonumber(vals[4])
	attr.type = tonumber(vals[5])

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

function Entity:setName(name)
	local t = "TYPE_" .. name
	t = string.upper(t)
	self:setType(Types[t])
end

function Entity:setType(type)
	self.attributes_.type = type
end

function Entity:getType()
	return self.attributes_.type
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

function Entity:setId(id)
	self.attributes_.id = id
end

function Entity:getId()
	return self.attributes_.id
end

function Entity:setMaxHealth(max)
	self.attributes_.healthMax = max
end

function Entity:setHealth(health)
	self.attributes_.health = health
end

function Entity:healthChange(val)
	local redis = self.redis_ or World:getRedis()
	self.redis_ = redis
	self.attributes_.health = redis:command("HGET", self.attributes_.id, "health")
	self.attributes_.health = self.attributes_.health + val
	local afterHealth = self.attributes_.health
	if self.attributes_.health > self.attributes_.healthMax then
		self.attributes_.health = self.attributes_.healthMax
	elseif self.attributes_.health <= 0 then
		World:broadcast("play.dead", {id = self.attributes_.id})
		self:reborn()
	end

	redis:command("HSET", self.attributes_.id, "health", self.attributes_.health)

	return afterHealth
end

function Entity:getInfo()
	local attr = self.attributes_
	local entityInfo = {}
	entityInfo.imageName = attr.armor
	entityInfo.pos = attr.pos
	entityInfo.id = attr.id
	entityInfo.type = attr.type

	return entityInfo
end

function Entity:reborn()
	local pos = self.attributes_.pos
	self.attributes_.pos = cc.p(math.random(pos.x - 5, pos.x + 5), math.random(pos.y - 5, pos.y + 5))
	self.attributes_.health = self.attributes_.healthMax

	World:broadcast("play.reborn", self:getInfo())
end

function Entity:isDead()
	return self.attributes_.health == 0
end

return Entity
