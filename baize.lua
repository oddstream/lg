-- baize.lua

local log = require 'log'

local Scene = require 'scene'
local Stock = require 'stock'
local Discard = require 'discard'
local Hand = require 'hand'
local Util = require 'util'

require 'colors'

local Baize = {}
Baize.__index = Baize
setmetatable(Baize, {__index = Scene})

function Baize.new()
    local o = Scene.new('baize')
	setmetatable(o, Baize)

	o.backgroundCanvas = nil
	o.stock = Stock.new()
	o.stock:fill()
	o.stock:shuffle()

	o.discard = Discard.new()
	
	o.computerCards = Hand.new('computer')

	o.humanCards = Hand.new('human')

	o:deal()

	o:resize(love.graphics.getWidth(), love.graphics.getHeight())

	return o
end

function Baize:load()
	print "baize loaded"
end

function Baize:unload()
    print "baize unloaded"
	self.backgroundCanvas = nil
end

function Baize:deal()
	for i = 1, 10 do
		local c = self.stock:pop()
		if c then
			self.humanCards:push(c)
		end
	end
	for i = 1, 10 do
		local c = self.stock:pop()
		if c then
			self.computerCards:push(c)
		end
	end
end

---@param x number
---@param y number
---@return Card|nil
function Baize:findCardAt(x, y)
	local sources = {self.stock, self.discard, self.humanCards} -- not computerCards!

	for j = #sources, 1, -1 do
		local pile = sources[j]
		for i = #pile.cards, 1, -1 do
			local card = pile.cards[i]
			if Util.inRect(x, y, card:getRect()) then
				return card
			end
		end
	end
	return nil
end

---@param x number
---@param y number
---@return Pile|nil
function Baize:findPileAt(x, y)
	for _, pile in ipairs({self.humanCards, self.discard}) do
		if Util.inRect(x, y, pile:getRect()) then
			return pile
		end
	end
	return nil
end

---@param c Card
---@return Pile|nil
function Baize:largestIntersection(c)
	local largestArea = 0
	local pile
	local cx, cy, cw, ch = c:getRect()
	for _, p in ipairs({self.discard, self.humanCards}) do
		local px, py, pw, ph = p:getRect()
		local area = Util.overlapArea(cx, cy, cw, ch, px, py, pw, ph)
		if area > largestArea then
			largestArea = area
			pile = p
		end
	end
	return pile
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function Baize:mousePressed(x, y, button, istouch, presses)
	if self.stroke then
		log.warn('mousePressed', button, 'already a stroke')
		return
	end
	self.stroke = {
		init = {x=x, y=y},
	}
	local card = self:findCardAt(x, y)
	if card and not card:transitioning() then
		-- when we start dragging, we remove the card from it's pile
		local cidx = card.owner:indexOf(card)
		assert(cidx)
		table.remove(card.owner.cards, cidx)
		self.stroke.object = card
		self.stroke.objectIdx = cidx	-- so we can put it back where we found it
		self.stroke.objectType = 'card'
		card:startDrag()
		love.mouse.setVisible(false)
		log.info('mousePressed', button, 'card', card.textureId, 'dragStart', card.dragStart.x, card.dragStart.y)
	else
		log.info('mousePressed', button, 'no static card at', x, y)
	end
end

---@param x number
---@param y number
---@param dx number
---@param dy number
---@param istouch boolean
function Baize:mouseMoved(x, y, dx, dy, istouch)
	-- dx, dy The amount moved along the x- and y-axis since the last time love.mousemoved was called.
	if not self.stroke then
		return
	end
	local dx2, dy2 = x - self.stroke.init.x, y - self.stroke.init.y
	if self.stroke.objectType == 'card' then
		local card = self.stroke.object
		card:dragBy(dx2, dy2)
	end
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function Baize:mouseReleased(x, y, button, istouch, presses)
	if not self.stroke then
		return
	end
	love.mouse.setVisible(true)
	if self.stroke.objectType == 'card' then
		local card = self.stroke.object
		if card:wasDragged() then
			log.info('mouseReleased', button, 'card', card.textureId, 'dragged to', card.x, card.y)
		else
			log.info('mouseReleased', button, 'card', card.textureId, 'not dragged')
		end
		card:stopDrag()
		if math.abs(self.stroke.init.x - x) < 4 and math.abs(self.stroke.init.y - y) < 4 then
			self:mouseTapped(x, y, button)	-- stroke is still valid, so we can call mouseTapped
		else
			-- see if card is from stock pile and is now over human hand
			-- see if card is from discard pile and is now over human hand
			-- (cannot move from anywhere to stock)
			-- see if card is from human hand and is now over discard pile
			-- see if card is from human hand and is now over human hand (reorder)
			local dst = self:largestIntersection(card)
			if not dst then
				table.insert(card.owner.cards, self.stroke.objectIdx, card)  -- put the card back in its pile
				card.owner:fan()
			else
				card.owner:cardDragged(card, dst)
			end
		end
		-- Hand piles will have .playerName field
	end
	self.stroke = nil
end

---@param x number
---@param y number
---@param button number
function Baize:mouseTapped(x, y, button)
	if self.stroke.objectType == 'card' then
		local c = self.stroke.object
		log.info('mouseTapped', button, 'card', c.textureId, 'at', c.x, c.y)
		-- tapping on stock or discard signals human wants to move card to their hand
		-- tapping on player hand signals human wants to move card to discard (cannot move to stock)
		table.insert(c.owner.cards, self.stroke.objectIdx, c)
		c.owner:fan()
	end
end

---@param key string
function Baize:keyPressed(key)
    print("baize key pressed: " .. key)
	if key == 'escape' then
		love.event.quit(0)
	elseif key == 's' then
		self.humanCards:sort()
	end
end

function Baize:resize(w, h)
	print("Baize resized to: " .. w .. "x" .. h)
	self.backgroundCanvas = nil
	for _, p in ipairs({self.stock, self.discard, self.computerCards, self.humanCards}) do
		p:setPosition()
		p:fan()
	end
end

---@param dt_seconds number
function Baize:update(dt_seconds)
	local sources = {self.stock, self.discard, self.computerCards, self.humanCards}
	for _, src in ipairs(sources) do
		src:update(dt_seconds)
	end
	if self.stroke and self.stroke.objectType == 'card' then
		local card = self.stroke.object
		card:update(dt_seconds)
	end
end

function Baize:draw()
   	if self.backgroundCanvas == nil then
		self.backgroundCanvas = Util.createGradientCanvas(_G.COLORS.DarkGreen)
	end
	love.graphics.draw(self.backgroundCanvas, 0, 0)

	local sources = {self.stock, self.discard, self.computerCards, self.humanCards}

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

	if self.stroke and self.stroke.objectType == 'card' then
		local card = self.stroke.object
		card:draw()
	end
end

return Baize
