-- stock.lua

local log = require 'log'

local Pile = require 'pile'
local Card = require 'card'

---@class (exact) Stock: Pile
---@field __index Stock
---@field __tostring function
---@field new function
---@field fill function
---@field shuffle function
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
    local ords = {1,2,3,4,5,6,7,8,9,10,11,12,13}
    local suits = {'♣','♦','♥','♠'}
    for _, ord in ipairs(ords) do
        for _, suit in ipairs(suits) do
            Pile.push(self, Card.new({ord=ord, suit=suit, prone=true}))
            -- card owner is assigned in Pile.push
        end
    end
end

function Stock:shuffle()
	-- https://en.wikipedia.org/wiki/Shuffling
    -- https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
	for i = #self.cards, 2, -1 do
		local j = math.random(i)
		if i ~= j then
			self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
		end
	end
end

function Stock:setPosition()
	local width, height, _ = love.window.getMode()
    self.x = (width / 2) - (_G.SETTINGS.cardWidth / 2)
    self.y = (height / 2) - (_G.SETTINGS.cardHeight / 2)

    self.x = self.x - (_G.SETTINGS.cardWidth * 0.75)
    self:repositionCards()
    log.trace("Stock:setPosition()", self, self.x, self.y)
end

-- update, draw handled by Pile

return Stock
