-- this is only for learning Lua and Love2d
-- sorry for spaghetti code
function love.load()
    scene = "welcome"
    nonPlayingFont = love.graphics.setNewFont("upheavtt.ttf", 100)
    playingFont = love.graphics.setNewFont("upheavtt.ttf", 30)
    love.graphics.setFont(nonPlayingFont)
    welcomeText = "START"
    welcomeTextX = (love.graphics.getWidth() - nonPlayingFont:getWidth(welcomeText)) / 2
    welcomeTextY = (love.graphics.getHeight() - nonPlayingFont:getHeight()) / 2
	snake = {}
    desiredDir = {}
    speed = nil
	food = {
        x = 256,
        y = 256
    }
    timer = 0
    dirChangeTrack = {}
    gameSpeed = nil
    love.graphics.setLineWidth(4)
end

function love.update(dt)
    if scene == "playing" then
        timer = timer + dt
        local shouldUpd = timer >= gameSpeed
        local shouldFreeze = false
        if shouldUpd then
            updateHeadDir()
            shouldFreeze = eat()
        end
        if not shouldFreeze then
            for idx, block in ipairs(snake) do
                if shouldUpd then
                    updateSnakeBlock(block)
                    checkIfEatenItself()
                end
                block.act_y = block.act_y - ((block.act_y - block.grid_y) * speed * dt)
                block.act_x = block.act_x - ((block.act_x - block.grid_x) * speed * dt)
            end
        end
        if shouldUpd then
            updateDirChangeTrack()
            updateSankeDirs()
            timer = 0
        end
    end
end

function love.draw()
    if scene == "welcome" then
        love.graphics.print(welcomeText, welcomeTextX, welcomeTextY)
    elseif scene == "playing" then
        love.graphics.setColor(1,1,1)
        local text = "SCORE " .. #snake - 1
        local textX = 960 - playingFont:getWidth(text)
        love.graphics.printf(text, 32, 16, 960, "right")
        love.graphics.setColor(128/255,128/255,128/255)
        for y = 1, 10 do
            for x = 0.5, 15 do
                love.graphics.rectangle("line", x * 64, y * 64, 64, 64)
            end
        end
        for _, block in ipairs(snake) do
            love.graphics.setColor(102/255, 255/255, 102/255)
            love.graphics.rectangle("fill", block.act_x - 32, block.act_y, 64, 64)
            love.graphics.setColor(0/255, 153/255, 51/255)
            love.graphics.rectangle("line", block.act_x - 32, block.act_y, 64, 64)
        end
        love.graphics.setColor(255/255, 255/255, 102/255)
        love.graphics.rectangle("fill", food.x - 32, food.y, 64, 64)
        love.graphics.setColor(204/255, 153/255, 0/255)
        love.graphics.rectangle("line", food.x - 32, food.y, 64, 64)
    elseif scene == "gameover" then
        local text = "GAME OVER\nSCORE " .. #snake - 1 .. "\nRETRY"
        local textX = (love.graphics.getWidth() - nonPlayingFont:getWidth(text)) / 2
        local textY = (love.graphics.getHeight() - nonPlayingFont:getHeight() * 3) / 2
        love.graphics.printf(text, textX, textY, nonPlayingFont:getWidth(text), "center")
    end
end

function love.keypressed(key)
    if scene == "playing" then
        if not desiredDir.shouldSetSec and key == "up" and snake[1].dir ~= "down" or
        key == "down" and snake[1].dir ~= "up" or
        key == "left" and snake[1].dir ~= "right" or
        key == "right" and snake[1].dir ~= "left" then
            desiredDir.first = key
            desiredDir.shouldSetSec = true
        elseif desiredDir.shouldSetSec and (key == "up" or
        key == "down" or
        key == "left" or
        key == "right") then
            desiredDir.sec = key
        end
    end
end

function love.mousepressed(x, y, button, istouch)
   if (scene == "welcome" or scene == "gameover") and button == 1 then
       recreateSnake()
       scene = "playing"
       love.graphics.setFont(playingFont)
   end
end

