-- stock.lua

local Pile = require 'pile'
local Card = require 'card'

---@class (exact) Stock: Pile
---@field __index Stock
---@field x integer
---@field y integer
---@field new function
---@field SetPosition function
---@

local Stock = {}
Stock.__index = Stock
setmetatable(Stock, {__index = Pile})

function Stock.new()
    local o = {x=0, y=0, cards={}}
    local ords = {1,2,3,4,5,6,7,8,9,10,11,12,13}
    local suits = {'♣','♦','♥','♠'}
    setmetatable(o, Stock)
    for _, ord in ipairs(ords) do
        for _, suit in ipairs(suits) do
            Pile.push(o, Card.new({ord=ord, suit=suit, prone=true}))
            -- card owner is assigned in Pile.push
        end
    end

    return o
end

function Stock:SetPosition()
	local width, height, _ = love.window.getMode()
    self.x = (width / 2) - (_G.SETTINGS.cardWidth / 2)
    self.y = (height / 2) - (_G.SETTINGS.cardHeight / 2)

    self.x = self.x - (_G.SETTINGS.cardWidth * 0.75)
end

-- draw is handled by Pile

return Stock
