-- scenes.lua

---@class (exact) Scenes
---@field stack Scene[] list of scenes, with the current scene at index 1
---@field push function(scene:Scene)
---@field pop function()
---@field keyPressed function(key:string)
---@field update function(dt_seconds:number)
---@field draw function()
---@field quit function()

local Scenes = {}
Scenes.__index = Scenes

function Scenes.new()
    local o = {}
    o.stack = {}
    return setmetatable(o, Scenes)
end

---@param scene Scene
function Scenes:push(scene)
    assert(scene, "Cannot push nil scene")
    assert(type(scene) == "table" and type(scene.name) == "string", "Invalid scene object")
    print("Pushing scene: " .. scene.name)

    if self.stack[1] then
        self.stack[1]:unload()
    end
    table.insert(self.stack, 1, scene)
    self.stack[1]:load()
end

function Scenes:pop()
    print("Popping scene")
    if self.stack[1] then
        self.stack[1]:unload()
        table.remove(self.stack, 1)
    end
    if self.stack[1] then
        self.stack[1]:load()
    end
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function Scenes:mousePressed(x, y, button, istouch, presses)
    if self.stack[1] then
        self.stack[1]:mousePressed(x, y, button, istouch, presses)
    end
end

---@param x number
---@param y number
---@param dx number
---@param dy number
---@param istouch boolean
function Scenes:mouseMoved(x, y, dx, dy, istouch)
    if self.stack[1] then
        self.stack[1]:mouseMoved(x, y, dx, dy, istouch)
    end
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function Scenes:mouseReleased(x, y, button, istouch, presses)
    if self.stack[1] then
        self.stack[1]:mouseReleased(x, y, button, istouch, presses)
    end
end

---@param key string
function Scenes:keyPressed(key)
    print("Scenes key pressed: " .. key)
    if self.stack[1] then
        self.stack[1]:keyPressed(key)
    end
end

---@param w number
---@param h number
function Scenes:resize(w, h)
    print("Scenes resized to: " .. w .. "x" .. h)
    if self.stack[1] then
        self.stack[1]:resize(w, h)
    end
end

---@param dt_seconds number
function Scenes:update(dt_seconds)
    if self.stack[1] then
        self.stack[1]:update(dt_seconds)
    end
end

function Scenes:draw()
    if self.stack[1] then
        self.stack[1]:draw()
    end
end

function Scenes:quit()
	love.event.quit(0)
end

return Scenes
