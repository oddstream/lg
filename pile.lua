-- pile

-- virtual base class for Stock, Discard, ape hand, bot hand, and any other pile of cards
-- by default, cards stack one on top of the other

local log = require 'log'

local Card = require 'card'

---@class (exact) Pile
---@field __index Pile
---@field __tostring function
---@field x integer
---@field y integer
---@field width integer
---@field height integer
---@field cards Card[]
---@field new function
---@field peek function
---@field pop function
---@field push function
---@field pushBottom function
---@field cardDragged function(c:Card)
---@field removeCard function(c:Card)
---@field insertCard function(c:Card)
---@field fan function
---@field indexOf function(c:Card):integer|nil
---@field repositionCards function
---@field sort function
---@field tapped function(c:Card)
---@field getRect function
---@field setPosition function
---@field layout function(r:Rect)
---@field resize function
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
		str = str .. tostring(c)
		-- str = str .. string.format('%d) %s %d ', i, c, c.x)
	end
	log.info(str)
end

---@return Pile
function Pile.new()
	local o = {x=0, y=0, width=_G.SETTINGS.cardWidth, height=_G.SETTINGS.cardHeight, cards={}}
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

---@param c Card
function Pile:pushBottom(c)
	assert(self.cards)
	assert(Card.isCard(c))
	table.insert(self.cards, 1, c)
	c.owner = self
	c:transitionTo(self.x, self.y)
end

---@param i integer|string
---@return Card
function Pile:remove(i)
	local card
	if type(i) == 'number' then
		card = table.remove(self.cards, i)
	elseif type(i) == 'string' then
		for j, c in ipairs(self.cards) do
			if c.textureId == i then
				card = table.remove(self.cards, j)
			end
		end
	else
		assert(false, 'remove argument must be number or string, not', type(i))
	end
	if card then card.owner = nil end
	return card
end

---@return number
---@return number
---@return number
---@return number
function Pile:getRect()
	return self.x, self.y, _G.SETTINGS.cardWidth, _G.SETTINGS.cardHeight
end

---@param x integer
---@param y integer
function Pile:setPosition(x, y)
	self.x = x
	self.y = y
	self:repositionCards()
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

--[[
---@param c Card
function Pile:tapped(c)
	-- do nothing, handled by sublasses
end
]]

function Pile:indexOf(c)
	for i, card in ipairs(self.cards) do
		if card == c then
			return i
		end
	end
	return nil
end

function Pile:repositionCards()
	-- log.trace('Pile:repositionCards() to', self.x, self.y)
	assert(type(self.x)=='number')
	assert(type(self.y)=='number')
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

---@param r Rect
function Pile:layout(r)
	-- do nothing, leave to subclasses
end

---@param w integer
---@param h integer
function Pile:resize(w, h)
	self.width = _G.SETTINGS.cardWidth
	self.height = _G.SETTINGS.cardHeight
end

function Pile:draw()
	-- do nothing, leave to subclasses
end

return Pile
