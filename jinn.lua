-- jinn.lua

-- for a singleton pattern in Lua 5.1,
-- a module is naturally singleton-like:
-- require caches the module’s returned value in package.loaded

local log = require 'log'

local poker = require 'poker with tie break'
local Card  = require 'card'

local roundHandSizes = {
	{bot=6, ape=9},
	{bot=7, ape=9},
	{bot=7, ape=8},
	{bot=7, ape=8},
	{bot=8, ape=7},
	{bot=8, ape=7},
	{bot=8, ape=7},
}

local maxHand = 5 -- maximum hands per round (experimental)

---@class (exact) Jinn
---@field __index Jinn
---@field __tostring function
---@field baize table
---@field state string 'setup'|'apePlayOrDraw'|'apeDiscard'|'botPlayOrDraw'|'botDiscard'|'cashout'|'gameover'
---@field round integer
---@field hand integer
---@field botRoundsWon integer
---@field apeRoundsWon integer
---@field botScoreThisRound integer
---@field apeScoreThisRound integer
---@field new function
---@field isAllowed function
---@field canToggleSelect function
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
	---@type Card[]
	local arr = hand:createCopy('all')
	if #arr > 0 then
		hand.sel = poker.handTypeEx(arr)
		typeLabel.text = hand.sel.type
		multLabel.text = string.format('%d x %d = %d', hand.sel.value, hand.sel.score, hand.sel.value * hand.sel.score)
	else
		hand.sel = nil
		typeLabel.text = '(no selection)'
		multLabel.text = '0 x 0 = 0'
	end
end

function Jinn:apeHandChanged()
	local hand, typeLabel, multLabel = self.baize.apeHand, self.baize.apeTypeLabel, self.baize.apeMultLabel
	hand:sort()
	hand:fan()
	---@type Card[]
	local arr = hand:createCopy('selected')
	if #arr > 0 then
		hand.sel = poker.handTypeEx(arr)
		typeLabel.text = hand.sel.type
		multLabel.text = string.format('%d x %d = %d', hand.sel.value, hand.sel.score, hand.sel.value * hand.sel.score)
	else
		hand.sel = nil
		typeLabel.text = '(no selection)'
		multLabel.text = '0 x 0 = 0'
	end
end

---@param card Card
---@param from Pile
---@param to Pile
---@return boolean
function Jinn:isAllowed(card, from, to)
	if (self.state == 'apePlayOrDraw')
		and (from == self.baize.stock or from == self.baize.discard)
		and (to == self.baize.apeHand)
		then return true
	end
	if (self.state == 'apeDiscard')
		and (from == self.baize.apeHand)
		and (to == self.baize.discard)
		then return true
	end
	return false
end

---@param card Card
---@return boolean
function Jinn:canToggleSelect(card)
	if not card.selected then
		local n = 0
		for _, c in ipairs(self.baize.apeHand.cards) do
			if c.selected then
				n = n + 1
			end
		end
		if n == 5 then
			return false
		end
	end
	if self.state == 'cashout' then
		return false
	end
	return true
end

---@param card Card
---@param from Pile
---@param to Pile
function Jinn:notifyCardMove(card, from, to)
	if self.state == 'apePlayOrDraw'
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
		self.state = 'botPlayOrDraw'
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
	local apeScore = 0
	local apeValue = 0
	if self.baize.apeHand.sel then
		apeScore = self.baize.apeHand.sel.score
		apeValue = valueTotal(self.baize.apeHand.sel.cards)
	end
	local botValue = valueTotal(self.baize.botHand.sel.cards)
	local botScore = self.baize.botHand.sel.score

	-- TODO UI bling here
	if self.baize.apeHand.sel then
		if (botScore * botValue) > (apeScore * apeValue) then
			log.info('bot wins hand')
		elseif apeScore > botScore then
			log.info('ape wins hand')
		else
			log.info('drawn hand')
		end
	end

	self.botScoreThisRound = self.botScoreThisRound + botValue * botScore
	self.apeScoreThisRound = self.apeScoreThisRound + apeValue * apeScore
	self.baize.botScoreLabel.text = string.format('Bot %d', self.botScoreThisRound)
	self.baize.apeScoreLabel.text = string.format('Ape %d', self.apeScoreThisRound)

	-- move selected bot cards to discard
	local src = self.baize.botHand.cards
	for i = #src, 1, -1 do
		if src[i].selected then
			src[i]:unselect()
			local c = table.remove(src, i)
			self.baize.discard:pushFront(c)
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

	-- move selected ape cards to discard
	src = self.baize.apeHand.cards
	for i = #src, 1, -1 do
		if src[i].selected then
			src[i]:unselect()
			local c = table.remove(src, i)
			self.baize.discard:pushFront(c)
		end
	end
	-- refill ape hand from stock
	while #self.baize.stock.cards > 0 and #self.baize.apeHand.cards < self.baize.apeHand.size do
		self.baize.apeHand:push(self.baize.stock:pop())
	end
	self:apeHandChanged()

	self.hand = self.hand + 1

	-- goto setup or gameover state if stock is empty, or maximum hands reached,
	-- otherwise goto botDraw/apeDraw state
	if self.hand <= maxHand and #self.baize.stock.cards > 0 then
		if self.hand % 2 == 0 then
			self.state = 'botPlayOrDraw'
		else
			self.state = 'apePlayOrDraw'
		end
	else
		-- TODO UI bling
		if self.apeScoreThisRound > self.botScoreThisRound then
			log.info('ape wins round')
			self.apeRoundsWon = self.apeRoundsWon + 1
		elseif self.botScoreThisRound > self.apeScoreThisRound then
			log.info('bot wins round')
			self.botRoundsWon = self.botRoundsWon + 1
		else
			log.info('round drawn')
		end
		if #roundHandSizes == self.round then
			self.state = 'gameover'
		else
			self.state = 'setup'
		end
	end
