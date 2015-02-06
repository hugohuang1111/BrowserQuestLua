
local WebSocketConnectBase = require("server.base.WebSocketConnectBase")
local WebSocketConnect = class("WebSocketConnect", WebSocketConnectBase)

local BattleService = cc.load("battle").service

function WebSocketConnect:ctor(config)
    printInfo("new WebSocketConnect instance")
    WebSocketConnect.super.ctor(self, config)
end

function WebSocketConnect:afterConnectReady()
	printInfo("WebSocketConnect afterConnectReady")
    -- init
    local uid = self:getSession():get("uid")
    if uid then
    	self:setConnectTag(uid)
    end
    -- self.battle = BattleService:create(self, uid)
end

function WebSocketConnect:beforeConnectClose()
	printInfo("WebSocketConnect beforeConnectClose")
    -- cleanup
    -- self.battle:quit()
end

return WebSocketConnect
