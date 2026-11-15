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
local longHand = {
	{suit='♣', ord=10},
	{suit='♦', ord=10},
	{suit='♥', ord=7},
	{suit='♣', ord=10},
	{suit='♦', ord=10},
	{suit='♥', ord=7},
	{suit='♣', ord=10},
	{suit='♦', ord=10},
	{suit='♥', ord=7},
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

print('Short Pair', pokerHandType(shortPair))
print('Long Hand', pokerHandType(longHand))
print('Single Card', pokerHandType(singleCard))
