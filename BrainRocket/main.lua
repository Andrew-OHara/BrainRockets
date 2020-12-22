Camera = require('camera')
Timer = require('timer')
Vector = require('vector')

lg = love.graphics
lt = love.timer

function love.load()
	require 'br_globals'
	require 'braintools'
	require 'resources'
	require 'neuron'
	require 'layer'
	require 'brain'
	require 'brainRocket'
	require 'thrustParticle'
	require 'generation'
    
 	--require("mobdebug").start()

 	math.randomseed( os.time() ) 

	lg.setBackgroundColor(2, 2, 5)

 	generation = SpawnGeneration(50, 5, 15)

	camera = Camera()
	camera:lookAt(SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.5)
end

function love.update(dt)	
  if dt > MAX_DT then dt = MAX_DT end 
  	UpdateGeneration(generation, dt)  	
    UpdateParticles(dt)
    
end

function love.draw()	
	camera:attach()		
		
		DrawParticles()		
		DrawGeneration(generation)	
				
	camera:detach()

	if generation.selected then 
		local drawData = GetBrainDrawData(generation.selected.brain, Vector(640, 300))
		DrawBrain(generation.selected.brain, _, drawData, Vector(50, 2))
		lg.setFont(MEDIUM_FONT)
		lg.setColor(COLORS[3])
			lg.print(generation.selected.id, 620, 12)
		lg.setFont(SMALL_FONT)
		
	end

	lg.setColor(COLORS[3])
	--lg.print("Particles : ".. tostring(#particles), 15, 80)
	lg.print("Rockets alive: ".. tostring(generation.livingCount), 10, 10)
	--lg.print("fps: " .. love.timer.getFPS(), 15, 15)
	lg.setColor(COLORS[1])	
end

function love.mousereleased(x, y, button, istouch)
	if button == 1 then
		generation.selected = SelectFirstFrom(generation, x, y)
	end	
end