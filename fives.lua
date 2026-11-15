-- Returns an iterator that yields each ordered 5-element sequence as a table.
function sequencesOfFive(a)
    local n = #a

    return coroutine.wrap(function()
        if n < 5 then return end

        local sequence = {}
        local used = {}

        local function generate(depth)
            if depth == 5 then
                local result = {}
                for i = 1, 5 do
                    result[i] = sequence[i]
                end
                coroutine.yield(result)
                return
            end

            for i = 1, n do
                if not used[i] then
                    used[i] = true
                    sequence[depth + 1] = a[i]
                    generate(depth + 1)
                    used[i] = nil
                end
            end
        end

        generate(0)
    end)
end

local a = {1,2,3,4,5,6}

for seq in sequencesOfFive(a) do
	table.sort(seq, function(i,j) return i<j end)
    print(table.concat(seq, ", "))
end
