-- hand.lua

local log = require 'log'

local Pile = require 'pile'
local Card = require 'card'

---@class (exact) Hand: Pile
---@field __index Hand
---@field __tostring function
---@field playerName string
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
    if self.playerName == _G.SETTINGS.humanName then
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
        c:transitionTo(x, self.y)
        x = x + (_G.SETTINGS.cardWidth * 0.75)
    end
end

local function cardsToMelds(cards)
    local candidates = {}
    local candidateKeys = {}

    -- Add a meld by card indices, avoiding duplicate candidates.
    local function addMeld(ids)
        local keyIds = {}
        for i = 1, #ids do
            keyIds[i] = ids[i]
        end
        table.sort(keyIds)

        local key = table.concat(keyIds, ",")
        if not candidateKeys[key] then
            candidateKeys[key] = true
            candidates[#candidates + 1] = { ids = keyIds }
        end
    end

    -- Generate every same-suit run of length 3 or more.
    for start = 1, #cards do
        local path = { start }

        local function extend()
            if #path >= 3 then
                addMeld(path)
            end

            local nextOrdinal = cards[path[#path]].ord + 1
            for i = 1, #cards do
                if cards[i].suit == cards[start].suit
                    and cards[i].ord == nextOrdinal then
                    path[#path + 1] = i
                    extend()
                    path[#path] = nil
                end
            end
        end

        extend()
    end

    -- Generate sets of 3 or 4 cards with the same ordinal.
    local byOrdinal = {}
    for i = 1, #cards do
        local ordinal = cards[i].ord
        byOrdinal[ordinal] = byOrdinal[ordinal] or {}
        byOrdinal[ordinal][#byOrdinal[ordinal] + 1] = i
    end

    local function addCombinations(group, size)
        local picked = {}

        local function choose(startAt)
            if #picked == size then
                addMeld(picked)
                return
            end

            for i = startAt, #group - (size - #picked) + 1 do
                picked[#picked + 1] = group[i]
                choose(i + 1)
                picked[#picked] = nil
            end
        end

        choose(1)
    end

    for _, group in pairs(byOrdinal) do
        if #group >= 3 then
            addCombinations(group, 3)
        end
        if #group >= 4 then
            addCombinations(group, 4)
        end
    end

    -- Index candidate melds by the cards they contain.
    local meldsForCard = {}
    for i = 1, #cards do
        meldsForCard[i] = {}
    end
    for _, meld in ipairs(candidates) do
        for _, id in ipairs(meld.ids) do
            meldsForCard[id][#meldsForCard[id] + 1] = meld
        end
    end

    -- Search for the disjoint combination covering the most cards.
    local occupied = {}
    local chosen = {}
    local bestMelds = {}
    local bestCovered = -1

    local function search(covered)
        local firstFree
        for i = 1, #cards do
            if not occupied[i] then
                firstFree = i
                break
            end
        end

        if not firstFree then
            if covered > bestCovered
                or (covered == bestCovered and #chosen < #bestMelds) then
                bestCovered = covered
                bestMelds = {}
                for i = 1, #chosen do
                    bestMelds[i] = chosen[i]
                end
            end
            return
        end

        -- Option: leave this card as deadwood.
        occupied[firstFree] = true
        search(covered)
        occupied[firstFree] = nil

        -- Option: use it in any compatible meld.
        for _, meld in ipairs(meldsForCard[firstFree]) do
            local available = true
            for _, id in ipairs(meld.ids) do
                if occupied[id] then
                    available = false
                    break
                end
            end

            if available then
                for _, id in ipairs(meld.ids) do
                    occupied[id] = true
                end
                chosen[#chosen + 1] = meld
                search(covered + #meld.ids)
                chosen[#chosen] = nil
                for _, id in ipairs(meld.ids) do
                    occupied[id] = nil
                end
            end
        end
    end

    search(0)

    local resultMelds = {}
    local inMeld = {}
    for i, meld in ipairs(bestMelds) do
        resultMelds[i] = {}
        for _, id in ipairs(meld.ids) do
            resultMelds[i][#resultMelds[i] + 1] = cards[id]
            inMeld[id] = true
        end
    end

    local deadwood = {}
    local deadwoodValue = 0
    for i, card in ipairs(cards) do
        if not inMeld[i] then
            deadwood[#deadwood + 1] = card
            deadwoodValue = deadwoodValue + card:value()
        end
    end

    return resultMelds, deadwood, deadwoodValue
end

function Hand:sort()
    table.sort(self.cards, function(a, b) return a.ord < b.ord end)
    self:fan()
    local melds, deadwood, deadwoodValue = cardsToMelds(self.cards)
    log.trace(#melds, 'melds')
    for _, meld in ipairs(melds) do
        for _, c in ipairs(meld) do
            log.trace(c)
        end
    end
    log.trace(#deadwood, 'deadwood cards, total value', deadwoodValue)
end

-- update, draw handled by Pile

return Hand
