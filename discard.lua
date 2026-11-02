-- discard.lua

local Pile = require 'pile'
local Card = require 'card'

---@class (exact) Discard: Pile
---@field __index Discard
---@field x integer
---@field y integer
---@field new function
---@field SetPosition function
---@

local Discard = {}
Discard.__index = Discard
setmetatable(Discard, {__index = Pile})

function Discard.new()
    local o = {x=0, y=0, cards={}}
    setmetatable(o, Discard)
    return o
end

function Discard:SetPosition()
	local width, height, _ = love.window.getMode()
    self.x = (width / 2) - (_G.SETTINGS.cardWidth / 2)
    self.y = (height / 2) - (_G.SETTINGS.cardHeight / 2)

    self.x = self.x + (_G.SETTINGS.cardWidth * 0.75)
end

-- draw is handled by Pile

return Discard
