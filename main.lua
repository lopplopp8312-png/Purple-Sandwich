local savetable = require("lib.tablesave")
local floor = math.floor



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
    placeholdermusic = love.audio.newSource("asset/Purple Sandwich.ogg", "stream")
    placeholdermusic:setLooping(true)
    placeholdermusic:play()

    playerdata = table.load("player data.lua")
    if not playerdata then
        -- initialise save file
    end

    -- random variable table for confusing names
    rvar = {}

    screen = {}
    gamestate = {}
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
            {"quiz host","[insert quiz here]","\n\n← cat","\n→ restart\nconversation","4"},
            {"testbro","you chose cat"},
            {"testbro","ok bye forever"},
            {"return"},
            {"quiz host","ok"},
            {"test2"},
        }
    }
    
    dialoguecolor = {
        "testguy", {0,1,1},
        "testbro", {1,0,1},
        "quiz host", {1,1,0},
    }
    
    leveldata = {
        GrassLands = {
            sky = "grass.png",
            -- cuboids
            objects = {
                -- texture name, xyz, scale xyz
                {
                "squ.png", 0, 1, 0, 2, 1, 1
                },
                {
                "grass3.png", 0, 0, -1, 2, 1, 1
                },
            },
        },
    }

    table.save(leveldata, "level data.lua")
    loadlevel("GrassLands")
end

function love.quit()
    playerdata.timeplayed = playerdata.timeplayed + timer
    playerdata.timesopened = playerdata.timesopened + 1
    table.save(playerdata, "player data.lua")
end

function loadlevel(level)
    levelgraphics = {}
    local data = leveldata[level]
    local objects = data.objects
    local sky = data.sky
    render.sky = love.graphics.newImage("asset/" .. sky)
    rvar.w, rvar.h = render.sky:getDimensions()
    rvar.w, rvar.h = 1/rvar.w * 1280, 1/rvar.h * 720

    for index = 1, #objects do
        local stuff = objects[index]
        local texture, x, y, z, sx, sy, sz =
        stuff[1], stuff[2],stuff[3],stuff[4],stuff[5],stuff[6],stuff[7]

        local function makeleftwall(x,y,z)
            local leftwall = love.math.newTransform()
            leftwall:translate(35,106)
            leftwall:shear(0,0.5)
            leftwall:translate(y*150+280,-z*150)
            leftwall:translate(x*150,x*-150)
            return leftwall
        end

        local function makerightwall(x,y,z)
            local rightwall = love.math.newTransform()
            rightwall:translate(634,412)
            rightwall:shear(0,-0.5)
            rightwall:translate(-x*150-20,z*150)
            rightwall:translate(y*-150,y*-150)
            return rightwall
        end

        local function makerhombus(x,y,z)
            local rhombus = love.math.newTransform()
            rhombus:translate(640,260)
            rhombus:scale(0.7071, 0.7071)
            rhombus:scale(2, 1)
            rhombus:rotate(0.7853)
            rhombus:translate(y*150,x*150)
            rhombus:translate(-z*150,-z*150)
        return rhombus
        end

        texture = love.graphics.newImage("asset/" .. texture)
        local object = love.graphics.newSpriteBatch(texture, 100)

        for i=x, x+sx-1 do
            for j=y, y+sy-1 do
                object:add(makerhombus(-i,-j,z))
            end
        end

        object:setColor(0.8,0.8,0.8)
        for i=y-1, y+sy-2 do
            for j=z, z-sz+1, -1 do
                object:add(makeleftwall(x,-i,j))
            end
        end
    

        object:setColor(0.4,0.4,0.4)
        for i=x, x+sx-1 do
            for j=-z, sz-z-1 do
                object:add(makerightwall(-i,y,j))
            end
        end

        levelgraphics[index] = object
    end
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
    dialogue.color = {1,1,1}
    rvar.color = false

    if choice2 then
        dialogue.count = dialogue.count + dialogue.data[dialogue.count][5]
    else
        dialogue.count = dialogue.count + 1
    end

    local data = dialogue.data[dialogue.count]

    local guy = data[1]
    for i = 1, #dialoguecolor, 2 do
        if guy == dialoguecolor[i] then
            dialogue.color = dialoguecolor[i+1]
            rvar.color = true
        end
    end

    if #data == 1 then
        if guy == "return" then
            gamestate.dialogue = false
            return
        end

        loaddialogue(guy)
        return
    elseif #data == 2 then
        dialogue.textupdate = true
        dialogue.shown = 0
        dialogue.text = love.graphics.newText(font, {black, ""})
        dialogue.texttext = data[2]
    else
        dialogue.text = love.graphics.newText(font, {black, data[2]})
    end

    dialogue.guy = love.graphics.newText(font, {black, data[1]})
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

    if keys("m") then
        if placeholdermusic:isPlaying() then
            placeholdermusic:stop()
        else
            placeholdermusic:play()
        end
    end

    if gamestate.dialogue then
        if gamestate.choice then
            if keys("left") then
                nextdialogue()
            elseif keys("right") then
                nextdialogue(true)
            end
        elseif keys("e") and not dialogue.textupdate then
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

    -- player
    if love.keyboard.isDown(wasd) then
        if wasd == "w" or wasd == "up" then
            player.vel.x = 1.5
            player.vel.y = 0
        elseif wasd == "a" or wasd == "left" then
            player.vel.x = 0
            player.vel.y = 1.5
        elseif wasd == "s" or wasd == "down" then
            player.vel.x = -1.5
            player.vel.y = 0
        else
            player.vel.x = 0
            player.vel.y = -1.5
        end
    else
        player.vel.x = 0
        player.vel.y = 0
    end

    player.pos.x = player.pos.x + player.vel.x * dt
    player.pos.y = player.pos.y + player.vel.y * dt

    screen.x = player.pos.x * -150 + player.pos.y * 150
    screen.y = player.pos.x * 75 + player.pos.y * 75

    -- dialogue
    if dialogue.textupdate then
        dialogue.shown = dialogue.shown + 60 * dt
        local text = dialogue.texttext
        text = text:sub(1, floor(dialogue.shown))
        
        if floor(dialogue.shown) > #text then
            dialogue.textupdate = false
        else
            dialogue.text:set({{0,0,0}, text})
        end
    end
