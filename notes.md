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
Mini displays for melds and deadwood (see https://www.gin-rummy-online.com/)

full card 40 wide, 54 high
mini card  7 wide,  9 high
... mini cards approx 1/6 size of full cards
... ordinal centered in top third, suit centered in bottom two thirds

### Card movement
Stock card can be dragged to the human hand (when allowed by FSM, transition back if not) (flip)
Discard card can be dragged to the human hand (when allowed by FSM, transition back if not)
Human hand card can only be dragged (a) left and right, or (b) up to the discard pile (when allowed by FSM, transition back if not)

-- when starting dragging, remove card from table
-- when dragging is over, either return card to source table, or insert it into target table
-- check mouseTapped (because mouseReleased happens afterwards, at present)

No baize dragging, no card spinning, YAGNI

## LAYERS

A practical set of layers:

LÖVE / platform layer — callbacks, keyboard and mouse events, graphics, audio, filesystem.

Input and UI layer — turns clicks into intent, such as “play this card” or “end turn”; handles hit-testing and menus.

Game rules layer — validates moves and applies effects: whose turn it is, what can be played, scoring, win/loss conditions. Keep this independent of love.graphics.

Game state layer — the current match data: deck, hands, discard pile, turn, score, and status.

Presentation layer — draws the state: card faces, piles, highlights, animations, and text.

Data and persistence layer — card definitions, images and sounds, settings, and saved progress.

## ROBOTO/GINBOT/ROB

## FSM

A finite state machine (FSM) for Gin Rummy models the game as a series of discrete states that track whose turn it is and whether the round is active or ending. The machine transitions based on player actions—such as drawing and discarding—and rule checks regarding the value of unmatched cards in a hand.

1. The Deal state initializes the game by distributing ten cards to each player and flipping the first card of the stock pile to start the discard pile. Once the setup is complete, the machine transitions to the Draw state for the starting player.
2. The Draw state occurs when the current player must acquire a card. The player chooses between the top card of the stock pile or the top card of the discard pile. After the card is added to the hand, the machine transitions to the Discard state.
3. The Discard state requires the player to select one card from their hand to place on the discard pile. After the discard is finalized, the machine transitions to the Knock Check state.
4. The Knock Check state evaluates the player's deadwood (the total value of cards not part of a meld). If the deadwood is zero, the machine transitions to the Gin state; if the deadwood is 10 or less, it transitions to the Knock state; otherwise, it transitions back to the Draw state for the opposing player.
5. The Showdown state is triggered by a knock or a gin. Both players reveal their hands, and the machine processes the lay-off phase, where the opponent may add their own deadwood cards to the knocker's melds (provided the knocker did not go gin).
6. The Scoring state calculates the points based on the remaining deadwood and any bonuses for gin or undercutting. The machine then checks the total game score; if the game limit is reached, it transitions to the Terminal state, otherwise it returns to the Deal state for a new round.

# TECH
.luarc.json changed from 5.4 to 5.1 (since LÖVE uses LuaJIT), because:

"The warning occurs because Love2D uses LuaJIT (based on Lua 5.1), where unpack is a global function, but your code editor or LSP is configured for Lua 5.2+ or Lua 5.4, where unpack was moved to table.unpack and the global name is deprecated or removed."

"Configure your LSP: Update your editor (e.g., VS Code, Neovim) to specify Lua 5.1 or LuaJIT as the language version in your workspace settings. This will stop the deprecation warning since unpack is valid global syntax in Lua 5.1."

https://zed.dev/docs/languages/lua?highlight=love#love2d
