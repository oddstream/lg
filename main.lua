-- main.lua

require 'settings'
local log = require 'log'
require 'cardfactory'

local scenes = require 'scenes'
local splash = require 'splash'

---@type love.Canvas[]
_G.cardFaceTextures = {}

---@type love.Canvas
_G.cardBackTexture = {}

---@type love.Canvas
_G.cardShadowTexture = {}

-- ♠ (Spade):	U+2660
-- ♣ (Club):	U+2663
-- ♥ (Heart):	U+2665
-- ♦ (Diamond):	U+2666
---@type string[]
_G.ALLSUITS = { '♣', '♦', '♥', '♠' }

---@type integer[]
_G.ALLORDS = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }

---@type string[]
_G.ORD2STRING = {'1','2','3','4','5','6','7','8','9','10','J','Q','K','A'}

---@type string
_G.ORD_FONT = 'assets/fonts/Acme-Regular.ttf'

---@type string
_G.SUIT_FONT = 'assets/fonts/DejaVuSans.ttf'

---@type love.Font
_G.uiFont = love.graphics.newFont(_G.ORD_FONT, _G.SETTINGS.cardWidth / 6)

-- instance of a Scenes object, holding stack of scenes, with the current scene at index 1
-- local to this file, but accessible to all scene files via the TransitionToScene() function below
local stage

function TransitionToScene(scene)
	assert(scene and type(scene) == "table" and type(scene.name) == "string", "Invalid scene object")
	-- print("Transitioning to scene: " .. scene.name)
	stage:push(scene)
end

---@param args table
function love.load(args)
	math.randomseed(os.time())

	stage = scenes.new()

	local ww, wh, _ = love.window.getMode()
	log.trace('load, initial window size', ww, wh)
	_G.SETTINGS.resize(ww, wh)
	_G.cardFaceTextures, _G.cardBackTexture, _G.cardShadowTexture = cardTextureFactory()
	assert(_G.cardFaceTextures)
	assert(type(_G.cardFaceTextures) == 'table')
	assert(_G.cardFaceTextures[string.format('%02u%s', 2, '♠')])
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
  _G.SETTINGS.resize(w, h)
  _G.cardFaceTextures, _G.cardBackTexture, _G.cardShadowTexture = cardTextureFactory()
  stage:resize(w, h)
end

---@param dt_seconds number
function love.update(dt_seconds)
	stage:update(dt_seconds)
end

function love.draw()
	stage:draw()
end
