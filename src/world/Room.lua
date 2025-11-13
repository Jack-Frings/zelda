--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Room = Class{}

function Room:init(player)
    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT

    -- Tiles
    self.tiles = {}
    self:generateWallsAndFloors()

    -- Entities
    self.entities = {}
    self:generateEntities()

    -- Objects
    self.objects = {}
    self:generateObjects()

    -- Doorways
    self.doorways = {}
    table.insert(self.doorways, Doorway('top', false, self))
    table.insert(self.doorways, Doorway('bottom', false, self))
    table.insert(self.doorways, Doorway('left', false, self))
    table.insert(self.doorways, Doorway('right', false, self))

    -- Reference to player
    self.player = player

    -- Rendering offsets
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0
end

function Room:generateEntities()
    local types = {'skeleton', 'slime', 'bat', 'ghost', 'spider'}

    for i = 1, 10 do
        local type = types[math.random(#types)]
        table.insert(self.entities, Entity{
            animations = ENTITY_DEFS[type].animations,
            walkSpeed = ENTITY_DEFS[type].walkSpeed or 20,
            x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                            VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
            y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                            VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16),
            width = 16,
            height = 16,
            health = 1
        })

        self.entities[i].stateMachine = StateMachine{
            ['walk'] = function() return EntityWalkState(self.entities[i]) end,
            ['idle'] = function() return EntityIdleState(self.entities[i]) end
        }

        self.entities[i]:changeState('walk')
    end
end

function Room:generateObjects()
    local switch = GameObject(
        GAME_OBJECT_DEFS['switch'],
        math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                    VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
        math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
    )

    switch.onCollide = function()
        if switch.state == 'unpressed' then
            switch.state = 'pressed'
            for k, doorway in pairs(self.doorways) do
                doorway.open = true
            end
            gSounds['door']:play()
            return true
        end
        return false
    end

    table.insert(self.objects, switch)
end

function Room:generateWallsAndFloors()
    for y = 1, self.height do
        table.insert(self.tiles, {})
        for x = 1, self.width do
            local id = TILE_EMPTY
            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
            else
                id = TILE_FLOORS[math.random(#TILE_FLOORS)]
            end
            table.insert(self.tiles[y], {id = id})
        end
    end
end

function Room:update(dt)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)

    -- Update entities
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        -- Handle death
        if entity.health <= 0 and not entity.dead then
            entity.dead = true
            self.player.score = self.player.score + 100

            -- Slayer & Pacifist tracking
            if gStateMachine.current.achievementManager then
                gStateMachine.current.achievementManager:increment('Slayer')
                gStateMachine.current.achievementManager:registerKill()
            end
        elseif not entity.dead then
            entity:processAI({room = self}, dt)
            entity:update(dt)
        end

        -- Collision with player
        if not entity.dead and self.player:collides(entity) and not self.player.invulnerable then
            gSounds['hit-player']:play()
            self.player:damage(1)
            self.player:goInvulnerable(1.5)

            -- Survivalist hit counter
            self.player.hitCounter = (self.player.hitCounter or 0) + 1

            if self.player.health == 0 then
                gStateMachine:change('game-over')
            end
        end

        -- Bullets vs entities
        for k, shot in pairs(self.player.shots) do
            if shot:collides(entity) and not entity.dead then
                entity:damage(3)
                gSounds['hit-enemy']:play()
                table.remove(self.player.shots, k)
                k = k - 1

                if entity.health <= 0 and math.random(3) == 1 then
                    local ammo = GameObject(GAME_OBJECT_DEFS['bullet'], entity.x, entity.y)
                    ammo.onCollide = function()
                        self.player.bullets = self.player.bullets + 1
                        for k, objs in pairs(self.objects) do
                            if objs == ammo then
                                table.remove(self.objects, k)
                            end
                        end
                    end
                    table.insert(self.objects, ammo)
                end
            end
        end
    end

    -- Update objects
    for k, object in pairs(self.objects) do
        object:update(dt)
        if self.player:collides(object) then
            object:onCollide()
        end

        for k, shot in pairs(self.player.shots) do
            if shot:collides(object) and object.type == 'switch' then
                local pressed = object:onCollide()
                if pressed then
                    table.remove(self.player.shots, k)
                    k = k - 1
                end
            end
        end
    end
end

function Room:render()
    -- Draw tiles
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
                (x-1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX,
                (y-1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
        end
    end

    -- Doorways
    for k, doorway in pairs(self.doorways) do
        doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    -- Objects
    for k, object in pairs(self.objects) do
        object:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    -- Entities
    for k, entity in pairs(self.entities) do
        if not entity.dead then
            entity:render(self.adjacentOffsetX, self.adjacentOffsetY)
        end
    end

    -- Stencil for player rendering
    love.graphics.stencil(function()
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)

    if self.player then
        self.player:render()
    end

    love.graphics.setStencilTest()
end
