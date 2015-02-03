
local Character = import(".Character")
local Player = class("Player", Character)

Player.VIEW_TAG_WEAPON = 102
Player.VIEW_TAG_NAME = 104

function Player:ctor(args)
	self.weaponName_ = args.weaponName
	self.name_ = args.name
	
	Player.super.ctor(self, args)

	self:createNameLabel_()
end

function Player:getView()
	if self.view_ then
		return self.view_
	end

	Player.super.getView(self)
	self:changeWeapon(self.weaponName_)

	return self.view_
end

function Player:changeCloth(name)
	self.view_:removeChildByTag(Player.VIEW_TAG_SPRITE)

	local texture = display.loadImage(app:getResPath(name))
	local frame = display.newSpriteFrame(texture,
			cc.rect(0, 0, self.json_.width * app:getScale(), self.json_.height * app:getScale()))
	display.newSprite(frame):addTo(self.view_, 1, Player.VIEW_TAG_SPRITE)
		:align(Character.ANCHOR)
end

function Player:changeWeapon(name)
	self.view_:removeChildByTag(Player.VIEW_TAG_WEAPON)
	
	local texture = display.loadImage(app:getResPath(name))
	local frame = display.newSpriteFrame(texture,
			cc.rect(0, 0, self.json_.width * app:getScale(), self.json_.height * app:getScale()))
	display.newSprite(frame):addTo(self.view_, 1, Player.VIEW_TAG_WEAPON)
		:align(Character.ANCHOR)
	self.weaponName_ = name
end

function Player:play(actionName, args)
	local result, resultWeapon = self:getFrames_(actionName)
	local frames = result.frames
	local weaponFrames = resultWeapon.frames
	if not frames then
		printError("Player:play invalid action name:%s", actionName)
	end

	local sp = self.view_:getChildByTag(Player.VIEW_TAG_SPRITE)
	sp:setFlippedX(result.flip)
	sp:stopAllActions()
	if args and args.isOnce then
		args.isOnce = false  -- remove used params
		sp:playAnimationOnce(display.newAnimation(frames, self:getAnimationTime(actionName)), args)
	else
		sp:playAnimationForever(display.newAnimation(frames, self:getAnimationTime(actionName)), args)
	end

	if weaponFrames then
		sp = self.view_:getChildByTag(Player.VIEW_TAG_WEAPON)
		if sp then
			sp:setFlippedX(resultWeapon.flip)
			sp:stopAllActions()
			if args and args.isOnce then
				args.isOnce = false  -- remove used params
				sp:playAnimationOnce(display.newAnimation(weaponFrames, self:getAnimationTime(actionName)), args)
			else
				sp:playAnimationForever(display.newAnimation(weaponFrames, self:getAnimationTime(actionName)), args)
			end
		end
	end
end

function Player:loadJson_()
	self.json_ = self:parseJson_(self.imageName_)
	self.jsonWeapon_ = self:parseJson_(self.weaponName_)
end

function Player:getFrames_(aniType)
	return self:parseFrames_(self.imageName_, self.json_, aniType), self:parseFrames_(self.weaponName_, self.jsonWeapon_, aniType)
end

function Player:createNameLabel_()
	if not self.name_ or 0 == string.len(self.name_) then
		return
	end

	local ttfConfig = {
		fontFilePath = "fonts/fzkt.ttf",
		fontSize = 14
		}
	local label = cc.Label:createWithTTF(ttfConfig, self.name_, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
	if Game:isSelf(self) then
		label:setTextColor(cc.c4b(255, 255, 0, 255))
		label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	end
	label:align(display.CENTER)
	label:setPosition(0, self.json_.height + 10)
	self.view_:addChild(label)
	label:setTag(Player.VIEW_TAG_NAME)
end

return Player
