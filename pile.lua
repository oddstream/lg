-- pile

-- virtual base class for Stock, Discard, human hand, computer hand, and any other pile of cards
-- by default, cards stack one on top of the other

local log = require 'log'

local Card = require 'card'

---@class (exact) Pile
---@field __index Pile
---@field __tostring function
---@field x integer
---@field y integer
---@field cards Card[]
---@field new function
---@field shuffle function
---@field peek function
---@field pop function
---@field push function
---@field cardDragged function(c:Card)
---@field removeCard function(c:Card)
---@field insertCard function(c:Card)
---@field fan function
---@field indexOf function(c:Card):integer|nil
---@field repositionCards function
---@field sort function
---@field tapped function(c:Card)
---@field getRect function
---@field update function(dt_seconds:number)
---@field draw function()

local Pile = {}
Pile.__index = Pile

---@return string
function Pile:__tostring()
	return string.format('pile(%d)', #self.cards)
end

function Pile:log()
	local str = ''
	for i, c in ipairs(self.cards) do
		str = str .. string.format('%d) %s %d ', i, c, c.x)
	end
	log.info(str)
end

---@return Pile
function Pile.new()
    local o = {x=0, y=0, cards={}}
    return setmetatable(o, Pile)
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
    assert(Card.isCard(c))
	table.insert(self.cards, c)
	c.owner = self
	c:transitionTo(self.x, self.y)
end

function Pile:getRect()
    return self.x, self.y, _G.SETTINGS.cardWidth, _G.SETTINGS.cardHeight
end

---@param c Card, still in it's owning pile
function Pile:cardDragged(c)
	assert(Card.isCard(c))
	log.info(self, c, 'dragging going on in base Pile class')
	-- do nothing for now, but subclasses can override this to handle card being dragged over them
end

---@param c Card, still in it's owning pile
function Pile:removeCard(c)
	-- default behaviour, pop, good for stock and discard piles
	-- can be overriden by subclasses
	assert(self:peek()==c)
	self:pop()
end

---@param c Card
function Pile:insertCard(c)
	-- default behaviour, push, good for stock and discard piles
	-- can be overriden by subclasses
	self:push(c)
end

function Pile:fan()
	-- do nothing, cards are stacked on top of each other
end

function Pile:sort()
	-- do nothing, cards are stacked on top of each other
end

---@param c Card
function Pile:tapped(c)
	-- do nothing, handled by sublasses
end

function Pile:indexOf(c)
	for i, card in ipairs(self.cards) do
		if card == c then
			return i
		end
	end
	return nil
end

function Pile:repositionCards()
	for _, c in ipairs(self.cards) do
		c:setPosition(self.x, self.y)
	end
end

---@param dt_seconds number
function Pile:update(dt_seconds)
	for _, c in ipairs(self.cards) do
		c:update(dt_seconds)
	end
end

function Pile:draw()
	if _G.SETTINGS.debug then
		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.setLineWidth(1)
		local x, y, w, h = self:getRect()
		love.graphics.rectangle('line', x, y, w, h, _G.SETTINGS.cardRadius, _G.SETTINGS.cardRadius)
		love.graphics.setColor(1, 1, 1, 1)
	end
end

return Pile
