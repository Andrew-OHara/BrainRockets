local MIN_NEURONS_PER_HIDDEN_LAYER = 1
local MAX_NEURONS_PER_HIDDEN_LAYER = 4

local AXON_COLOR_INERT = {40, 40, 40, 255}
local AXON_COLOR_FIRING = {75, 255, 75, 255}

local lg = love.graphics
local lt = love.timer

function CreateBrain(hiddenLayerCount, inputValues, outputCount, minNeurons, maxNeurons, drawPos, drawArea)	
	
	local minNeuronsPerLayer = minNeurons or MIN_NEURONS_PER_HIDDEN_LAYER
	local maxNeuronsPerLayer = maxNeurons or MAX_NEURONS_PER_HIDDEN_LAYER

	local brain = {}
	
	brain.layers = {}
	brain.drawData = {}	
	brain.neuronColors = {}	
	
	brain.layers[1] = InitInputLayer(inputValues)

	-- The first hidden layers weights per neuron count is determined by the number of outputs in the input layer
	local weightCountPerNeuron = #brain.layers[1].outputs

	-- Add two to hiddenLayerCount, one for the layer we initialized and one to include an output layer by default
	local outputLayerIndex = hiddenLayerCount + 2
	for layerIndex = 2, outputLayerIndex do
		brain.layers[layerIndex] = CreateLayer()
		
		local randomNumber = math.random(minNeuronsPerLayer, maxNeuronsPerLayer)
		local neuronCount = (layerIndex == outputLayerIndex) and outputCount or randomNumber		

		local thisLayer = brain.layers[layerIndex]
		InitLayer(thisLayer, weightCountPerNeuron, neuronCount)

		-- Other layers determine weights per neuron count by the number of neurons in the previous hidden layer
		weightCountPerNeuron = #thisLayer.neurons
	end	
	
	brain.drawPos = drawPos or Vector(75, 75)
	brain.drawArea = drawArea or Vector(85, 40)
	brain.drawData = GetBrainDrawData(brain)	

	return brain
end

