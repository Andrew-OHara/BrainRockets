local MIN_MAXTHRUST = 100
local MAX_MAXTHRUST = 6000

local MIN_ROCKETSIZE = 15
local MAX_ROCKETSIZE = 60

local MAX_ROCKET_VEL = 40

local MIN_PARTICLE_SIZE = 1
local MAX_PARTICLE_SIZE = 3
local MAX_PARTICLE_VEL = 5

local ROCKET_MASS = 0.1

local brainImage = LoadImage("assets/brain.png")

function CreateBrainRocket(pos, size, maxThrust, color, id)
	--print('CreateBrainRocket - start: ', lg.getColor())
	local rocket = {}	
	rocket.size = size or math.random(MIN_ROCKETSIZE, MAX_ROCKETSIZE)
	rocket.maxThrust = maxThrust or math.random(MIN_MAXTHRUST, MAX_MAXTHRUST)
	rocket.color = color and CopyColor(color) or COLORS[math.random(#COLORS)]
	
	ResetBrainRocket(rocket, pos)	

	local hiddenLayerCount = math.random(1, 3)
	rocket.brain = CreateBrain(hiddenLayerCount, {0,0,0,0,0,0,0}, 3, math.random(1, 3), math.random(3, 9), rocket.pos, Vector(rocket.size * 1.16, rocket.size))

	rocket.drawScale = rocket.size / 100
	rocket.drawOffset = Vector(brainImage.offset.x * rocket.drawScale, brainImage.offset.y * rocket.drawScale)
	rocket.drawPos = Vector(rocket.pos.x - rocket.drawOffset.x, rocket.pos.y - rocket.drawOffset.y)
	rocket.id = id or tostring(GetUniqueId())

	--print('CreateBrainRocket - end: ', lg.getColor())

	return rocket
end

function DrawBrainRocket(rocket)	
	lg.setColor(rocket.color)	
	lg.draw(brainImage.img, rocket.drawPos.x, rocket.drawPos.y, _, rocket.drawScale, rocket.drawScale)	
	
	if rocket.drawBrain then		
		DrawBrain(rocket.brain, rocket.drawOffset * 0.4, _, rocket.pos)		
	end		
	lg.setColor(COLORS[1])
end

function UpdateBrainRocket(rocket, dt)

	-- update physics	
	local vel = rocket.pos - rocket.previousPos
	local accel = (GRAVITY / ROCKET_MASS) + rocket.thrust
	local newPos = rocket.pos + vel + accel*dt*dt	
	rocket.previousPos = rocket.pos 
	rocket.pos = newPos
	rocket.vel = vel	

	-- update brain
	local inputs = GatherSensoryData(rocket)

	FeedBrainInput(rocket.brain, inputs)
	FireBrain(rocket.brain)	

	local outputs = GetOutputs(rocket.brain)

	-- use brain output to thrust rocket
	local forceDir = Vector(outputs[1], outputs[2]):normalized()

	rocket.thrust = (outputs[3] + 1) * rocket.maxThrust
	ThrustBrainRocket(rocket, forceDir * rocket.thrust)


	-- update brainrocket state
	rocket.drawPos = rocket.pos - rocket.drawOffset
	rocket.distanceMoved = rocket.distanceMoved + rocket.vel:len() * 0.001
	rocket.alive = not TestForBrainRocketDeath(rocket)		
end

function ThrustBrainRocket(rocket, accel)
	rocket.thrust = accel
	if rocket.processParticles then
		local particleVel = -accel:normalized() * (rocket.thrust:len() / SCREEN_WIDTH) * MAX_PARTICLE_VEL
		CreateParticle(rocket.pos, particleVel, math.random(MIN_PARTICLE_SIZE, MAX_PARTICLE_SIZE), rocket.color)
	end
end

function GatherSensoryData(rocket)
-- collect and interpolate distances from walls
	local px = rocket.pos.x 
	local py = rocket.pos.y
	local distFromFloor = (Vector(px, SCREEN_HEIGHT) - Vector(px, py)):len()
	local distFromCeil = (Vector(px, py) - Vector(px, 0)):len()
	local distFromRight = (Vector(SCREEN_WIDTH, py) - Vector(px, py)):len()
	local distFromLeft = (Vector(px, py) - Vector(0, py)):len()
	local lerpedDistFromFloor = ((distFromFloor / SCREEN_HEIGHT) * 2) - 1
	local lerpedDistFromCeil = ((distFromCeil / SCREEN_HEIGHT) * 2) - 1
	local lerpedDistFromRight = ((distFromRight / SCREEN_WIDTH) * 2) - 1
	local lerpedDistFromLeft = ((distFromLeft / SCREEN_WIDTH) * 2) - 1
	-- get direction and amount of velocity
	
	local dir = rocket.vel:normalized()			
	local scalarVel = rocket.vel:len()
	--store a clamped velocity value to interpolate
	local maxVel = MAX_ROCKET_VEL
	local clampedVel = (scalarVel > maxVel) and maxVel or scalarVel	
	local velInput = ((clampedVel / maxVel) * 2) - 1	

	-- prepare input for sensing by brain
	local inputArray = { lerpedDistFromFloor, lerpedDistFromCeil, lerpedDistFromLeft, lerpedDistFromRight, dir.x, dir.y, velInput }

	return inputArray
end

function TestForBrainRocketDeath(rocket)		
	return (rocket.pos.x < 0 or rocket.pos.x > SCREEN_WIDTH) or (rocket.pos.y < 0 or rocket.pos.y > SCREEN_HEIGHT)
end

function CopyBrainRocket(original)
	local copied = CreateBrainRocket(original.pos, original.size, original.maxThrust, original.color, original.id)
	copied.brain = CopyBrain(original.brain)

	return copied
end

function CopyBrainRockets(to, from)
	for fromIndex = 1, #from do
		to[fromIndex] = CopyBrainRocket(from[fromIndex])		
	end
end

function MutateBrainRocket(rocket, minMutationRate, maxMutationRate, mutationRange)	
	local minMuteRates = Vector(math.random() * minMutationRate, minMutationRate)
	local maxMuteRates = Vector(minMutationRate, maxMutationRate)
	local muteRange = Vector(math.random() * mutationRange, mutationRange)

	-- layerMuteRates higher than 1 means every hidden layer gets mutated
	MutateBrain(rocket.brain, 2, minMuteRates, maxMuteRates, muteRange)

	if math.random() < maxMutationRate then		
		local maxSizeChange = math.random(muteRange.x, muteRange.y) * (MAX_ROCKETSIZE - MIN_ROCKETSIZE)
		local negative = (math.random() < 0.5)
		local changeValue = math.random() * maxSizeChange
		changeValue = negative and -changeValue or changeValue
		rocket.size = rocket.size + changeValue
		rocket.size = Clamp(rocket.size, MIN_ROCKETSIZE, MAX_ROCKETSIZE)
		--print("size mutated by ", changeValue)
	end

	if math.random() < maxMutationRate then
		local maxThrustChange = math.random(muteRange.x, muteRange.y) * (MAX_MAXTHRUST - MIN_MAXTHRUST)
		local negative = (math.random() < 0.5)
		local changeValue = math.random() * maxThrustChange
		changeValue = negative and -changeValue or changeValue
		rocket.maxThrust = rocket.maxThrust + changeValue
		rocket.maxThrust = Clamp(rocket.maxThrust, MIN_MAXTHRUST, MAX_MAXTHRUST)
		--print("maxThrust mutated by ", changeValue)
	end

	if math.random() < maxMutationRate then
		local componentIndex = math.random(1, 3)		
		local maxColorChange = ((math.random() * (muteRange.y - muteRange.x)) + muteRange.x) * 255
		local negative = (math.random() < 0.5)
		local changeValue = math.random() * maxColorChange
		--print("color " .. componentIndex .. " changed by ", changeValue)
		changeValue = negative and -changeValue or changeValue
		rocket.color[componentIndex] = rocket.color[componentIndex] + changeValue
		rocket.color[componentIndex] = Clamp(rocket.color[componentIndex], 0, 255)
	end	

	ResetBrainRocket(rocket)

end

function ResetBrainRocket(rocket, pos, processParticles)
	rocket.pos = pos and pos:clone() or Vector(math.random() * SCREEN_WIDTH, math.random() * SCREEN_HEIGHT)
	rocket.vel = Vector(0, 0)
	rocket.previousPos = rocket.pos:clone()		
	rocket.thrust = Vector(0, 0)	
	rocket.distanceMoved = 0
	rocket.alive = true
	rocket.drawBrain = false	
	rocket.processParticles = true
end

function CreateOffspringFrom(rocket, id)
	local offspring = CopyBrainRocket(rocket)
	--offspring.id = offspring.id .. '.' .. tostring(id) 	
	MutateBrainRocket(offspring, 0.3, 0.85, 1.0)	-- these parameter values are arbitrary right now
	return offspring
end