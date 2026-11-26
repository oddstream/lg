-- settings

-- DefaultRatio = 1.444
-- BridgeRatio  = 1.561
-- PokerRatio   = 1.39

_G.SETTINGS = {
	debug = true,

	cardRatioPortrait = 1.39,
	cardHeight = 200,
	cardWidth = 200 / 1.39,
	cardRoundness = 200 / 10,
	cardRadius = 200 / 1.39 / 10,    -- cardWidth / 10

	aniSpeed = 0.75,

	cardColors = {
		-- ['♦'] = 'Crimson',
		['♦'] = 'Firebrick',
		['♥'] = 'Crimson',
		-- ['♣'] = 'Black',
		['♣'] = 'MidnightBlue',
		['♠'] = 'Black',
	}
}

_G.SETTINGS.resize = function(ww, wh)
	_G.SETTINGS.cardHeight = wh / 6
	_G.SETTINGS.cardWidth = _G.SETTINGS.cardHeight / _G.SETTINGS.cardRatioPortrait
	-- _G.SETTINGS.cardWidth = ww / 14
	-- _G.SETTINGS.cardHeight = _G.SETTINGS.cardWidth * _G.SETTINGS.cardRatioPortrait
	_G.SETTINGS.cardRoundness = _G.SETTINGS.cardWidth / 10
	_G.SETTINGS.cardRadius = _G.SETTINGS.cardWidth / _G.SETTINGS.cardRatioPortrait / _G.SETTINGS.cardRoundness
	_G.cardFaceTextures, _G.cardBackTexture, _G.cardShadowTexture = cardTextureFactory()
end
