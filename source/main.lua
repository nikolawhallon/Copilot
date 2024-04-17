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

-- globals
local player = {}
player.position = gmtry.point.new(200, 120)
player.radius = 8
player.turret_offset = 3
player.turret_radius = 1
player.turret_angle = 0

local bullets = {}

function drawPlayer()
	gfx.drawCircleAtPoint(player.position, player.radius)

	vector = gmtry.vector2D.newPolar(player.turret_offset, player.turret_angle)
	turret_position = player.position:offsetBy(vector:unpack())
	gfx.drawCircleAtPoint(turret_position, player.turret_offset)
end

function drawBullets()
	for index, bullet in pairs(bullets) do
		gfx.drawCircleAtPoint(bullet.position, 2) -- TODO: don't hardcode bullet radius here
	end
end

function spawnBullet()
	bullet = {}
	bullet.position = gmtry.point.new(player.position:unpack())
	bullet.angle = player.turret_angle
	
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
	player.position = gmtry.point.new(200, 120)
	player.radius = 8
	player.turret_offset = 3
	player.turret_radius = 1
	player.turret_angle = 0

	for index = #bullets, 1, -1 do
		table.remove(bullets, index)
	end
end

initGame()

function playdate.update()
	gfx.clear()
	gfx.setLineWidth(1)
	gfx.setColor(playdate.graphics.kColorXOR)
	
	-- handle input
	local crankChange, crankAcceleratedChange = playdate.getCrankChange()

	-- this is temporary for testing
	if playdate.buttonJustPressed( playdate.kButtonB ) then		
		initGame()
		return
	end

	if playdate.buttonJustPressed( playdate.kButtonA ) then		
		spawnBullet()
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
		delta:scale(speed)
		bullets[index].position:offset(delta:unpack())
		
		if outOfBounds(bullets[index].position) then
			table.remove(bullets, index) -- TODO: do this a better way (maybe)
		end
	end

	-- draw objects
	drawPlayer()
	drawBullets()
	
	playdate.timer.updateTimers()
end
