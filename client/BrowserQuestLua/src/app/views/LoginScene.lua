
local LoginScene = class("LoginScene", cc.load("mvc").ViewBase)

function LoginScene:onCreate()

    Game:loadData()

    -- add background image
    local bgPath = app:getResPath("wood.png")
    local bg = cc.Sprite:create(bgPath, cc.size(display.width, display.height))
    bg:getTexture():setTexParameters(gl.LINEAR, gl.LINEAR, gl.REPEAT, gl.REPEAT)
    bg:align(display.CENTER, display.cx, display.cy):addTo(self)

    -- logo
    local logo = display.newSprite("#logo.png")
    	:align(display.CENTER, display.cx, display.height - 100)
    	:addTo(self)

    -- bg
    local parchment = display.newSprite("#parchment.png")
    	:align(display.CENTER, display.cx, display.cy)
    	:addTo(self)

    -- str
    local parchmentSize = parchment:getContentSize()
    local str = cc.Label:createWithTTF("A Massively Multiplayer Adventure", "fonts/arial.ttf", 12)
    str:setTextColor(cc.c4b(0, 0, 0, 255))
    str:align(display.CENTER, parchmentSize.width/2, parchmentSize.height - 30)
    	:addTo(parchment)
    local strSize = str:getContentSize()

    local leftsp = display.newSprite("#left-ornament.png")
    	:align(display.RIGHT_CENTER, parchmentSize.width/2 - strSize.width/2 - 10, parchmentSize.height - 30)
    	:addTo(parchment)
    local rightsp = display.newSprite("#right-ornament.png")
    	:align(display.LEFT_CENTER, parchmentSize.width/2 + strSize.width/2 + 10, parchmentSize.height - 30)
    	:addTo(parchment)

    local rolesp = display.newSprite("#character.png")
    	:align(display.CENTER, parchmentSize.width/2, parchmentSize.height - 50)
    	:addTo(parchment)

    local nameBgSize = cc.size(200, 30)
    local nameBg = cc.LayerColor:create(cc.c4b(0, 0, 0, 60))
    nameBg:setContentSize(nameBgSize)
    nameBg:align(display.CENTER, 120, parchmentSize.height - 100)
    nameBg:addTo(parchment)

    local textfield = ccui.TextField:create("Name your character", "fonts/fzkt.ttf", 20)
        :align(display.CENTER, nameBgSize.width/2, nameBgSize.height/2)
        :addTo(nameBg)

    local playerInfo = Game:getPlayerData()
    if playerInfo then
        textfield:setString(playerInfo.nickName or "")
    end

    ccui.Button:create("button.png", "button.png", "button-disable.png", ccui.TextureResType.plistType)
        :align(display.CENTER, parchmentSize.width/2, parchmentSize.height - 135)
        :addTo(parchment)
        :onTouch(function(event)
            if "ended" == event.name then
                local name = textfield:getString()
                if name and string.len(name) > 0 then
                    local playerInfo = Game:getPlayerData() or {}
                    playerInfo.nickName = name
                    Game:setPlayerData(playerInfo)
                    Game:saveData()
                    Game:sendCmd("user.welcome", Game:getPlayerData())
                else
                    self:shake(nameBg)
                end
            end
        end)

    -- nameBg:setAnchorPoint(cc.p(1, 1))
    -- local nameEditBox = ccui.TextField:create("Name your character",
    --                          "fonts/graphicpixel-webfont.ttf", 24);
    -- nameEditBox:align(display.CENTER, nameBgSize.width/2, nameBgSize.height/2):addTo(nameBg)

end

function LoginScene:shake(target)
    local time = 0.1
    local actions = {}
    actions[#actions + 1] = cc.MoveBy:create(time/2, cc.p(-5, 0))
    actions[#actions + 1] = cc.MoveBy:create(time, cc.p(10, 0))
    actions[#actions + 1] = cc.MoveBy:create(time, cc.p(-10, 0))
    actions[#actions + 1] = cc.MoveBy:create(time, cc.p(5, 0))
    local seq = transition.sequence(actions)
    target:runAction(seq)
end

return LoginScene
