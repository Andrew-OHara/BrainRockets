local PARTICLE_MASS = 5
local GRAVITY_ACCEL = GRAVITY / PARTICLE_MASS

particles.nextIndex = 1

function CreateParticle(pos, vel, size, color)
	local p = {}

	p.pos = pos
	p.previousPos = p.pos - vel
	p.size = size	
	p.alive = true
	p.color = color and CopyColor(color) or CopyColor(COLORS[math.random(#COLORS)])	
	p.lifetime = math.random(2, 30)
	p.clock = 0
	p.transparency = 0

	-- look for particle to recycle before adding to the list
	local reincarnated = false
	for particleIndex = 1, particles.nextIndex - 1 do
		if not particles[particleIndex].alive then 
			particles[particleIndex] = p
			reincarnated = true
			break
		end
	end

	if not reincarnated then
		particles[particles.nextIndex] = p
		particles.nextIndex = particles.nextIndex + 1
	end

	return p
end

function UpdateParticle(p, dt)
	
	if p.alive then
		local vel = p.pos - p.previousPos
		-- add some slight randomness to the particles motion
		local randomFactor = Vector((math.random() * 0.0025) - 0.00125, (math.random() * 0.025) - 0.0125)
		local variation = Vector(randomFactor.x, randomFactor.y)	
		vel = vel + variation
		local newPos = p.pos + vel + GRAVITY_ACCEL * dt*dt	
		p.previousPos = p.pos 
		p.pos = newPos

		p.transparency = 255 - ((p.clock / p.lifetime) * 255)

		p.color = { p.color[1], p.color[2], p.color[3], p.transparency }
		p.clock = p.clock + 1
		if p.clock > p.lifetime then
			KillParticle(p)
		end
	end	
end

function UpdateParticles(dt)
	if #particles > 0 then	
		for particleIndex = 1, particles.nextIndex-1 do
			local particle = particles[particleIndex]
			if particle then
				UpdateParticle(particle, dt)
			end
		end
		CleanUpParticles()
	end	
end

function DrawParticle(p)
	if p.alive then
		lg.setColor(p.color)
		lg.draw(sphere.img, p.pos.x, p.pos.y, _, p.size * 0.02, p.size * 0.02)		
	end	
end

function DrawParticles()	
	lg.setBlendMode('add', 'alphamultiply')		
	for particleIndex = 1, particles.nextIndex-1 do
		local particle = particles[particleIndex]
		if particle then
			DrawParticle(particle)
		end
	end
	lg.setBlendMode('alpha')
	lg.setColor(COLORS[1])	
end

function KillParticle(p)
	p.alive = false
	p.previousPos = p.pos	
	p.invisibilityFactor = 0
end

function CleanUpParticles()	
	local particleIndex = particles.nextIndex - 1
	local originalIndex = particleIndex
	while not particles[particleIndex].alive do
		particles[particleIndex] = nil
    particleIndex = particleIndex - 1    
	end	
	local cleanedCount = originalIndex - particleIndex		
	particles.nextIndex = particleIndex + 1
	--if cleanedCount > 0 then
		--print(tostring(cleanedCount) .. " particles cleaned." )		
	--end
end