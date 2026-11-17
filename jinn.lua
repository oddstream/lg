-- jinn.lua

-- for a singleton pattern in Lua 5.1,
-- a module is naturally singleton-like:
-- require caches the module’s returned value in package.loaded

local log = require 'log'

---@param map integer
---@return boolean
local function isRoyal(map)
	-- we know that arr is a straight AND a flush, but is it royal?

	-- AKQJX987654321
	-- 11111000000000 = 15872

	return map == 15872
end

--- flush defined here as all cards being the same suit
---@param arr table
---@return boolean
local function isFlush(arr)
    local s = arr[1].suit
	for i = 2, #arr do
        if arr[i].suit ~= s then return false end
	end
	return true
end

--- this is only going to work for five cards
---@param map integer
---@return boolean
local function isStraight(map)
	-- a straight need not be in order, so treat the cards as a set

	-- nb we don't use a 1 card; the ace is 14
    -- AKQJX987654321
    -- 11111000000000 = 15872
    -- 00000000111110 = 62
	--
	-- for (i=2;i<10;i++) { console.log(31<<i) }
	for _,test in ipairs({62,124,248,496,992,1984,3968,7936,15872}) do
		if test == map then return true end
	end

	return false
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

---@param arr table
---@return string
local function pokerHandType(arr) -- an array of cards
	-- if #arr ~= 5 then
	-- 	return nil
	-- end
    --[[
  local bits = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096}
  assert(#bits==13)
  local histogram = {0,0,0,0,0,0,0,0,0,0,0,0,0}
  assert(#histogram==13)
  local map = 0
  for i=1,5 do
    local o = arr[i].ord
    map = bit.bor(map, bits[o])
    histogram[o] = histogram[o] + 1
  end
]]
    -- histogram array contains counts of each card ordinal in arr
	-- so if there are five 2's, then histogram would be [0,5,0,0..]
	local histogram = {0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    assert(#histogram == 14)

    -- bits is a list of flags; the flag is set (true) if there is a card
    -- with that ordinal in arr. Poker deck doesn't use ordinal 1
	local bits = {false,false,false,false,false,false,false,false,false,false,false,false,false,false}
	assert(#bits==14)

    for i = 1, #arr do
		local o = arr[i].ord
		histogram[o] = histogram[o] + 1
		bits[o] = true
	end

    -- bitValues is a static/constant list of binary numbers with increasing left shifted bit
    -- eg 0b0001, 0b0010, 0x0100, 0x1000 ...
	-- each bit is a flag
    local bitValues = { 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192 }
    assert(#bitValues == 14)

    -- combine all the flags set in boolean array bits[] into a single number
	local map = 0
	for i = 1, 14 do
		if bits[i] then map = map + bitValues[i] end
	end

	local fl = #arr == 5 and isFlush(arr)
	local st = #arr == 5 and isStraight(map)

	-- test in decreasing order
	if st and fl then
		if isRoyal(map) then
			return 'Royal Flush'
  		else
   			return 'Straight Flush'
		end
	elseif isOfAKind(histogram, 4) then return 'Four of a Kind'
	elseif isOfAKind(histogram, 3) and isOfAKind(histogram, 2) then return 'Full House'
	elseif fl then return 'Flush'
	elseif st then return 'Straight'
	elseif isOfAKind(histogram, 3) then return 'Three of a Kind'
	elseif numOf(histogram, 2) == 2 then return 'Two Pair'
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
    local o = {baize = baize, state = 'setup', botCoin = 0, humanCoin = 0}
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
	self.baize.botHand.selectedPokerHandType = pokerHandType(arr)
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
    log.trace('isAllowed?', self.state, card, from, to)
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
    for _, c in ipairs(self.baize.botHand.cards) do
        c:flip()
    end
    self.state = 'showdown'
end

function Jinn:action()
    -- log.info('Jinn action', self.state)
    if self.state == 'setup' then
        self.baize:deal()
        self:botHandChanged()
        self:humanHandChanged()
        self.state = 'humanDraw'
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
        self.state = 'humanDraw'
    elseif self.state == 'showdown' then
    -- change Play button to 'Cash Out'
        local arr = {}
        for _, c in ipairs(self.baize.botHand.cards) do
            table.insert(arr, c)
        end
        self.baize.botHand.selectedPokerHandType = pokerHandType(arr)
        local botScore = pokerHandScore[self.baize.botHand.selectedPokerHandType].uk

        arr = {}
        for _, c in ipairs(self.baize.humanHand.cards) do
            if c.selected then
                table.insert(arr, c)
            end
        end
        self.baize.humanHand.selectedPokerHandType = pokerHandType(arr)
        local humanScore = pokerHandScore[self.baize.humanHand.selectedPokerHandType].uk

        if botScore > humanScore then
            log.info('bot wins', self.baize.botHand.selectedPokerHandType, 'better than',
                self.baize.humanHand.selectedPokerHandType)
            self.botCoin = self.botCoin + pokerHandScore[self.baize.botHand.selectedPokerHandType].uk
        elseif humanScore > botScore then
            log.info('human wins', self.baize.humanHand.selectedPokerHandType, 'better than',
                self.baize.botHand.selectedPokerHandType)
            self.humanCoin = self.humanCoin + pokerHandScore[self.baize.humanHand.selectedPokerHandType].uk
        else
            log.info('draw')
        end
        log.info('bot has', self.botCoin, 'coin, human has', self.humanCoin, 'coin')
        self.state = 'setup'
        -- self.state = 'cashout'
    elseif self.state == 'cashout' then
        self.state = 'setup'
    end

    if self.state == 'humanDraw' and self.baize.humanHand:numberSelected() > 0 then
        self.baize.playButton.state = 'active'
    else
        self.baize.playButton.state = 'disabled'
    end
end

return Jinn
