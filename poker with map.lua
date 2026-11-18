-- poker.lua

-- local bit = require 'plugin.bit'  -- http://bitop.luajit.org/
--
-- https://en.wikipedia.org/wiki/List_of_poker_hands
-- TODO check and adjust to cope with 1 .. 5 cards, not just 5

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

local royalFlush = {
	{suit='♣', ord=14},
	{suit='♣', ord=13},
	{suit='♣', ord=12},
	{suit='♣', ord=11},
	{suit='♣', ord=10},
}

local straightFlush = {
	{suit='♣', ord=9},
	{suit='♣', ord=8},
	{suit='♣', ord=7},
	{suit='♣', ord=6},
	{suit='♣', ord=5},
}
local fullHouse = {
	{suit='♣', ord=14},
	{suit='♦', ord=14},
	{suit='♥', ord=3},
	{suit='♠', ord=3},
	{suit='♣', ord=3},
}

local flush = {
	{suit='♣', ord=14},
	{suit='♣', ord=13},
	{suit='♣', ord=10},
	{suit='♣', ord=3},
	{suit='♣', ord=2},
}

local straight = {
	{suit='♣', ord=14},
	{suit='♦', ord=13},
	{suit='♥', ord=12},
	{suit='♠', ord=11},
	{suit='♣', ord=10},
}

local four = {
	{suit='♣', ord=5},
	{suit='♦', ord=14},
	{suit='♥', ord=5},
	{suit='♠', ord=5},
	{suit='♣', ord=5},
}

local three = {
	{suit='♣', ord=5},
	{suit='♦', ord=14},
	{suit='♥', ord=5},
	{suit='♠', ord=11},
	{suit='♣', ord=5},
}

local twoPair = {
	{suit='♣', ord=14},
	{suit='♦', ord=14},
	{suit='♥', ord=7},
	{suit='♠', ord=3},
	{suit='♣', ord=3},
}

local onePair = {
	{suit='♣', ord=14},
	{suit='♦', ord=14},
	{suit='♥', ord=7},
	{suit='♠', ord=6},
	{suit='♣', ord=3},
}

local highCard = {
	{suit='♣', ord=14},
	{suit='♦', ord=10},
	{suit='♥', ord=7},
	{suit='♠', ord=6},
	{suit='♣', ord=3},
}

local shortPair = {
	{suit='♣', ord=10},
	{suit='♦', ord=10},
	{suit='♥', ord=7},
}
local longHandFullHouse = {
	{suit='♣', ord=11},
	{suit='♦', ord=10},
	{suit='♦', ord=7},
	{suit='♦', ord=10},
	{suit='♦', ord=8},
	{suit='♦', ord=7},
	{suit='♣', ord=10},
}
local longHandFlush = {
	{suit='♣', ord=11},
	{suit='♦', ord=10},
	{suit='♦', ord=9},
	{suit='♦', ord=8},
	{suit='♦', ord=2},
	{suit='♦', ord=7},
	{suit='♣', ord=13},
}
local longHandStraight = {
	{suit='♦', ord=2},
	{suit='♣', ord=11},
	{suit='♦', ord=10},
	{suit='♣', ord=9},
	{suit='♦', ord=8},
	{suit='♦', ord=7},
	{suit='♣', ord=13},
}
local singleCard = {
	{suit='♣', ord=10},
}

print('Royal Flush', pokerHandType(royalFlush))
print('Straight Flush', pokerHandType(straightFlush))
print('Four of a Kind', pokerHandType(four))
print('Full House', pokerHandType(fullHouse))
print('Flush', pokerHandType(flush))
print('Straight', pokerHandType(straight))
print('Three of a Kind', pokerHandType(three))
print('Two Pair', pokerHandType(twoPair))
print('Pair', pokerHandType(onePair))
print('High Card', pokerHandType(highCard))

print('Short Pair', pokerHandType(shortPair), '(should be one pair)')
print('Long Hand', pokerHandType(longHandFullHouse), '(should be full house)')
print('Long Hand', pokerHandType(longHandFlush), '(should be flush)')
print('Long Hand', pokerHandType(longHandStraight), '(should be straight)')
print('Single Card', pokerHandType(singleCard), '(should be high card)')

function get_combinations(cards, k)
    return coroutine.create(function()
        local n = #cards
        local current_hand = {}

        local function generate(start_index)
            -- Base case: we have selected k cards
            if #current_hand == k then
                -- Yield a copy of the current hand
                local copy = {}
                for i = 1, k do
                    copy[i] = current_hand[i]
                end
                coroutine.yield(copy)
                return
            end

            -- Recursive step: pick the next card from the remaining pool
            for i = start_index, n do
                table.insert(current_hand, cards[i])
                generate(i + 1)
                table.remove(current_hand) -- Backtrack
            end
        end

        generate(1)
    end)
end
--[[
local function printHand(hand)
    local str = ''
    for i, c in ipairs(hand) do
    	str = str .. c.suit .. c.ord .. ' '
    end
	print(str)
end

local co = get_combinations(longHand, 5)
printHand(longHand)
print("Generating combinations of 5 from 7:")
local count = 0
local bestType = ''
local bestScore = 0
while true do
    local success, result = coroutine.resume(co)
    if not success or not result then break end
    local typ = pokerHandType(result)
    count = count + 1
    -- Format the table for printing
    printHand(result)
end
-- print(string.format("Total combinations generated: %d (expected 21)", count))
]]
