import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- from https://github.com/Whitebrim/AnimatedSprite
import "AnimatedSprite.lua"

-- constants
local gfx <const> = playdate.graphics
gfx.setBackgroundColor(gfx.kColorBlack)

function initGame()

end

initGame()

function playdate.update()

	local crankChange, crankAcceleratedChange = playdate.getCrankChange()
		
	gfx.clear()
	
	gfx.setLineWidth(20)
	gfx.setColor(playdate.graphics.kColorXOR)
	gfx.drawLine(0, 0, 400, 240)
	
	playdate.timer.updateTimers()
end
