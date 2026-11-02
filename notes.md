# WHAT
A regular pack of 52 cards
Folks don't want to learn new rules
Two-player games fit the screen better than 4-player

https://en.wikipedia.org/wiki/Gin_rummy
https://cardgames.io/ginrummy/
https://www.gin-rummy-online.com/

Cribbage
Noddy

# NEXT
Create a pack of cards, face down, in a stock pile in the middle of the screen
(pile is good for stock and discard, roboto and user's cards will need a 'fan')
(and minifans later for the melds/sets(flushes)/runs(straights))

No baize dragging, no card spinning, YAGNI

# TECH
.luarc.json changed from 5.4 to 5.1 (since LÖVE uses LuaJIT), because:

"The warning occurs because Love2D uses LuaJIT (based on Lua 5.1), where unpack is a global function, but your code editor or LSP is configured for Lua 5.2+ or Lua 5.4, where unpack was moved to table.unpack and the global name is deprecated or removed."

"Configure your LSP: Update your editor (e.g., VS Code, Neovim) to specify Lua 5.1 or LuaJIT as the language version in your workspace settings. This will stop the deprecation warning since unpack is valid global syntax in Lua 5.1."

https://zed.dev/docs/languages/lua?highlight=love#love2d
