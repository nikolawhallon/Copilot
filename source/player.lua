import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local gmtry <const> = playdate.geometry

-- this global, as other modules need access to the player
player = {}

-- local
local playerSpeed = 3.0
local playerBoostSpeed = 6.0

-- global
function initPlayer()
	player.position = gmtry.point.new(200, 120)
	player.radius = 8
	player.turret_offset = 3
	player.turret_radius = 1
	player.turret_angle = 0
end

function updatePlayer()
	local crankChange, crankAcceleratedChange = playdate.getCrankChange()

	-- shooting bullets
	if playdate.buttonJustPressed( playdate.kButtonA ) and not playdate.buttonIsPressed( playdate.kButtonB ) then
		-- note that this is a global function, hence we have access to it here	
		spawnBullet(player.position, player.turret_angle)
	end

	-- moving
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

		local delta = gmtry.vector2D.new(dx, dy)
		delta:normalize()

	if playdate.buttonIsPressed( playdate.kButtonB ) then		
		delta:scale(playerBoostSpeed)
	else
		delta:scale(playerSpeed)
	end

	player.position:offset(delta:unpack())

	-- aiming the turret
	local crank_position = playdate.getCrankPosition()
	player.turret_angle = crank_position

	-- wrap the player
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
end

function drawPlayer()
	gfx.drawCircleAtPoint(player.position, player.radius)

	vector = gmtry.vector2D.newPolar(player.turret_offset, player.turret_angle)
	turret_position = player.position:offsetBy(vector:unpack())
	gfx.drawCircleAtPoint(turret_position, player.turret_offset)
end
