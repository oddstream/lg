-- stock.lua

local Pile = require 'pile'
local Card = require 'card'

---@class (exact) Stock: Pile
---@field __index Stock
---@field __tostring function
---@field new function
---@field setPosition function

local Stock = {}
Stock.__index = Stock
setmetatable(Stock, {__index = Pile})

---@return string
function Stock:__tostring()
	return string.format('stock(%d)', #self.cards)
end

---@return Stock
function Stock.new()
    local o = Pile.new()
    return setmetatable(o, Stock)
end

function Stock:fill()
    -- local ords = {1,2,3,4,5,6,7,8,9,10,11,12,13}
    local ords = {1}
    -- local suits = {'♣','♦','♥','♠'}
    local suits = {'♣'}
    for _, ord in ipairs(ords) do
        for _, suit in ipairs(suits) do
            Pile.push(self, Card.new({ord=ord, suit=suit, prone=true}))
            -- card owner is assigned in Pile.push
        end
    end
end

function Stock:setPosition()
	local width, height, _ = love.window.getMode()
    self.x = (width / 2) - (_G.SETTINGS.cardWidth / 2)
    self.y = (height / 2) - (_G.SETTINGS.cardHeight / 2)

    self.x = self.x - (_G.SETTINGS.cardWidth * 0.75)
    self:repositionCards()
end

-- update, draw handled by Pile

return Stock
