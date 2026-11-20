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

local Stock = {}
Stock.__index = Stock
setmetatable(Stock, {__index = Pile})

---@return string
function Stock:__tostring()
	return string.format('stock(%d)', #self.cards)
end

---@return Stock
function Stock.new()
    ---@class (exact) Stock: Pile
    local o = Pile.new()
    return setmetatable(o, Stock)
end

function Stock:fill()
    for _, ord in ipairs(_G.ALLORDS) do
        for _, suit in ipairs(_G.ALLSUITS) do
            local c = Card.new({ord = ord, suit = suit, prone = true})
            assert(Card.isCard(c))
            Pile.push(self, c)
            -- card owner is assigned in Pile.push
        end
    end
    assert(#self.cards==52)
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

---@return Card
function Stock:pop()
    return Pile.pop(self)
    -- up to the receiver to flip card up or down
end

---@param c Card
function Stock:push(c)
    c:unselect()
    c:flipDown()	-- receiver determines flip up or down
    Pile.push(self, c)
end

--[[
---@param c Card
function Stock:tapped(c)
    -- TODO don't think we need this function
end
]]

---@param r Rect
function Stock:layout(r)
    self.x = r.x + (r.width / 2) - (_G.SETTINGS.cardWidth / 2)
    self.y = r.y + (r.height / 2) - (_G.SETTINGS.cardHeight / 2)

    self.x = self.x - (_G.SETTINGS.cardWidth * 0.75)
    self:repositionCards()
end

-- update, draw handled by Pile

return Stock
