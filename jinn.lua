-- jinn.lua

-- for a singleton pattern in Lua 5.1,
-- a module is naturally singleton-like:
-- require caches the module’s returned value in package.loaded

local log = require 'log'
local poker = require 'poker'
local Card  = require 'card'

---@class (exact) Jinn
---@field __index Jinn
---@field __tostring function
---@field baize table
---@field state string 'setup'|'humanDraw'|'humanDiscard'|'botDraw'|'botDiscard'|'cashout'
---@field round integer
---@field botCoin integer
---@field humanCoin integer
---@field new function
---@field isAllowed function
---@field notifyCardMove function
---@field notifyCardTapped function
---@field action function

local Jinn = {}
Jinn.__index = Jinn

---@return string
function Jinn:__tostring()
	return self.state
end

---@param baize Baize
---@return Jinn
function Jinn.new(baize)
	local o = {baize = baize, state = 'setup', round = 0, botCoin = 0, humanCoin = 0}
	-- for the moment, the bot is always the dealer
	return setmetatable(o, Jinn)
end

function Jinn:botHandChanged()
	self.baize.botHand:sort()
	self.baize.botHand:fan()
	-- un/comment this to always display bot hand type
	local arr = self.baize.botHand:createCopy('all')
	if #arr > 0 then
		local t, s, c = poker.handTypeEx(arr)
		self.baize.botHand.sel = {type=t, score=s, cards=c}
		log.trace('botHandChanged', self.baize.botHand.sel.type)
	else
		self.baize.botHand.sel = nil
		log.trace('botHandChanged - nil')
	end
end

function Jinn:humanHandChanged()
	self.baize.humanHand:sort()
	self.baize.humanHand:fan()
	local arr = self.baize.humanHand:createCopy('selected')
	if #arr > 0 then
		local t, s, c = poker.handTypeEx(arr)
		self.baize.humanHand.sel = {type=t, score=s, cards=c}
	else
		self.baize.humanHand.sel = nil
	end
end

---@param card Card
---@param from Pile
---@param to Pile
---@return boolean
function Jinn:isAllowed(card, from, to)
	-- log.trace('isAllowed?', self.state, card, from, to)
	if (self.state == 'humanDraw')
		and (from == self.baize.stock or from == self.baize.discard)
		and (to == self.baize.humanHand)
		then return true
	end
	if (self.state == 'humanDiscard')
		and (from == self.baize.humanHand)
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
	if self.state == 'humanDraw'
		and (from == self.baize.stock or from == self.baize.discard)
		and to == self.baize.humanHand
	then
		self:humanHandChanged()
		self.state = 'humanDiscard'
	end
	if self.state == 'humanDiscard'
		and from == self.baize.humanHand
		and to == self.baize.discard
	then
		self:humanHandChanged()
		self.state = 'botDraw'
	end
end

---@param card Card
function Jinn:notifyCardTapped(card)
	if card.owner == self.baize.humanHand then
		self:humanHandChanged()
	end
end

function Jinn:play()
	-- human or bot has pressed the play button
	-- show bot cards and hand type
	-- goto cashout state
	for _, c in ipairs(self.baize.botHand.cards) do
		c:flipUp()
	end
	assert(self.baize.botHand.sel)
	-- local arr = self.baize.botHand:createCopy('all')
	-- if #arr > 0 then
	-- 	local t,s,c = poker.handTypeEx(arr)
	-- 	self.baize.botHand.sel = { type=t, score=s, cards=c }
	-- else
	-- 	self.baize.botHand.sel = nil
	-- end

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

	local arr = self.baize.humanHand:createCopy('selected')
	if #arr > 0 then
   		local t,s,c = poker.handTypeEx(arr)
		self.baize.humanHand.sel = {type=t, score=s, cards=c}
	else
	   	self.baize.humanHand.sel = nil
	end

	self.state = 'cashout'
end

