-- pokertest.lua

local poker = require 'poker'

local function printHand(hand)
    local str = ''
    for _, c in ipairs(hand) do
    	str = str .. c.suit .. c.ord .. ' '
    end
	print(str)
end

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
	{suit='♣', ord=2},
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

--[[
print('Royal Flush', poker.handType(royalFlush))
print('Straight Flush', poker.handType(straightFlush))
print('Four of a Kind', poker.handType(four))
print('Full House', poker.handType(fullHouse))
print('Flush', poker.handType(flush))
print('Straight', poker.handType(straight))
print('Three of a Kind', poker.handType(three))
print('Two Pair', poker.handType(twoPair))
print('Pair', poker.handType(onePair))
print('High Card', poker.handType(highCard))

print('Short One Pair', poker.handType(shortPair))
print('Long Royal Flush', poker.handType(longHandRoyalFlush))
print('Long Full House', poker.handType(longHandFullHouse))
print('Long Flush', poker.handType(longHandFlush))
print('Long Straight', poker.handType(longHandStraight))
print('Long Two Pair', poker.handType(longHandTwoPair))
print('Single Card', poker.handType(singleCard))
]]

local t,s,h = poker.handTypeEx(longHandRoyalFlush)
printHand(longHandRoyalFlush)
print(t)
print(s)
printHand(h)

t,s,h = poker.handTypeEx(shortPair)
printHand(shortPair)
print(t)
print(s)
printHand(h)

