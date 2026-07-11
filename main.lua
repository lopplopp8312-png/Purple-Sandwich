function love.load()
    wasd = "w"
    timer = 0
    local width, height = love.window.getDesktopDimensions()
    local width, height = width*0.8, height*0.8
    screenscale = math.max(width / 1280, height/ 720)
    love.window.setMode(width, height, {resizable = true, centered = true, highdpi = true, vsync = 0}) 
    love.window.setTitle("gam")

    grass = love.graphics.newImage("grass.png")
    grass:setWrap("repeat", "repeat")

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

    local xscale, yscale, zscale = 2, 3, 4

    local xscale2, yscale2, zscale2 = (xscale - 1) * 50, (yscale - 1) * 50, (zscale - 1) * 100

    local topx, topy                 = 0 + 2*xscale2 - 2*yscale2, -100 - xscale2 - yscale2
    local toprightx, toprighty       = 100 + 2*xscale2, -50 - xscale2
    local bottomrightx, bottomrighty = 100 + 2*xscale2, 50 - xscale2 + zscale2
    local bottomx, bottomy           = 0, 100 + zscale2
    local bottomleftx, bottomlefty   = -100 - 2*yscale2, 50 + zscale2 - yscale2
    local topleftx, toplefty         = -100 - 2*yscale2, -50 - yscale2

    local cube = {
        -- top (x, y, u, v, r, g, b)
        {topleftx, toplefty, 0, xscale},
        {topx, topy, 0, 0},
        {toprightx, toprighty, yscale, 0},

        {toprightx, toprighty, yscale, 0},
        {0, 0, yscale, xscale},
        {topleftx, toplefty, 0, xscale},

        -- left
        {topleftx, toplefty, 0, 0, 0.8, 0.8, 0.8},
        {bottomleftx, bottomlefty, 0, zscale, 0.8, 0.8, 0.8},
        {bottomx, bottomy, yscale, zscale, 0.8, 0.8, 0.8},
        
        {bottomx, bottomy, yscale, zscale, 0.8, 0.8, 0.8},
        {0, 0, yscale, 0, 0.8, 0.8, 0.8},
        {topleftx, toplefty, 0, 0, 0.8, 0.8, 0.8},

        -- right
        {toprightx, toprighty, xscale, 0, 0.4, 0.4, 0.4},
        {bottomrightx, bottomrighty, xscale, zscale, 0.4, 0.4, 0.4},
        {bottomx, bottomy, 0, zscale, 0.4, 0.4, 0.4},

        {bottomx, bottomy, 0, zscale, 0.4, 0.4, 0.4},
        {0, 0, 0, 0, 0.4, 0.4, 0.4},
        {toprightx, toprighty, xscale, 0, 0.4, 0.4, 0.4},
    }

    cubemesh = love.graphics.newMesh(cube, "triangles", "static")

    cubemesh:setTexture(grass)

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
     debugvalues = {
        "fps: " .. fps,
        "timer: " .. timer,
        "screenscale: " .. screenscale,
        "wasd : " .. wasd,
        "posx: " .. player.pos.x
    }
    for index,value in ipairs(debugvalues) do
         love.graphics.print(value, 20, index * 20)
    end

    local x, y = test1, test2
    local scale = 1

    love.graphics.push()

    love.graphics.scale(screenscale, screenscale)
    love.graphics.translate(screen.x, screen.y)

    love.graphics.draw(cubemesh, x, y, 0, scale, scale)

    love.graphics.pop()

    if aspecttruthness then
        love.graphics.setColor(1,0,1)
        love.graphics.print(
            "ASPECT RATIO IS NOT 16:9\nVISUALS MIGHT BREAK\npress escape for full screen\npress backspace to ignore"
            , 50, 100, 0, 3, 3)
        love.graphics.setColor(1,1,1)
        if love.keyboard.isDown("backspace") then
            aspecttruthness = false
        end 
    end
end