function CreateNeuron()
	local neuron = {}

	-- weight values are in the range of -1 to 1
	neuron.weights = {}

	return neuron
end

function InitNeuron(neuron, weightValues)
	local weightCount = #weightValues

	for weightIndex = 1, weightCount do
		neuron.weights[weightIndex] = weightValues[weightIndex]
	end
end

function InitRandomNeuron(neuron, weightCount)
	for weightIndex = 1, weightCount do
		neuron.weights[weightIndex] = (math.random() * 2) - 1
	end
end

function CopyNeuron(original)
	local copied = CreateNeuron()
	for weightIndex = 1, #original.weights do
		copied.weights[weightIndex] = original.weights[weightIndex]
	end
	return copied
end

-- rate and range are from 0 to 1. rate is the chance each mutable variable will change, range is max amount of total range can mutate by
function MutateNeuron(neuron, mutationRate, mutationRange)
	assert(mutationRate >= 0 and mutationRate <= 1)
	assert(mutationRange >= 0 and mutationRange <= 1)
	local oddsOfMutation = mutationRate * 100
	--print("neuron mutated")		
	for weightIndex = 1, #neuron.weights do
		local r = math.random(100)
		if r < oddsOfMutation then
			--print("		weight mutated. odds were ", oddsOfMutation)
			-- range is from -1 to 1, so value can change up to 2
			local maxGeneticChange = mutationRange * 2
			local negative = (math.random() < 0.5)
			local changeValue = math.random() * maxGeneticChange
			changeValue = negative and -changeValue or changeValue			
			neuron.weights[weightIndex] = neuron.weights[weightIndex] + changeValue
			neuron.weights[weightIndex] = Clamp(neuron.weights[weightIndex], -1, 1)			
			
		else
			--print("not mutated")
		end
	end
end