function SpawnGeneration(rocketCount, winnerCount, epochTime, savedSeed)
	local gen = {}		
	gen.runTime = epochTime or 300
	gen.winnerCount = winnerCount or 10
	gen.livingCount = rocketCount
	gen.running = true
	gen.secondsRunning = 0
	gen.winners = {}
	gen.rocketCount = rocketCount
	gen.offspringCount = gen.rocketCount
	gen.rockets = {}
	gen.selected = nil
	gen.counter = 1

	gen.speciesCount = nil
	
	ResetGenerationElapsedTime(gen)

	gen.processParticles = true
	for i = 1, gen.rocketCount do
		gen.rockets[i] = CreateBrainRocket()
	end	
	return gen
end

function UpdateGeneration(gen, dt)	
	if gen.running then
		gen.secondsRunning = gen.secondsRunning + dt		
		for i = 1, gen.rocketCount do
			local thisRocket = gen.rockets[i] 
			if thisRocket.alive then
				UpdateBrainRocket(thisRocket, dt)		
				if not thisRocket.alive then					
					gen.livingCount = gen.livingCount - 1
				end
			end
		end			
    	CleanUpRockets(gen)    	
		if gen.secondsRunning > gen.runTime or gen.livingCount < gen.winnerCount + 1 then
			gen.running = false
			--  gather up the winning rockets - based on distance travelled		
			local countedSpecies = {}
			for winnerIndex = 1, gen.winnerCount do 
				local highestIndex
				local highest = 0
				for rocketIndex = 1, gen.rocketCount do
					local rocket = gen.rockets[rocketIndex]
					if rocket.alive then
            			if rocket.distanceMoved > highest then
							highestIndex = rocketIndex 
							highest = rocket.distanceMoved
						end
					end
				end
				if highestIndex then
					gen.winners[#gen.winners + 1] = CopyBrainRocket(gen.rockets[highestIndex])
					gen.rockets[highestIndex].alive = false
					if not Contains(countedSpecies, gen.rockets[highestIndex].id) then
						countedSpecies[#countedSpecies + 1] = gen.rockets[highestIndex].id
						print(countedSpecies[#countedSpecies])
					end
				else
					--print('random rocket...')
					gen.winners[#gen.winners + 1] = CreateBrainRocket()	
					if not Contains(countedSpecies, gen.winners[#gen.winners].id) then
						countedSpecies[#countedSpecies + 1] = gen.winners[#gen.winners].id
						print(countedSpecies[#countedSpecies])
					end				
        		end
			end	
			gen.winners[#gen.winners + 1] = CreateBrainRocket()  -- add one random rocket to each generation
			if not Contains(countedSpecies, gen.winners[#gen.winners].id) then
				countedSpecies[#countedSpecies + 1] = gen.winners[#gen.winners].id
				print(countedSpecies[#countedSpecies])
				print()
			end
			gen.speciesCount = #countedSpecies			
		end
		
	else		
		for i = 1, #gen.winners do								
			local thisRocket = gen.winners[i]
			UpdateBrainRocket(thisRocket, dt)
		end		
		SpawnNewGeneration(gen)		
	end	
	UpdateGenerationElapsedTime(gen, dt)	
end

function DrawGeneration(gen)	
	if gen.running then
		for i = 1, gen.rocketCount do
			local thisRocket = gen.rockets[i]      
			if thisRocket.alive then
				if generation.selected then
					if thisRocket.id == generation.selected.id then
						DrawBrainRocket(thisRocket)
					end
				else
					DrawBrainRocket(thisRocket)
				end
			end
		end		
		lg.setColor(COLORS[3])
		lg.print("Generation " .. tostring(gen.counter), 10, 40)
		local t = gen.elapsedTime
		lg.print("Time elapsed: " .. t.days .. ": " .. t.hours .. ": " .. t.minutes .. ": " .. math.floor(t.seconds), 10, 65)
		if gen.speciesCount then
			lg.print("Distinct Species " .. tostring(gen.speciesCount), 10, 90)
		end		
		lg.setColor(COLORS[1])
	else		
		for i = 1, #gen.winners do 
			local thisRocket = gen.winners[i]
			DrawBrainRocket(thisRocket)
		end
	end	
end

-- TODO: check this function. its breaking the rocketCount
function CleanUpRockets(gen)
	local rocketCount = #gen.rockets	
	local rocketIndex = rocketCount
	local originalIndex = rocketIndex
	local thisRocket = gen.rockets[rocketIndex]  

	while not thisRocket.alive and rocketIndex > 0 do
		gen.rockets[rocketIndex] = nil
    	rocketIndex = rocketIndex - 1
       	thisRocket = gen.rockets[rocketIndex]
	end	

	local cleanedCount = originalIndex - rocketIndex
	gen.rocketCount = rocketIndex

	--if cleanedCount > 0 then
	--	print(tostring(cleanedCount) .. " rockets cleaned." )
	--	print(tostring(#gen.rockets .. " rockets left."))	
	--	print()	
	--end	
end

function SelectFirstFrom(gen, x, y)
	for i = 1, #gen.rockets do
		local rocket = gen.rockets[i]
		if rocket.alive then
			if rocket.size > (Vector(x, y) - rocket.pos):len() then
				return rocket
			end
		end
	end
	return nil
end

function SpawnNewGeneration(gen)	
	gen.rockets = {}
	gen.ancestors = {}
	CopyBrainRockets(gen.ancestors, gen.winners)
	gen.winners = {}
	gen.selected = nil
	gen.secondsRunning = 0
	gen.running = true
	gen.livingCount = gen.rocketCount	

	local offspringPerRocket = math.floor(gen.offspringCount / #gen.ancestors)
	local leftoverCount = gen.offspringCount % #gen.ancestors	

	local rocketIndex = 1
	for winnerIndex = 1, #gen.ancestors do
		local thisAncestor = gen.ancestors[winnerIndex]
		for offspringCount = 1, offspringPerRocket do
			gen.rockets[rocketIndex] = CreateOffspringFrom(thisAncestor, offspringCount)
			rocketIndex = rocketIndex + 1
		end	
	end
	assert(#gen.rockets <= gen.offspringCount)

	for leftoverIndex = 1, leftoverCount do
		local thisAncestor = gen.ancestors[math.random(#gen.ancestors)]
		gen.rockets[rocketIndex] = CreateOffspringFrom(thisAncestor)
		rocketIndex = rocketIndex + 1
	end

	gen.counter = gen.counter + 1

	--print()
	--print('total ' .. tostring(gen.offspringCount) .. ", created " .. tostring(#gen.rockets) .. ", leftover " .. tostring(leftoverCount) )
	
end

function ResetGenerationElapsedTime(gen)
	gen.elapsedTime = {}
	gen.elapsedTime.seconds = 0
	gen.elapsedTime.minutes = 0
	gen.elapsedTime.hours = 0
	gen.elapsedTime.days = 0

end

function UpdateGenerationElapsedTime(gen, dt)
	local t = gen.elapsedTime
	t.seconds = t.seconds + dt
	if t.seconds > 59 then
		t.minutes = t.minutes + 1
		t.seconds = t.seconds - 60
	end
	if t.minutes > 59 then
		t.hours = t.hours + 1
		t.minutes = t.minutes - 60
	end
	if t.hours > 23 then
		t.days = t.days + 1
		t.hours = t.hours - 24
	end
end