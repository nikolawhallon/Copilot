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

local speed = 2.0
local bulletSpeed = 4.0

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

local enemies = {}
local enemyTimer = nil
local enemyRadius = 4

local function enemyBulletTimerCallback(enemy)
	local ref = gmtry.vector2D.new(1, 0)
	local vector = player.position - enemy.position
	vector:normalize()
	spawnBullet(enemy.position, ref:angleBetween(vector) + 90)
end

local function enemyTimerCallback()
	local positionFromCenter = gmtry.vector2D.newPolar(200 + 32, math.random(0, 360))
	local destinationFromCenter = gmtry.vector2D.newPolar(200 + 32, math.random(0, 360))
	local center = gmtry.point.new(200, 120)
	enemy = {}
	enemy.position = center + positionFromCenter
	enemy.destination = center + destinationFromCenter

	if enemies[1] == nil then
		enemies[1] = enemy
	else
		table.insert(enemies, enemy)
	end
		
	enemy.bulletTimer = playdate.timer.new(1432, enemyBulletTimerCallback, enemy)
	enemy.bulletTimer.repeats = true
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
	
	enemyTimer = playdate.timer.new(2134, enemyTimerCallback)
	enemyTimer.repeats = true
end

initGame()

function playdate.update()
	gfx.clear()
	gfx.setLineWidth(1)
	gfx.setColor(playdate.graphics.kColorXOR)
	
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
		return
	end
	
	-- handle input
	local crankChange, crankAcceleratedChange = playdate.getCrankChange()

	-- this is temporary for testing
	if playdate.buttonJustPressed( playdate.kButtonB ) then		
		initGame()
		return
	end

	if playdate.buttonJustPressed( playdate.kButtonA ) then		
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
	delta:scale(speed)
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
	
	-- check for collisions
	for e = #enemies, 1, -1 do
		for b = #bullets, 1, -1 do
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
