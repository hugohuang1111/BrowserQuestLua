
local TextEdit = class("TextEdit", function()
		return display.newNode()
	end)

function TextEdit:ctor(args)
	local label = cc.Label:createWithTTF({fontFilePath = args.fontFilePath or "fonts/arial.ttf",
    									fontSize = args.fontSize or 24},
    									args.text or "Input Text",
    									cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
	if args.text then
		label:setTextColor(cc.c4b(128, 128, 128, 128))
	else
		label:setTextColor(cc.c4b(255, 255, 255, 255))
	end
	self:addChild(label)

	self:onClick(handler(self, self.onTouchEvent))
end

function TextEdit:onTouchEvent()
	self:showKeyBoard_()
end

function TextEdit:showKeyBoard_()
	local keyBoard = self:getKeyBoardView_()
	KeyBoard:setVisible(true)
end

function TextEdit:getKeyBoardView_()
	-- body
end

return TextEdit
