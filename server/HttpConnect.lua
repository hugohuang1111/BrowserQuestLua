
local HttpConnectBase = require("server.base.HttpConnectBase")
local HttpConnect = class("HttpConnect", HttpConnectBase)

function HttpConnect:ctor( ... )
	HttpConnect.super.ctor(self, ...)
end

return HttpConnect