end

function love.draw()
    -- world stuff here
    love.graphics.push()

    love.graphics.scale(screenscale, screenscale)
    love.graphics.translate(screen.x, screen.y)

    for i=1, #levelgraphics do
        love.graphics.draw(levelgraphics[i])
    end

    love.graphics.pop()

    -- UI/background stuff here
    love.graphics.push()

    love.graphics.scale(screenscale, screenscale)

    -- draw sky
    -- love.graphics.draw(render.sky, 0, 0, 0, rvar.w, rvar.h)

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.print("pre-alpha stage, everything sucks and\n     everything you see will change", 280, 50, 0, 3, 3)
    love.graphics.setColor(1,1,1,1)

    -- dialogue
    if gamestate.dialogue then
        love.graphics.setColor(dialogue.color)
        love.graphics.draw(dialogue.box, 338, 480,0,1.5,1.5)
        love.graphics.setColor(1,1,1)

        love.graphics.draw(dialogue.guy, 380, 420,0,1,1)
        love.graphics.draw(dialogue.text, 380, 510,0,1,1)
        love.graphics.draw(dialogue.choice1, 380, 510,0,1,1)
        love.graphics.draw(dialogue.choice2, 650, 510,0,1,1)
    end

     -- debug
    if debug then
        local x, y = love.mouse.getPosition()
        x, y = floor(x/screenscale), floor(y/screenscale)
        debugvalues = {
           "fps: " .. fps,
            "timer: " .. timer,
            "screenscale: " .. screenscale,
            "wasd : " .. wasd,
            "posx: " .. player.pos.x,
            "posy: " .. player.pos.y,
            "posz: " .. player.pos.z,
            "test: " .. 1,
            "test: " .. 1,
            "testdata: " .. x,
            "testdata: " .. y,
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