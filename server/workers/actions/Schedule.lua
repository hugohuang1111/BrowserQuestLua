
local Schedule = class("Schedule")
local RedisService = cc.load("redis").service
require("cocos.init")
local WorldCls = import("models.World")
local Entity = require("models.Entity")
local NetMsg = require("network.NetMsg")
local _CHANNEL_ALL_ = "ChannelAll"

function Schedule:ctor(work)
	self.work_ = work
end

function Schedule:reborn(args)
	assert("table" == type(args) and args.id)

	local entity = Entity.new()
	local redis = self:getRedis_()
	entity:setRedis(redis)
	entity:load(args.id)
	entity:reborn()
	self:broadcast_("mob.reborn", entity:getInfo())
	self:closeRedis_()
end

function Schedule:loop()
	local redis = self:getRedis_()
	self:closeRedis_()
end

function Schedule:getRedis_()
	self.redis_ = RedisService:create(self.work_.config.redis)
    self.redis_:connect()

    return self.redis_
end

function Schedule:closeRedis_()
	self.redis_:setKeepAlive(10, 6)
	self.redis_ = nil
end

function Schedule:broadcast_(action, args)
	local msg = NetMsg.new()
	msg:setAction(action)
	msg:setBody(args)

	local redis = self.redis_
    redis:command("PUBLISH", _CHANNEL_ALL_, msg:getString())
end

return Schedule
