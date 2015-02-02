
local Character = import(".Character")
local Player = class("Player", Character)

Player.VIEW_TAG_WEAPON = 102

function Player:ctor(args)
	self.weaponName_ = args.weaponName
	
	Player.super.ctor(self, args)
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

return Player
