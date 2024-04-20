import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local gmtry <const> = playdate.geometry

-- this global, as other modules need access to the alphas
alphas = {}

-- these are local, other modules don't need access to them
local alphaRadius = 8
local alphaSpeed = 2.5
local alphaTimer = nil
local alphaSpawnInterval = 2134
local alphaBulletSpawnInterval = 1432

-- the following are local functions which other modules don't need to worry about
local function alphaBulletTimerCallback(alpha)
	local ref = gmtry.vector2D.new(1, 0)
	local vector = player.position - alpha.position
	vector:normalize()
	spawnBullet(alpha.position, ref:angleBetween(vector) + 90)
end

local function alphaTimerCallback()
	local positionFromCenter = gmtry.vector2D.newPolar(200 + 32, math.random(0, 360))
	local center = gmtry.point.new(200, 120)
	local alpha = {}
	alpha.radius = alphaRadius
	alpha.speed = alphaSpeed
	alpha.position = center + positionFromCenter

	local vector = player.position - alpha.position
	vector:normalize()
	vector:scale((200 + 32) * 2)
	alpha.destination = alpha.position + vector

	if alphas[1] == nil then
		alphas[1] = alpha
	else
		table.insert(alphas, alpha)
	end
		
	alpha.bulletSpawnTimer = playdate.timer.new(alphaBulletSpawnInterval, alphaBulletTimerCallback, alpha)
	alpha.bulletSpawnTimer.repeats = true
end

-- the following are global functions which other modules need to call
function initAlphas()
	for index = #alphas, 1, -1 do
		alphas[index].bulletSpawnTimer:remove()
		table.remove(alphas, index)
	end
	
	alphaTimer = playdate.timer.new(alphaSpawnInterval, alphaTimerCallback)
	alphaTimer.repeats = true
end

function removeAllAlphaTimers()
	alphaTimer:remove()
	
	for index = #alphas, 1, -1 do
		alphas[index].bulletSpawnTimer:remove()
	end
end

function updateAlphas()
	for index = #alphas, 1, -1 do
		local delta = alphas[index].destination - alphas[index].position
		delta:normalize()
		delta:scale(alphas[index].speed)
		alphas[index].position:offset(delta:unpack())

		if alphas[index].position:distanceToPoint(alphas[index].destination) < 5 then
			alphas[index].bulletSpawnTimer:remove() -- this seems like the best/right way to remove the timer!
			table.remove(alphas, index) -- TODO: do this a better way (maybe)
		end
	end
end

function drawAlphas()
	for index, alpha in pairs(alphas) do
		gfx.drawCircleAtPoint(alpha.position, alphaRadius)
	end
end