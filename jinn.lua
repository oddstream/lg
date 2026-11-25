-- jinn.lua

-- for a singleton pattern in Lua 5.1,
-- a module is naturally singleton-like:
-- require caches the module’s returned value in package.loaded

local log = require 'log'
local poker = require 'poker'
local Card  = require 'card'

local roundHandSizes = {
	{bot=6, ape=8},	-- ape>8 overlaps the Play button
	{bot=7, ape=8},
	{bot=7, ape=8},
	{bot=8, ape=8},
	{bot=8, ape=7},
	{bot=9, ape=7},
	{bot=10, ape=7},
}

---@class (exact) Jinn
---@field __index Jinn
---@field __tostring function
---@field baize table
---@field state string 'setup'|'apeDraw'|'apeDiscard'|'botDraw'|'botDiscard'|'cashout'|'gameover'
---@field round integer
---@field botRoundsWon integer
---@field apeRoundsWon integer
---@field botScoreThisRound integer
---@field apeScoreThisRound integer
---@field new function
---@field isAllowed function
---@field notifyCardMove function
---@field notifyCardTapped function
---@field action function
---@field play function
local Jinn = {}
Jinn.__index = Jinn

---@return string
function Jinn:__tostring()
	return self.state
end

---@param baize Baize
---@return Jinn
function Jinn.new(baize)
	local o = {baize = baize, state = 'setup',
		round = 0,	-- first setup bumps this to 1
		botScoreThisRound = 0,
		apeScoreThisRound = 0,
		botRoundsWon = 0,
		apeRoundsWon = 0,
	}
	-- for the moment, the bot is always the dealer
	return setmetatable(o, Jinn)
end

function Jinn:botHandChanged()
	local hand, typeLabel, multLabel = self.baize.botHand, self.baize.botTypeLabel, self.baize.botMultLabel
	hand:sort()
	hand:fan()
	local arr = hand:createCopy('all')
	if #arr > 0 then
		hand.sel = poker.handTypeEx(arr)
		typeLabel.text = hand.sel.type
		multLabel.text = string.format('%d x %d', hand.sel.value, hand.sel.score)
	else
		hand.sel = nil
		typeLabel.text = '(no selection)'
		multLabel.text = '0 x 0'
	end
end

function Jinn:apeHandChanged()
	local hand, typeLabel, multLabel = self.baize.apeHand, self.baize.apeTypeLabel, self.baize.apeMultLabel
	hand:sort()
	hand:fan()
	local arr = hand:createCopy('selected')
	if #arr > 0 then
		hand.sel = poker.handTypeEx(arr)
		typeLabel.text = hand.sel.type
		multLabel.text = string.format('%d x %d', hand.sel.value, hand.sel.score)
	else
		hand.sel = nil
		typeLabel.text = '(no selection)'
		multLabel.text = '0 x 0'
	end
end

---@param card Card
---@param from Pile
---@param to Pile
---@return boolean
function Jinn:isAllowed(card, from, to)
	-- log.trace('isAllowed?', self.state, card, from, to)
	if (self.state == 'apeDraw')
		and (from == self.baize.stock or from == self.baize.discard)
		and (to == self.baize.apeHand)
		then return true
	end
	if (self.state == 'apeDiscard')
		and (from == self.baize.apeHand)
		and (to == self.baize.discard)
		then return true
	end
	log.warn('not allowed')
	return false
end

---@param card Card
---@param from Pile
---@param to Pile
function Jinn:notifyCardMove(card, from, to)
	-- log.trace('notifyCardMove', self.state, card, from, to)
	if self.state == 'apeDraw'
		and (from == self.baize.stock or from == self.baize.discard)
		and to == self.baize.apeHand
	then
		self:apeHandChanged()
		self.state = 'apeDiscard'
	end
	if self.state == 'apeDiscard'
		and from == self.baize.apeHand
		and to == self.baize.discard
	then
		self:apeHandChanged()
		self.state = 'botDraw'
	end
end

---@param card Card
function Jinn:notifyCardTapped(card)
	if card.owner == self.baize.apeHand then
		self:apeHandChanged()
	end
end

