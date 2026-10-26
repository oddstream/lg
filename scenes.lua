-- scenes.lua

---@class (exact) Scenes
---@field stack Scene[] list of scenes, with the current scene at index 1
---@field push function(scene:Scene)
---@field pop function()
---@field keypressed function(key:string)
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

---@param key string
function Scenes:keypressed(key)
    print("Scenes key pressed: " .. key)
    if self.stack[1] then
        self.stack[1]:keypressed(key)
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
