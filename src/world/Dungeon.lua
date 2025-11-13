--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Dungeon = Class{}

function Dungeon:init(player)
    self.player = player

    -- container for static dungeon rooms (unused here)
    self.rooms = {}

    -- current room we're in
    self.currentRoom = Room(self.player)

    -- next room when shifting
    self.nextRoom = nil

    -- camera translation values during shifting
    self.cameraX = 0
    self.cameraY = 0
    self.shifting = false

    -- events to trigger room shifting
    Event.on('shift-left', function()  self:beginShifting(-VIRTUAL_WIDTH, 0) end)
    Event.on('shift-right', function() self:beginShifting(VIRTUAL_WIDTH, 0) end)
    Event.on('shift-up', function()    self:beginShifting(0, -VIRTUAL_HEIGHT) end)
    Event.on('shift-down', function()  self:beginShifting(0, VIRTUAL_HEIGHT) end)
end

-- Begin shifting camera to next room
function Dungeon:beginShifting(shiftX, shiftY)
    self.shifting = true
    self.nextRoom = Room(self.player)

    -- open doors in next room temporarily
    for k, doorway in pairs(self.nextRoom.doorways) do
        doorway.open = true
    end

    self.nextRoom.adjacentOffsetX = shiftX
    self.nextRoom.adjacentOffsetY = shiftY

    local playerX, playerY = self.player.x, self.player.y

    if shiftX > 0 then
        playerX = VIRTUAL_WIDTH + (MAP_RENDER_OFFSET_X + TILE_SIZE)
    elseif shiftX < 0 then
        playerX = -VIRTUAL_WIDTH + (MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE) - TILE_SIZE - self.player.width)
    elseif shiftY > 0 then
        playerY = VIRTUAL_HEIGHT + (MAP_RENDER_OFFSET_Y + self.player.height / 2)
    else
        playerY = -VIRTUAL_HEIGHT + MAP_RENDER_OFFSET_Y + (MAP_HEIGHT * TILE_SIZE) - TILE_SIZE - self.player.height
    end

    Timer.tween(1, {
        [self] = {cameraX = shiftX, cameraY = shiftY},
        [self.player] = {x = playerX, y = playerY}
    }):finish(function()
        self:finishShifting()

        -- reset player position to the new room's doorway
        if shiftX < 0 then
            self.player.x = MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE) - TILE_SIZE - self.player.width
            self.player.direction = 'left'
        elseif shiftX > 0 then
            self.player.x = MAP_RENDER_OFFSET_X + TILE_SIZE
            self.player.direction = 'right'
        elseif shiftY < 0 then
            self.player.y = MAP_RENDER_OFFSET_Y + (MAP_HEIGHT * TILE_SIZE) - TILE_SIZE - self.player.height
            self.player.direction = 'up'
        else
            self.player.y = MAP_RENDER_OFFSET_Y + self.player.height / 2
            self.player.direction = 'down'
        end

        -- close doors in the previous room
        for k, doorway in pairs(self.currentRoom.doorways) do
            doorway.open = false
        end

        gSounds['door']:play()
    end)
end

function Dungeon:finishShifting()
    self.player.shots = {}

    -- reset camera and deactivate shifting
    self.cameraX = 0
    self.cameraY = 0
    self.shifting = false

    if gStateMachine.current and gStateMachine.current.leaveRoom then
        gStateMachine.current:leaveRoom()
    end

    -- swap current room with next room
    self.currentRoom = self.nextRoom
    self.nextRoom = nil
    self.currentRoom.adjacentOffsetX = 0
    self.currentRoom.adjacentOffsetY = 0
end

function Dungeon:update(dt)
    if not self.shifting then
        self.currentRoom:update(dt)
    else
        -- still update player animation while shifting rooms
        self.player.currentAnimation:update(dt)
    end
end

function Dungeon:render()
    if self.shifting then
        love.graphics.translate(-math.floor(self.cameraX), -math.floor(self.cameraY))
    end

    self.currentRoom:render()

    if self.nextRoom then
        self.nextRoom:render()
    end
end
