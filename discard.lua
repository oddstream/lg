-- discard.lua

local log = require 'log'

local Pile = require 'pile'

---@class (exact) Discard: Pile
---@field __index Discard
---@field __tostring function
---@field new function

local Discard = {}
Discard.__index = Discard
setmetatable(Discard, {__index = Pile})

---@return string
function Discard:__tostring()
	return string.format('discard(%d)', #self.cards)
end

---@return Discard
function Discard.new()
    ---@class (exact) Discard: Pile
    local o = Pile.new()
    return setmetatable(o, Discard)
end

function Discard:push(c)
    -- log.info('push ', c, ' to ', self)
    c:unselect()
    c:flipUp()	-- discard cards are always face up
    Pile.push(self, c)
end

---@param r Rect
function Discard:layout(r)
    self.x = (r.width / 2) - (_G.SETTINGS.cardWidth / 2)
    self.y = (r.height / 2) - (_G.SETTINGS.cardHeight / 2)

    self.x = self.x + (_G.SETTINGS.cardWidth * 0.75)
    self:repositionCards()
    -- log.trace("Discard:layout()", self, self.x, self.y)
end

-- update, draw handled by Pile

function Discard:draw()
    if #self.cards == 0 then
    	-- show where the drag target is
        love.graphics.setColor(1, 1, 1, 0.1)
        local x, y, w, h = self:getRect()
        love.graphics.rectangle('fill', x, y, w, h, _G.SETTINGS.cardRadius, _G.SETTINGS.cardRadius)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Discard
