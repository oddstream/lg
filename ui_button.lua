-- ui_button.lua

local Widget = require 'ui_widget'
local Util = require 'util'

---@class Button : Widget
---@field text string
---@field radius number
---@field radiusFactor number
---@field foreColor string
---@field backColor string

local Button = {}
Button.__index = Button
setmetatable(Button, {__index = Widget})

---@param o table
function Button.new(o)
	o = Widget.new(o)
	return setmetatable(o, Button)
end

---@param x number
---@param y number
---@return boolean
function Button:isPointOver(x, y)
	if self.state == 'disabled' or self.state == 'hidden' then return false end
	local d = Util.distance(self.x, self.y, x, y)
	return d <= self.radius
	-- return Util.inRect(x, y, self:getRect())
end

---@param w number
---@param h number
function Button:resize(w, h)
	self.radius = _G.SETTINGS.cardWidth / self.radiusFactor
end

function Button:draw()
	if self.state == 'hidden' then return end

	local x, y = self.x, self.y
	if self.state == 'pressed' then
		x = x + 4
		y = y + 4
	end

	local backColor
	if self.state == 'disabled' then
		backColor = 'UiGrayedOut'
	elseif not self.backColor then
		backColor = 'UiBackground'
	else
		backColor = self.backColor
	end
	Util.setColor(backColor)
	love.graphics.circle('fill', x, y, self.radius)
	love.graphics.setLineWidth(1)
	love.graphics.setColor(0, 0, 0, 0.05)	-- cartoon outlines are black, so why not
	love.graphics.circle('line', x, y, self.radius)

	if self.text then
		love.graphics.setFont(_G.UI_FONT)
		
		local foreColor
		if not self.foreColor then
			foreColor = 'UiForeground'
		else
			foreColor = self.foreColor
		end
		Util.setColor(foreColor)
		-- center the text in the circle
		local textY = y - _G.UI_FONT:getHeight() / 2
		love.graphics.printf(self.text, x - self.radius, textY, self.radius * 2, "center")
	end

	love.graphics.setColor(1, 1, 1, 1)
end

return Button
