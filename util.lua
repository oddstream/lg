-- util.lua

require 'gradient'

local Util = {}

---@param A number
---@param B number
---@param v number
---@return number
function Util.smoothstep(A, B, v)
	-- see http://sol.gfxile.net/interpolation/
	if v > 1.0 then v = 1.0 end
	v = (v) * (v) * (3.0 - 2.0 * (v));
	return (B * v) + (A * (1.0 - v));
end

---@param A number
---@param B number
---@param v number
---@return number
function Util.smootherstep(A, B, v)
	-- see http://sol.gfxile.net/interpolation/
	if v > 1.0 then v = 1.0 end
	v = (v) * (v) * (v) * ((v)*((v) * 6.0 - 15.0) + 10.0);
	return (B * v) + (A * (1.0 - v));
end

---@param start number
---@param finish number
---@param factor number
---@return number
function Util.lerp(start, finish, factor)
	-- return start*(1-factor) + finish*factor
	-- Precise method, which guarantees start = finish when factor = 1.
	-- https://en.wikipedia.org/wiki/Linear_interpolation
	if factor > 1.0 then factor = 1.0 end
	return (1 - factor) * start + factor * finish;
end

---The opposite of lerp. Instead of a range and a factor, we give a range and a value to find out the factor.
---@param start number
---@param finish number
---@param value number
---@return number
function Util.normalize(start, finish, value)
	return (value - start) / (finish - start)
end

---Converts a value from the scale [fromMin, fromMax] to a value from the scale[toMin, toMax]. It’s just the normalize and lerp functions working together.
---@param value number
---@param fromMin number
---@param fromMax number
---@param toMin number
---@param toMax number
---@return number
function Util.mapValue(value, fromMin, fromMax, toMin, toMax)
	return Util.lerp(toMin, toMax, Util.normalize(fromMin, fromMax, value))
end

---@param value any
---@param min number
---@param max number
---@return number
function Util.clamp(value, min, max)
	return math.min(math.max(value, min), max)
end

---@param color table
---@return love.Canvas
function Util.createGradientCanvas(color)
	local ww, wh, _ = love.window.getMode()
	local ww2, wh2 = ww / 2, wh / 2

	local canvas = love.graphics.newCanvas(ww, wh)
	love.graphics.setCanvas({canvas, stencil=true})	-- direct drawing operations to the canvas

	local amount = 0.3333
	local r, g, b, a = love.math.colorFromBytes(unpack(color))
	local amt = 1.0 + amount
	local frontColor = {r * amt, g * amt, b * amt, a}
	amt = 1.0 - amount
	local backColor = {r * amt, g * amt, b * amt, a}

	love.gradient.draw(
		function()
			love.graphics.rectangle('fill', 0, 0, ww, wh)
		end,
		'radial',		-- gradient type
		ww2, wh2,		-- center of shape
		ww2, ww2,		-- width of shape
		backColor,		-- back color
		frontColor)		-- front color

	love.graphics.setCanvas()
	return canvas
end

return Util
