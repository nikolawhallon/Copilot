import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- from https://github.com/Whitebrim/AnimatedSprite
import "AnimatedSprite.lua"

-- these are the enemy types
import "alphas"
-- import "betas"
-- import "gammas"
-- import "deltas"

import "player"
import "bullets"

local gfx <const> = playdate.graphics
local gmtry <const> = playdate.geometry
gfx.setBackgroundColor(gfx.kColorBlack)

local gameOver = false
local score = 0

-- TODO: put in some "utils" or something
function outOfBounds(point)
	if point.x < 0 - 32 or point.x > 400 + 32 or point.y < 0 - 32 or point.y > 240 + 32 then
		return true
	end
	
	return false
end

function initGame()
	gameOver = false
	score = 0

	clearBullets()
	initAlphas() -- note this also clears any currently present alphas
	initPlayer()
end

function updateGame()
	gfx.clear()
	gfx.setLineWidth(1)
	gfx.setColor(playdate.graphics.kColorXOR)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		
	if gameOver then
		removeAllAlphaTimers()

		if playdate.buttonIsPressed( playdate.kButtonA ) and playdate.buttonIsPressed( playdate.kButtonB ) then		
			initGame()
		end

		drawBullets()
		drawAlphas()
		
		gfx.drawTextAligned("Game Over", 200, 120 - 16 - 4, kTextAlignment.center)
		gfx.drawTextAligned("Press A+B To Retry", 200, 120 + 4, kTextAlignment.center)
		gfx.drawTextAligned("Score: " .. tostring(score), 8, 8, kTextAlignment.left)

		return
	end
	
	-- update
	updatePlayer()
	updateBullets()
	updateAlphas()
	
	-- check for collisions
	for b = #bullets, 1, -1 do
		for a = #alphas, 1, -1 do
			-- TODO: occasionally something here is nil, why?
			-- also, Lua doesn't have "continue" sad face
			if alphas[a] == nil or bullets[b] == nil then
				break
			end
			
			if alphas[a].position:distanceToPoint(bullets[b].position) < alphas[a].radius + bullets[b].radius then
				alphas[a].bulletSpawnTimer:remove()
				table.remove(alphas, a)
				table.remove(bullets, b)
				score += 1
			end
		end
	end
	
	for b = #bullets, 1, -1 do
		if player.position:distanceToPoint(bullets[b].position) < player.radius + bullets[b].radius then
			gameOver = true
			table.remove(bullets, b)
		end
	end

	-- draw
	drawPlayer()
	drawBullets()
	drawAlphas()
	
	gfx.drawTextAligned("Score: " .. tostring(score), 8, 8, kTextAlignment.left)

	playdate.timer.updateTimers()
end
