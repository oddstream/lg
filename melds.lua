local function cardsToMelds(cards)
    local candidates = {}
    local candidateKeys = {}

    -- Add a meld by card indices, avoiding duplicate candidates.
    local function addMeld(ids)
        local keyIds = {}
        for i = 1, #ids do
            keyIds[i] = ids[i]
        end
        table.sort(keyIds)

        local key = table.concat(keyIds, ",")
        if not candidateKeys[key] then
            candidateKeys[key] = true
            candidates[#candidates + 1] = { ids = keyIds }
        end
    end

    -- Generate every same-suit run of length 3 or more.
    for start = 1, #cards do
        local path = { start }

        local function extend()
            if #path >= 3 then
                addMeld(path)
            end

            local nextOrdinal = cards[path[#path]].ord + 1
            for i = 1, #cards do
                if cards[i].suit == cards[start].suit
                    and cards[i].ord == nextOrdinal then
                    path[#path + 1] = i
                    extend()
                    path[#path] = nil
                end
            end
        end

        extend()
    end

    -- Generate sets of 3 or 4 cards with the same ordinal.
    local byOrdinal = {}
    for i = 1, #cards do
        local ordinal = cards[i].ord
        byOrdinal[ordinal] = byOrdinal[ordinal] or {}
        byOrdinal[ordinal][#byOrdinal[ordinal] + 1] = i
    end

    local function addCombinations(group, size)
        local picked = {}

        local function choose(startAt)
            if #picked == size then
                addMeld(picked)
                return
            end

            for i = startAt, #group - (size - #picked) + 1 do
                picked[#picked + 1] = group[i]
                choose(i + 1)
                picked[#picked] = nil
            end
        end

        choose(1)
    end

    for _, group in pairs(byOrdinal) do
        if #group >= 3 then
            addCombinations(group, 3)
        end
        if #group >= 4 then
            addCombinations(group, 4)
        end
    end

    -- Index candidate melds by the cards they contain.
    local meldsForCard = {}
    for i = 1, #cards do
        meldsForCard[i] = {}
    end
    for _, meld in ipairs(candidates) do
        for _, id in ipairs(meld.ids) do
            meldsForCard[id][#meldsForCard[id] + 1] = meld
        end
    end

    -- Search for the disjoint combination covering the most cards.
    local occupied = {}
    local chosen = {}
    local bestMelds = {}
    local bestCovered = -1

    local function search(covered)
        local firstFree
        for i = 1, #cards do
            if not occupied[i] then
                firstFree = i
                break
            end
        end

        if not firstFree then
            if covered > bestCovered
                or (covered == bestCovered and #chosen < #bestMelds) then
                bestCovered = covered
                bestMelds = {}
                for i = 1, #chosen do
                    bestMelds[i] = chosen[i]
                end
            end
            return
        end

        -- Option: leave this card as deadwood.
        occupied[firstFree] = true
        search(covered)
        occupied[firstFree] = nil

        -- Option: use it in any compatible meld.
        for _, meld in ipairs(meldsForCard[firstFree]) do
            local available = true
            for _, id in ipairs(meld.ids) do
                if occupied[id] then
                    available = false
                    break
                end
            end

            if available then
                for _, id in ipairs(meld.ids) do
                    occupied[id] = true
                end
                chosen[#chosen + 1] = meld
                search(covered + #meld.ids)
                chosen[#chosen] = nil
                for _, id in ipairs(meld.ids) do
                    occupied[id] = nil
                end
            end
        end
    end

    search(0)

    local resultMelds = {}
    local inMeld = {}
    for i, meld in ipairs(bestMelds) do
        resultMelds[i] = {}
        for _, id in ipairs(meld.ids) do
            resultMelds[i][#resultMelds[i] + 1] = cards[id]
            inMeld[id] = true
        end
    end

    local deadwood = {}
    local deadwoodValue = 0
    for i, card in ipairs(cards) do
        if not inMeld[i] then
            deadwood[#deadwood + 1] = card
            deadwoodValue = deadwoodValue + card:value()
        end
    end

    return resultMelds, deadwood, deadwoodValue
end
