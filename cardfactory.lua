-- cardfactory

local Util = require 'util'

local log = require 'log'

local pipInfo = {
	--[[ 1 ]] {},
	--[[ 2 ]] {
		{x=0.5, y=0.166},
		{x=0.5, y=0.833},
	},
	--[[ 3 ]] {
		{x=0.5, y=0.166},
		{x=0.5, y=0.5},
		{x=0.5, y=0.833},
	},
	--[[ 4 ]] {
		{x=0.375, y=0.166},	{x=0.625, y=0.166},
		{x=0.375, y=0.833},	{x=0.625, y=0.833},
	},
	--[[ 5 ]] {
		{x=0.375, y=0.166},	{x=0.625, y=0.166},
		{x=0.5, y=0.5},
		{x=0.375, y=0.833},	{x=0.625, y=0.833},
	},
	--[[ 6 ]] {
		{x=0.375, y=0.166},	{x=0.625, y=0.166},
		{x=0.375, y=0.5},	{x=0.625, y=0.5},
		{x=0.375, y=0.833},	{x=0.625, y=0.833},
	},
	--[[ 7 ]] {
		{x=0.375, y=0.166},	{x=0.625, y=0.166},
		{x=0.5, y=0.333},
		{x=0.375, y=0.5},	{x=0.625, y=0.5},
		{x=0.375, y=0.833},	{x=0.625, y=0.833},
	},
	--[[ 8 ]] {
		{x=0.375, y=0.166},	{x=0.625, y=0.166},
		{x=0.5, y=0.333},
		{x=0.375, y=0.5},	{x=0.625, y=0.5},
		{x=0.5, y=0.666},
		{x=0.375, y=0.833},	{x=0.625, y=0.833},
	},
	--[[ 9 ]] {
		{x=0.375, y=0.166}, {x=0.625, y=0.166},
		{x=0.375, y=0.4}, {x=0.625, y=0.4},
		{x=0.5, y=0.5, scale=0.75},
		{x=0.375, y=0.6}, {x=0.625, y=0.6},
		{x=0.375, y=0.833}, {x=0.625, y=0.833},
	},
	--[[ 10 ]] {
	--[[
		X X
		 X
		X X
		X X
		 X
		X X
	--]]
		{x=0.375, y=0.166}, {x=0.625, y=0.166},
		{x=0.5, y=0.285, scale=0.75},
		{x=0.375, y=0.4}, {x=0.625, y=0.4},
		{x=0.375, y=0.6}, {x=0.625, y=0.6},
		{x=0.5, y=0.715, scale=0.75},
		{x=0.375, y=0.833}, {x=0.625, y=0.833},

	--[[
		 X
		X X
		X X
		X X
		X X
		 X
		{x=0.5, y=0.166},
		{x=0.375, y=0.3}, {x=0.625, y=0.3},
		{x=0.2, y=0.45}, {x=0.8, y=0.45},
		{x=0.2, y=0.6}, {x=0.8, y=0.6},
		{x=0.375, y=0.75}, {x=0.625, y=0.75},
		{x=0.5, y=0.833},
	]]
	},
	--[[ 11 ]] {},
	--[[ 12 ]] {},
	--[[ 13 ]] {},
}

---@param suit string
---@return table (of three rgb numbers)
local function getSuitColor(suit)
	-- returns {r, g, b} table that can be passed to love.graphics.setColor
	-- after unpacking and passing through getColorFromBytes
    if suit == '♦' or suit == '♥' then
        return _G.COLORS['Crimson']
    else
        return _G.COLORS['Black']
    end
end

---@param color string
---@param amount number
---@return table
---@return table
local function getGradientColors(color, amount)
	amount = amount or 0.1
	local r, g, b, a = love.math.colorFromBytes(unpack(_G.COLORS[color]))
	local amt = amount + 1.0
	local frontColor = {r * amt, g * amt, b * amt, a}
	amt = 1.0 - amount
	local backColor = {r * amt, g * amt, b * amt, a}
	return frontColor, backColor
end

---@param cardFaceTexture love.Canvas
---@param ordFont love.Font
---@param suitFont love.Font
---@param suitFontSmall love.Font
---@param suitFontLarge love.Font
---@param width number
---@param height number
---@param ord number
---@param suit string
---@return love.Canvas
local function createRegularFace(cardFaceTexture, ordFont, suitFont, suitFontSmall, suitFontLarge, width, height, ord, suit)
	-- could/should be a function within factory

	local function printAt(str, rx, ry, font, angle)
		love.graphics.setFont(font)
		-- jaggies with scale at anything other than 1.0
		angle = angle or 0.0
		local ox = font:getWidth(str) / 2
		local oy = font:getHeight(str) / 2
		love.graphics.print(str,
			width * rx,
			height * ry,
			angle,
			1.0, 1.0,
			ox, oy)
	end

	local canvas = love.graphics.newCanvas(width, height)
	love.graphics.setCanvas({canvas, stencil=true})	-- direct drawing operations to the canvas

	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(cardFaceTexture)

	local suitRGB = getSuitColor(suit)

	-- every card gets an ord top left and bottom right (inverted)
	love.graphics.setColor(love.math.colorFromBytes(unpack(suitRGB)))
	printAt(_G.ORD2STRING[ord], 0.15, 0.15, ordFont)
	printAt(_G.ORD2STRING[ord], 0.85, 0.85, ordFont, math.pi)

	if ord > 1 and ord < 11 then
		-- cards 2 .. 10 get pips in the middle

		love.graphics.setColor(love.math.colorFromBytes(unpack(suitRGB)))
		local pips = pipInfo[ord]
		for _, pip in ipairs(pips) do
			local angle = 0.0
			if pip.y > 0.5 then
				angle = math.pi
			end
			if pip.scale and pip.scale < 1.0 then
				printAt(suit, pip.x, pip.y, suitFontSmall, angle)
			else
				printAt(suit, pip.x, pip.y, suitFont, angle)
			end
		end
	else
		-- Ace, Jack, Queen, King get suit runes at top right and bottom left
		-- so the suit can be seen when fanned
		-- they also get purdy rectangles in the middle

		love.graphics.setColor(0,0,0,0.05)
		love.graphics.rectangle('fill', width * 0.25, height * 0.25, width * 0.5, height * 0.5, width / 20, height / 20)

		love.graphics.setColor(love.math.colorFromBytes(unpack(suitRGB)))
		printAt(suit, 0.5, 0.5, suitFontLarge)

		printAt(suit, 0.85, 0.15, suitFont)
		printAt(suit, 0.15, 0.85, suitFont, math.pi)
	end

	love.graphics.setCanvas()	-- reset render target to the screen
	return canvas
