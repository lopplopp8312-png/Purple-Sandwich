local savetable = require("lib.tablesave")

-- goodluck to whoever reading this (lazy to document everything / brain hurt)



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


    -- random variable table for confusing names
    vars = {}

    flags = {}
    dialogue = {}

    dialogue.box = love.graphics.newImage("asset/textbox.png")

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

    heightmap = {
        -- pixels
        13, 5, 63, 53, 92, 75, 86, 80, 23, 32
    }

    planetvertex = {}
    planettriangles = {}

    loadheightmap()

end


function love.quit()
end


function loadheightmap()
    local heightmap = heightmap
    local x,y = 0,0

    for i = 1, #heightmap do
        local height = heightmap[i]
        local angle = (2 * math.pi * -i / #heightmap) + math.pi
        table.insert(planetvertex,
            height * math.sin(angle)
        )
        table.insert(planetvertex,
            height * math.cos(angle)
        )
    end

    planettriangles = love.math.triangulate(planetvertex)
end


function loaddialogue(id)
    flags.dialogue = true
    dialogue.data = dialoguedata[id]
    dialogue.count = 0
    table.save(dialogue.data, "level data.lua")
    nextdialogue()
end


function nextdialogue(choice2)
    flags.choice = false
    local black = {0,0,0}
    dialogue.color = {1,1,1}
    vars.color = false

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
            vars.color = true
        end
    end

    if #data == 1 then
        if guy == "return" then
            flags.dialogue = false
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
        flags.choice = true
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

    if flags.dialogue then
        if flags.choice then
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

    -- dialogue
    if dialogue.textupdate then
        dialogue.shown = dialogue.shown + 60 * dt
        local text = dialogue.texttext
        text = text:sub(1, math.floor(dialogue.shown))
        
        if math.floor(dialogue.shown) > #text then
            dialogue.textupdate = false
        else
            dialogue.text:set({{0,0,0}, text})
        end
    end
end

function love.draw()
    love.graphics.scale(screenscale, screenscale)
    -- game stuff
    love.graphics.push()

    love.graphics.translate(640,360)

    love.graphics.push()

        love.graphics.setColor(0,0.8,0)

        for i, triangle in ipairs(planettriangles) do
            love.graphics.polygon("fill", triangle)
        end

    love.graphics.pop()

    love.graphics.pop()

    -- UI/background stuff here
    love.graphics.push()

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.print("pre-alpha stage, everything sucks and\n     everything you see will change", 280, 50, 0, 3, 3)
    love.graphics.setColor(1,1,1,1)

    -- dialogue
    if flags.dialogue then
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
        x, y = math.floor(x/screenscale), math.floor(y/screenscale)
        debugvalues = {
           "fps: " .. fps,
            "timer: " .. timer,
            "screenscale: " .. screenscale,
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