function Jinn:play()
	-- ape or bot has pressed the play button
	-- show bot cards and hand type
	-- goto cashout state
	assert(self.baize.botHand.sel)

	for _, c in ipairs(self.baize.botHand.cards) do
		c:flipUp()
	end

	-- select bot cards
	for _, c in ipairs(self.baize.botHand.cards) do
		c:unselect()
	end
	for _, cs in ipairs(self.baize.botHand.sel.cards) do
		-- find cs in bot cards
		for _, ch in pairs(self.baize.botHand.cards) do
			if cs.ord == ch.ord and cs.suit == ch.suit then
				ch:select()
			end
		end
	end
	-- refan to show selected bot cards
	self.baize.botHand:fan()

	-- show what type of hand the bot has
	self.baize.botTypeLabel.state = 'active'
	self.baize.botMultLabel.state = 'active'

	self.state = 'cashout'
end

---@param cards Card[]
---@return integer
local function valueTotal(cards)
	local n = 0
	for _, c in ipairs(cards) do
		-- these aren't real cards, so we can't use Card:value()
		-- n = n + math.min(c.ord, 10)
		n = n + _G.CARDVALUES[c.ord]
	end
	return n
end

function Jinn:cashout()

	-- player has pressed the cashout button
	self.baize.botTypeLabel.state = 'hidden'
	self.baize.botMultLabel.state = 'hidden'

	-- update score/coins
	assert(self.baize.botHand.sel)
	local botValue = valueTotal(self.baize.botHand.sel.cards)
	local botScore = self.baize.botHand.sel.score
	local apeScore = 0
	local apeValue = 0
	if self.baize.apeHand.sel then
		apeScore = self.baize.apeHand.sel.score
		apeValue = valueTotal(self.baize.apeHand.sel.cards)
	end

	-- TODO UI bling here
	if self.baize.apeHand.sel then
		if (botScore * botValue) > (apeScore * apeValue) then
			log.info('bot wins', self.baize.botHand.sel.type, 'better than', self.baize.apeHand.sel.type)
		elseif apeScore > botScore then
			log.info('ape wins', self.baize.apeHand.sel.type, 'better than', self.baize.botHand.sel.type)
		else
			log.info('draw')
		end
		log.trace('bot score', botValue * botScore, 'ape score', apeValue * apeScore)
	end

	self.botScoreThisRound = self.botScoreThisRound + botValue * botScore
	self.apeScoreThisRound = self.apeScoreThisRound + apeValue * apeScore
	self.baize.botScoreLabel.text = string.format('Bot %d', self.botScoreThisRound)
	self.baize.apeScoreLabel.text = string.format('Ape %d', self.apeScoreThisRound)

	-- move selected bot cards to stash
	local src = self.baize.botHand.cards
	for i = #src, 1, -1 do
		if src[i].selected then
			src[i]:unselect()
			local c = table.remove(src, i)
			self.baize.stash:push(c)
		end
	end
	-- hide remaining bot cards
	for _, c in ipairs(self.baize.botHand.cards) do
		c:flipDown()
	end
	-- refill bot hand from stock
	while #self.baize.stock.cards > 0 and #self.baize.botHand.cards < self.baize.botHand.size do
		self.baize.botHand:push(self.baize.stock:pop())
	end
	self:botHandChanged()

	-- move selected ape cards to stash
	src = self.baize.apeHand.cards
	for i = #src, 1, -1 do
		if src[i].selected then
			src[i]:unselect()
			local c = table.remove(src, i)
			self.baize.stash:push(c)
		end
	end
	-- refill ape hand from stock
	while #self.baize.stock.cards > 0 and #self.baize.apeHand.cards < self.baize.apeHand.size do
		self.baize.apeHand:push(self.baize.stock:pop())
	end
	self:apeHandChanged()

	-- log.trace('#stash', #self.baize.stash.cards)
	-- log.trace('#stock', #self.baize.stock.cards)

	-- goto setup state if stock is empty, otherwise goto apeDraw state
	if #self.baize.stock.cards > 0 then
		self.state = 'apeDraw'
	else
		if self.apeScoreThisRound > self.botScoreThisRound then
			self.apeRoundsWon = self.apeRoundsWon + 1
		elseif self.botScoreThisRound > self.apeScoreThisRound then
			self.botRoundsWon = self.botRoundsWon + 1
		end
		if #roundHandSizes == self.round then
			self.state = 'gameover'
		else
			self.state = 'setup'
		end
	end
end

function Jinn:action()

	-- log.info('Jinn action', self.state)
	if self.state == 'setup' then
		self.round = self.round + 1
		self.botScoreThisRound = 0
		self.apeScoreThisRound = 0
		self.baize.botHand.size = roundHandSizes[self.round].bot
		self.baize.apeHand.size = roundHandSizes[self.round].ape
		self.baize:deal()
		self:botHandChanged()
		self:apeHandChanged()
		
		self.baize.roundLabel.text = string.format('Round %d', self.round)
		self.baize.roundProgressLabel.text = string.format('Bot %d, Ape %d',
			self.botRoundsWon,
			self.apeRoundsWon
		)
		self.baize.botScoreLabel.text = string.format('Bot %d', self.botScoreThisRound)
		self.baize.apeScoreLabel.text = string.format('Ape %d', self.apeScoreThisRound)
		
		self.baize.botTypeLabel.state = 'hidden'
		self.baize.botMultLabel.state = 'hidden'

		self.baize.apeHand.sel = nil
		self.baize.playButton.state = 'disabled'
		self.baize.cashoutButton.state = 'hidden'
		self.state = 'apeDraw'
	elseif self.state == 'gameover' then
		log.info('game over')
		if self.botRoundsWon > self.apeRoundsWon then
			log.info('bot wins', self.botRoundsWon, ':', self.apeRoundsWon)
		elseif self.apeRoundsWon > self.botRoundsWon then
			log.info('ape wins', self.apeRoundsWon, ':', self.botRoundsWon)
		else
			log.info('game tied', self.apeRoundsWon, ':', self.botRoundsWon)
		end
		PopScene()	-- pop Baize to go back to Menu
	elseif self.state == 'apeDraw' then
		if self.baize.apeHand:numberSelected() > 0 then
			self.baize.playButton.state = 'active'
		else
			self.baize.playButton.state = 'disabled'
		end
		self.baize.cashoutButton.state = 'hidden'
	elseif self.state == 'apeDiscard' then
		self.baize.playButton.state = 'disabled'
		self.baize.cashoutButton.state = 'hidden'
		-- waiting for player to discard, do nothing
	elseif self.state == 'botDraw' then
		-- bot must play, or take a card from stock or discard
		-- cheat: if bot hand > ape hand, then play

		assert(self.baize.botHand.sel)
		local botScore = self.baize.botHand.sel.value * self.baize.botHand.sel.score
		
		-- ape may have nothing selected
		local arr = self.baize.apeHand:createCopy('all')
		local info = poker.handTypeEx(arr)
		local apeScore = info.value * info.score

		if botScore > apeScore then
			self:play()
		else
			-- move a card from stock or discard to botHand
			-- create a copy of hand, add peeked stock card, test (cheat)
			-- create a copy of hand, add peeked discard card, test
			-- use best source
			arr = self.baize.botHand:createCopy('all')
			local c = self.baize.stock:peek()
			if not c then
				log.warn('botDraw: Stock is empty')
			else
				table.insert(arr, {ord=c.ord, suit=c.suit})
				info = poker.handTypeEx(arr)
				local stockScore = info.value * info.score

				arr = self.baize.botHand:createCopy('all')
				c = self.baize.discard:peek()
				if not c then
					log.warn('botDraw: Discard is empty')
				else
					table.insert(arr, {ord=c.ord, suit=c.suit})
					info = poker.handTypeEx(arr)
					local discardScore = info.value * info.score

					if stockScore > discardScore then
						self.baize.botHand:push(self.baize.stock:pop())
					else
						self.baize.botHand:push(self.baize.discard:pop())
					end
					self:botHandChanged()
				end
			end
			self.state = 'botDiscard'
		end
	elseif self.state == 'botDiscard' then
		local arr = self.baize.botHand:createCopy('all')
		local info  = poker.handTypeEx(arr)
		local bestScore = info.value * info.score

		local discardIndex = 1
		for i = 1, #arr do
			local arr2 = {}
			for j = 1, #arr do
				if i ~= j then
					table.insert(arr2, arr[j])
				end
			end
			info = poker.handTypeEx(arr2)
			local score2 = info.value * info.score
			if score2 >= bestScore then
				discardIndex = i
				break
			end
		end
		assert(self.baize.botHand.cards[discardIndex])
		local c = self.baize.botHand:remove(discardIndex)
		self.baize.discard:push(c)
		self:botHandChanged()
		self.baize.playButton.state = 'disabled'
		self.baize.cashoutButton.state = 'hidden'
		self.state = 'apeDraw'
	elseif self.state == 'cashout' then
		self.baize.playButton.state = 'hidden'
		self.baize.cashoutButton.state = 'active'
	end

end

return Jinn
