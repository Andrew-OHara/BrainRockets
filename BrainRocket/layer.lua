

function CreateLayer()
	local layer = {}
	layer.neurons = {}
	layer.outputs = {}
	
	return layer
end

function InitInputLayer(inputValues)
--[[	Input layers don't have neuron objects. They only
		need output values to serve as inputs for the actual
		brain. The input layer is the 'sense interface'.		]]

	local layer = CreateLayer()

	SetLayerOutputs(layer, inputValues)

	return layer
end

function InitLayer(layer, weightsPerNeuron, neuronCount)
--		Weights per neuron: num connected outputs from previous layer	
	
	for neuronIndex = 1, neuronCount do
		layer.neurons[neuronIndex] = CreateNeuron()
		local thisNeuron = layer.neurons[neuronIndex]
    	layer.outputs[neuronIndex] = 0
		InitRandomNeuron(thisNeuron, weightsPerNeuron)
	end
end


function IsInputLayer(layer)
	-- Initialized Input layers always have outputs and never have neurons.
	
	assert(not (#layer.neurons == 0 and #layer.outputs == 0), "An uninitialized layer cannot be passed to this function!")
	return (#layer.neurons == 0 and #layer.outputs ~= 0)
end

function SetLayerOutputs(layer, outputValues)	
	local outputCount = #outputValues
	for outputIndex = 1, outputCount do
		layer.outputs[outputIndex] = outputValues[outputIndex]
	end
end

function CopyLayer(original)
	local copied = CreateLayer()
	for neuronIndex = 1, #original.neurons do		
		local thisNeuron = original.neurons[neuronIndex]
		copied.neurons[neuronIndex] = CopyNeuron(thisNeuron)			
	end
  SetLayerOutputs(copied, original.outputs)
	return copied
end

function MutateLayer(brain, layerIndex, minMutationRate, maxMutationRate, maxMutationRange)
	assert(maxMutationRate >= 0 and maxMutationRate <= 1)
	assert(minMutationRate >= 0 and minMutationRate <= 1)
	assert(maxMutationRange >= 0 and maxMutationRange <= 1)
	assert(layerIndex > 1) -- we don't mutate input layers

	local layer = brain.layers[layerIndex]

	local avgMutationRate = (minMutationRate + maxMutationRate) * 0.5	
	local oddsOfMutation = avgMutationRate * 100

	for neuronIndex = 1, #layer.neurons do			
		local neuronMutationRate = ( math.random() * (maxMutationRate - minMutationRate)) + minMutationRate			
		local neuronMutationRange =  math.random() * maxMutationRange		
		local r = math.random(100)
		if r < oddsOfMutation then
			MutateNeuron(layer.neurons[neuronIndex], neuronMutationRate, neuronMutationRange)
		end		
	end

	-- small chance to add a new neuron
	local oddsOfNewNeuron = oddsOfMutation * 0.01	
	if math.random() * 100 < oddsOfNewNeuron then
		if layerIndex ~= #brain.layers then		
			AddNeuronToLayer(brain, layerIndex)		
			--print("added neuron to layer ", layerIndex)
		end
	end
	FireBrain(brain)
	brain.drawData = GetBrainDrawData(brain)
end

function AddNeuronToLayer(brain, layerIndex, numWeights)
	assert(layerIndex > 1 and layerIndex ~= #brain.layers)  -- we don't add neurons to input or output layers

	local layer = brain.layers[layerIndex]
	local neuronIndex = #layer.neurons + 1
	-- if not passed in we get the number of weights from another neuron in this layer
	local weightCount = numWeights or #layer.neurons[1].weights 

	layer.neurons[neuronIndex] = CreateNeuron()	
	InitRandomNeuron(layer.neurons[neuronIndex], weightCount)

	layer.outputs[neuronIndex] = 0.0

	-- connect new neuron to the rest of the brain
	local nextLayer = brain.layers[layerIndex + 1]
	for neuronIndex = 1, #nextLayer.neurons do
		local thisNeuron = nextLayer.neurons[neuronIndex]
		thisNeuron.weights[#thisNeuron.weights+1] = (math.random() * 2) - 1
	end	
end