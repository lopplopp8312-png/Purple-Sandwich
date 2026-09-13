---@diagnostic disable: lowercase-global
---@diagnostic disable: param-type-mismatch
local debug = true
local zoomlvl = 1
speedalongtangent = 0
dangle = 0
planetx = 0
planety = 0
testobjects = {}
size = 3

-- goodluck to whoever reading this

local function dotproduct(ax, ay, bx, by)
    return ax * bx + ay * by
end

local function getgroundheight(angle)
    local heightmap = heightmap
    local n = #heightmap
    local tau = 2*math.pi
    angle = angle + tau/4

    local function index(x)
        return heightmap[((x) % n) + 1]
    end

    local function catmullrom(p0,p1,p2,p3, t)
        local t2 = t * t
        local t3 = t2 * t
        return 0.5 * (
            2 * p1
            + (-p0 + p2) * t
            + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
            + (-p0 + 3 * p1 - 3 * p2 + p3) * t3
        )
    end

    local p0 = index(math.floor(((angle/tau)*n) - 1))
    local p1 = index(math.floor(((angle/tau)*n)))
    local p2 = index(math.floor(((angle/tau)*n) + 1))
    local p3 = index(math.floor(((angle/tau)*n) + 2))

    local h = catmullrom(p0,p1,p2,p3, (angle/tau)*n % 1)

    return h
end

local function loadheightmap()
    local heightmap = heightmap
    local x,y = planetx, planety
    local smoothness = 60
    local tau = 2*math.pi

    for i = 0, tau, tau/smoothness do
        local h = getgroundheight(i)

        local angle = i
        table.insert(planetvertex,
            h * math.cos(angle) + x
        )
        table.insert(planetvertex,
            h * math.sin(angle) - y
        )
    end

    planettriangles = love.math.triangulate(planetvertex)

    planetbody = love.physics.newBody(world, x, y, "static")

    local planetpoints = planetvertex

    planetshape = love.physics.newChainShape(false, planetpoints)
    planetfixture = love.physics.newFixture(planetbody, planetshape)
    planetfixture:setFriction(0.5)
    planetfixture:setUserData("Planet")

    --for outline

    table.insert(planetvertex, planetvertex[1])
    table.insert(planetvertex, planetvertex[2])
    
end

local function distance(x,y)
    return math.sqrt(x^2 + y^2)
end

local function calcG(x, y, px, py, strength, dt)
    return (strength * dt) / (((x - px)/700)^2 + ((y - py)/700)^2)
end

local function normal(x, y, planetx, planety)
    local x, y = x - planetx, y - planety
    local angle = math.atan2(y, x)
    local nx, ny = math.cos(angle), math.sin(angle)
    return angle, nx, ny
end

local function applygravity(body)
    local x, y = body:getPosition()
    local mass = body:getMass()
    local angle, nx, ny = normal(x, y, planetx, planety)
    local bigG = calcG(x, y, planetx, planety, 400, 1)

    body:applyForce(nx*-bigG*mass, ny*-bigG*mass)
end

local nextdialogue, loaddialogue

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

function loaddialogue(id)
    flags.dialogue = true
    dialogue.data = dialoguedata[id]
    dialogue.count = 0
    table.save(dialogue.data, "level data.lua")
    return nextdialogue()
end

local beginContact, endContact, preSolve, postSolve

