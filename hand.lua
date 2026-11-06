-- hand.lua

local log = require 'log'

local Pile = require 'pile'
local Card = require 'card'

---@class (exact) Hand: Pile
---@field __index Hand
---@field __tostring function
---@field playerName string 'human' or 'computer'
---@field new function
---@field setPosition function
---@field cardTapped function(c:Card)
---@field cardDragged function(c:Card, dest:Pile)
---@field fan function
---@field sort function
---@field width function
---@field getRect function
---@field repositionCards function
---@field update function(dt_seconds:number)

local Hand = {}
Hand.__index = Hand
setmetatable(Hand, {__index = Pile})

---@return string
function Hand:__tostring()
	return string.format('hand(%s)(%d)', self.playerName, #self.cards)
end

---@return Hand
function Hand.new(playerName)
    local o = Pile.new()
    o.playerName = playerName
    return setmetatable(o, Hand)
end

---@param c Card
function Hand:push(c)
    -- send this card to Pile.push, which will set the owner to this hand
    Pile.push(self, c)
    if self.playerName == 'human' then
        c:flipUp()
    else
        c:flipDown()
    end
    log.trace("Hand:push()", self, c, c.owner)
end

---@param c Card, taken out of it's owning pile, but .owner still set
function Hand:cardTapped(c)
	assert(c)
	assert(type(c)=='table')
	assert(c.__index==Card)
    assert(c.owner.playerName)
	log.trace("Hand:cardTapped()", c)
	c.owner:push(c)
    c.owner:fan()
end

---@param c Card, taken out of it's owning pile, but .owner still set
---@param dest Pile
function Hand:cardDragged(c, dest)
    if not dest then 
        table.insert(c.owner.cards, c)  -- put the card back in its pile
        c.owner:fan()
        return
    end
    assert(c)
    assert(type(c)=='table')
    assert(c.__index==Card)
    assert(c.owner.playerName)
    log.trace("Hand:cardDragged()", c)

    -- TODO use x,y to verify we are over the hand pile, or (TODO) discard pile
    local left, right = 1, #c.owner.cards + 1

    -- Find the first position whose x is >= c.x
    while left < right do
        local mid = math.floor((left + right) / 2)
        if c.owner.cards[mid].x < c.x then
            left = mid + 1
        else
            right = mid
        end
    end

    table.insert(c.owner.cards, left, c)
    c.owner:fan()
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

    if self.playerName == 'human' then
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
        c:transitionTo(x, self.y)
        x = x + (_G.SETTINGS.cardWidth * 0.75)
    end
end

function Hand:sort()
    table.sort(self.cards, function(a, b) return a.ord < b.ord end)
    self:fan()
end

-- update, draw handled by Pile

return Hand
