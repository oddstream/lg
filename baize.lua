-- baize.lua

local log = require 'log'

local Scene = require 'scene'
local Stock = require 'stock'
local Discard = require 'discard'
local Hand = require 'hand'
local Card = require 'card'
local Util = require 'util'
local Jinn = require 'jinn'

require 'colors'

---@class (exact) Baize
---@field __index Baize
---@field __tostring function
---@field stroke table
---@field debugFont love.font
---@field new function
---@field load function
---@field unload function
---@field deal function
---@field findCardAt function
---@field findPileAt function
---@field largestIntersection function
---@field mousePressed function
---@field mouseMoved function
---@field mouseReleased function
---@field keyPressed function
---@field resize function
---@field update function
---@field draw function
---@field stock Stock
---@field discard Discard
---@field botHand Hand
---@field humanHand Hand

local Baize = {}
Baize.__index = Baize
setmetatable(Baize, {__index = Scene})

function Baize.new()
	local o = Scene.new('baize')

	o.backgroundCanvas = nil
	o.stock = Stock.new()
	o.stock:fill()
	o.stock:shuffle()
	o.stock:setPosition() -- otherwise it's at 0,0
	log.info('created', #o.stock.cards, 'cards')
	o.discard = Discard.new()

	o.botHand = Hand.new(_G.SETTINGS.botName)

	o.humanHand = Hand.new(_G.SETTINGS.humanName)

	o:resize(love.graphics.getWidth(), love.graphics.getHeight())

	o.elapsed = 0.0	-- count down Jinn action
	_G.Gin = Jinn.new(o)

	return setmetatable(o, Baize)
end

function Baize:load()
	print "baize loaded"
end

function Baize:unload()
	print "baize unloaded"
	self.backgroundCanvas = nil
end

function Baize:deal()
	-- The dealer deals ten cards to each player one at a time
	-- starting with their opponent, and then places the next card
	-- in the deck face up. This begins the discard pile. The face
	-- down pile is known as the stock pile.

	-- recall all cards from piles
	log.info(#self.stock.cards, 'cards in stock')
	for _, p in ipairs({self.botHand, self.discard, self.humanHand}) do
		log.info('recall', #p.cards, 'from', p)
		while #p.cards > 0 do
			self.stock:push(p:pop())
		end
	end
	log.info(#self.stock.cards, 'cards in stock')
	assert(#self.stock.cards==52)
	-- shuffle stock
	self.stock:shuffle()
	-- deal
	for i = 1, 10 do
		self.humanHand:push(self.stock:pop())
		self.botHand:push(self.stock:pop())
	end
	self.discard:push(self.stock:pop())
	assert(#self.stock.cards == 52 - 10 - 10 - 1)

	self:resize(love.graphics.getWidth(), love.graphics.getHeight())
end

---@param x number
---@param y number
---@return Card|nil
function Baize:findCardAt(x, y)
	-- only look at top card of stock and discard Piles
	if #self.stock.cards > 0 then
		local card = self.stock.cards[#self.stock.cards]
		if not Card.isCard(card) then
			log.error('Not a card at index', #self.stock.cards, 'of', self.stock)
			return nil
		end
		if Util.inRect(x, y, card:getRect()) then
			return card
		end
	end
	if #self.discard.cards > 0 then
		local card = self.discard.cards[#self.discard.cards]
		if not Card.isCard(card) then
			log.error('Not a card at index', #self.discard.cards, 'of', self.discard)
			return nil
		end
		if Util.inRect(x, y, card:getRect()) then
			return card
		end
	end
	if #self.humanHand.cards > 0 then
		for i = #self.humanHand.cards, 1, -1 do
			local card = self.humanHand.cards[i]
			if not Card.isCard(card) then
				log.error('Not a card at index', i, 'of', self.humanHand)
				return nil
			end
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
	for _, pile in ipairs({self.humanHand, self.discard}) do
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
	for _, p in ipairs({self.discard, self.humanHand}) do
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
	local card = self:findCardAt(x, y)
	if not card then
		log.info('mousePressed', 'no card at', x, y)
		return
	end
	if not card:static() then
		log.warn('mousePressed', card, 'is not static')
	end
	-- when we start dragging, we leave the card in it's owning pile
	self.stroke = {
		init = {x = x, y = y},
		object = card,
		objectType = 'card',
	}
	card:startDrag()
	love.mouse.setVisible(false)
	-- log.info('mousePressed', 'card', 'dragStart', card.dragStart.x, card.dragStart.y)
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
	-- do the card drag and tap moving logic at the Baize level
	-- because piles don't know about other piles
	if not self.stroke then
		return
	end
	love.mouse.setVisible(true)
	if self.stroke.objectType == 'card' then
		local card = self.stroke.object
        if card:wasDragged() then
            -- log.info('mouseReleased', card, 'dragged to', card.x, card.y)
            local dst = self:largestIntersection(card)
            if not dst then
                card:cancelDrag() -- animate card back to it's original position
                card.owner:fan()
            else
                log.info('drag', card, 'from', card.owner, 'to', dst)
                if card.owner == dst then
                    card:stopDrag()
                    card.owner:cardDragged(card)
                else -- dragging card to a different pile
                    if _G.Gin:isAllowed(card, card.owner, dst) then
                        local from, to = card.owner, dst
                        -- remove card from src pile (pile:pop() | table.remove() + fan())
                        from:removeCard(card)
                        -- insert card into dst pile (push() | table.insert())
                        dst:insertCard(card)
                        card:stopDrag()
                        _G.Gin:notifyCardMove(card, from, to)
                    else
                        card:cancelDrag()
                        card.owner:fan() -- animate dragged card back to owner
                    end
                end
            end
        else -- card was not dragged, so we'll call that a tap
            log.info('mouseReleased', card, 'tapped (not dragged)')
            if card.owner == self.stock then
                if _G.Gin:isAllowed(card, self.stock, self.humanHand) then
                    card:stopDrag()
                    self.stock:pop() -- .owner is now nil
                    self.humanHand:push(card)
                    _G.Gin:notifyCardMove(card, self.stock, self.humanHand)
                else
                    card:cancelDrag()
                end
            elseif card.owner == self.discard then
                if _G.Gin:isAllowed(card, self.discard, self.humanHand) then
                    card:stopDrag()
                    self.discard:pop()
                    self.humanHand:push(card)
                    _G.Gin:notifyCardMove(card, self.discard, self.humanHand)
                else
                    card:cancelDrag()
                end
            elseif card.owner == self.humanHand then
                if _G.Gin:isAllowed(card, self.humanHand, self.discard) then
                    card:stopDrag()
                    self.humanHand:removeCard(card)
                    self.discard:push(card)
                    _G.Gin:notifyCardMove(card, self.humanHand, self.discard)
                else
                    card:cancelDrag()
                end
            else
                card:cancelDrag()
            end
        end
		assert(not card:dragging())
	end
	self.stroke = nil
end

--[[
---@param x number
---@param y number
---@param button number
function Baize:mouseTapped(x, y, button)
	if self.stroke.objectType == 'card' then
		local c = self.stroke.object
		-- log.info('mouseTapped on', c, 'at', c.x, c.y)
		-- tapping on stock, move top card to human hand
		-- tapping on discard, move top card to human hand
		-- tapping on human hand, move card to discard pile
		c.owner:tapped(c)
	end
end
]]

---@param key string
function Baize:keyPressed(key)
	-- log.info("baize key pressed: " .. key)
	if key == 'escape' then
		love.event.quit(0)
	elseif key == 'd' then
		self:deal()
	elseif key == 's' then
		self.humanHand:sort()
	elseif key == 'p' then
		log.info(self.botHand, self.stock, self.discard, self.humanHand)
	end
end

---@param w number
---@param h number
function Baize:resize(w, h)
	-- log.info("Baize resized to: " .. w .. "x" .. h)
	self.backgroundCanvas = nil
	for _, p in ipairs({self.stock, self.discard, self.botHand, self.humanHand}) do
		p:setPosition()
		p:fan()
	end
	self.debugFont = nil
end

---@param dt_seconds number
function Baize:update(dt_seconds)
	local sources = {self.stock, self.discard, self.botHand, self.humanHand}
	for _, src in ipairs(sources) do
		src:update(dt_seconds)
	end
	if self.stroke and self.stroke.objectType == 'card' then
		local card = self.stroke.object
		card:update(dt_seconds)
	end
	self.elapsed = self.elapsed + dt_seconds
	if self.elapsed > 2.0 then
		_G.Gin:action()
		self.elapsed = 0.0
	end

end

function Baize:draw()
   	if self.backgroundCanvas == nil then
		self.backgroundCanvas = Util.createGradientCanvas(_G.COLORS.DarkGreen)
	end
	love.graphics.draw(self.backgroundCanvas, 0, 0)

	local sources = {self.stock, self.discard, self.botHand, self.humanHand}

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

	-- used to need this when card.owner was removed when dragging started
	-- if self.stroke and self.stroke.objectType == 'card' then
	-- 	local card = self.stroke.object
	-- 	card:draw()
	-- end

	if _G.SETTINGS.debug then
		if not self.debugFont then
			self.debugFont = love.graphics.newFont(_G.ORD_FONT, _G.SETTINGS.cardWidth / 4)
		end
		local w, h, _ = love.window.getMode()
		love.graphics.setFont(self.debugFont)
		love.graphics.print(_G.Gin.state,
			(w / 2) - self.debugFont:getWidth(_G.Gin.state) / 2,
			h - self.debugFont:getHeight())
	end
end

return Baize
