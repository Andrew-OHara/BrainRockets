GRAVITY = Vector(0, 98)

MAX_DT = 1 / 60

COLORS = {
	 { 255, 255, 255, 255 },
	{ 130, 130, 255, 255 },
	{ 100, 255, 100, 255 },
	{ 255, 130, 130, 255 },
	{ 255, 160, 255, 255 }, 
	{ 255, 50, 255, 255 },
	{ 120, 255, 50, 255 },
	{ 40, 60, 255, 255 },
	{ 60, 255, 40, 255 },
	{ 95, 40, 255, 255 },
	{ 255, 40, 90, 255 }
}


SCREEN_HEIGHT = lg.getHeight()
SCREEN_WIDTH = lg.getWidth()

MEDIUM_FONT = love.graphics.newFont( 20 )
SMALL_FONT = love.graphics.newFont( 12 )

particles = {}