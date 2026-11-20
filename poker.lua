-- poker.lua

-- local bit = require 'plugin.bit'  -- http://bitop.luajit.org/
--
-- https://en.wikipedia.org/wiki/List_of_poker_hands

local poker = {}

poker.handScore = {
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

---@param map integer
---@return boolean
local function isRoyal(map)
	-- we know that arr is a straight AND a flush, but is it royal?

	-- AKQJX987654321
	-- 11111000000000 = 15872

	return map == 15872
end

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

---@param arr table
---@return string|nil
function poker.handType(arr) -- an array of cards
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

    local fl = containsFlush(arr)
	-- local fl = isOfAKind(histogram, 5)	-- isIfAKind() considers ord, not suit
    -- local st = #arr == 5 and isStraight(map)
	local st, royal = containsStraight(arr)

	-- test in decreasing order
	if st and fl then
		-- if isRoyal(map) then
		if royal then
			return 'Royal Flush'	-- A K Q J 10, same suit
  		else
   			return 'Straight Flush'	-- eg J 10 9 8 7, same suit
		end
	elseif isOfAKind(histogram, 4) then return 'Four of a Kind'
	elseif isOfAKind(histogram, 3) and isOfAKind(histogram, 2) then return 'Full House'
	elseif fl then return 'Flush'
	elseif st then return 'Straight'
	elseif isOfAKind(histogram, 3) then return 'Three of a Kind'
	elseif numOf(histogram, 2) >= 2 then return 'Two Pair'
	elseif isOfAKind(histogram, 2) then return 'One Pair'
	else return 'High Card'
	end
end

function poker.handType5(cards)
    local n = #cards
    assert(n >= 1 and n <= 5, "expected 1 to 5 cards")

    local counts = {}
    local sameSuit = true
    local firstSuit = cards[1].suit

    for i = 1, n do
        local rank = cards[i].ord
        assert(type(rank) == "number" and rank >= 2 and rank <= 14,
               "ordinal must be a number from 2 to 14")
        counts[rank] = (counts[rank] or 0) + 1
        if cards[i].suit ~= firstSuit then
            sameSuit = false
        end
    end

    local groups = {}
    for _, count in pairs(counts) do
        groups[#groups + 1] = count
    end
    table.sort(groups, function(a, b) return a > b end)

    local royal, straight = false, false
    if n == 5 and #groups == 5 then
        local ranks = {}
        for rank in pairs(counts) do
            ranks[#ranks + 1] = rank
        end
        table.sort(ranks)	-- sort into AScending order

        straight = true
        for i = 2, 5 do
            if ranks[i] ~= ranks[i - 1] + 1 then
                straight = false
                break
            end
        end

        if straight and ranks[5] == 14 then
        	royal = true
        end
    end

    if straight and royal and sameSuit then return "Royal Flush" end
    if straight and sameSuit then return "Straight Flush" end
    if groups[1] == 4 then return "Four of a Kind" end
    if groups[1] == 3 and groups[2] == 2 then return "Full House" end
    if sameSuit and n == 5 then return "Flush" end
    if straight then return "Straight" end
    if groups[1] == 3 then return "Three of a Kind" end
    if groups[1] == 2 and groups[2] == 2 then return "Two Pair" end
    if groups[1] == 2 then return "One Pair" end
    return "High Card"
end


return poker
