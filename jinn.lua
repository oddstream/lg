-- jinn.lua

-- for a singleton pattern in Lua 5.1,
-- a module is naturally singleton-like:
-- require caches the module’s returned value in package.loaded

local log = require 'log'

---@class (exact) Jinn
---@field __index Jinn
---@field __tostring function
---@field state string
---@field baize table
---@field new function
---@field isAllowed function
---@field notifyCardMove function
---@field action function

local Jinn = {}
Jinn.__index = Jinn

local state = {
    'setup',
    'humanDraw',   -- from stock or discard
    'humanDiscard',-- to discard
    'botDraw',
    'botDiscard',
}

---@return string
function Jinn:__tostring()
    return self.state
end

function Jinn.new(baize)
    local o = {baize=baize, state='setup'}
    -- for the moment, the bot is always the dealer
    return setmetatable(o, Jinn)
end

---@param card Card
---@param from Pile
---@param to Pile
---@return boolean
function Jinn:isAllowed(card, from, to)
    log.trace('isAllowed?', self.state, card, from, to)
    if (self.state == 'humanDraw')
    and (from == self.baize.stock or from == self.baize.discard)
    and (to == self.baize.humanHand)
    and #self.baize.humanHand.cards == 10
        then return true
    end
    if (self.state == 'humanDiscard')
    and (from == self.baize.humanHand)
    and (to == self.baize.discard)
    and #self.baize.humanHand.cards == 11
    and not card.justDiscarded
        then return true
    end
    log.warn('not allowed')
    return false
end

---@param card Card
---@param from Pile
---@param to Pile
function Jinn:notifyCardMove(card, from, to)
    log.trace('notifyCardMove', self.state, card, from, to)
    if self.state == 'humanDraw'
        and (from == self.baize.stock or from == self.baize.discard)
        and to == self.baize.humanHand
        then
        self.baize.humanHand:sort()
        self.state = 'humanDiscard'
    end
    if self.state == 'humanDiscard'
        and from == self.baize.humanHand
        and to == self.baize.discard
        then
    	assert(not card.justDiscarded)
        self.baize.humanHand:sort()
        self.state = 'botDraw'
        for _, c in ipairs(self.baize.humanHand.cards) do
        	c.justDiscarded = nil
        end
    end
    -- "If a player chooses to draw face-up card (from the discard pile)
    -- the discarded card cannot be the just drawn card."
    if from == self.baize.discard and to == self.baize.humanHand then
        card.justDiscarded = true
    end
    -- TODO determine where to reset this flag
end

function Jinn:action()
    -- log.info('Jinn action', self.state)
    if self.state == 'setup' then
        self.baize:deal()
        self.baize.humanHand:sort()
        self.baize.botHand:sort()
        self.state = 'humanDraw'
    elseif self.state == 'botDraw' then
        -- move a card from stock/discard to botHand
        -- for now, draw card from stock
        self.baize.botHand:push(self.baize.stock:pop())
        self.baize.botHand:fan()
        self.baize.botHand:sort()
        self.state = 'botDiscard'
    elseif self.state == 'botDiscard' then
        -- move a card from botHand to discard
        -- local n = math.random(#self.baize.botHand.cards)
        -- local c = self.baize.botHand:remove(n)
        -- for now, remove a random deadwood card
        assert(#self.baize.botHand.deadwood>0)
        local n = math.random(#self.baize.botHand.deadwood)
        local c = self.baize.botHand:remove(self.baize.botHand.deadwood[n].textureId)
        self.baize.botHand:fan()
        self.baize.discard:push(c)
        self.baize.botHand:sort()
        self.state = 'humanDraw'
    end
end

return Jinn
