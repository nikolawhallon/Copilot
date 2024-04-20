import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local gmtry <const> = playdate.geometry

-- global
bullets = {}

-- local
local bulletRadius = 2
local bulletSpeed = 4.0

-- global
function spawnBullet(position, angle)
	local bullet = {}
	bullet.speed = bulletSpeed
	bullet.radius = bulletRadius
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

function updateBullets()
	for index = #bullets, 1, -1 do
		local delta = gmtry.vector2D.newPolar(1, bullets[index].angle)
		delta:normalize()
		delta:scale(bullets[index].speed)
		bullets[index].position:offset(delta:unpack())
		
		if outOfBounds(bullets[index].position) then
			table.remove(bullets, index) -- TODO: do this a better way (maybe)
		end
	end
end

function clearBullets()
	for index = #bullets, 1, -1 do
		table.remove(bullets, index)
	end
end

function drawBullets()
	for index, bullet in pairs(bullets) do
		gfx.drawCircleAtPoint(bullet.position, bullet.radius)
	end
end