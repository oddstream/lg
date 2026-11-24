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
	apeName = 'Gilbert',

	cardColors = {
		['♦'] = 'Crimson',
		-- ['♦'] = 'DarkOrange',
		['♥'] = 'Crimson',
		['♣'] = 'Black',
		-- ['♣'] = 'DarkBlue',
		['♠'] = 'Black',
	}
}

_G.SETTINGS.resize = function(ww, wh)
	-- _G.SETTINGS.cardHeight = wh / 4
	-- _G.SETTINGS.cardWidth = _G.SETTINGS.cardHeight / _G.SETTINGS.cardRatioPortrait
	_G.SETTINGS.cardWidth = ww / 12
	_G.SETTINGS.cardHeight = _G.SETTINGS.cardWidth * _G.SETTINGS.cardRatioPortrait
	_G.SETTINGS.cardRoundness = _G.SETTINGS.cardWidth / 10
	_G.SETTINGS.cardRadius = _G.SETTINGS.cardWidth / _G.SETTINGS.cardRatioPortrait / _G.SETTINGS.cardRoundness
end
