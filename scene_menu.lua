-- scene_menu.lua

local Scene = require 'scene'

local Menu = {}
Menu.__index = Menu
setmetatable(Menu, {__index = Scene})

function Menu.new()
	local o = Scene.new("menu")
	return setmetatable(o, Menu)
end

function Menu:load()
	print "menu loaded"
end

function Menu:unload()
	print "menu unloaded"
end

---@param key string
function Menu:keypressed(key)
    print("menu key pressed: " .. key)
	if key == 'escape' then
		love.event.quit(0)
	end	
end

function Menu:draw()
	love.graphics.print("Menu - press escape to quit!",0,0)
end

return Menu
