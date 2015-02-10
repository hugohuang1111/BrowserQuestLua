
import(".cocos.init")
local WorldCls = import(".models.World")
local WebSocketConnectBase = require("server.base.WebSocketConnectBase")
local WebSocketConnect = class("WebSocketConnect", WebSocketConnectBase)

function WebSocketConnect:ctor(config)
    WebSocketConnect.super.ctor(self, config)

    local mapFile = self.config.appRootPath .. "/maps/world_server.json"
    World = WorldCls.new(self)
    World:setMapPath(mapFile)
    World:initMapIf()
end

function WebSocketConnect:afterConnectReady()
    World:subscribeChannel()
    -- init
    local uid = self:getSession():get("uid")
    if uid then
    	self:setConnectTag(uid)
    end
end

function WebSocketConnect:beforeConnectClose()
    World:playerQuit()
    World:unsubscribeChannel()
    -- cleanup
    -- self.battle:quit()
end

return WebSocketConnect
