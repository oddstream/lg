-- jinn.lua

-- for a singleton pattern in Lua 5.1,
-- a module is naturally singleton-like:
-- require caches the module’s returned value in package.loaded

local log = require 'log'

---@param arr table
---@return boolean
local function containsFlush(arr)
    if #arr < 5 then return false end
    if #arr == 5 then
        local s = arr[1].suit
        for i = 2, #arr do
            if arr[i].suit ~= s then return false end
        end
        return true
    end
    if #arr > 5 then
        local counts = {}
        for _, c in ipairs(arr) do
            counts[c.suit] = (counts[c.suit] or 0) + 1
            if counts[c.suit] >= 5 then
                return true
            end
        end
        return false
    end
	return false
end

---@param t table
---@return boolean, boolean
local function containsStraight(t)
	-- only works if table is sorted into decreasing .ord
    local streak = 1

    for i = 2, #t do
        if t[i].ord == t[i - 1].ord - 1 then
            streak = streak + 1
            if streak == 5 then
                return true, t[i].ord == 10
            end
        else
            streak = 1
        end
    end

    return false, false
end

---@param hist integer[]
---@param n integer
---@return boolean
local function isOfAKind(hist, n)
	for i = 1, 14 do
		if hist[i] == n then
			return true
		end
	end
	return false
end

---@param hist integer[]
---@param n integer
---@return integer
local function numOf(hist, n)
	local count = 0
	for i = 1, 14 do
		if hist[i] == n then
			count = count + 1
		end
	end
	return count
end

