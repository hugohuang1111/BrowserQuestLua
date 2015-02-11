
local Utilitys = import(".Utilitys")
local Character = import(".Character")
local Player = class("Player", Character)

Player.VIEW_TAG_WEAPON = 102
Player.VIEW_TAG_NAME = 104

Player.ANCHOR = cc.p(0.5, 0.5)

function Player:ctor(args)
	self.weaponName_ = args.weaponName
	self.name_ = args.name
	args.type = Character.TYPE_WARRIOR
	
	Player.super.ctor(self, args)

	self:createNameLabel_()
end

function Player:setUser(isUser)
	self.isUser_ = isUser

	local label = self.view_:getChildByTag(Player.VIEW_TAG_NAME)
	if not label then
		return
	end
	if isUser then
		label:setTextColor(cc.c4b(255, 0, 0, 255))
		label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	else
		label:setTextColor(cc.c4b(250, 250, 250, 250))
		label:enableOutline(cc.c4b(0, 0, 0, 250), 1)
	end
end

function Player:isUser()
	return self.isUser_
end

function Player:getView()
	if self.view_ then
		return self.view_
	end

	Player.super.getView(self)
	self:changeWeapon(self.weaponName_)

	return self.view_
end

function Player:getNickName()
	return self.name_
end

function Player:changeCloth(name)
	self.view_:removeChildByTag(Player.VIEW_TAG_SPRITE)

	self.imageName_ = name or self.imageName_
	self:loadJson_()

	local texture = display.loadImage(app:getResPath(name))
	local frame = display.newSpriteFrame(texture,
			cc.rect(0, 0, self.json_.width * app:getScale(), self.json_.height * app:getScale()))
	display.newSprite(frame):addTo(self.view_, 1, Player.VIEW_TAG_SPRITE)
		:align(Player.ANCHOR) --(Character.ANCHOR)
end

function Player:changeWeapon(name)
	self.view_:removeChildByTag(Player.VIEW_TAG_WEAPON)

	self.weaponName_ = name or self.weaponName_
	self:loadJson_()
	
	local texture = display.loadImage(app:getResPath(name))
	local frame = display.newSpriteFrame(texture,
			cc.rect(0, 0, self.jsonWeapon_.width * app:getScale(), self.jsonWeapon_.height * app:getScale()))
	display.newSprite(frame):addTo(self.view_, 1, Player.VIEW_TAG_WEAPON)
		:align(Player.ANCHOR) --(Character.ANCHOR)
end

function Player:loot(item)
	self:fllow(item)
	self.lootEntity_ = item or self.lootEntity_

	if not self.lootEntity_ then
		return
	end

	if 1 == self:distanceWith(self.lootEntity_) then
		self:lootItem(item)
	end
end

function Player:lootItem(item)
	if not item then
		return
	end

	local armorRank = Utilitys.getRankByName(self.imageName_)
	local weaponRank = Utilitys.getRankByName(self.weaponName_)
	local itemRank = Utilitys.getRankByName(item:getImageName())
	local msg

	if itemRank > Character.TYPE_ARMORS_BEGIN and itemRank < Character.TYPE_ARMORS_END then
		-- armor
		if itemRank > armorRank then
			self:changeCloth(item:getImageName())
			self:play("idle")
			msg = item:getLootMsg()
		elseif itemRank == armorRank then
			msg = "You already have this armor"
		else
			msg = "You are wearing a better armor"
		end
	elseif itemRank > Character.TYPE_WEAPONS_BEGIN and itemRank < Character.TYPE_WEAPONS_END then
		-- weapon
		if itemRank > armorRank then
			self:changeWeapon(item:getImageName())
			self:play("idle")
			msg = item:getLootMsg()
		elseif itemRank == armorRank then
			msg = "You already have this weapon"
		else
			msg = "You are wielding a better weapon"
		end
	end

	Game:removeEntity(item)
end

function Player:play(actionName, args)
	actionName = self:getStateByOrientation(actionName)
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
	if self.isUser_ then
		label:setTextColor(cc.c4b(255, 0, 0, 255))
		label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	else
		label:setTextColor(cc.c4b(250, 250, 250, 250))
		label:enableOutline(cc.c4b(0, 0, 0, 250), 1)
	end
	label:align(display.CENTER)
	label:setPosition(0, self.json_.height + 10)
	self.view_:addChild(label)
	label:setTag(Player.VIEW_TAG_NAME)
end

function Player:getInfo()
	return {
		imageName = self.imageName_,
		weaponName = self.weaponName_,
		nickName = self.name_,
		pos = self.pos_,
		id = self.id
	}
end

return Player
