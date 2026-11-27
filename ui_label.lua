-- ui_label.lua

local Widget = require 'ui_widget'
local Util = require 'util'

---@class Label : Widget

local Label = {}
Label.__index = Label
setmetatable(Label, {__index = Widget})

---@param o table
function Label.new(o)
    o = Widget.new(o)
    o.width = o.width or _G.SETTINGS.cardHeight
    o.height = o.height or _G.SETTINGS.cardWidth
	o.backColor = o.backColor or ''
    o.foreColor = o.foreColor or 'CornflowerBlue'
	o.state = o.state or 'active'
	return setmetatable(o, Label)
end

---@param w number
---@param h number
function Label:resize(w, h)
	self.width = w / 6  --_G.SETTINGS.cardHeight
	self.height = _G.SETTINGS.cardWidth / 2
end

function Label:draw()

	if self.state == 'hidden' then return end

	if self.backColor and string.len(self.backColor) > 0 then
		local backColor
		if self.state == 'disabled' then
			backColor = 'UiGrayedOut'
		else
			backColor = self.backColor
		end
		Util.setColor(backColor)
		love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
	end

	if self.text then
		love.graphics.setFont(_G.UI_FONT)

		local foreColor
		if not self.foreColor then
			foreColor = 'UiForeground'
		else
			foreColor = self.foreColor
		end
		Util.setColor(foreColor)
		Util.printCentered(self.text, self.x, self.y, self.width, self.height)
	end

	love.graphics.setColor(1, 1, 1, 1)
end

return Label
