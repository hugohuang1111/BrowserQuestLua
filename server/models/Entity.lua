
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
	self.redis_:command("HMSET", attr.id,
		"posX", attr.pos.x,
		"posY", attr.pos.y,
		"health", attr.health,
		"type", attr.type)
end

function Entity:load(entityId)
	local id = entityId or self.attributes_.id
	self.attributes_.id = id
	local vals = self.redis_:command("HMGET", id, "posX", "posY", "health", "type")
	if not vals then
		return false
	end
	local attr = self.attributes_
	attr.pos = cc.p(vals[1], vals[2])
	attr.health = vals[3]
	attr.type = vals[4]

	return true
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

function Entity:setHealth(health)
	self.attributes_.health = health
end

function Entity:isDead()
	return self.attributes_.health == 0
end

return Entity
