-- card

local Util = require 'util'

---@class (exact) Card
---@field suit '♣'|'♦'|'♥'|'♠'
---@field ord number 1 ... 13
---@field textureId string created by string.format('%02u%s', ord, suit)
---@field x integer
---@field y integer
---@field prone boolean
---@field flipWidth number
---@field flipDirection number
---@field owner Pile|Fan
---@field new function
---@field transitionTo function

local Card = {
}
Card.__index = Card

function Card:__tostring()
	return self.textureId
end

function Card.new(o)
	assert(type(o)=='table')
	assert(type(o.suit)=='string')
	assert(type(o.ord)=='number')
	assert(type(o.prone)=='boolean')

	-- fictional start point off top of screen
	o.x = 512
	o.y = -128

	o.textureId = Util.cardTextureId(o.ord, o.suit)	-- used as index/key into Card Texture Library

	-- cards have to flip faster than they transition
	-- remember that flipping happens in two steps
	-- so three times faster would do, but four times faster seems snappier
	o.flipWidth = 1.0	-- lerps from 1.0 to 0.0 (then from 0.0 to 1.0)
	o.flipDirection = 0	-- -1 narrower, 0 static, +1 wider

    return setmetatable(o, Card)
end

---@param x number
---@param y number
function Card:setPosition(x, y)
	self.x = x
	self.y = y
	self:stopTransition()
end

---@return number
---@return number
function Card:getPosition()
	return self.x, self.y
end

---@return number
---@return number
---@return number
---@return number
function Card:getRect()
	return self.x, self.y, _G.SETTINGS.cardWidth, _G.SETTINGS.cardHeight
end

---@return number
---@return number
---@return number
---@return number
function Card:getStaticRect()
	if self:dragging() then
		return self.dragStart.x, self.dragStart.y, _G.SETTINGS.cardWidth, _G.SETTINGS.cardHeight
	else
		return self.x, self.y, _G.SETTINGS.cardWidth, _G.SETTINGS.cardHeight
	end
end

function Card:_startFlip()
	self.flipWidth = 1.0
	self.flipDirection = -1	-- start by making card narrower
	self.flipStartTime = love.timer.getTime()
end

function Card:flipUp()
	if self.prone then
		self.prone = false
		self:_startFlip()
	end
end

function Card:flipDown()
	if not self.prone then
		self.prone = true
		self:_startFlip()
	end
end

function Card:flip()
	if self.prone then
		self:flipUp()
	else
		self:flipDown()
	end
end

---@return boolean
function Card:flipping()
	return self.flipDirection ~= 0.0
end

---@return boolean
function Card:static()
	return self.dst == nil or self.dragStart == nil or self.flipDirection == 0.0
end

---@return boolean
function Card:transitioning()
	return self.dst ~= nil
end

---@return boolean
function Card:nearEnough()
	return math.abs(self.x - self.dst.x) < 1.0 and math.abs(self.y - self.dst.y) < 1.0
	-- return self.x == self.dst.x and self.y == self.dst.y
end

function Card:stopTransition()
	self.src = nil
	self.dst = nil
end

---@param x number
---@param y number
function Card:transitionTo(x, y)
    -- print(self.x, self.y, 'to', x, y)
	if self.x == x and self.y == y then
		self:setPosition(x, y)
		return
	end

	if self.dst then
		if self:nearEnough() then
			self:setPosition(x, y)
			return	-- repeat request
		end
	end

	self.src = {x = self.x, y = self.y}
	self.dst = {x = x, y = y}

	self.lerpStartTime = love.timer.getTime()
end

---@return boolean
function Card:dragging()
	return self.dragStart ~= nil
end

function Card:startDrag()
	if self:transitioning() then
		self.dragStart = self.dst
		self:stopTransition()
	else
		self.dragStart = {x=self.x, y=self.y}
	end
end

---@param dx number
---@param dy number
function Card:dragBy(dx, dy)
	self:setPosition(self.dragStart.x + dx, self.dragStart.y + dy)
end

function Card:cancelDrag()
	self:transitionTo(self.dragStart.x, self.dragStart.y)
	self.dragStart = nil
end

function Card:stopDrag()
	self.dragStart = nil
end

---@return boolean
function Card:wasDragged()
	if self.dragStart then
		if self.dragStart.x ~= self.x or self.dragStart.y ~= self.y then
			return true
		end
	end
	return false
