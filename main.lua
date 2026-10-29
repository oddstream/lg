-- main.lua

local scenes = require 'scenes'
local scene_splash = require 'scene_splash'

-- instance of a Scenes object, holding stack of scenes, with the current scene at index 1
-- local to this file, but accessible to all scene files via the TransitionToScene() function below
local stage

local function tprint (tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2 
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "   
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end

function TransitionToScene(scene)
	assert(scene and type(scene) == "table" and type(scene.name) == "string", "Invalid scene object")
	print("Transitioning to scene: " .. scene.name)
	stage:push(scene)
end

---@param args table
function love.load(args)
	math.randomseed(os.time())

	stage = scenes.new()

	TransitionToScene(scene_splash.new())
end

---@param key string
function love.keypressed(key)
	stage:keypressed(key)
end

function love.resize(w, h)
	stage:resize(w, h)
end

---@param dt_seconds number
function love.update(dt_seconds)
	stage:update(dt_seconds)
end

function love.draw()
	stage:draw()
end
