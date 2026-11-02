-- pile

-- virtual base class for Stock, Discard
-- container for stack of cards, one on top of the other

local Card = require 'card'

---@class (exact) Pile
---@field __index Pile
---@field cards Card[]
---@field x integer
---@field y integer

local Pile = {}
Pile.__index = Pile

function Pile:shuffle()
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
function Pile:peek()
	return self.cards[#self.cards]
end

---@return Card
function Pile:pop()
	local c = table.remove(self.cards)
	if c then
		c.owner = nil
	end
	return c
end

---@param c Card
function Pile:push(c)
    assert(self.cards)
    assert(c)
    assert(type(c)=='table')
	table.insert(self.cards, c)
	c.owner = self
	c:transitionTo(self.x, self.y)
end

---@param dt_seconds number
function Pile:update(dt_seconds)
	for _, c in ipairs(self.cards) do
		c:update(dt_seconds)
	end
end

function Pile:draw()
	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.setLineWidth(1)
	love.graphics.rectangle('line', self.x, self.y, _G.SETTINGS.cardWidth, _G.SETTINGS.cardHeight, _G.SETTINGS.cardRadius, _G.SETTINGS.cardRadius)
   	love.graphics.setColor(1, 1, 1, 1)
end

return Pile
