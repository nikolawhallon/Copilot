import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- from https://github.com/Whitebrim/AnimatedSprite
import "AnimatedSprite.lua"

-- constants
local gfx <const> = playdate.graphics
local gmtry <const> = playdate.geometry
gfx.setBackgroundColor(gfx.kColorBlack)

local speed = 3.0
local boostSpeed = 6.0
local bulletSpeed = 5.0

-- globals
local gameOver = false
local player = {}
player.position = gmtry.point.new(200, 120)
player.radius = 8
player.turret_offset = 3
player.turret_radius = 1
player.turret_angle = 0

local bullets = {}
local bulletRadius = 2

-- the following variables and
-- enemyBulletTimerCallback, enemyTimerCallback, updateEnemies, drawEnemies
-- and enemy collision handling logic are all specific to one style of
-- enemy behavior - but I would like to support multiple styles
-- of enemy behavior - I am thinking, then, to create waves of enemies
-- where each wave has its own logic
-- TODO: refactor into
--   alpha_enemies
--   beta_enemies
--   gamma_enemies
--   delta_enemies (just one, a boss)
-- waves could be score dependent, # spawned enemies dependent, or time dependent
-- for starters, I think I will go with score dependent
local enemies = {}
local enemyTimer = nil
local enemyRadius = 8
local enemyInterval = 2134
local enemyBulletInterval = 1432

local function enemyBulletTimerCallback(enemy)
	local ref = gmtry.vector2D.new(1, 0)
	local vector = player.position - enemy.position
	vector:normalize()
	spawnBullet(enemy.position, ref:angleBetween(vector) + 90)
end

local function enemyTimerCallback()
	local positionFromCenter = gmtry.vector2D.newPolar(200 + 32, math.random(0, 360))
	local center = gmtry.point.new(200, 120)
	enemy = {}
	enemy.position = center + positionFromCenter

	local vector = player.position - enemy.position
	vector:normalize()
	vector:scale((200 + 32) * 2)
	enemy.destination = enemy.position + vector

	if enemies[1] == nil then
		enemies[1] = enemy
	else
		table.insert(enemies, enemy)
	end
		
	enemy.bulletTimer = playdate.timer.new(enemyBulletInterval, enemyBulletTimerCallback, enemy)
	enemy.bulletTimer.repeats = true
end

function updateEnemies()
	for index = #enemies, 1, -1 do
		local delta = enemies[index].destination - enemies[index].position
		delta:normalize()
		delta:scale(speed)
		enemies[index].position:offset(delta:unpack())

		if enemies[index].position:distanceToPoint(enemies[index].destination) < 5 then
			enemies[index].bulletTimer:remove() -- this seems like the best/right way to remove the timer!
			table.remove(enemies, index) -- TODO: do this a better way (maybe)
		end
	end
end

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

function drawEnemies()
	for index, enemy in pairs(enemies) do
		gfx.drawCircleAtPoint(enemy.position, enemyRadius)
	end
end

function drawBoss()
	gfx.drawCircleAtPoint(gmtry.point.new(64, 64), 32)
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

	for index = #enemies, 1, -1 do
		enemies[index].bulletTimer:remove()
		table.remove(enemies, index)
	end
	
	-- TODO: I would like the time here to depend on both enemyInterval
	-- and the player's score - if I want other waves of enemies to have
	-- a similar reliance, I probably need to break the score up by wave
	-- e.g. alpha_score, beta_score, gamma_score, delta_score
	enemyTimer = playdate.timer.new(enemyInterval, enemyTimerCallback)
	enemyTimer.repeats = true
end

initGame()

function playdate.update()
	gfx.clear()
	gfx.setLineWidth(1)
	gfx.setColor(playdate.graphics.kColorXOR)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		
	if gameOver then
		enemyTimer:remove()
		
		for index = #enemies, 1, -1 do
			enemies[index].bulletTimer:remove()
		end

		if playdate.buttonIsPressed( playdate.kButtonA ) and playdate.buttonIsPressed( playdate.kButtonB ) then		
			initGame()
		end

		drawBullets()
		drawEnemies()
		
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
		delta:scale(boostSpeed)
	else
		delta:scale(speed)
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

	-- update enemies
	updateEnemies()
	
	-- check for collisions
	for e = #enemies, 1, -1 do
		for b = #bullets, 1, -1 do
			-- TODO: occasionally something here is nil, why?
			-- also, Lua doesn't have "continue" sad face
			if enemies[e] == nil or bullets[b] == nil then
				break
			end
			if enemies[e].position:distanceToPoint(bullets[b].position) < enemyRadius + bulletRadius then
				enemies[e].bulletTimer:remove()
				table.remove(enemies, e)
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

	--print(#enemies)
	--print(#playdate.timer.allTimers())

	-- draw objects
	drawPlayer()
	drawBullets()
	drawEnemies()
	
	playdate.timer.updateTimers()
end
