-- menu.lua

local Util = require 'util'

local Scene = require 'scene'
local Button = require 'ui_button'
local Baize = require 'baize'

require 'colors'

local Menu = {}
Menu.__index = Menu
setmetatable(Menu, {__index = Scene})

function Menu.new()
	local o = Scene.new('menu')
	setmetatable(o, Menu)

	o.backgroundCanvas = nil
	o.playButton = Button.new({
		state = 'active',
		text = 'Play',
		radiusFactor = 2,
		backColor = 'CornflowerBlue',
		foreColor = 'Ivory',
		fn = function() TransitionToScene(Baize.new()) end
	})
		o.quitButton = Button.new({
		state = 'active',
		text = 'Quit',
		radiusFactor = 2,
		backColor = 'CornflowerBlue',
		foreColor = 'Ivory',
		fn = function() love.event.quit(0) end,
	})
	o.buttons = {o.playButton,o.quitButton}

	o:resize(love.graphics.getWidth(), love.graphics.getHeight())

	return o
end

function Menu:load()
	print 'menu loaded'
end

function Menu:unload()
	print 'menu unloaded'
	self.backgroundCanvas = nil
end

---@param key string
function Menu:keyPressed(key)
	if key == 'p' then
		self.playButton.fn()
	elseif key == 'q' or key == 'escape' then
		self.quitButton.fn()
	end
end

---@param x number
---@param y number
---@return Widget|Button|nil
function Menu:findWidgetAt(x, y)
	for _, b in ipairs(self.buttons) do
		if b:isPointOver(x, y) then
			return b
		end
	end
	return nil
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function Menu:mousePressed(x, y, button, istouch, presses)
	self.pressedButton = self:findWidgetAt(x,y)
	if self.pressedButton then
		self.pressedButton.state = 'pressed'
	end
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function Menu:mouseReleased(x, y, button, istouch, presses)
	if self.pressedButton then
		if self.pressedButton == self:findWidgetAt(x,y) then
			self.pressedButton.fn()
		end
		self.pressedButton.state = 'active'
		self.pressedButton = nil
	end
end

---@param w number
---@param h number
function Menu:resize(w, h)
	self.backgroundCanvas = nil
	_G.UI_FONT = love.graphics.newFont(_G.ORD_FONT, _G.SETTINGS.cardWidth / 4)
	local y = h / 2
	for _, b in ipairs(self.buttons) do
		b:resize(w, h)
		b:setPosition(w / 2, y)
		y = y + (b.radius * 2) + (b.radius / 2)
	end

end

function Menu:draw()
	-- create gradient canvas here so that it is recreated on resize
	if self.backgroundCanvas == nil then
		self.backgroundCanvas = Util.createGradientCanvas(_G.COLORS.MidnightBlue)
	end
	love.graphics.draw(self.backgroundCanvas, 0, 0)

	local ww, wh, _ = love.window.getMode()
	Util.setColor('Ivory')
	love.graphics.setFont(_G.UI_FONT)
	Util.printCentered('LÕVE Gin Poker', 0, 0, ww, wh/2)

	for _, b in ipairs(self.buttons) do
		b:draw()
	end
end

return Menu

