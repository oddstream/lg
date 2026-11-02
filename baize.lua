-- baize.lua

local Scene = require 'scene'
local Stock = require 'stock'
local Discard = require 'discard'
local Util = require 'util'

require 'colors'

local Baize = {}
Baize.__index = Baize
setmetatable(Baize, {__index = Scene})

function Baize.new()
    local o = Scene.new('baize')
	o.backgroundCanvas = nil
	o.stock = Stock.new()
	o.stock:setPosition()
	o.stock:fill()
	o.stock:shuffle()
	o.discard = Discard.new()
	o.discard:setPosition()
	return setmetatable(o, Baize)
end

function Baize:load()
	print "baize loaded"
end

function Baize:unload()
    print "baize unloaded"
	self.backgroundCanvas = nil
end

---@param key string
function Baize:keypressed(key)
    print("baize key pressed: " .. key)
	if key == 'escape' then
		love.event.quit(0)
	end
end

function Baize:resize(w, h)
	print("Baize resized to: " .. w .. "x" .. h)
	self.backgroundCanvas = nil
	self.stock:setPosition()
	self.discard:setPosition()
end

---@param dt_seconds number
function Baize:update(dt_seconds)
	local sources = {self.stock, self.discard}
	for _, src in ipairs(sources) do
		src:update(dt_seconds)
	end
end

function Baize:draw()
   	if self.backgroundCanvas == nil then
		self.backgroundCanvas = Util.createGradientCanvas(_G.COLORS.DarkGreen)
	end
	love.graphics.draw(self.backgroundCanvas, 0, 0)

	love.graphics.setColor(1, 1, 1, 1) -- reset drawing color

	love.graphics.print("press escape to quit",0,0)

	local sources = {self.stock, self.discard}
	for _, p in ipairs(sources) do
		p:draw()
	end
	for _, p in ipairs(sources) do
		for _, c in ipairs(p.cards) do
			if c:static() then
				c:draw()
			end
		end
	end
	for _, p in ipairs(sources) do
		for _, c in ipairs(p.cards) do
			if c:transitioning() then
				c:draw()
			end
		end
	end
	for _, p in ipairs(sources) do
		for _, c in ipairs(p.cards) do
			if c:flipping() then
				c:draw()
			end
		end
	end
	for _, p in ipairs(sources) do
		for _, c in ipairs(p.cards) do
			if c:dragging() then
				c:draw()
			end
		end
	end

end

return Baize
