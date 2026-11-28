-- baize.lua

local log = require 'log'

local Button = require 'ui_button'
local Label = require 'ui_label'
local Scene = require 'scene'
local Pile = require 'pile'
local Stock = require 'stock'
local Discard = require 'discard'
local Hand = require 'hand'
local Card = require 'card'
local Util = require 'util'
local Jinn = require 'jinn'

require 'colors'

---@class (exact) Rect
---@field x number
---@field y number
---@field width number
---@field height number

---@class (exact) Baize
---@field __index Baize
---@field __tostring function
---@field uiRect Rect
---@field cardRect Rect
---@field stroke table
---@field labels Label[]
---@field buttons Button[]
---@field playButton Widget
---@field cashoutButton Widget
---@field new function
---@field load function
---@field unload function
---@field deal function
---@field findCardAt function
---@field findPileAt function
---@field findWidgetAt function
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
---@field apeHand Hand

local Baize = {}
Baize.__index = Baize
setmetatable(Baize, {__index = Scene})

function Baize.new()
	local o = Scene.new('baize')

	o.backgroundCanvas = nil
	o.stock = Stock.new()
	o.stock:fill()
	log.info('Baize.new() created', #o.stock.cards, 'cards')
	o.discard = Discard.new()

	o.botHand = Hand.new(Card.flipDown)
	o.apeHand = Hand.new(Card.flipUp)

	o.allPiles = { o.stock, o.discard, o.botHand, o.apeHand }

	o.buttons = {}
	if love.system.getOS() == 'Android' then
		o.quitButton = Button.new({
			state = 'active',
			text = 'X',
			radiusFactor = 4,
			backColor = 'CornflowerBlue',
			foreColor = 'Ivory',
			fn = function() PopScene() end,
		})
		table.insert(o.buttons, o.quitButton)
	end
	o.playButton = Button.new({
		state = 'disabled',
		text = 'Play',
		radiusFactor = 2,
		backColor = 'CornflowerBlue',
		foreColor = 'Ivory',
		fn = function() o.jinn:play() end,
    })
	table.insert(o.buttons, o.playButton)

	o.cashoutButton = Button.new({
		state = 'disabled',
		text = 'Cash Out',
		radiusFactor = 2,
		backColor = 'Gold',
		foreColor = 'Black',
		fn = function() o.jinn:cashout() end,
    })
	table.insert(o.buttons, o.cashoutButton)

	-- [ Round 7 ]
	-- [ Bot Score ]
	-- [ Bot Hand Type ]
	-- [ Bot 12 x 10 ]
	-- [ Ape Score ]
	-- [ Ape Hand Type ]
	-- [ Ape 7 x 2 ]

	o.roundLabel = Label.new({
		backColor = 'Black',
		foreColor = 'Ivory',
		state = 'active',
	})
	o.roundProgressLabel = Label.new({
		backColor = 'Black',
		foreColor = 'Ivory',
		state = 'active',
	})

	o.handLabel = Label.new({
		backColor = 'DarkGreen',
		foreColor = 'Ivory',
		state = 'active',
	})

	o.botScoreLabel = Label.new({
		-- backColor = 'DarkGreen',
		foreColor = 'CornflowerBlue',
		state = 'active',
	})
	o.botTypeLabel = Label.new({
		-- backColor = 'DarkGreen',
		foreColor = 'CornflowerBlue',
		state = 'active',
	})
	o.botMultLabel = Label.new({
		-- backColor = 'DarkGreen',
		foreColor = 'CornflowerBlue',
		state = 'active',
	})

	o.apeScoreLabel = Label.new({
		-- backColor = 'DarkGreen',
		foreColor = 'Ivory',
		state = 'active',
	})
	o.apeTypeLabel = Label.new({
		-- backColor = 'DarkGreen',
		foreColor = 'Ivory',
		state = 'active',
	})
	o.apeMultLabel = Label.new({
		-- backColor = 'DarkGreen',
		foreColor = 'Ivory',
		state = 'active',
	})
	o.labels = {
        o.roundLabel, o.roundProgressLabel,
		o.handLabel,
		o.botScoreLabel,o.botTypeLabel,o.botMultLabel,
		o.apeScoreLabel,o.apeTypeLabel,o.apeMultLabel
	}

	setmetatable(o, Baize)

	o:resize(love.graphics.getWidth(), love.graphics.getHeight())

	o.elapsed = 10.0	-- count down Jinn action; start high to get going immediately
	o.jinn = Jinn.new(o)

	return o
end

function Baize:load()
	-- print "baize loaded"
end

function Baize:unload()
	-- print "baize unloaded"
	self.backgroundCanvas = nil
end

function Baize:deal()
	-- recall all cards from all piles (not stock)
	for _, p in ipairs({self.botHand, self.discard, self.apeHand}) do
		while #p.cards > 0 do
			self.stock:push(p:pop())
		end
	end
	-- log.info(#self.stock.cards, 'cards in stock')
	-- shuffle stock
	self.stock:shuffle()
	-- deal
	for _ = 1, self.botHand.size do
		self.botHand:push(self.stock:pop())
	end
	for _ = 1, self.apeHand.size do
		self.apeHand:push(self.stock:pop())
	end
	self.discard:push(self.stock:pop())

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
	if #self.apeHand.cards > 0 then
		for i = #self.apeHand.cards, 1, -1 do
			local card = self.apeHand.cards[i]
			if not Card.isCard(card) then
				log.error('Not a card at index', i, 'of', self.apeHand)
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
	for _, pile in ipairs({self.apeHand, self.discard}) do
		if Util.inRect(x, y, pile:getRect()) then
			return pile
		end
	end
	return nil
end

---@param x number
---@param y number
---@return Widget|Button|nil
function Baize:findWidgetAt(x, y)
	for _, b in ipairs(self.buttons) do
		if b:isPointOver(x, y) then
			return b
		end
	end
	return nil
end

---@param c Card|Widget|Label|Button
---@return Pile|nil
function Baize:largestIntersection(c)
	local largestArea = 0
	local pile
	local cx, cy, cw, ch = c:getRect()
	for _, p in ipairs({self.discard, self.apeHand}) do
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
	if button == 2 then
		self.stroke = {init = {x = x, y = y}}
		love.mouse.setVisible(false)
		return
	end
	local card = self:findCardAt(x, y)
	if card then
		if not card:static() then
			log.warn('mousePressed', card, 'is not static')
		end
		self.stroke = {
			init = {x = x, y = y},
			object = card,
			objectType = 'card',
		}
		card:startDrag()
		love.mouse.setVisible(false)
		-- log.info('mousePressed', 'card', 'dragStart', card.dragStart.x, card.dragStart.y)
	else
		local widget = self:findWidgetAt(x, y)
		if widget then
			-- log.info('widget mousePressed', widget.state)
			if widget.state == 'active' then
				self.stroke = {
					init = {x = x, y = y},
					object = widget,
					objectType = 'widget',
				}
				widget.state = 'pressed'
			else
				log.warn('widget is not active', widget.state)
			end
		end
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
	-- we don't drag buttons/widgets, so no action required
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
	if button == 2 then
		for _, c in ipairs(self.apeHand.cards) do
			c:unselect()
		end
		self.apeHand:fan()
		self.stroke = nil
		return
	end
	if self.stroke.objectType == 'card' then
		local card = self.stroke.object
		-- card:wasDragged allows the card to move a little when tapped
		if card:wasDragged() then
			-- log.info('mouseReleased', card, 'dragged to', card.x, card.y)
			local dst = self:largestIntersection(card)
			if not dst then
				-- dragging a hand card into nowhere - short cut for dragging to discard pile
				if self.jinn:isAllowed(card, card.owner, self.discard) then
					local from, to = card.owner, self.discard
					from:removeCard(card)
					to:push(card)
					card:stopDrag()
					self.jinn:notifyCardMove(card, from, to)
				else
					card:cancelDrag()
					card.owner:fan() -- animate dragged card back to owner
				end
			else
				-- log.info('drag', card, 'from', card.owner, 'to', dst)
				if card.owner == dst then
					card:stopDrag()
					card.owner:cardDragged(card)
				else -- dragging card to a different pile
					if self.jinn:isAllowed(card, card.owner, dst) then
						local from, to = card.owner, dst
						from:removeCard(card)
						dst:insertCard(card)
						card:stopDrag()
						self.jinn:notifyCardMove(card, from, to)
					else
						card:cancelDrag()
						card.owner:fan() -- animate dragged card back to owner
					end
				end
			end
		else -- card was not dragged, so we'll call that a tap
			-- log.info('mouseReleased', card, 'tapped (not dragged)')
			if card.owner == self.stock then
				if self.jinn:isAllowed(card, self.stock, self.apeHand) then
					card:stopDrag()
					self.stock:pop() -- .owner is now nil
					self.apeHand:push(card)
					self.jinn:notifyCardMove(card, self.stock, self.apeHand)
				else
					card:cancelDrag()
				end
			elseif card.owner == self.discard then
				if self.jinn:isAllowed(card, self.discard, self.apeHand) then
					card:stopDrag()
					self.discard:pop()
					self.apeHand:push(card)
					self.jinn:notifyCardMove(card, self.discard, self.apeHand)
				else
					card:cancelDrag()
				end
			elseif card.owner == self.apeHand then
				-- no longer tap to move card to discard; ape has to drag it (sorry)
                card:stopDrag()
				if self.jinn:canToggleSelect(card) then
					card:toggleSelect()
					self.jinn:notifyCardTapped(card)
				end
			else
				card:cancelDrag()
			end
		end
		assert(not card:dragging())
	elseif self.stroke.objectType == 'widget' then
		-- check mouse is still over button before triggering action
		local widget = self.stroke.object
		if widget:isPointOver(x, y) then
			if type(widget.fn) == 'function' then
				widget.fn()
			end
		end
		widget.state = 'active'
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
		-- tapping on stock, move top card to ape hand
		-- tapping on discard, move top card to ape hand
		-- tapping on ape hand, move card to discard pile
		c.owner:tapped(c)
	end
end
]]

