-- ui_label.lua

local Widget = require 'ui_widget'
local Util = require 'util'

---@class Label : Widget
---@field text string
---@field radius number
---@field foreColor string
---@field backColor string
---@field font love.font

local Label = {}
Label.__index = Label
setmetatable(Label, {__index = Widget})

---@param o table
function Label.new(o)
    o = Widget.new(o)
    return setmetatable(o, Label)
end

---@param w number
---@param h number
function Label:resize(w, h)
    self.width = _G.SETTINGS.cardHeight
	self.height = _G.SETTINGS.cardWidth
    self.font = love.graphics.newFont(_G.ORD_FONT, self.height / 2)
end

function Label:draw()

local function printCentered(text, x, y, w, h)
    local font = love.graphics.getFont()
    local _, lines = font:getWrap(text, w)
    local textHeight = #lines * font:getHeight() * font:getLineHeight()
    local textY = y + (h - textHeight) / 2

    love.graphics.printf(text, x, textY, w, "center")
end

    if self.state == 'hidden' then return end

    if self.backColor then
        local backColor
        if self.state == 'disabled' then
            backColor = 'UiGrayedOut'
        else
            backColor = self.backColor
        end
        Util.setColor(backColor)
        love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    end

    -- font is created when label is resized, this happens early
    if self.font then
        local foreColor
        if not self.foreColor then
            foreColor = 'UiForeground'
        else
            foreColor = self.foreColor
        end
        Util.setColor(foreColor)

        printCentered(self.text, self.x, self.y, self.width, self.height)
        -- local tw, th = self.font:getWidth(self.text), self.font:getHeight()
        -- love.graphics.print(self.text,
        --     self.x + (tw/2 - self.width/2),
        --     self.y + (th/2 - self.height/2))
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Label
