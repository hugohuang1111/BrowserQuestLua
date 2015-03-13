
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

-- opengl
require "cocos.cocos2d.OpenglConstants"

-- ui
require "cocos.ui.GuiConstants"
require "cocos.ui.experimentalUIConstants"

-- json
require "cocos.cocos2d.json"

-- websocket
require "cocos.network.NetworkConstants"



-- device.writablePath =
-- 	io.pathinfo(cc.FileUtils:getInstance():fullPathForFilename("browserquest.dat")).dirname
-- printInfo("device.writablePath 1:" .. device.writablePath)


local function main()
    require("app.MyApp"):create():run("LoginScene")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
