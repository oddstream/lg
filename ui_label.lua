-- ui_label.lua

local Widget = require 'ui_widget'
local Util = require 'util'

---@class Label : Widget
---@field text string
---@field radius number
---@field foreColor string
---@field backColor string

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
    self.width = w / 6  --_G.SETTINGS.cardHeight
	self.height = _G.SETTINGS.cardWidth / 2
end

function Label:draw()

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

    if self.text then
        love.graphics.setFont(_G.uiFont)

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
