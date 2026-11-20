-- pokertest.lua

local poker = require 'poker'

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
local longHandRoyalFlush = {
	{suit='♣', ord=1},
	{suit='♣', ord=14},
	{suit='♣', ord=13},
	{suit='♣', ord=12},
	{suit='♣', ord=11},
	{suit='♣', ord=10},
	{suit='♣', ord=7},
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
local longHandTwoPair = {
	{suit='♦', ord=11},
	{suit='♣', ord=11},
	{suit='♦', ord=10},
	{suit='♣', ord=9},
	{suit='♦', ord=9},
	{suit='♦', ord=7},
	{suit='♣', ord=7},
}
local singleCard = {
	{suit='♣', ord=10},
}

print('Royal Flush', poker.handType5(royalFlush))
print('Straight Flush', poker.handType5(straightFlush))
print('Four of a Kind', poker.handType5(four))
print('Full House', poker.handType5(fullHouse))
print('Flush', poker.handType5(flush))
print('Straight', poker.handType5(straight))
print('Three of a Kind', poker.handType5(three))
print('Two Pair', poker.handType5(twoPair))
print('Pair', poker.handType5(onePair))
print('High Card', poker.handType5(highCard))

--[[
print('Short One Pair', pokerHandType(shortPair))
print('Long Royal Flush', pokerHandType(longHandRoyalFlush))
print('Long Full House', pokerHandType(longHandFullHouse))
print('Long Flush', pokerHandType(longHandFlush))
print('Long Straight', pokerHandType(longHandStraight))
print('Long Two Pair', pokerHandType(longHandTwoPair))
print('Single Card', pokerHandType(singleCard))
]]

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