function recreateSnake()
    snake = {
        {
            grid_x = 512,
            grid_y = 512,
            act_x = 400,
            act_y = 400,
            dir = "up",
        }
    }
    dirChangeTrack = {}
    desiredDir = {
        first = nil,
        sec = nil,
        shouldSetSec = false,
        prev = "up"
    }
    gameSpeed = 0.5
    speed = 10
end

function checkIfEatenItself()
    for i = 2, #snake do
        if snake[i].grid_x == snake[1].grid_x and snake[i].grid_y == snake[1].grid_y then
            scene = "gameover"
            love.graphics.setColor(1,1,1)
            love.graphics.setFont(nonPlayingFont)
        end
    end
end

function updateDirChangeTrack()
    for idx, value in ipairs(dirChangeTrack) do
        if value[1] + 1 <= #snake then
            value[1] = value[1] + 1
        else
            table.remove(dirChangeTrack, idx)
        end
    end
end

function updateSankeDirs()
    for _, value in ipairs(dirChangeTrack) do
        snake[value[1]].dir = value[2]
    end
end

function eat()
    local head = snake[1]
    local newBlock = {
        grid_x = food.x,
        grid_y = food.y,
        act_x = food.x,
        act_y = food.y,
        dir = head.dir
    }
    local canEat = false
    if food.x == head.grid_x and head.dir == "up" then
        if head.grid_y - 64 == food.y or head.grid_y == 64 and food.y == 640 then
            canEat = true
        end
    elseif food.x == head.grid_x and head.dir == "down" then
        if head.grid_y + 64 == food.y or head.grid_y == 640 and food.y == 64 then
            canEat = true
        end
    elseif food.y == head.grid_y and head.dir == "left" then
        if head.grid_x - 64 == food.x or head.grid_x == 64 and food.x == 960 then
            canEat = true
        end
    elseif food.y == head.grid_y and head.dir == "right" then
        if head.grid_x + 64 == food.x or head.grid_x == 960 and food.x == 64 then
            canEat = true
        end
    end
    if canEat then
        table.insert(snake, 1, newBlock)
        local isLookingForFreePos = true
        while isLookingForFreePos do
            food.x = math.random(1, 15) * 64
            food.y = math.random(1, 10) * 64
            local isNewFoodColiding = false
            for idx, block in ipairs(snake) do
                if food.x == block.grid_x and food.y == block.grid_y then
                    isNewFoodColiding = true
                end
            end
            if not isNewFoodColiding then
                isLookingForFreePos = false
            end
        end
        if gameSpeed >= 0.01 then
            gameSpeed = gameSpeed - 0.015
            speed = speed + 1
        end
    end
    return canEat
end

function updateHeadDir()
    local head = snake[1]
    local k = "prev"
    if desiredDir.sec then k = "sec" end
    if desiredDir.first then k = "first" end
    head.dir = desiredDir[k]
    desiredDir[k] = nil
    if k ~= "prev" then
        table.insert(dirChangeTrack, 1, {1, head.dir})
    end
    desiredDir.prev = head.dir
    desiredDir.shouldSetSec = false
end

function updateSnakeBlock(currBlock)
    if currBlock.dir == "up" then
        if currBlock.grid_y == 64 then
            currBlock.act_y = 704
            currBlock.grid_y = 640
        else
            currBlock.grid_y = currBlock.grid_y - 64
        end
    elseif currBlock.dir == "down" then
        if currBlock.grid_y == 640 then
            currBlock.act_y = 0
            currBlock.grid_y = 64
        else
            currBlock.grid_y = currBlock.grid_y + 64
        end
    elseif currBlock.dir == "left" then
        if currBlock.grid_x == 64 then
            currBlock.act_x = 1024
            currBlock.grid_x = 960
        else
            currBlock.grid_x = currBlock.grid_x - 64
        end
    elseif currBlock.dir == "right" then
        if currBlock.grid_x == 960 then
            currBlock.act_x = 0
            currBlock.grid_x = 64
        else
            currBlock.grid_x = currBlock.grid_x + 64
        end
    end
end
