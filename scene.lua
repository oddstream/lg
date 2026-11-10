-- scene.lua
-- base class for scenes

---@class (exact) Scene
---@field name string
---@field new function(name:string):Scene
---@field load function()
---@field unload function()
---@field mousePressed function(x:number, y:number, istouch:boolean, presses:number)
---@field mouseMoved function(x:number, y:number, dx:number, dy:number, istouch:boolean)
---@field mouseReleased function(x:number, y:number, button:number, istouch:boolean, presses:number)
---@field keyPressed function(key:string)
---@field resize function(w:number, h:number)
---@field update function(dt_seconds:number)
---@field draw function()

local Scene = {}
Scene.__index = Scene

---@param name string
function Scene.new(name)
    local o = {}
    o.name = name
    return setmetatable(o, Scene)
end

function Scene:load()
    -- print("Scene " .. self.name .. " loaded")
    -- override in subclass
end

function Scene:unload()
    -- print("Scene " .. self.name .. " unloaded")
    -- override in subclass
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function Scene:mousePressed(x, y, button, istouch, presses)
    -- override in subclass
end

---@param x number
---@param y number
---@param dx number
---@param dy number
---@param istouch boolean
function Scene:mouseMoved(x, y, dx, dy, istouch)
    -- override in subclass
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function Scene:mouseReleased(x, y, button, istouch, presses)
    -- override in subclass
end

---@param key string
function Scene:keyPressed(key)
    print("Key pressed in scene " .. self.name .. ": " .. key)
    -- override in subclass
end

---@param w number
---@param h number
function Scene:resize(w, h)
    -- print("Scene " .. self.name .. " resized to: " .. w .. "x" .. h)
    -- override in subclass
end

---@param dt_seconds number
function Scene:update(dt_seconds)
    -- override in subclass
end

function Scene:draw()
    -- override in subclass
end

return Scene
