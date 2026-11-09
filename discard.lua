-- discard.lua

local log = require 'log'

local Pile = require 'pile'

---@class (exact) Discard: Pile
---@field __index Discard
---@field __tostring function
---@field new function
---@field setPosition function

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
    log.info('push ', c, ' to ', self)
    Pile.push(self, c)
end

function Discard:setPosition()
	local width, height, _ = love.window.getMode()
    self.x = (width / 2) - (_G.SETTINGS.cardWidth / 2)
    self.y = (height / 2) - (_G.SETTINGS.cardHeight / 2)

    self.x = self.x + (_G.SETTINGS.cardWidth * 0.75)
    self:repositionCards()
end

-- update, draw handled by Pile

return Discard
