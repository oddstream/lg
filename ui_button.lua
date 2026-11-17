-- ui_button.lua

local Widget = require 'ui_widget'
local Util = require 'util'

---@class Button : Widget
---@field text string
---@field radius number
---@field foreColor string
---@field backColor string
---@field font love.font
---@field jinCommand string

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
    local d = Util.distance(self.x, self.y, x, y)
    return d <= self.radius
    -- return Util.inRect(x, y, self:getRect())
end

---@param w number
---@param h number
function Button:resize(w, h)
    self.font = love.graphics.newFont(_G.ORD_FONT, _G.SETTINGS.cardWidth / 2)
    self.radius = _G.SETTINGS.cardWidth / 2
	self:setPosition(w - self.radius * 2, h - self.radius * 2)
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
    -- love.graphics.setLineWidth(1)
    -- love.graphics.setColor(0, 0, 0, 1)	-- cartoon outlines are black, so why not
    -- love.graphics.circle('line', self.x, self.y, _G.SETTINGS.cardWidth / 2)

    -- font is created when button is resized, this happens early
    if self.font then
        local foreColor
        if not self.foreColor then
            foreColor = 'UiForeground'
        else
            foreColor = self.foreColor
        end
        Util.setColor(foreColor)
        -- center the text in the circle
        local tw, th = self.font:getWidth(self.text), self.font:getHeight()
        -- Use offsets (ox, oy) to center the text anchor point
        love.graphics.print(self.text, x-(tw/4), y-(th/4)) --, 0, 1, 1, tw / 2, th / 2)
    end

    -- do
    --     love.graphics.setColor(1, 1, 1, 0.1)
    --     local x, y, w, h = self:getRect()
    --     love.graphics.rectangle('fill', x, y, w, h, _G.SETTINGS.cardRadius, _G.SETTINGS.cardRadius)
    -- end

    love.graphics.setColor(1, 1, 1, 1)
end

return Button
