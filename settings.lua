-- settings

-- DefaultRatio = 1.444
-- BridgeRatio  = 1.561
-- PokerRatio   = 1.39

_G.SETTINGS = {
    cardHeight = 200,
    cardWidth = 200 / 1.444,
    cardRatioPortrait = 1.444,
    cardRoundness = 200 / 10,
    cardRadius = 200 / 1.444 / 10,    -- cardWidth / 10

    aniSpeed = 0.5
}

_G.SETTINGS.Calculate = function()
	local _, wh, _ = love.window.getMode()
    _G.SETTINGS.cardHeight = wh / 4
    _G.SETTINGS.cardWidth = _G.SETTINGS.cardHeight / _G.SETTINGS.cardRatioPortrait
    _G.SETTINGS.cardRoundness = _G.SETTINGS.cardWidth / 10
    _G.SETTINGS.cardRadius = _G.SETTINGS.cardWidth / _G.SETTINGS.cardRatioPortrait / _G.SETTINGS.cardRoundness
end
