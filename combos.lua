
--[[
	"I have a Lua table containing seven numbers, for example {2,3,6,10,11,11,14}.
	The numbers in the table may occur more than once. Write a Lua function to produce every combination of five card hands
	from with the seven card hand. Use coroutines in the solution."

	Gemma 4 31B

	To generate combinations of five cards from a seven-card hand using coroutines,
	you can create a recursive generator function that yields each combination as it is found.
	Because Lua tables are passed by reference,
	it is important to yield a copy of the current hand to prevent the caller from seeing the table change as the function backtracks.

	In this implementation, get_combinations returns a coroutine object.
	The inner generate function uses a standard backtracking algorithm to explore all possible index combinations.
	By passing i + 1 to the next recursive call, the function ensures that it only moves forward through the table,
	which prevents duplicate sets (like picking cards 1,2,3,4,5 and then 5,4,3,2,1).
	The while loop then resumes the coroutine repeatedly until it returns false, signaling that all combinations have been exhausted.

	Because the 7-card hand can contain duplicate numbers,
	this implementation selects combinations based on indices (choosing 5 distinct positions out of the 7),
	ensuring that if the same number appears multiple times at different positions, each unique positional combination is correctly generated.
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

-- Example usage:
local hand = {2, 3, 6, 10, 11, 11, 14}
local co = get_combinations(hand, 5)
print("{" .. table.concat(hand, ", ") .. "}")
print("Generating combinations of 5 from 7:")
local count = 0
while true do
    local success, result = coroutine.resume(co)
    if not success or not result then break end
    count = count + 1
    -- Format the table for printing
    print("{" .. table.concat(result, ", ") .. "}")
end
print(string.format("Total combinations generated: %d (expected 21)", count))
