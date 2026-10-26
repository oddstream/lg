-- scene_splash.lua

local Scene = require 'scene'
local scene_menu = require 'scene_menu'

local Splash = {}
Splash.__index = Splash
setmetatable(Splash, {__index = Scene})

function Splash.new()
	local o = Scene.new("splash")
	o.logo = love.graphics.newImage("assets/love_icon_512x512.png")
	o.seconds = 2.0
	return setmetatable(o, Splash)
end

function Splash:load()
	print "splash loaded"
end

function Splash:unload()
	print "splash unloaded"
end

---@param key string
function Splash:keypressed(key)
    print("Splash key pressed: " .. key)
	TransitionToScene(scene_menu.new())
end

function Splash:draw()
	love.graphics.draw(self.logo, love.graphics.getWidth()/2 - self.logo:getWidth()/2, love.graphics.getHeight()/2 - self.logo:getHeight()/2)
end

---@param dt number
function Splash:update(dt)
	self.seconds = self.seconds - dt
	if self.seconds <= 0 then
		TransitionToScene(scene_menu.new())
	end
end

return Splash
