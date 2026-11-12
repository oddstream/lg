-- settings

-- DefaultRatio = 1.444
-- BridgeRatio  = 1.561
-- PokerRatio   = 1.39

_G.SETTINGS = {
    debug = true,

    cardHeight = 200,
    cardWidth = 200 / 1.444,
    cardRatioPortrait = 1.444,
    cardRoundness = 200 / 10,
    cardRadius = 200 / 1.444 / 10,    -- cardWidth / 10

    aniSpeed = 0.75,

    botName = 'GinBot',
    humanName = 'Gilbert',

    meldColors = {
        [1] = {0.5, 1, 1, 1},
        [2] = {1, 0.5, 1, 1},
        [3] = {1, 1, 0.5, 1},
        [4] = {0.5, 1, 0.5, 1},
    },
}

_G.SETTINGS.Calculate = function()
    -- set the card size to allow 12 cards to fit across the width of the window
    -- hand is 10 + 1 so 12 will leave margins
	local ww, wh, _ = love.window.getMode()
    -- _G.SETTINGS.cardHeight = wh / 4
    -- _G.SETTINGS.cardWidth = _G.SETTINGS.cardHeight / _G.SETTINGS.cardRatioPortrait
    _G.SETTINGS.cardWidth = ww / 10
    _G.SETTINGS.cardHeight = _G.SETTINGS.cardWidth * _G.SETTINGS.cardRatioPortrait
    _G.SETTINGS.cardRoundness = _G.SETTINGS.cardWidth / 10
    _G.SETTINGS.cardRadius = _G.SETTINGS.cardWidth / _G.SETTINGS.cardRatioPortrait / _G.SETTINGS.cardRoundness
end