end

---@param dt_seconds number
function Card:update(dt_seconds)

	if self:transitioning() then
		if not self:nearEnough() then
			-- Calculate the fraction of the total duration that has passed
			local t = (love.timer.getTime() - self.lerpStartTime) / _G.SETTINGS.aniSpeed
			self.x = Util.smoothstep(self.src.x, self.dst.x, t)
			self.y = Util.smoothstep(self.src.y, self.dst.y, t)
			-- local rate = 10.0	-- too low gives settling flicker
			-- https://www.gamedeveloper.com/programming/improved-lerp-smoothing-
			-- value = lerp(target, value, exp2(-rate*deltaTime))
			-- exp2(x) is 2 ^ x
			-- ... rate controls how quickly the value converges on the target.
			-- With a rate of 1.0, the value will move halfway to the target each second.
			-- If you double the rate, the value will move in twice as fast.
			-- If you halve the rate, it will move in half as fast.
			--
			-- Even better, it’s frame rate independent.
			-- If you lerp() this way 60 times with a delta time of 1/60 s,
			-- it will be the same result as 30 times with 1/30 s, or once with 1 s.
			-- No fixed time step is needed, or the jittery movement it causes.
			-- self.x = Util.lerp(self.dst.x, self.x, math.pow(2, -rate * dt_seconds))
			-- self.y = Util.lerp(self.dst.y, self.y, math.pow(2, -rate * dt_seconds))
		else
			-- we have arrived at our destination
			-- make sure card is in proper place
			-- and terminate any transition
			self:setPosition(self.dst.x, self.dst.y)	-- also stops lerping
		end
	end

	if self:flipping() then
		-- Calculate the fraction of the total duration that has passed
		local t = (love.timer.getTime() - self.flipStartTime) / (_G.SETTINGS.aniSpeed / 3)
		if self.flipDirection < 0 then
			self.flipWidth = Util.lerp(1.0, 0.0, t)
			if self.flipWidth <= 0.0 then
				-- reverse direction, make card bigger
				self.flipDirection = 1
				self.flipStartTime = love.timer.getTime()
			end
		elseif self.flipDirection > 0 then
			self.flipWidth = Util.lerp(0.0, 1.0, t)
			if self.flipWidth >= 1.0 then
				-- finished
				self.flipDirection = 0
			end
		end
	end
end

function Card:draw()
	local x, y = self:getPosition()

	-- very important!: reset color before drawing to canvas to have colors properly displayed
	-- see discussion here: https://love2d.org/forums/viewtopic.php?f=4&p=211418#p211418
	love.graphics.setColor(1,1,1,1)

	local img
	if self.flipDirection < 0.0 then
		if self.prone then
			-- card is getting narrower, and it's going to show face down, but show face up
			img = _G.cardFaceTextures[self.textureId]
		else
			-- card is getting narrower, and it's going to show face up, but show face down
			img = _G..cardBackTexture
		end
	else
		if self.prone then
			img = _G.cardBackTexture
		else
			img = _G.cardFaceTextures[self.textureId]
		end
	end

	if self:flipping() then
		local cw = _G.SETTINGS.cardWidth
		local scw = cw / self.flipWidth
		love.graphics.draw(img, x, y,
			0,
			self.flipWidth, 1.0,
			(cw - scw) / 2, 0)
	elseif self:transitioning() then
		local xoffset, yoffset = 1, 1
		love.graphics.draw(_G.cardShadowTexture, x + xoffset, y + yoffset)
		love.graphics.draw(img, x, y)
	elseif self:dragging() then
		local xoffset, yoffset = 2, 2
		-- local xoffset = b.cardWidth / 66
		-- local yoffset = b.cardHeight / 66
		love.graphics.draw(_G.cardShadowTexture, x + xoffset, y + yoffset)
		-- this looks intuitively better than "lifting" the card with offset * 2
		-- even though "lifting" it (moving it up/left towards the light source) would be more "correct"
		x = x - xoffset / 2
		y = y - yoffset / 2
		-- love.graphics.setColor(1, 0.95, 1, 1)
		love.graphics.draw(img, x, y)
		-- love.graphics.setColor(1,1,1,1)
	else
		love.graphics.draw(img, x, y)
	end
end

return Card
