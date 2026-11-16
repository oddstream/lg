-- hand.lua

local log = require 'log'

local Card = require 'card'
local Pile = require 'pile'

---@class (exact) Hand: Pile
---@field __index Hand
---@field __tostring function
---@field playerName string
---@field selectedPokerHandType string
---@field new function
---@field setPosition function
---@field cardDragged function(c:Card)
---@field fan function
---@field sort function
---@field width function
---@field getRect function
---@field repositionCards function
---@field numberSelected function
---@field update function(dt_seconds:number)

local Hand = {}
Hand.__index = Hand
setmetatable(Hand, {__index = Pile})

---@return string
function Hand:__tostring()
	return string.format('hand(%s)(%d)', self.playerName, #self.cards)
end

---@param playerName string
---@return Hand
function Hand.new(playerName)
    ---@class (exact) Hand: Pile
    local o = Pile.new()
    o.playerName = playerName
    return setmetatable(o, Hand)
end

---@param c Card
function Hand:push(c)
    -- send this card to Pile.push, which will set the owner to this hand
    if self.playerName == _G.SETTINGS.humanName then
        c:flipUp()
    else
        c:flipDown()
    end
    Pile.push(self, c)
    -- log.trace("Hand:push()", self, c, c.owner)
end

---@param c Card, has been dragged to a new x,y position in this hand
function Hand:cardDragged(c)
    assert(Card.isCard(c))
    log.trace("cardDragged()", c, c.x, c.y)

    local function isSorted()
        for i = 2, #self.cards do
            if self.cards[i].x < self.cards[i - 1].x then
                return false
            end
        end
        return true
    end

    -- we can remove c from this table because we
    -- only need it's x position, not it's index
    local idx = self:indexOf(c)
    assert(idx)
    table.remove(self.cards, idx)
    assert(isSorted())

    -- reinsert c after cards with a smaller value for x
    -- classic 'insert into sorted list' problem
    -- no need for binary search as list is always 10 items long
    local i = 1
    while i <= #self.cards and self.cards[i].x <= c.x do
        i = i + 1
    end
    table.insert(self.cards, i, c)
    c.owner = self
    -- log.info('inserted', c, 'at', i)
    -- assert(isSorted())
    self:fan()
end

---@param c Card
function Hand:removeCard(c)
    local idx = self:indexOf(c)
    assert(idx)
    table.remove(self.cards, idx)
    self:sort()
end

---@param c Card
function Hand:insertCard(c)
    -- reinsert c after cards with a smaller value for x
    -- classic 'insert into sorted list' problem
    -- no need for binary search as list is always 10 items long
    local i = 1
    while i <= #self.cards and self.cards[i].x <= c.x do
        i = i + 1
    end
    c:flipUp()
    table.insert(self.cards, i, c)
    c.owner = self
    -- log.info('inserted', c, 'at', i)
    self:sort()
end

---@return number
function Hand:width()
    -- if self.cards == nil or #self.cards == 0 then
    --     return 0
    -- end
    -- Hand piles need space for 10 + 1 cards
    -- return (#self.cards - 1) * _G.SETTINGS.cardWidth * 0.75 + _G.SETTINGS.cardWidth
    return (10) * _G.SETTINGS.cardWidth * 0.75 + _G.SETTINGS.cardWidth
end

function Hand:getRect()
    return self.x, self.y, self:width(), _G.SETTINGS.cardHeight
end

function Hand:setPosition()
    if self.cards == nil or #self.cards == 0 then
        return
    end
	local width, height, _ = love.window.getMode()
    self.x = (width / 2) - (self:width() / 2)

    if self.playerName == _G.SETTINGS.humanName then
        self.y = height - _G.SETTINGS.cardHeight - (_G.SETTINGS.cardHeight / 4)
    else
        self.y = (_G.SETTINGS.cardHeight / 4)
    end
    -- log.trace("Hand:setPosition()", self, self.x, self.y)
    self:repositionCards()
end

function Hand:fan()
    if self.cards == nil or #self.cards == 0 then
        return
    end
    local x = self.x
    for _, c in ipairs(self.cards) do
        local y = self.y
        if c.selected then
        	if self.playerName == _G.SETTINGS.humanName then
        		y = y - (_G.SETTINGS.cardHeight * 0.15)
         	else
        		y = y + (_G.SETTINGS.cardHeight * 0.15)
        	end
        end
        c:transitionTo(x, y)
        x = x + (_G.SETTINGS.cardWidth * 0.75)
    end
end

function Hand:sort()
    table.sort(self.cards, function(a, b) return a.ord > b.ord end)
    self:fan()
end

---@return integer
function Hand:numberSelected()
    local n = 0
    for _, c in ipairs(self.cards) do
    	if c.selected then n = n + 1 end
    end
    return n
end

-- update, draw handled by Pile

return Hand
