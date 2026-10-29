-- scene_splash.lua

require 'colors'

local Util = require 'util'

local Scene = require 'scene'
local scene_menu = require 'scene_menu'

local Splash = {}
Splash.__index = Splash
setmetatable(Splash, {__index = Scene})

function Splash.new()
	local o = Scene.new('splash')
	o.logo = nil
	o.elapsed = 0.0	-- seconds since scene started
	o.hold = 0.5	-- nothing happens for this many seconds, then fade out starts
	o.fade = 1.5	-- fade out over this many seconds
	o.alpha = 1.0
	o.backgroundCanvas = nil
	return setmetatable(o, Splash)
end

function Splash:load()
	print 'splash loaded'
	self.logo = love.graphics.newImage('assets/love_icon_512x512.png')
end

function Splash:unload()
	print 'splash unloaded'
	self.logo = nil
	self.backgroundCanvas = nil
end

---@param key string
function Splash:keypressed(key)
    print('Splash key pressed: ' .. key)
	TransitionToScene(scene_menu.new())
end

function Splash:resize(w, h)
	print("Splash resized to: " .. w .. "x" .. h)
	self.backgroundCanvas = nil
end

function Splash:draw()
	-- use color picked from the logo image for the gradient background
	-- https://imagecolorpicker.com/
	local logoBlue = {39, 170, 225}
	-- create gradient canvas here so that it is recreated on resize
	if self.backgroundCanvas == nil then
		self.backgroundCanvas = Util.createGradientCanvas(logoBlue)
	end
	love.math.colorFromBytes(unpack(logoBlue))
	love.graphics.draw(self.backgroundCanvas, 0, 0)

	love.graphics.setColor(1, 1, 1, self.alpha)
	love.graphics.draw(self.logo,
		love.graphics.getWidth()/2 - self.logo:getWidth()/2,
		love.graphics.getHeight()/2 - self.logo:getHeight()/2)
	love.graphics.setColor(1, 1, 1, 1) -- reset drawing color
end

---@param dt number
function Splash:update(dt)
	self.elapsed = self.elapsed + dt
	if self.elapsed > self.hold then
		self.alpha = math.max(0, 1 - (self.elapsed - self.hold) / self.fade)
	end
	if self.alpha <= 0.0 then
		TransitionToScene(scene_menu.new())
	end
end

return Splash
