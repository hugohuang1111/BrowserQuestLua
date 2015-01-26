
local MyApp = class("MyApp", cc.load("mvc").AppBase)

function MyApp:onCreate()
	self.resScale_ = 2

	display.loadSpriteFrames("img/" .. self.resScale_ .. "/spritesheet.plist",
		"img/" .. self.resScale_ .. "/spritesheet.png")
	display.loadSpriteFrames("img/" .. self.resScale_ .. "/barsheet.plist",
		"img/" .. self.resScale_ .. "/barsheet.png")

    math.randomseed(os.time())

    -- global varibale
	cc.exports.app = self
end

function MyApp:getResPath(filename)
	local fileUtils = cc.FileUtils:getInstance()

	local pathInfo = io.pathinfo(filename)
	if ".png" == pathInfo.extname then
		local pathArr = {"img", self.resScale_, filename}
		local path = table.concat( pathArr, device.directorySeparator)
		path = fileUtils:fullPathForFilename(path)
		if fileUtils:isFileExist(path) then
			return path
		end

		pathArr[2] = "common"
		path = table.concat( pathArr, device.directorySeparator)
		path = fileUtils:fullPathForFilename(path)
		if fileUtils:isFileExist(path) then
			return path
		end
	else
		local path = fileUtils:fullPathForFilename(filename)
		return path
	end
end

function MyApp:getScale()
	return self.resScale_
end

return MyApp
