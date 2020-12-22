local newImage = love.graphics.newImage

function LoadImage(filepath, sharpness)
	local sharpness = sharpness or 0
	local obj = {img = newImage(filepath)}	
	obj.offset = Vector(obj.img:getWidth() / 2, obj.img:getHeight() / 2)

	return obj
end

sphere = LoadImage('assets/sphere.png')