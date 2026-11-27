-- ui_widget.lua

local Util = require 'util'

---@class Widget
---@field __index Widget
---@field new function
---@field state string 'active'|'hidden'|'pressed'|'disabled'
---@field fn function
---@field x number
---@field y number
---@field width number
---@field height number
---@field text string
---@field foreColor string
---@field backColor string
---@field getPosition function
---@field setPosition function
---@field getRect function
---@field setRect function
---@field isPointOver function
---@field resize function
---@field update function
---@field draw function

local Widget = {}
Widget.__index = Widget

---@param o table
---@return Widget
function Widget.new(o)
	o.x = o.x or 0
	o.y = o.y or 0
	return setmetatable(o, Widget)
end

---@param x number
---@param y number
function Widget:setPosition(x,y)
	self.x = x
	self.y = y
end

---@return number
---@return number
function Widget:getPosition()
	return self.x, self.y
end

---@return number
---@return number
---@return number
---@return number
function Widget:getRect()
	return self.x, self.y, self.width, self.height
end

---@param x number
---@param y number
---@param w number
---@param h number
function Widget:setRect(x, y, w, h)
	self.x = x
	self.y = y
	self.width = w
	self.height = h
end

---@param x number
---@param y number
---@return boolean
function Widget:isPointOver(x, y)
	return Util.inRect(x, y, self:getRect())
end

---@param w number
---@param h number
function Widget:resize(w, h)
	-- handled by subclass
end

---@param dt_seconds number
function Widget:update(dt_seconds)
	-- handled by subclass
end

function Widget:draw()
	-- handled by subclass
end

return Widget