end

function Jinn:action()

	if self.state == 'setup' then
		self.round = self.round + 1
		self.hand = 1
		self.botScoreThisRound = 0
		self.apeScoreThisRound = 0
		self.baize.botHand.size = roundHandSizes[self.round].bot
		self.baize.apeHand.size = roundHandSizes[self.round].ape
		self.baize:deal()
		self:botHandChanged()
		self:apeHandChanged()

		self.baize.roundLabel.text = string.format('Round %d of %d', self.round, #roundHandSizes)
		self.baize.roundProgressLabel.text = string.format('Bot %d, Ape %d',
			self.botRoundsWon,
			self.apeRoundsWon
		)
		self.baize.botScoreLabel.text = string.format('Bot %d', self.botScoreThisRound)
		self.baize.apeScoreLabel.text = string.format('Ape %d', self.apeScoreThisRound)
		--
		self.baize.botTypeLabel.state = 'hidden'
		self.baize.botMultLabel.state = 'hidden'

		self.baize.apeHand.sel = nil
		self.baize.playButton.state = 'disabled'
		self.baize.cashoutButton.state = 'hidden'
		if self.hand % 2 == 0 then
			self.state = 'botPlayOrDraw'
		else
			self.state = 'apePlayOrDraw'
		end
	elseif self.state == 'gameover' then
		-- TODO UI bling
		if self.apeRoundsWon > self.botRoundsWon then
			log.info('ape wins game')
		elseif self.botRoundsWon > self.apeRoundsWon then
			log.info('bot wins game')
		else
			log.info('game drawn')
		end
		-- TODO UI bling
		PopScene()	-- pop Baize to go back to Menu
	elseif self.state == 'apePlayOrDraw' then
		self.baize.handLabel.text = string.format('Hand %d of %d', self.hand, maxHand)

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
	elseif self.state == 'botPlayOrDraw' then
		-- bot must play, or take a card from stock or discard
		-- cheat: if bot hand > ape hand, then play

		assert(self.baize.botHand.sel)
		local botScore = self.baize.botHand.sel.value * self.baize.botHand.sel.score

		-- ape may have nothing selected
		---@type Card[]
		local arr = self.baize.apeHand:createCopy('all')
		---@type PokerHandInfo
		local info = poker.handTypeEx(arr)
		---@type number
		local apeScore = info.value * info.score

		if botScore > apeScore then
			self:play()
		elseif #self.baize.stock.cards == 0 or #self.baize.discard.cards == 0 then
			-- if stock or discard empty, bot can't have a fair turn
			self.state = 'cashout'
		else
			-- move a card from stock or discard to botHand
			-- create a copy of hand, add peeked stock card, test (cheat)
			-- create a copy of hand, add peeked discard card, test
			-- use best source
			---@type Card[]
			arr = self.baize.botHand:createCopy('all')
			---@type Card
			local c = self.baize.stock:peek()
			if not c then
			else
				table.insert(arr, {ord=c.ord, suit=c.suit})
				info = poker.handTypeEx(arr)
				local stockScore = info.value * info.score

				arr = self.baize.botHand:createCopy('all')
				c = self.baize.discard:peek()
				if not c then
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
		---@type Card[]
		local arr = self.baize.botHand:createCopy('all')
		---@type PokerHandInfo
		local info  = poker.handTypeEx(arr)
		---@type number
		local bestScore = info.value * info.score

		---@type integer
		local discardIndex = 1
		for i = 1, #arr do
			---@type Card[]
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
		self.state = 'apePlayOrDraw'
	elseif self.state == 'cashout' then
		self.baize.playButton.state = 'hidden'
		self.baize.cashoutButton.state = 'active'
	end

end

return Jinn