---@param key string
function Baize:keyPressed(key)
	if key == 'escape' then
		PopScene()	-- pop Baize to go back to Menu
	elseif key == 'f' then
		for _, c in ipairs(self.botHand.cards) do
			c:flip()
		end
	end
end

---@param w number
---@param h number
function Baize:resize(w, h)
	-- log.info("Baize resized to: " .. w .. "x" .. h)
	self.backgroundCanvas = nil	-- regenerate this at next draw()

	self.uiRect = {x=0, y=0, width=w/6, height=h}
	self.cardRect = {x=self.uiRect.width, y=0, width=w-self.uiRect.width, height=h}
	_G.UI_FONT = love.graphics.newFont(_G.ORD_FONT, _G.SETTINGS.cardWidth / 4)

	for _, p in ipairs(self.allPiles) do
		p:resize(w, h)
		p:layout(self.cardRect)
		p:fan()
	end

	-- center the buttons on a vertical line 3/4 of a card width from the right margin of cardRect
	local x = self.cardRect.x + self.cardRect.width - _G.SETTINGS.cardWidth * 0.75
	if self.quitButton then
		-- quit button at the top right
		self.quitButton:resize(w, h)	-- recalc radius
		local gap = self.quitButton.radius / 2
		self.quitButton:setPosition(
			x,
			self.cardRect.y + self.quitButton.radius + gap
		)
	end
	-- play, cashout buttons sit at bottom of the screen/cardRect
	for _, b in ipairs({self.playButton, self.cashoutButton}) do
		b:resize(w, h)	-- recalc radius
		local gap = b.radius / 2
		b:setPosition(
			x,
			self.cardRect.y + self.cardRect.height - b.radius - gap
		)
	end
	-- labels stack vertically from the top of the uiRect
	local y = self.uiRect.y
	for _, l in ipairs(self.labels) do
		l:resize(w, h)	-- recalc width, height
		l:setPosition(self.uiRect.x, y)
		y = y + l.height
	end
