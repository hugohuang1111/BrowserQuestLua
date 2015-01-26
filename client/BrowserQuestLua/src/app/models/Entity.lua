
require("cocos.cocos2d.json")
local Entity = class("Entity")

Entity.ANIMATION_DELAY = 0.2

function Entity:ctor(image)
	self.imageName_ = image
end

function Entity:getView()
	if self.view_ then
		return self.view_
	end

	self:loadJson_()

	local path = app:getResPath(self.imageName_)
	local texture = display.loadImage(app:getResPath(self.imageName_))
	local frame = display.newSpriteFrame(texture,
			cc.rect(0, 0, self.json_.width * app:getScale(), self.json_.height * app:getScale()))
	self.view_ = display.newSprite(frame)

	return self.view_
end

function Entity:play(actionName)
	local frames = self:getFrames_(actionName)
	if not frames then
		printError("Entity:play invalid action name:%s", actionName)
	end
	self.view_:playAnimationForever(display.newAnimation(frames, Entity.ANIMATION_DELAY))
end

function Entity:loadJson_()
	local jsonFileName = "sprites/" .. string.gsub(self.imageName_, ".png", ".json")
	local fileContent = cc.FileUtils:getInstance():getStringFromFile(jsonFileName)
	self.json_ = json.decode(fileContent)
end

function Entity:getFrames_(aniType)
	aniType = aniType or "idle"

	local json = self.json_[aniType]
	if not json then
		local spos, epos = string.find(aniType, "_")
		if spos then
			local newAniType = string.gsub(aniType, "(%a)", function(str)
				if "left" == str then
					return "right"
				elseif "right" == str then
					return "left"
				elseif "up" == str then
					return "down"
				elseif "down" == str then
					return "up"
				end
			end)

			json = self.json_[newAniType]
		else
			local newAniType = aniType .. "_down"
			json = self.json_["animations"][newAniType]
		end
	end
	if not json then
		printError("Entity:getAnimation aniType:%s", aniType)
		return
	end

	local texture = display.loadImage(app:getResPath(self.imageName_))
	local width = self.json_.width * app:getScale()
	local height = self.json_.height * app:getScale()

	local frames = {}
	for i=1,json.length do
		local frame = display.newSpriteFrame(texture,
			cc.rect(width * (i - 1), height * json.row, width, height))
        frames[#frames + 1] = frame
	end

	return frames
end


return Entity
