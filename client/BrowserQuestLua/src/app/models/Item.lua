
local Entity = import(".Entity")
local Item = class("Item", Entity)

Item.ANIMATION_IDLE_TIME = 0.5 	-- idle animation frame time
Item.ANIMATION_MOVE_TIME = 0.8 	-- move animation frame time
Item.DISPLAY_TIME = 3
Item.FADE_TIME = 0.2
Item.DISAPPEAR_TIME = 0.5

Item.ANCHOR = cc.p(0.5, 0.5)

function Item:ctor(args)
	Item.super.ctor(self, args)

	self:toFlash_(Item.DISPLAY_TIME)
end

function Item:toFlash_(time)
	local actions = {}
	actions[#actions + 1] = cc.DelayTime:create(time)
	actions[#actions + 1] = cc.FadeOut:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.DelayTime:create(Item.DISAPPEAR_TIME)
	actions[#actions + 1] = cc.FadeIn:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.FadeOut:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.DelayTime:create(Item.DISAPPEAR_TIME)
	actions[#actions + 1] = cc.FadeIn:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.FadeOut:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.DelayTime:create(Item.DISAPPEAR_TIME)
	actions[#actions + 1] = cc.FadeIn:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.FadeOut:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.DelayTime:create(Item.DISAPPEAR_TIME)
	actions[#actions + 1] = cc.FadeIn:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.FadeOut:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.DelayTime:create(Item.DISAPPEAR_TIME)
	actions[#actions + 1] = cc.FadeIn:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.FadeOut:create(Item.FADE_TIME)
	actions[#actions + 1] = cc.DelayTime:create(Item.DISAPPEAR_TIME)
	actions[#actions + 1] = cc.CallFunc:create(function()
		Game:removeEntity(self)
	end)
	self.flashHandle_ = transition.sequence(actions)
	self.view_:runAction(self.flashHandle_)
	self.view_:setCascadeOpacityEnabled(true)
end

function Item:getImageName()
	return string.sub(self.imageName_, 6)
end

function Item:getLootMsg()
	return self.lootMsg_
end

return Item
