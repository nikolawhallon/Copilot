import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- from https://github.com/Whitebrim/AnimatedSprite
import "AnimatedSprite.lua"

-- pseudo-enum for game state
MENU = 0
GAME = 1

STATE = MENU

import "game"
import "menu"

local gfx <const> = playdate.graphics
local gmtry <const> = playdate.geometry
gfx.setBackgroundColor(gfx.kColorBlack)

function playdate.update()
	if STATE == MENU then
		local state_change = updateMenu()
		if state_change ~= nil and state_change == GAME then
			initGame()
			STATE = GAME
		end
	elseif STATE == GAME then
		updateGame()
	end
end
