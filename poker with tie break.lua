-- poker.lua

-- local bit = require 'plugin.bit'  -- http://bitop.luajit.org/
--
-- https://en.wikipedia.org/wiki/List_of_poker_hands

local poker = {}

poker.handScore = {
  ['Royal Flush'] = 100,
  ['Straight Flush'] = 75,
  ['Four of a Kind'] = 50,
  ['Full House'] = 25,
  ['Flush'] = 20,
  ['Straight'] = 15,
  ['Three of a Kind'] = 10,
  ['Two Pair'] = 5,
  ['One Pair'] = 2,
  ['High Card'] = 1,
}

local function compareKeyArrays(a, b)
	local len = math.max(#a, #b)
	for i = 1, len do
		local va = a[i] or 0
		local vb = b[i] or 0
		if va > vb then return 1 end
		if va < vb then return -1 end
	end
	return 0
end

-- Returns an array of numbers (highest priority first) for breaking ties
-- within the same handType.
function poker.handRankKey(cards, handType)
	assert(type(cards) == 'table' and #cards > 0, "expected non-empty cards table")
	handType = handType or poker.handType5(cards)

	local counts = {}
	local allOrds = {}
	for _, c in ipairs(cards) do
		counts[c.ord] = (counts[c.ord] or 0) + 1
		allOrds[#allOrds + 1] = c.ord
	end
	table.sort(allOrds, function(a, b) return a > b end)

	if handType == "Royal Flush" or handType == "Straight Flush" or handType == "Straight" then
		-- Wheel check (A-2-3-4-5): if ranks are 2, 3, 4, 5, 14, high card of straight is 5
		if #allOrds == 5 and allOrds[1] == 14 and allOrds[2] == 5
			and allOrds[3] == 4 and allOrds[4] == 3 and allOrds[5] == 2 then
			return { 5 }
		end
		return { allOrds[1] }
	end

	if handType == "Flush" or handType == "High Card" then
		return allOrds
	end

	local byGroup = { [4] = {}, [3] = {}, [2] = {}, [1] = {} }
	for rank, cnt in pairs(counts) do
		local bucket = byGroup[cnt]
		if bucket then
			bucket[#bucket + 1] = rank
		end
	end
	for _, bucket in pairs(byGroup) do
		table.sort(bucket, function(a, b) return a > b end)
	end

	local key = {}
	if handType == "Four of a Kind" then
		for _, r in ipairs(byGroup[4]) do key[#key + 1] = r end
		for _, r in ipairs(byGroup[1]) do key[#key + 1] = r end
		return key
	end

	if handType == "Full House" then
		for _, r in ipairs(byGroup[3]) do key[#key + 1] = r end
		for _, r in ipairs(byGroup[2]) do key[#key + 1] = r end
		return key
	end

	if handType == "Three of a Kind" then
		for _, r in ipairs(byGroup[3]) do key[#key + 1] = r end
		for _, r in ipairs(byGroup[1]) do key[#key + 1] = r end
		return key
	end

	if handType == "Two Pair" then
		for _, r in ipairs(byGroup[2]) do key[#key + 1] = r end
		for _, r in ipairs(byGroup[1]) do key[#key + 1] = r end
		return key
	end

	if handType == "One Pair" then
		for _, r in ipairs(byGroup[2]) do key[#key + 1] = r end
		for _, r in ipairs(byGroup[1]) do key[#key + 1] = r end
		return key
	end

	return allOrds
end

function poker.handType5(cards)
	assert(cards)
	assert(type(cards) == 'table')
	assert(#cards > 0)
	assert(#cards>=1)
	assert(#cards<=5)
	local n = #cards
	-- assert(n >= 1 and n <= 5, "expected 1 to 5 cards")

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

-- Returns only the cards that form the given handType within a 1-5 card set.
local function filterScoringCards(cards, handType)
	if handType == "Royal Flush"
		or handType == "Straight Flush"
		or handType == "Full House"
		or handType == "Flush"
		or handType == "Straight"
	then
		local copy = {}
		for i, c in ipairs(cards) do
			copy[i] = c
		end
		return copy
	end

	local counts = {}
	for _, c in ipairs(cards) do
		counts[c.ord] = (counts[c.ord] or 0) + 1
	end

	if handType == "Four of a Kind" then
		local targetRank
		for rank, cnt in pairs(counts) do
			if cnt == 4 then
				targetRank = rank
				break
			end
		end
		local result = {}
		for _, c in ipairs(cards) do
			if c.ord == targetRank then
				result[#result + 1] = c
			end
		end
		return result
	end

	if handType == "Three of a Kind" then
		local targetRank
		for rank, cnt in pairs(counts) do
			if cnt == 3 then
				targetRank = rank
				break
			end
		end
		local result = {}
		for _, c in ipairs(cards) do
			if c.ord == targetRank then
				result[#result + 1] = c
			end
		end
		return result
	end

	if handType == "Two Pair" then
		local pairRanks = {}
		for rank, cnt in pairs(counts) do
			if cnt == 2 then
				pairRanks[rank] = true
			end
		end
		local result = {}
		for _, c in ipairs(cards) do
			if pairRanks[c.ord] then
				result[#result + 1] = c
			end
		end
		return result
	end

	if handType == "One Pair" then
		local targetRank
		for rank, cnt in pairs(counts) do
			if cnt == 2 then
				targetRank = rank
				break
			end
		end
		local result = {}
		for _, c in ipairs(cards) do
			if c.ord == targetRank then
				result[#result + 1] = c
			end
		end
		return result
	end

	-- "High Card": keep only the single highest-ordinal card
	local bestCard = cards[1]
	for i = 2, #cards do
		if cards[i].ord > bestCard.ord then
			bestCard = cards[i]
		end
	end
	return { bestCard }
end

-- Compares two PokerHandInfo tables (or raw card tables).
-- Returns: 1 if `a` beats `b`, -1 if `b` beats `a`, 0 if tied.
function poker.compareHands(a, b)
	local infoA = (type(a) == "table" and a.type and a.tieKey) and a or poker.handTypeEx(a)
	local infoB = (type(b) == "table" and b.type and b.tieKey) and b or poker.handTypeEx(b)

	local scoreA = poker.handScore[infoA.type] or infoA.score or 0
	local scoreB = poker.handScore[infoB.type] or infoB.score or 0

	if scoreA > scoreB then return 1 end
	if scoreA < scoreB then return -1 end

	return compareKeyArrays(infoA.tieKey or {}, infoB.tieKey or {})
end

---@class (exact) PokerHandInfo
---@field type string
---@field score integer
---@field cards Card[] (not real cards)
---@field value integer sum of all the card values
---@field tieKey integer[]

---@param hand Card[]
---@return PokerHandInfo
function poker.handTypeEx(hand)

	local function totalValue(cards)
		local n = 0
		for _, c in ipairs(cards) do
			-- these aren't real cards, so we can't use Card:value()
			-- n = n + math.min(c.ord, 10)
			n = n + _G.CARDVALUES[c.ord]
		end
		return n
	end

	local function get_combinations(cards, k)
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

	local function isBetterCandidate(candType, candKey, bestType, bestKey, hasBest)
		if not hasBest then return true end
		local candScore = poker.handScore[candType]
		local bestScore = poker.handScore[bestType]
		if candScore > bestScore then return true end
		if candScore < bestScore then return false end
		return compareKeyArrays(candKey, bestKey) == 1
	end

	if not hand or #hand == 0 then
		assert(hand and #hand>0, 'Passing empty hand to poker.handTypeEx')
   		return {type='', score=0, cards={}, value=0, tieKey={}}
	end
	if #hand <= 5 then
		local t = poker.handType5(hand)
		local key = poker.handRankKey(hand, t)
		local scoringCards = filterScoringCards(hand, t)
		return {
			type = t,
			score = poker.handScore[t],
			cards = scoringCards,
			value = totalValue(scoringCards),
			tieKey = key
		}
	end

	local co = get_combinations(hand, 5)
	local bestType = 'High Card'
	local bestScore = 0
	local bestHand = nil
	local bestKey = {}
	local hasBest = false

	while true do
		local success, result = coroutine.resume(co)
		if not success or not result then break end
		local typ = poker.handType5(result)
		local key = poker.handRankKey(result, typ)
		if isBetterCandidate(typ, key, bestType, bestKey, hasBest) then
			bestType = typ
			bestScore = poker.handScore[typ]
			bestHand = result
			bestKey = key
			hasBest = true
		end
	end

	local scoringCards = filterScoringCards(bestHand, bestType)
	return {
		type = bestType,
		score = bestScore,
		cards = scoringCards,
		value = totalValue(scoringCards),
		tieKey = bestKey
	}
end

return poker