function love.load()
    timer = 0
    width, height = love.window.getDesktopDimensions()
    width, height = width*0.8, height*0.8
    screenscale = math.max(width / 1280, height/ 720)
    love.window.setMode(width, height, {resizable = true, centered = true, highdpi = true, vsync = false}) 
    love.window.setTitle("Purple Error")
    font = love.graphics.newFont("asset/BuilderSans-Medium-500.ttf", 40, "normal", 20)
    placeholdermusic = love.audio.newSource("asset/Purple Sandwich.ogg", "stream")
    placeholdermusic:setLooping(true)
    placeholdermusic:play()
    placeholderguy = love.graphics.newImage("asset/guy.png")
    testimage = love.graphics.newImage("asset/cat.jfif")

    vars = {}

    flags = {}
    dialogue = {}
    screen = {}
    player = {
        size = 30,
        dir = 0,
        ground = false,
    }

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
        -- in pixels
        --587,610,601,596,604,605,600,582,595,607,619,596,590,605,584,602,599,620,601,591,583,602,612,588,612,600,603,586,594,609,603,600,589,615,594,599
        600,600,600,600,600,600,600,600,600,600,600,600,600,600,1000,600,600,600,600,600
    }
    planetvertex = {}
    planettriangles = {}



    screen.x, screen.y = 0, 0

    --physics

    love.physics.setMeter(50)

    world = love.physics.newWorld(0,0, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    for i = 1, 2000 do
        local x, y
        repeat
            x = math.random()*2 - 1
            y = math.random()*2 - 1
            local c = distance(x, y)
        until c <= 1
        local radius = 200
        x, y = x*radius, y*radius
        testobjects[i] = {}
        testobjects[i].body = love.physics.newBody(world,x, -1000 + y, "dynamic")
        testobjects[i].shape = love.physics.newCircleShape(size)
        testobjects[i].fixture = love.physics.newFixture(testobjects[i].body, testobjects[i].shape)
        testobjects[i].fixture:setRestitution(1)
        testobjects[i].fixture:setFriction(0)
        testobjects[i].body:setLinearVelocity(0,-400)
    end
    
    loadheightmap()

    -- player
    player.body = love.physics.newBody(world, 0, -700, "dynamic")
    player.shape = love.physics.newCircleShape(player.size)
    player.fixture = love.physics.newFixture(player.body, player.shape, 0.5)
    player.fixture:setFriction(10)
    player.fixture:setUserData("Player")
end


function love.quit()
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

    local aspecttruthness = math.abs(aspecty - aspectx) > 0.05

    if aspecttruthness then
        local buttons = {"OK", "Cancel"}
        local n = love.window.showMessageBox("GAME PAUSED!!!! WINDOW IS NOT 16:9",
            "if you wanted to fullscreen kindly press OK.\nElse please resize the window manually to 16:9.\n\ngraphics will break if it stays like this",
            buttons, "warning")

        --fullscreen
        if n == 1 then
            local w, h = love.window.getDesktopDimensions()
            local aspectx, aspecty = w / 1280, h / 720

            local aspecttruthness = math.abs(aspecty - aspectx) > 0.05
            if not aspecttruthness then
                love.window.setFullscreen(true, "desktop")
            else
                --fallback
                love.window.showMessageBox("sorry","your desktop is a weird shape\nplease the window resize manually\nim doing my best ok?", "info")
            end
        end
    end
end

function beginContact(a, b, coll)
    local dataA = a:getUserData()
    local dataB = b:getUserData()

    local function contact(a, b)
        if (dataA == b and dataB == a) or (dataA == a and dataB == b) then
            return true
        end
        return false
    end

    if contact("Player", "Planet") then
        player.ground = true
    end
end

function endContact(a, b, coll)
    local dataA = a:getUserData()
    local dataB = b:getUserData()

    local function contact(a, b)
        if (dataA == b and dataB == a) or (dataA == a and dataB == b) then
            return true
        end
        return false
    end

    if contact("Player", "Planet") then
        player.ground = false
    end
end

function preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end

function love.update(dt)
    fps = math.floor(1 / dt)
    timer = timer + dt

    -- lag detection
    if dt > 0.016 then
        dt = 0.016
        flags.slowed = true
    else
        flags.slowed = false
    end

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


    if love.keyboard.isDown("up") then
        screen.y = screen.y + 1000*dt
    end
    if love.keyboard.isDown("down") then
        screen.y = screen.y - 1000*dt
    end
    if love.keyboard.isDown("left") then
        screen.x = screen.x + 1000*dt
    end
    if love.keyboard.isDown("right") then
        screen.x = screen.x - 1000*dt
    end
    if love.keyboard.isDown("=") then
        zoomlvl = zoomlvl + dt
    end
    if love.keyboard.isDown("-") then
        zoomlvl = zoomlvl - dt
    end
    zoom = math.exp(zoomlvl)

    local a, d = love.keyboard.isDown("a"), love.keyboard.isDown("d")

    if d then
        player.dir = 10
    end
    if a then
        player.dir = -10
    end
    if (a and d) or not (a or d) then
        player.dir = 0
    end

    player.body:setAngularVelocity(player.dir)

    --test
    for i, n in ipairs(testobjects) do
        applygravity(n.body)
    end

    applygravity(player.body)

    world:update(dt)
end





function love.draw()
    love.graphics.scale(screenscale, screenscale)
    local px, py = player.body:getPosition()
    local angle

    -- game stuff
    love.graphics.push()

    love.graphics.translate(640,360)
    love.graphics.scale(zoom,zoom)
    love.graphics.translate(screen.x, screen.y)
    if true then
        angle = normal(px, py, planetx, planety) + math.pi / 2
        love.graphics.rotate(-angle)
        love.graphics.translate(-px, -py)
    end

    --planet
    --atmosphere
    local atmosphere = 850
    for i = 0, 20 do
        love.graphics.setColor(0.3,0.6,1,0.05+i/80)
        love.graphics.circle("fill", planetx, -planety, atmosphere-i*10)
    end

    --terrain
    love.graphics.setColor(0,0.8,0)

    for i, triangle in ipairs(planettriangles) do
        love.graphics.polygon("fill", triangle)
    end

    love.graphics.setColor(0,0.6,0)

    love.graphics.setLineWidth(4)
    love.graphics.line(planetvertex)

    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(1)

    for i, n in ipairs(testobjects) do
        local x, y = n.body:getPosition()
        love.graphics.circle("line", x, y, size)
    end

    --player
    local angle = player.body:getAngle()
    love.graphics.circle("fill", px, py, player.size)
    love.graphics.draw(placeholderguy, px, py, angle, 0.03, 0.03, 1024, 1024)
    
    love.graphics.pop()


    -- UI/background stuff here
    love.graphics.push()

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.print("peepeepoopoo", 280, 50, 0, 3, 3)
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
           "angluar: " .. player.body:getAngularVelocity(),
           "ground?: " .. tostring(player.ground)
        }

        for index,value in ipairs(debugvalues) do
            love.graphics.print(value, 20, index * 20)
        end
    end

    if flags.slowed then
        love.graphics.print("lag detected. game slowed down.", 5, 700)
    end

    love.graphics.pop()
end
