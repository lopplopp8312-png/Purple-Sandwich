local savetable = require("lib.tablesave")




function love.load()
    debug = true
    wasd = "w"
    timer = 0
    width, height = love.window.getDesktopDimensions()
    width, height = width*0.8, height*0.8
    screenscale = math.max(width / 1280, height/ 720)
    love.window.setMode(width, height, {resizable = true, centered = true, highdpi = true, vsync = 0}) 
    love.window.setTitle("Purple Error")
    font = love.graphics.newFont("asset/BuilderSans-Medium-500.ttf", 40, "normal", 20)
    -- random variable table for confusing names
    rvar = {}

    screen = {}
    gamestate = {dialogue = false}
    render = {}
    dialogue = {}

    dialogue.box = love.graphics.newImage("asset/textbox.png")

    -- disgusting 'temporary' data
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

    dialoguedata = {
        test = {
            {"testguy","hi"},
            {"testguy","helo"},
            {"testguy","bye\nonto dialogue test2"},
            {"test2"}
        },
        test2 = {
            {"testbro","success"},
            {"testbro","multiselection test"},
            {"quiz host","[insert quiz here]","\n\n← cat","\n\n→ car","1"},
            {"testbro","test completed"},
            {"testbro","bye forever"},
            {"return"}
        }
    }
    
    
    leveldata = {
        GrassLands = {
            sky = "grass.png",

        },
    }

    table.save(leveldata, "level data.lua")
    loadlevel("GrassLands")
end

function loadlevel(level)
    local data = leveldata[level]
    local sky = data.sky
    render.sky = love.graphics.newImage("asset/" .. sky)
    rvar.w, rvar.h = render.sky:getDimensions()
    rvar.w, rvar.h = 1/rvar.w * 1280, 1/rvar.h * 720
end

function loaddialogue(id)
    gamestate.dialogue = true
    dialogue.data = dialoguedata[id]
    dialogue.count = 0
    table.save(dialogue.data, "level data.lua")
    nextdialogue()
end

function nextdialogue(choice2)
    gamestate.choice = false
    local black = {0,0,0}

    if choice2 then
        dialogue.count = dialogue.count + dialogue.data[dialogue.count][5]
    else
        dialogue.count = dialogue.count + 1
    end

    local data = dialogue.data[dialogue.count]
    if #data == 1 then
        if data [1] == "return" then
            gamestate.dialogue = false
            return
        end

        loaddialogue(data[1])
        return
    end

    dialogue.guy = love.graphics.newText(font, {black, data[1]})
    dialogue.text = love.graphics.newText(font, {black, data[2]})
    dialogue.choice1 = love.graphics.newText(font, {black, data[3]})
    dialogue.choice2 = love.graphics.newText(font, {black, data[4]})

    if data[4] then
        gamestate.choice = true
    end
end

function love.keypressed(key)

    local function keys(...)
        local KEYS = {...}

        for i = 1, #KEYS do
            if key == KEYS[i] then
                return true
            end
        end

        return false
    end

    if keys("w", "a", "s", "d", "up", "left", "down", "right") then
        wasd = key
    end

    if keys("escape") then
        local isfullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(isfullscreen, "desktop")
    end

    if keys("\\") then
        love.event.quit()
    end

    if keys("p") then
        loaddialogue("test")
    end

    if gamestate.dialogue then
        if gamestate.choice then
            if keys("left") then
                nextdialogue()
            elseif keys("right") then
                nextdialogue(true)
            end
        elseif keys("e") then
            nextdialogue()
        end
    end
end

function love.resize(w, h)
    width, height = w, h
    local aspectx, aspecty = w / 1280, h / 720
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
    -- world stuff here
    love.graphics.push()

    love.graphics.scale(screenscale, screenscale)
    love.graphics.translate(screen.x, screen.y)



    love.graphics.pop()

    -- UI/background stuff here
    love.graphics.push()

    love.graphics.scale(screenscale, screenscale)

    -- draw sky
    love.graphics.draw(render.sky, 0, 0, 0, rvar.w, rvar.h)

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.print("pre-alpha stage, everything sucks and\n     everything you see will change", 280, 50, 0, 3, 3)
    love.graphics.setColor(1,1,1,1)

    -- dialogue
    if gamestate.dialogue then
        love.graphics.draw(dialogue.box, 338, 480,0,1.5,1.5)
        love.graphics.draw(dialogue.guy, 380, 420,0,1,1)
        love.graphics.draw(dialogue.text, 380, 510,0,1,1)
        love.graphics.draw(dialogue.choice1, 380, 510,0,1,1)
        love.graphics.draw(dialogue.choice2, 650, 510,0,1,1)
    end

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
        }
        for index,value in ipairs(debugvalues) do
            love.graphics.print(value, 20, index * 20)
        end
    end

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