function DrawBrain(brain, offset, alternateDrawData, alternateDrawPos)	
	if not offset then offset = Vector(0, 0) end
	local drawData = alternateDrawData or brain.drawData
	local previousLineStarts = {}

	local totalNeuronIndex = 1
	for layerIndex = 1, #drawData.layerPosOffsets do
		local linePosStarts = {}

		for neuronIndex = 1, drawData.neuronDrawLimits[layerIndex] do
			local drawOffset = Vector(drawData.layerPosOffsets[layerIndex], drawData.neuronPosOffsets[neuronIndex])			
			
			local drawPos = (alternateDrawPos) and 
							(alternateDrawPos + drawOffset - offset) or 
							(brain.drawPos + drawOffset - offset)
			
			lg.setColor(brain.neuronColors[totalNeuronIndex])
			lg.circle('line', drawPos.x, drawPos.y, drawData.neuronRadius, 40)
			lg.setColor(COLORS[1])			
			totalNeuronIndex = totalNeuronIndex + 1			

			-- draw lines from previous layer neurons to this neuron			
		
			linePosStarts[#linePosStarts+1] = drawPos

			if layerIndex > 1 then
				for previousNeuronIndex = 1, #previousLineStarts do
					-- get the weight value for this line from this neuron					
					local weightValue = brain.layers[layerIndex].neurons[neuronIndex].weights[previousNeuronIndex]
					local color = GetColorFromSignal(weightValue)					
					local startPos = previousLineStarts[previousNeuronIndex]
					lg.setColor(color)
					lg.line(startPos.x, startPos.y, drawPos.x, drawPos.y)
					lg.setColor(COLORS[1])
				end
			end			
		end	
		
    	previousLineStarts = {}
		previousLineStarts = CopyVectorTable(linePosStarts)
		linePosStarts = {}
	end
	lg.setColor(COLORS[1])
end

function SetBrainDrawPos(brain, pos)
	brain.drawPos = pos
end

function SetBrainDrawArea(brain, area)
	brain.drawArea = area
end

function FireBrain(brain)	
	local totalNeuronIndex = 1
	-- Set input layer neuronColors. This happens here because this layer isn't processed during the loop.
	local inputLayer = brain.layers[1]
	for inputNeuronIndex = 1, #inputLayer.outputs do
		local thisOutput = inputLayer.outputs[inputNeuronIndex]			
		brain.neuronColors[totalNeuronIndex] = GetColorFromSignal(thisOutput)
		totalNeuronIndex = totalNeuronIndex + 1
	end

	for layerIndex = 2, #brain.layers do
		local thisLayer = brain.layers[layerIndex]		
		for neuronIndex = 1, #thisLayer.neurons do
			local thisNeuron = thisLayer.neurons[neuronIndex]
			local sumTotal = 0
			for weightIndex = 1, #thisNeuron.weights do
				local weight = thisNeuron.weights[weightIndex]
				local prevLayer = brain.layers[layerIndex-1]
				sumTotal = sumTotal + prevLayer.outputs[weightIndex] * weight
			end	

			thisLayer.outputs[neuronIndex] = sumTotal
			brain.neuronColors[totalNeuronIndex] = GetColorFromSignal(sumTotal)
			totalNeuronIndex = totalNeuronIndex + 1			
		end
	end
end
 
function GetBrainDrawData(brain, alternateDrawArea)
	local drawData = {}	
	local drawArea = alternateDrawArea or brain.drawArea	
	local layerCount = #brain.layers
	local totalNeurons = 0

-- Find the largest number of neurons in a layer
	--	start with the 'neurons' from the input layer (it has no neurons so we use it's outputs) 

	local mostNeurons = #brain.layers[1].outputs
	 									-- we want this to count the input 'neurons'
	for layerIndex = 2, layerCount do
		local neuronCount = #brain.layers[layerIndex].neurons
		if neuronCount > mostNeurons then
			mostNeurons = neuronCount
		end
		
	end

-- 	Math for spacing
	local spacePerLayer = drawArea.x / layerCount
	local spacePerNeuron = drawArea.y / mostNeurons		
	drawData.layerPosOffsets = {}
	drawData.neuronPosOffsets = {}

	drawData.layerPosOffsets[1] = spacePerLayer / 2.0
	drawData.neuronPosOffsets[1] = spacePerNeuron / 2.0

--  Save the offsets from drawPos to draw at and number of neurons to draw per layer

	drawData.neuronDrawLimits = {}
	drawData.neuronDrawLimits[1] = #brain.layers[1].outputs

	local prevOffset = drawData.layerPosOffsets[1]
	for layerPosIndex = 2, layerCount do
		drawData.layerPosOffsets[layerPosIndex] = prevOffset + spacePerLayer
		prevOffset = drawData.layerPosOffsets[layerPosIndex]
		drawData.neuronDrawLimits[layerPosIndex] = #brain.layers[layerPosIndex].neurons		
	end	

	prevOffset = drawData.neuronPosOffsets[1]
	for neuronPosIndex = 2, mostNeurons do
		drawData.neuronPosOffsets[neuronPosIndex] = prevOffset + spacePerNeuron
		prevOffset = drawData.neuronPosOffsets[neuronPosIndex]		
	end
	
	drawData.neuronRadius = spacePerNeuron / 4.0

	return drawData

end

function GetColorFromSignal(signal)
	local color = {}

	if signal > 0 then
		if signal > 1 then signal = 1 end
		color = { 50, (signal * 205) + 50, 50, 255 }
	else
		if signal < -1 then signal = -1 end
		color = { (-signal * 205) + 50, 50, 50, 255 }
	end

	return color
end

function RandomizeBrainInput(brain)
	local inputLayer = brain.layers[1]
	local numInputs = #inputLayer.outputs
	local inputs = {}
	for inputIndex = 1, numInputs do
		-- input between -1 and 1
		inputs[inputIndex] = (math.random() * 2) - 1
	end
	SetLayerOutputs(inputLayer, inputs)
end

function FeedBrainInput(brain, inputs)
	SetLayerOutputs(brain.layers[1], inputs)
end

function GetOutputs(brain)
	local result = {}
	local layerCount = #brain.layers
	local outputs = brain.layers[layerCount].outputs
	for outputIndex = 1, #outputs do
		result[outputIndex] = outputs[outputIndex]
	end

	return result
end

function CopyBrain(original)
	local copied = {}

	copied.layers = {}	
	for layerIndex = 1, #original.layers do
		local thisLayer = original.layers[layerIndex]
		copied.layers[layerIndex] = CopyLayer(thisLayer)
	end

	copied.drawPos = original.drawPos:clone()
	copied.drawArea = original.drawArea:clone()
	copied.drawData = GetBrainDrawData(original)

	copied.neuronColors = CopyColorTable(original.neuronColors)

	return copied
end

function MutateBrain(brain, layerMuteRate, lowRangeMuteRates, highRangeMuteRates, maxMuteRangeRange) -- ranges must be between 0 and 1	
	assert(math.min(highRangeMuteRates.x, highRangeMuteRates.y) >= math.max(lowRangeMuteRates.x, lowRangeMuteRates.y))

	--print("brain mutated")

	local avgLowRate = (lowRangeMuteRates.x + lowRangeMuteRates.x) * 0.5
	local avgHighRate = (highRangeMuteRates.x + highRangeMuteRates.y) * 0.5	

	for layerIndex = 2, #brain.layers do	
		local minMuteRate = math.random() * (lowRangeMuteRates.y - lowRangeMuteRates.x) + lowRangeMuteRates.x
		local maxMuteRate = math.random() * (highRangeMuteRates.y - highRangeMuteRates.x) + highRangeMuteRates.x	
		local maxMuteRange = math.random() * (maxMuteRangeRange.y - maxMuteRangeRange.x) + maxMuteRangeRange.x
		
		if math.random() <= layerMuteRate then
			--print("layer mutated")
			MutateLayer(brain, layerIndex, minMuteRate, maxMuteRate, maxMuteRange)	
		end	
	end

	-- very small chance of mutating a new layer
	local oddsOfNewLayer = lowRangeMuteRates.x * 0.006	
	if math.random() < oddsOfNewLayer then
		--print("new layer...")
		AddLayerToBrain(brain, math.random(MIN_NEURONS_PER_HIDDEN_LAYER, MAX_NEURONS_PER_HIDDEN_LAYER))
	end
  
  FireBrain(brain)
  
end

function AddLayerToBrain(brain, numNeurons)
	-- decide where to add layer (between which layers?) Cannot add input or output layers
	local layers = brain.layers
	local addLimit = #layers
	local newLayerIndex = math.random(2, addLimit)

  -- shift layers in the table to make room for the addition
	local addIndex = #layers + 1
	while addIndex > newLayerIndex do
		layers[addIndex] = CopyLayer(layers[addIndex - 1])    
		addIndex = addIndex - 1
	end
	
	layers[addIndex] = CreateLayer()
	InitLayer(layers[addIndex], #layers[addIndex-1].outputs, 1)

	-- readjust weights in next connected layer  (do this before adding neurons to this layer so that added neurons connect up properly)
	local nextLayer = layers[addIndex + 1]
	for neuronIndex = 1, #nextLayer.neurons do
		local thisNeuron = nextLayer.neurons[neuronIndex]
		for weightIndex = 2, #thisNeuron.weights + 1 do  -- only leave one weight, the rest will be added with neurons
			thisNeuron.weights[weightIndex] = nil
		end
	end

	-- add neurons to this layer
	local thisLayer = layers[addIndex]
	local numWeights = #layers[addIndex-1].outputs
	for neuronIndex = 1, numNeurons-1 do
		AddNeuronToLayer(brain, addIndex, numWeights)
	end

	FireBrain(brain)

	brain.drawData = GetBrainDrawData(brain)
end