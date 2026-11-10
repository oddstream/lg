-- jinn.lua

local Jinn = {}
Jinn.__index = Jinn

function Jinn.new(baize)
    return setmetatable({baize=baize}, Jinn)
end

function Jinn:isAllowed()
    return true
end

return Jinn
