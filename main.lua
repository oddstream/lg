-- main.lua

require 'settings'
require 'cardfactory'

local scenes = require 'scenes'
local splash = require 'splash'

---@type love.Canvas[]
_G.cardFaceTextures = {}

---@type love.Canvas
_G.cardBackTexture = {}

---@type love.Canvas
_G.cardShadowTexture = {}

---@type string[]
_G.ORD2STRING = {'A','2','3','4','5','6','7','8','9','10','J','Q','K'}

---@type string
_G.ORD_FONT = 'assets/fonts/Acme-Regular.ttf'

---@type string
_G.SUIT_FONT = 'assets/fonts/DejaVuSans.ttf'

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

 	_G.SETTINGS.Calculate()
  _G.cardFaceTextures, _G.cardBackTexture, _G.cardShadowTexture = cardTextureFactory(_G.SETTINGS.cardWidth, _G.SETTINGS.cardHeight, _G.SETTINGS.cardRadius)
  assert(_G.cardFaceTextures)
  assert(type(_G.cardFaceTextures) == 'table')
  assert(_G.cardFaceTextures[string.format('%02u%s', 1, '♠')])
	TransitionToScene(splash.new())
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function love.mousepressed(x, y, button, istouch, presses)
	stage:mousePressed(x, y, button, istouch, presses)
end

---@param x number
---@param y number
---@param dx number
---@param dy number
---@param istouch boolean
function love.mousemoved(x, y, dx, dy, istouch)
	stage:mouseMoved(x, y, dx, dy, istouch)
end

---@param x number
---@param y number
---@param button number
---@param istouch boolean
---@param presses number
function love.mousereleased(x, y, button, istouch, presses)
	stage:mouseReleased(x, y, button, istouch, presses)
end

---@param key string
function love.keypressed(key)
	stage:keyPressed(key)
end

function love.resize(w, h)
  _G.SETTINGS.Calculate()
  _G.cardFaceTextures, _G.cardBackTexture, _G.cardShadowTexture = cardTextureFactory(_G.SETTINGS.cardWidth, _G.SETTINGS.cardHeight, _G.SETTINGS.cardRadius)
  stage:resize(w, h)
end

---@param dt_seconds number
function love.update(dt_seconds)
	stage:update(dt_seconds)
end

function love.draw()
	stage:draw()
end
