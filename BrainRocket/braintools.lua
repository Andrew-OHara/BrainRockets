____nextID = 0

function CopyVectorTable(t)
	local r = {}
	for i = 1, #t do
		r[i] = Vector(t[i].x, t[i].y) 
	end
  return r
end

function CopyColorTable(t)
	local r = {}
	for i = 1, #t do
		local c = t[i]
		r[i] = {c[1], c[2], c[3], c[4]}
	end
	return r
end

function Clamp(v, min, max)
	local r = v
	local mn = math.min(min, max)
	local mx = math.max(min, max)
	if v < mn then r = mn end
	if v > mx then r = mx end
	return r
end

function PrintColor(color)
	print(color[1], color[2], color[3])
end

function GetUniqueId()
	____nextID = ____nextID + 1
	return ____nextID
end

function CopyColor(c)
	local r = {}
	for i = 1, 4 do
		r[i] = c[i]
	end
	return r
end

function Contains(t, v)
	for i = 1, #t do
		if t[i] == v then
			return true
		end
	end
	return false
end