end

---@param width number width of a card
---@param height number height of a card
---@param radius number
---@return love.Canvas[] table of canvases, indexed by an ord+suit key
---@return love.Canvas canvas card back, same for all cards
---@return love.Canvas canvas card shadow, same for all cards
function _G.cardTextureFactory(width, height, radius)
	assert(width and width ~= 0)
	assert(height and height ~= 0)

	-- turn off anti-aliasing to prevent fuzzy cards
	-- https://love2d.org/wiki/FilterMode
	love.graphics.setDefaultFilter('nearest', 'nearest', 1)

	local halfWidth = width / 2
	local halfHeight = height / 2

	local function drawCardRect()
		love.graphics.rectangle('fill', 0, 0, width, height, radius, radius)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0, 0, 0, 0.05)	-- cartoon outlines are black, so why not
        love.graphics.rectangle('line', 1, 1, width - 2, height - 2, radius, radius)
	end

	-- create fonts

	local ordFontSize = width / 3.5
	local ordFont = love.graphics.newFont(_G.ORD_FONT, ordFontSize)
	local ordFont10 = love.graphics.newFont(_G.ORD_FONT, ordFontSize * 0.8)

	local suitFontSize = width / 3.75
	local suitFont = love.graphics.newFont(_G.SUIT_FONT, suitFontSize)
	local suitFontSmall = love.graphics.newFont(_G.SUIT_FONT, suitFontSize * 0.8)
	local suitFontLarge = love.graphics.newFont(_G.SUIT_FONT, suitFontSize * 2)

	-- create textures

	local canvas

	-- blank card face

	canvas = love.graphics.newCanvas(width, height)
	love.graphics.setCanvas({canvas, stencil=true})	-- direct drawing operations to the canvas

    local frontColor, backColor = getGradientColors('Ivory', 0.06)
    love.gradient.draw(
        function()
            drawCardRect()
        end,
        'radial',
        halfWidth, halfHeight,
        halfWidth, halfHeight,
        backColor,
        frontColor
    )

	love.graphics.setCanvas()	-- reset render target to the screen
	local cardFaceTexture = canvas

	-- card back

	canvas = love.graphics.newCanvas(width, height)
	love.graphics.setCanvas({canvas, stencil=true})	-- direct drawing operations to the canvas

    frontColor, backColor = getGradientColors('CornflowerBlue', 0.09)
    love.gradient.draw(
        function()
            drawCardRect()
        end,
        'radial',
        halfWidth, halfHeight,
        halfWidth, halfHeight,
        backColor,
        frontColor
    )

    do  -- draw some fancy little pips in the middle of the card back
		local pipWidth = suitFont:getWidth('♠') * 0.8
		local pipHeight = suitFont:getHeight() * 0.8
		love.graphics.setFont(suitFont)
		love.graphics.setColor(0,0,0, 0.1)
		love.graphics.print('♦', width / 2, height / 2 - pipHeight)	-- top right
		love.graphics.print('♥', width / 2 - pipWidth, height / 2)	-- bottom left
		love.graphics.setColor(0,0,0, 0.2)
		love.graphics.print('♣', width / 2 - pipWidth, height / 2 - pipHeight)	-- top left
		love.graphics.print('♠', width / 2, height / 2)	-- bottom right
    end
  
	love.graphics.setCanvas()	-- reset render target to the screen
	local cardBackTexture = canvas

	-- card shadow

	canvas = love.graphics.newCanvas(width, height)
	love.graphics.setCanvas(canvas)	-- direct drawing operations to the canvas
	love.graphics.setLineWidth(1)
	love.graphics.setColor(love.math.colorFromBytes(0, 0, 0, 128))
	drawCardRect()
	love.graphics.setCanvas()	-- reset render target to the screen
	local cardShadowTexture = canvas

	--

	local cardFaceTextures = {}
	for _, ord in ipairs{1,2,3,4,5,6,7,8,9,10,11,12,13} do
		for _, suit in ipairs{'♣','♦','♥','♠'} do	-- club diamond heart spade; alpha order
			local key = Util.cardTextureId(ord, suit)
            if ord == 10 then
                cardFaceTextures[key] = createRegularFace(cardFaceTexture, ordFont10, suitFont, suitFontSmall, suitFontLarge, width, height, ord, suit)
            else
                cardFaceTextures[key] = createRegularFace(cardFaceTexture, ordFont, suitFont, suitFontSmall, suitFontLarge, width, height, ord, suit)
            end
		end
	end

	-- put FilterMode back to default otherwise toast text, pips are garbled
	-- https://love2d.org/wiki/FilterMode
	love.graphics.setDefaultFilter('linear', 'linear', 1)

	return cardFaceTextures, cardBackTexture, cardShadowTexture
end