end

---@return boolean
function Baize:allCardsStatic()
	-- experimental - wait for cards to stop animating
	for _, p in ipairs(self.allPiles) do
		for _, c in ipairs(p.cards) do
			if not c:static() then
				log.trace('...')
				return false
			end
		end
	end
	return true
end

---@param dt_seconds number
function Baize:update(dt_seconds)
	for _, src in ipairs(self.allPiles) do
		src:update(dt_seconds)
	end
	if self.stroke and self.stroke.objectType == 'card' then
		local card = self.stroke.object
		card:update(dt_seconds)
	end
	self.elapsed = self.elapsed + dt_seconds
	if self.elapsed > 1.0 and self:allCardsStatic() then
		self.jinn:action()
		self.elapsed = 0.0
	end

end

function Baize:draw()
	if self.backgroundCanvas == nil then
		self.backgroundCanvas = Util.createGradientCanvas(_G.COLORS.DarkGreen)
	end
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(self.backgroundCanvas, 0, 0)

	if self.cardRect then	-- may not have had a resize() yet
		Util.setColor('DarkGreen')
		love.graphics.setLineWidth(1)
		love.graphics.line(
			self.cardRect.x,
			self.cardRect.y,
			self.cardRect.x,
			self.cardRect.y + self.cardRect.height)
	end

	for _, p in ipairs(self.allPiles) do
		p:draw()
	end

	for _, p in ipairs(self.allPiles) do
		for _, c in ipairs(p.cards) do
			if c:static() then
				c:draw()
			end
		end
	end
	for _, p in ipairs(self.allPiles) do
		for _, c in ipairs(p.cards) do
			if c:transitioning() then
				c:draw()
			end
		end
	end
	for _, p in ipairs(self.allPiles) do
		for _, c in ipairs(p.cards) do
			if c:flipping() then
				c:draw()
			end
		end
	end
	for _, p in ipairs(self.allPiles) do
		for _, c in ipairs(p.cards) do
			if c:dragging() then
				c:draw()
			end
		end
	end

	for _, b in ipairs(self.buttons) do
		b:draw()
	end
	for _, l in ipairs(self.labels) do
		l:draw()
	end

--[[
	if _G.SETTINGS.debug then
		love.graphics.setFont(_G.UI_FONT)
		Util.setColor('Ivory')

		if self.botHand.sel and self.botHand.sel.type then
			local rx, ry, rw, rh = self.botHand:getRect()
			local gap = _G.SETTINGS.cardHeight / 3
			Util.printCentered(self.botHand.sel.type,
				rx, ry + rh + gap, rw, _G.UI_FONT:getLineHeight())
		end
		if self.apeHand.sel and self.apeHand.sel.cards and #self.apeHand.sel.cards > 0 then
			local rx, ry, rw, rh = self.apeHand:getRect()
			local gap = _G.SETTINGS.cardHeight / 3
			Util.printCentered(self.apeHand.sel.type,
				rx, ry - gap, rw, _G.UI_FONT:getLineHeight())
		end
		love.graphics.print(self.jinn.state, 0, 0)
	end
]]
end

return Baize