function Jinn:cashout()
	-- player has pressed the cashout button

	-- update score/coins
	assert(self.baize.botHand.sel)
	local botScore = self.baize.botHand.sel.score
	local humanScore = 0
	if self.baize.humanHand.sel then
		humanScore = self.baize.humanHand.sel.score
	end
	log.trace('bot score', botScore, 'human score', humanScore)
	if botScore > humanScore then
		-- log.info('bot wins', self.baize.botHand.sel.type, 'better than', self.baize.humanHand.sel.type)
		self.botCoin = self.botCoin + botScore
		self.baize.botScoreLabel.text = string.format('Bot $%d', self.botCoin)
	elseif humanScore > botScore then
		-- log.info('human wins', self.baize.humanHand.sel.type, 'better than', self.baize.botHand.sel.type)
		self.humanCoin = self.humanCoin + humanScore
		self.baize.humanScoreLabel.text = string.format('You $%d', self.humanCoin)
	else
		log.info('draw')
	end

	-- move bot selected cards to stash
	local src = self.baize.botHand.cards
	for i = #src, 1, -1 do
		src[i]:flipDown()
		if src[i].selected then
			src[i]:unselect()
			local c = table.remove(src, i)
			-- log.trace('remove bot card', i, c)
			self.baize.stash:push(c)
		end
	end
	-- refill bot hand from stock
	while #self.baize.stock.cards > 0 and #self.baize.botHand.cards < self.baize.botHand.size do
		self.baize.botHand:push(self.baize.stock:pop())
	end
	self:botHandChanged()

	-- move selected human cards to stash
	src = self.baize.humanHand.cards
	for i = #src, 1, -1 do
		if src[i].selected then
			src[i]:unselect()
			local c = table.remove(src, i)
			-- log.trace('remove human card', i, c)
			self.baize.stash:push(c)
		end
	end
	-- refill human hand from stock
	while #self.baize.stock.cards > 0 and #self.baize.humanHand.cards < self.baize.humanHand.size do
		self.baize.humanHand:push(self.baize.stock:pop())
	end
	self:humanHandChanged()

	-- log.trace('#stash', #self.baize.stash.cards)
	-- log.trace('#stock', #self.baize.stock.cards)

	-- goto setup state if stock is empty, otherwise goto humanDraw state
	if #self.baize.stock.cards > 0 then
		self.state = 'humanDraw'
	else
		self.state = 'setup'
	end
end

function Jinn:action()
	-- log.info('Jinn action', self.state)
	if self.state == 'setup' then
		self.round = self.round + 1
		self.baize:deal()
		self:botHandChanged()
		self:humanHandChanged()
		self.baize.roundLabel.text = string.format('Round %d', self.round)
		self.baize.botScoreLabel.text = string.format('Bot $%d', self.botCoin)
		self.baize.humanScoreLabel.text = string.format('You $%d', self.humanCoin)
		self.baize.humanHand.sel = nil
		self.baize.playButton.state = 'disabled'
		self.baize.cashoutButton.state = 'hidden'
		self.state = 'humanDraw'
	elseif self.state == 'humanDraw' then
		if self.baize.humanHand:numberSelected() > 0 then
			self.baize.playButton.state = 'active'
		else
			self.baize.playButton.state = 'disabled'
		end
		self.baize.cashoutButton.state = 'hidden'
	elseif self.state == 'humanDiscard' then
		self.baize.playButton.state = 'disabled'
		self.baize.cashoutButton.state = 'hidden'
		-- waiting for player to discard, do nothing
	elseif self.state == 'botDraw' then
		-- cheat: if bot hand > possible human hand, then play
		local arr = self.baize.humanHand:createCopy('all')
		local humanScore = poker.handScore[poker.handTypeEx(arr)].us
		arr = self.baize.botHand:createCopy('all')
		local botScore = poker.handScore[poker.handTypeEx(arr)].us
		log.trace('scores: bot:', botScore, 'human:', humanScore)
		if botScore > humanScore then
			self:play()
		else
			-- move a card from stock or discard to botHand
			-- create a copy of hand, add stock card, test
			-- create a copy of hand, add discard card, test
			-- use best source
			local arr = self.baize.botHand:createCopy('all')
			local c = self.baize.stock:peek()
			assert(c)
			table.insert(arr, {ord=c.ord, suit=c.suit})
			local stockScore = poker.handScore[poker.handTypeEx(arr)].us

			arr = self.baize.botHand:createCopy('all')
			c = self.baize.discard:peek()
			assert(c)
			table.insert(arr, {ord=c.ord, suit=c.suit})
			local discardScore = poker.handScore[poker.handTypeEx(arr)].us

			if stockScore > discardScore then
				self.baize.botHand:push(self.baize.stock:pop())
			else
				self.baize.botHand:push(self.baize.discard:pop())
			end
			self:botHandChanged()
			self.state = 'botDiscard'
		end
	elseif self.state == 'botDiscard' then
		local arr = self.baize.botHand:createCopy('all')
		local bestScore = poker.handScore[poker.handTypeEx(arr)].us
		local discardIndex = 1
		for i = 1, #arr do
			local arr2 = {}
			for j = 1, #arr do
				if i ~= j then
					table.insert(arr2, arr[j])
				end
			end
			local score2 = poker.handScore[poker.handTypeEx(arr2)].us
			-- discarding a card cannot make the hand score better
			-- so settle for not making it worse
			if score2 == bestScore then
				discardIndex = i
				break
			end
		end
		local c = self.baize.botHand:remove(discardIndex)
		self.baize.discard:push(c)
		self:botHandChanged()
		self.baize.playButton.state = 'disabled'
		self.baize.cashoutButton.state = 'hidden'
		self.state = 'humanDraw'
	elseif self.state == 'cashout' then
		self.baize.playButton.state = 'hidden'
		self.baize.cashoutButton.state = 'active'
		-- waiting for player to press cashout button, do nothing
	end

end

return Jinn
