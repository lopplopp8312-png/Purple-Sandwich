function love.load()
    debug = true
    wasd = "w"
    timer = 0
    local width, height = love.window.getDesktopDimensions()
    local width, height = width*0.8, height*0.8
    screenscale = math.max(width / 1280, height/ 720)
    love.window.setMode(width, height, {resizable = true, centered = true, highdpi = true, vsync = 0}) 
    love.window.setTitle("Purple Error")

    grass = love.graphics.newImage("grass.png")

    screen = {}

    player = {
        pos = {
            x = 0,
            y = 0,
            z = 0
        },
        vel = {
            x = 0,
            y = 0,
            z = 0
        }
    }

    -- disgusting level data
    leveldata = {
        GrassLands = {
            sky = "cat.jfif",
        },
    }

    loadlevel("GrassLands")
end

function loadlevel(level)
    local data = leveldata[level]
    sky = data["sky"]
end

function love.keypressed(key)

    if key == "w" or key == "a" or key == "s" or key == "d"
    or key == "up" or  key == "left" or  key == "down" or  key == "right" then
        wasd = key
    end

    if key == "escape" then
        local isfullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(isfullscreen, "desktop")
    end

    if key == "\\" then
        love.event.quit()
    end

end

function love.resize(width, height)
    local aspectx, aspecty = width / 1280, height/ 720
    screenscale = math.max(aspectx, aspecty)

    aspecttruthness = math.abs(aspecty - aspectx) > 0.05
end

function love.update(dt)
    fps = math.floor(1 / dt)
    timer = timer + dt

    if love.keyboard.isDown(wasd) then
        if wasd == "w" or wasd == "up" then
            player.vel.x = 2
            player.vel.y = 0
        elseif wasd == "a" or wasd == "left" then
            player.vel.x = 0
            player.vel.y = 2
        elseif wasd == "s" or wasd == "down" then
            player.vel.x = -2
            player.vel.y = 0
        else
            player.vel.x = 0
            player.vel.y = -2
        end
    else
        player.vel.x = 0
        player.vel.y = 0
    end

    player.pos.x = player.pos.x + player.vel.x * dt
    player.pos.y = player.pos.y + player.vel.y * dt

    screen.x = player.pos.x * -100 + player.pos.y * 100
    screen.y = player.pos.x * 50 + player.pos.y * 50
end

function love.draw()
    local test1, test2 = 640, 280

    -- debug
    if debug then
        debugvalues = {
           "fps: " .. fps,
            "timer: " .. timer,
            "screenscale: " .. screenscale,
            "wasd : " .. wasd,
            "posx: " .. player.pos.x,
            "posy: " .. player.pos.y,
            "posz: " .. player.pos.z,      
            "sky: " .. sky,
        }
        for index,value in ipairs(debugvalues) do
            love.graphics.print(value, 20, index * 20)
        end
    end

    local x, y = test1, test2
    local scale = 1

    -- world stuff here
    love.graphics.push()

    love.graphics.scale(screenscale, screenscale)
    love.graphics.translate(screen.x, screen.y)



    love.graphics.pop()

    -- UI stuff here
    love.graphics.push()

    love.graphics.scale(screenscale, screenscale)

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.print("pre-alpha stage, everything sucks and\n     everything you see will change", 280, 50, 0, 3, 3)
    love.graphics.setColor(1,1,1,1)

    if aspecttruthness then
        love.graphics.setColor(1,0,1)
        love.graphics.print(
            "ASPECT RATIO IS NOT 16:9\nVISUALS WILL BREAK\npress escape for full screen\npress backspace to ignore"
            , 50, 100, 0, 3, 3)
        love.graphics.setColor(1,1,1)
        if love.keyboard.isDown("backspace") then
            aspecttruthness = false
        end 
    end

    love.graphics.pop()
end