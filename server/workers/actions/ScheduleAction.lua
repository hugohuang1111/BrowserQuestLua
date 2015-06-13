
local Schedule = class("Schedule")
local RedisService = cc.load("redis").service
local JobService = cc.load("job").service
local BeansService = cc.load("beanstalkd").service
require("cocos.init")
local WorldCls = import("models.World")
local Entity = require("models.Entity")
local NetMsg = require("network.NetMsg")
local Constant = require("models.Constant")

Schedule.ACCEPTED_REQUEST_TYPE = "worker"

function Schedule:ctor(work)
	self.work_ = work
end

function Schedule:rebornAction(args)
	assert("table" == type(args) and args.id)

	local entity = Entity.new()
	local redis = self:getRedis_()
	entity:setRedis(redis)
	entity:load(args.id)
	entity:reborn()
	self:broadcast_("mob.reborn", entity:getInfo())
	self:closeRedis_()
end

function Schedule:loopAction(args)
	self.config_ = args or self.config_
	assert("table" == type(self.config_))

	local redis = self:getRedis_()
	local ids = redis:command("SMEMBERS", Constant._REDIS_KEY_SETS_PLAYER_)
	for i, id in ipairs(ids) do
		local vals = redis:command("HMGET", id, "health", "healthMax")
		if "table" == type(vals) and 2 == #vals then
			if vals[1] < vals[2] then
				redis:command("HINCRBY", id, "health", 1)
				self:broadcast_("user.info", {id = id, healthPercent = vals[1]/vals[2]})
			end
		end
	end

	self:schedule("schedule.loop", nil, 1)

	self:closeRedis_()
end

function Schedule:scheduleAction(action, data, delay)
	local cfg = self.work_.config
	local beans = BeansService.new(cfg.beanstalkd)
	beans:connect()
	local job = JobService.new(self.redis_, beans, cfg)
	job:add(action, data, delay)
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
    redis:command("PUBLISH", Constant._CHANNEL_ALL_, msg:getString())
end

return Schedule
