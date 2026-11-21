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

function poker.handTypeEx(hand)

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

    if not hand or #hand == 0 then
    	assert(hand and #hand>0, 'Passing empty hand to poker.handTypeEx')
   		return '', 0, {}
    end
    if #hand <= 5 then
      local t = poker.handType5(hand)
        return t, poker.handScore[t].us, hand
    end
    local co = get_combinations(hand, 5)
    local bestType = 'High Card'
    local bestScore = 0
    local bestHand = {}
    while true do
        local success, result = coroutine.resume(co)
        if not success or not result then break end
        local typ = poker.handType5(result)
        if poker.handScore[typ].us > bestScore then
        bestType = typ
        bestScore = poker.handScore[typ].us
        bestHand = result
        end
    end
    return bestType, bestScore, bestHand
end

return poker
