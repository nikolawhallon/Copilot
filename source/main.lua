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

-- constants
local gfx <const> = playdate.graphics
local gmtry <const> = playdate.geometry
gfx.setBackgroundColor(gfx.kColorBlack)

local gameOver = false

-- this global, as other modules need access to the player
player = {}
player.position = gmtry.point.new(200, 120)
player.radius = 8
player.turret_offset = 3
player.turret_radius = 1
player.turret_angle = 0

local playerSpeed = 3.0
local playerBoostSpeed = 6.0

local bullets = {}
local bulletRadius = 2
local bulletSpeed = 5.0

function drawPlayer()
	gfx.drawCircleAtPoint(player.position, player.radius)

	vector = gmtry.vector2D.newPolar(player.turret_offset, player.turret_angle)
	turret_position = player.position:offsetBy(vector:unpack())
	gfx.drawCircleAtPoint(turret_position, player.turret_offset)
end

function drawBullets()
	for index, bullet in pairs(bullets) do
		gfx.drawCircleAtPoint(bullet.position, bulletRadius)
	end
end

function spawnBullet(position, angle)
	bullet = {}
	bullet.position = gmtry.point.new(position:unpack())
	bullet.angle = angle
	
	-- offset the bullet so that it never collides with its source
	local delta = gmtry.vector2D.newPolar(1, bullet.angle)
	delta:normalize()
	delta:scale(16)
	bullet.position:offset(delta:unpack())

	if bullets[1] == nil then
		bullets[1] = bullet
	else
		table.insert(bullets, bullet)
	end
end

function outOfBounds(point)
	if point.x < 0 - 32 or point.x > 400 + 32 or point.y < 0 - 32 or point.y > 240 + 32 then
		return true
	end
	
	return false
end

function initGame()
	gameOver = false
	
	player.position = gmtry.point.new(200, 120)
	player.radius = 8
	player.turret_offset = 3
	player.turret_radius = 1
	player.turret_angle = 0

	for index = #bullets, 1, -1 do
		table.remove(bullets, index)
	end

	initAlphas()
end

initGame()

function playdate.update()
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
		
		gfx.drawTextAligned("Game Over", 200, 120 - 16, kTextAlignment.center)
		gfx.drawTextAligned("Press A+B To Retry", 200, 120, kTextAlignment.center)

		return
	end
	
	-- handle input
	local crankChange, crankAcceleratedChange = playdate.getCrankChange()

	if playdate.buttonJustPressed( playdate.kButtonA ) and not playdate.buttonIsPressed( playdate.kButtonB ) then		
		spawnBullet(player.position, player.turret_angle)
	end
	
	local dx = 0
	local dy = 0
	if playdate.buttonIsPressed( playdate.kButtonUp ) then
		dy = -1.0
	end
	if playdate.buttonIsPressed( playdate.kButtonDown ) then
		dy = 1.0
	end
	if playdate.buttonIsPressed( playdate.kButtonLeft ) then
		dx = -1.0
	end
	if playdate.buttonIsPressed( playdate.kButtonRight ) then
		dx = 1.0
	end
	
	-- update player
	local delta = gmtry.vector2D.new(dx, dy)
	delta:normalize()
	
	-- intermingles input handling and player updated, ugh
	if playdate.buttonIsPressed( playdate.kButtonB ) then		
		delta:scale(playerBoostSpeed)
	else
		delta:scale(playerSpeed)
	end

	player.position:offset(delta:unpack())

	local crank_position = playdate.getCrankPosition()
	player.turret_angle = crank_position
	
	-- not using outOfBounds here because of special wrapping logic
	local x, y = player.position:unpack()
	if x < 0 - 32 then
		player.position = gmtry.point.new(400 + 32, y)
	end
	if x > 400 + 32 then
		player.position = gmtry.point.new(0 - 32, y)
	end
	if y < 0 - 32 then
		player.position = gmtry.point.new(x, 240 + 32)
	end
	if y > 240 + 32 then
		player.position = gmtry.point.new(x, 0 - 32)
	end

	-- update bullets
	for index = #bullets, 1, -1 do
		local delta = gmtry.vector2D.newPolar(1, bullets[index].angle)
		delta:normalize()
		delta:scale(bulletSpeed)
		bullets[index].position:offset(delta:unpack())
		
		if outOfBounds(bullets[index].position) then
			table.remove(bullets, index) -- TODO: do this a better way (maybe)
		end
	end

	-- update alphas
	updateAlphas()
	
	-- check for collisions
	for b = #bullets, 1, -1 do
		for a = #alphas, 1, -1 do
			-- TODO: occasionally something here is nil, why?
			-- also, Lua doesn't have "continue" sad face
			if alphas[a] == nil or bullets[b] == nil then
				break
			end
			
			if alphas[a].position:distanceToPoint(bullets[b].position) < alphas[a].radius + bulletRadius then
				alphas[a].bulletSpawnTimer:remove()
				table.remove(alphas, a)
				table.remove(bullets, b)
			end
		end
	end
	
	for b = #bullets, 1, -1 do
		if player.position:distanceToPoint(bullets[b].position) < player.radius + bulletRadius then
			gameOver = true
			table.remove(bullets, b)
		end
	end

	-- draw objects
	drawPlayer()
	drawBullets()
	drawAlphas()
	
	playdate.timer.updateTimers()
end
