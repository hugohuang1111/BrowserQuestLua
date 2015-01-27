
local Character = import(".Player")
local Player = class("Player", Character)

Player.VIEW_TAG_WEAPON = 102

function Player:ctor(args)
	self.super.ctor(self, args)
	self.weaponName_ = args.weaponName

end

function Player:getView()
	if self.view_ then
		return self.view_
	end

	self.super.getView(self)
end

function Player:changeCloth(name)
	self.view_:removeChildByTag(Player.VIEW_TAG_SPRITE)

	local texture = display.loadImage(app:getResPath(name))
	local frame = display.newSpriteFrame(texture,
			cc.rect(0, 0, self.json_.width * app:getScale(), self.json_.height * app:getScale()))
	display.newSprite(frame):addTo(self.view_, 1, Entity.VIEW_TAG_SPRITE)
end

function Player:changeWeapon(name)
	self.view_:removeChildByTag(Player.VIEW_TAG_WEAPON)
	
	local texture = display.loadImage(app:getResPath(name))
	local frame = display.newSpriteFrame(texture,
			cc.rect(0, 0, self.json_.width * app:getScale(), self.json_.height * app:getScale()))
	display.newSprite(frame):addTo(self.view_, 2, Entity.VIEW_TAG_WEAPON)
end

return Player