---@param arr Card[]
---@return string
local function pokerHandType(arr)
    -- only works if hand is sorted into decreasing ord (because of straight check)
    -- histogram array contains counts of each card ordinal in arr
	-- so if there are five 2's, then histogram would be [0,5,0,0..]
	local histogram = {0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    assert(#histogram == 14)
    for i = 1, #arr do
		local o = arr[i].ord
		histogram[o] = histogram[o] + 1
	end

	local fl = containsFlush(arr)
    local st, royal = containsStraight(arr)

	-- test in decreasing order
	if st and fl then
        if royal then
			return 'Royal Flush'
  		else
   			return 'Straight Flush'
		end
	elseif isOfAKind(histogram, 4) then return 'Four of a Kind'
	elseif isOfAKind(histogram, 3) and isOfAKind(histogram, 2) then return 'Full House'
	elseif fl then return 'Flush'
	elseif st then return 'Straight'
	elseif isOfAKind(histogram, 3) then return 'Three of a Kind'
        -- use >= not == incase there are three pair, which we don't count
	elseif numOf(histogram, 2) >= 2 then return 'Two Pair'
	elseif isOfAKind(histogram, 2) then return 'One Pair'
	else return 'High Card'
	end
end

local pokerHandScore = {
  ['Royal Flush'] = {uk=30, us=100},
  ['Straight Flush'] = {uk=30, us=75},
  ['Four of a Kind'] = {uk=16, us=50},
  ['Full House'] = {uk=10, us=25},
  ['Flush'] = {uk=5, us=20},
  ['Straight'] = {uk=12, us=15},
  ['Three of a Kind'] = {uk=6, us=10},
  ['Two Pair'] = {uk=3, us=5},
  ['One Pair'] = {uk=1, us=2},
  ['High Card'] = {uk=0, us=0},
}

---@class (exact) Jinn
---@field __index Jinn
---@field __tostring function
---@field state string
---@field baize table
---@field new function
---@field isAllowed function
---@field notifyCardMove function
---@field notifyCardTapped function
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
    local o = {baize = baize, state = 'setup', round = 0, botCoin = 0, humanCoin = 0}
    -- for the moment, the bot is always the dealer
    return setmetatable(o, Jinn)
end

function Jinn:botHandChanged()
    -- self.baize.botHand:log()
	        --[[
	local bestHandScore = 0
    local bestHandType = 'noname'
    local arr = {}
    for _, c in ipairs(self.baize.botHand.cards) do
        table.insert(arr, c)
    end
    for hand in sequencesOfFive(arr) do
        local typ = pokerHandType(hand)
		if hand and pokerHandScore[typ].uk > bestHandScore then
            bestHandScore = pokerHandScore[typ].uk
			bestHandType = typ
		end
	end
	self.baize.botHand.selectedPokerHandType = bestHandType
	]]
	self.baize.botHand:sort()
	local arr = {}
    for _, c in ipairs(self.baize.botHand.cards) do
        table.insert(arr, c)
    end
	-- self.baize.botHand.selectedPokerHandType = pokerHandType(arr)
	self.baize.botHand.selectedPokerHandType = nil
	self.baize.botHand:fan()
end

function Jinn:humanHandChanged()
    self.baize.humanHand:sort()
	local arr = {}
    for _, c in ipairs(self.baize.humanHand.cards) do
        if c.selected then
            table.insert(arr, c)
        end
    end
    self.baize.humanHand.selectedPokerHandType = pokerHandType(arr)
    -- log.info(#arr, 'cards selected', self.baize.humanHand.selectedPokerHandType)
    self.baize.humanHand:fan()
end

---@param card Card
---@param from Pile
---@param to Pile
---@return boolean
function Jinn:isAllowed(card, from, to)
    -- log.trace('isAllowed?', self.state, card, from, to)
    if (self.state == 'humanDraw')
    and (from == self.baize.stock or from == self.baize.discard)
    and (to == self.baize.humanHand)
        then return true
    end
    if (self.state == 'humanDiscard')
    and (from == self.baize.humanHand)
    and (to == self.baize.discard)
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
        self:humanHandChanged()
        self.state = 'humanDiscard'
    end
    if self.state == 'humanDiscard'
        and from == self.baize.humanHand
        and to == self.baize.discard
    then
        self:humanHandChanged()
        self.state = 'botDraw'
    end
end

---@param card Card
function Jinn:notifyCardTapped(card)
    if card.owner == self.baize.humanHand then
        self:humanHandChanged()
    end
end

function Jinn:play()
    -- player has pressed the play button
    -- show bot cards and hand type
    -- hide play button
    -- show cashout button
    for _, c in ipairs(self.baize.botHand.cards) do
        c:flip()
    end

    local arr = {}
    for _, c in ipairs(self.baize.botHand.cards) do
        table.insert(arr, c)
    end
    self.baize.botHand.selectedPokerHandType = pokerHandType(arr)

    arr = {}
    for _, c in ipairs(self.baize.humanHand.cards) do
        if c.selected then
            table.insert(arr, c)
        end
    end
    self.baize.humanHand.selectedPokerHandType = pokerHandType(arr)

    self.state = 'cashout'
end

function Jinn:cashout()
    -- player has pressed the cashout button
    -- update coins and return to setup state
    local botScore = pokerHandScore[self.baize.botHand.selectedPokerHandType].uk
    local humanScore = pokerHandScore[self.baize.humanHand.selectedPokerHandType].uk

    if botScore > humanScore then
        log.info('bot wins', self.baize.botHand.selectedPokerHandType, 'better than',
            self.baize.humanHand.selectedPokerHandType)
        self.botCoin = self.botCoin + botScore
    elseif humanScore > botScore then
        log.info('human wins', self.baize.humanHand.selectedPokerHandType, 'better than',
            self.baize.botHand.selectedPokerHandType)
        self.humanCoin = self.humanCoin + humanScore
    else
        log.info('draw')
    end
    log.info('bot has', self.botCoin, 'coin, human has', self.humanCoin, 'coin')

    self.state = 'setup'
end

function Jinn:action()
    -- log.info('Jinn action', self.state)
    if self.state == 'setup' then
        self.round = self.round + 1
        self.baize:deal()
        self:botHandChanged()
        self:humanHandChanged()
        self.baize.roundLabel.text = string.format('Round %d', self.round)
        self.baize.botScoreLabel.text = string.format('Bot $%d', self.botCoin)
        self.baize.humanScoreLabel.text = string.format('You $%d', self.humanCoin)
        self.baize.playButton.state = 'disabled'
        self.baize.cashoutButton.state = 'hidden'
        self.state = 'humanDraw'
    elseif self.state == 'humanDraw' then
        if self.baize.humanHand:numberSelected() > 0 then
            self.baize.playButton.state = 'active'
        else
            self.baize.playButton.state = 'disabled'
        end
        self.baize.cashoutButton.state = 'hidden'
    elseif self.state == 'humanDiscard' then
        self.baize.playButton.state = 'disabled'
        self.baize.cashoutButton.state = 'hidden'
        -- waiting for player to discard, do nothing
    elseif self.state == 'botDraw' then
        -- move a card from stock/discard to botHand
        -- for now, draw card from stock
        self.baize.botHand:push(self.baize.stock:pop())
        self:botHandChanged()
        self.state = 'botDiscard'
    elseif self.state == 'botDiscard' then
        -- for now, move a random card from botHand to discard
        -- local n = math.random(#self.baize.botHand.cards)
        -- local c = self.baize.botHand:remove(n)
        local c = self.baize.botHand:pop()
        self.baize.discard:push(c)
        self:botHandChanged()
        self.baize.playButton.state = 'disabled'
        self.baize.cashoutButton.state = 'hidden'
        self.state = 'humanDraw'
    elseif self.state == 'cashout' then
        self.baize.playButton.state = 'hidden'
        self.baize.cashoutButton.state = 'active'
        -- waiting for player to press cashout button, do nothing
    end

end

return Jinn
