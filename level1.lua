-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local storyboard = require( "storyboard" )
local StickLib   = require("lib_analog_stick")
local scene = storyboard.newScene()

system.activate( "multitouch" )

-- include Corona's "physics" library
local physics = require("physics")
physics.start(); physics.pause()
physics.setGravity(0, 0)

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5
local backgroundSpeed = 5

screenWidth = display.contentWidth - (display.screenOriginX*2)
screenHeight = display.contentHeight - (display.screenOriginY*2)
screenTop = display.screenOriginY
screenRight = display.contentWidth - display.screenOriginX
screenBottom = display.contentHeight - display.screenOriginY
screenLeft = display.screenOriginX
screenCenterX = display.contentWidth/2
screenCenterY = display.contentHeight/2

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once,
--		 unless storyboard.removeScene() is called.
-- 
-----------------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )

	local group = self.view
	local explosionSnd = audio.loadSound( "explosion.mp3" )
	local beamSnd = audio.loadSound( "beam.mp3" )
	local asteroidExplosionSnd = audio.loadSound( "asteroid_explosion.mp3" )

	local sndtrack = audio.loadSound( "soundtrack.mp3" )

	local explosionOptions = {
		width = 64,
		height = 64,
		numFrames = 6,
		sheetContentWidth=192, 
		sheetContentHeight=128
	}
	local explosionSheet = graphics.newImageSheet("explosion.png", explosionOptions)
	local sequenceData = {
		{name = "explode", start=1, count=6, time=1000, loopCount=1}
	}

	local stick = StickLib.NewStick( 
        {
        x             = screenWidth*.1,
        y             = screenHeight*.85,
        thumbSize     = 16,
        borderSize    = 32, 
        snapBackSpeed = .75, 
        R             = 255,
        G             = 255,
        B             = 255
        } )


	-- Moving starfield background
	local background1 = display.newImage( "space.png", screenWidth, screenHeight )
	background1:setReferencePoint( display.TopLeftReferencePoint )
	background1.x, background1.y = 0, 0
	local background2 = display.newImage( "space.png", screenWidth, screenHeight )
	background2:setReferencePoint( display.TopLeftReferencePoint )
	background2.x, background2.y = background1.width, 0
	local background3 = display.newImage( "space.png", screenWidth, screenHeight )
	background3:setReferencePoint( display.TopLeftReferencePoint )
	background3.x, background3.y = background1.width + background2.width, 0

	local function updateBackgroud()
		background1.x = background1.x - backgroundSpeed
		background2.x = background2.x - backgroundSpeed
		background3.x = background3.x - backgroundSpeed

		if background1.x <= (-background1.width) then
			background1.x = (background3.x +(background3.width))
		end

		if background2.x <= (-background2.width) then
			background2.x = (background1.x + (background1.width))
		end

		if background3.x <= (-background3.width) then
			background3.x = (background2.x + (background2.width))
		end
	end
	
	Runtime:addEventListener('enterFrame', updateBackgroud)


	-- Setting the warrior on screen
	local warrior = display.newImage( "starship.png")
	warrior.myName = "warrior"
	warrior:setReferencePoint( display.TopLeftReferencePoint )
	local warriorScaledHeight = warrior.height * warrior.yScale
	local warriorScaledWidth = warrior.width * warrior.xScale
	warrior.x, warrior.y = 20, (screenCenterY - (warriorScaledHeight/2))
	physics.addBody(warrior, "static")

	local xUpperBoundary = (screenRight - warriorScaledWidth)
	local yUpperBoundary = (screenBottom - warriorScaledHeight)


	-- Move our warrior by using the stick
	local function moveWarrior(event)
		if not warrior.isVisible then 
			Runtime:removeEventListener('enterFrame', moveWarrior)
			return
		end
		if warrior.x <= screenLeft then warrior.x = screenLeft end
		if warrior.x >= xUpperBoundary then warrior.x = xUpperBoundary end
		if warrior.y <= screenTop then warrior.y = screenTop end
		if warrior.y >= yUpperBoundary then warrior.y = yUpperBoundary end

		local maxSpeed = 7.0
		stick:move(warrior, 7.0, false)

			--warrior:applyForce(4000, 4000, warrior.x, warrior.y)
	end

	Runtime:addEventListener('enterFrame', moveWarrior)

	asteroids = {}
	-- Generate random asteroid
	local function generateAsteroid(event)
		probability = 0.05

		if math.random() < probability then
			local asteroid = display.newImage( "asteroid".. (math.random(1, 4)) ..".png" )
			asteroid.myName = "asteroid"
			physics.addBody(asteroid)
			asteroid:setReferencePoint( display.TopLeftReferencePoint )
			asteroid.x = screenRight
			asteroid.y = (math.random() * (screenBottom - (asteroid.width * asteroid.xScale)))
			asteroid.isFixedRotation = true
			asteroids[#asteroids+1] = asteroid
	
			group:insert( asteroid )

			local force = math.random()*10
			asteroid:applyForce(force, (math.random(-1,1)*force/2), asteroid.x, asteroid.y)
			asteroid:applyTorque( 100 )

			print("Asteroid #" .. #asteroids)
		end
	end

	local function moveAsteroids(event)
		for index, asteroid in pairs(asteroids) do
			if asteroid.isVisible then 
				asteroid.x = asteroid.x - backgroundSpeed
				if asteroid.x == -(asteroid.width * asteroid.xScale) then
					asteroids[index] = nil
				end
			else
				asteroids[index] = nil
			end

		end
	end

	Runtime:addEventListener('enterFrame', generateAsteroid)
	Runtime:addEventListener('enterFrame', moveAsteroids)

	local beams = {}
	local function onShoot(self, event)
		if not warrior.isVisible then return end
		local beam = display.newImage( "projectile2.png" )
		beam.myName = "beam"
		beam.x = (warrior.x + warrior.width)
		beam.y = (warrior.y + (warrior.height/2))
		physics.addBody(beam, "static")
		beams[#beams+1] = beam

		group:insert(beam)
		audio.play(beamSnd)
	end

	stick.Shoot:addEventListener("touch", onShoot)


	local function moveBeams(event)
		for index, beam in pairs(beams) do
			beam.x = beam.x + 5
		end
	end

	Runtime:addEventListener('enterFrame', moveBeams)



	local function onCollision(event)
		local asteroid
		local other
		if event.object1.myName == "asteroid" then
			asteroid = event.object1
			other  = event.object2
		elseif event.object2.myName == "asteroid" then
			asteroid = event.object2
			other = event.object1
		end

		if asteroid then
			if other.myName == "beam" then
				audio.play(asteroidExplosionSnd)
				asteroid:removeSelf()
			elseif other.myName == "warrior" then
				local explosionSprite = display.newSprite(explosionSheet, sequenceData)
				explosionSprite.x = (other.x + other.width/2)
				explosionSprite.y = (other.y + other.height/2)
				other:removeSelf()
				asteroid:removeSelf()
				audio.play(explosionSnd)
				explosionSprite:setSequence( "explosion" )
				explosionSprite:play()

				local function exitScene()
					Runtime:removeEventListener('enterFrame', moveWarrior)
					Runtime:removeEventListener('enterFrame', generateAsteroid)
					Runtime:removeEventListener('enterFrame', moveAsteroids)
					Runtime:removeEventListener('enterFrame', updateBackgroud)
					stick.Shoot:removeEventListener("touch", onShoot)
					Runtime:removeEventListener('enterFrame', moveBeams)

					storyboard.gotoScene("level2")
				end
				-- storyboard.gotoScene( "level1" )
				-- timer.performWithDelay( 1500, exitScene, 1 )
			end
		end

	end

	Runtime:addEventListener( "collision", onCollision )


	-- Insert elements into screen
	group:insert( background1 )
	group:insert( background2 )
	group:insert( background3 )
	group:insert( warrior )

	audio.play(sndtrack)

end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view
	
	physics.start()
	
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	local group = self.view
	
	physics.stop()
	
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	local group = self.view
	
	package.loaded[physics] = nil
	physics = nil
end


-----------------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
-----------------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched whenever before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

-----------------------------------------------------------------------------------------

return scene