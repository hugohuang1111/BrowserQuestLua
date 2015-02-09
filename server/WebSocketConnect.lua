
import(".cocos.init")
local WorldCls = import(".models.World")
local WebSocketConnectBase = require("server.base.WebSocketConnectBase")
local WebSocketConnect = class("WebSocketConnect", WebSocketConnectBase)

function WebSocketConnect:ctor(config)
    printInfo("HTL     WebSocketConnect ctor")
    WebSocketConnect.super.ctor(self, config)

    local mapFile = self.config.appRootPath .. "/maps/world_server.json"
    World = WorldCls.new(self)
    World:setMapPath(mapFile)
    World:initMapIf()
end

function WebSocketConnect:afterConnectReady()
	printInfo("WebSocketConnect afterConnectReady")

    World:subscribeChannel()
    -- init
    local uid = self:getSession():get("uid")
    if uid then
    	self:setConnectTag(uid)
    end
end

function WebSocketConnect:beforeConnectClose()
	printInfo("WebSocketConnect beforeConnectClose")
    local id = self:getConnectTag()
    if id then
        World:setPlayerStatus(id, false)
    end
    World:unsubscribeChannel()
    -- cleanup
    -- self.battle:quit()
end

return WebSocketConnect
