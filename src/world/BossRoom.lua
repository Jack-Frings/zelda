--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

BossRoom = Class{}

function BossRoom:init(player, shiftX, shiftY)
    self.is_boss_room = true 
    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT

    self.tiles = {}
    self:generateWallsAndFloors()

    self.entities = {}
    self:spawn_boss()

    self.total_health = 40

    self.killed_bosses = false

    self.objects = {}


    -- doorways that lead to other dungeon rooms
    self.doorways = {}
    if shiftX == -VIRTUAL_WIDTH then 
        table.insert(self.doorways, Doorway('right', false, self))
    elseif shiftX == VIRTUAL_WIDTH then 
        table.insert(self.doorways, Doorway('left', false, self))
    elseif shiftY == -VIRTUAL_HEIGHT then 
        table.insert(self.doorways, Doorway('bottom', false, self))
    elseif shiftY == VIRTUAL_HEIGHT then 
        table.insert(self.doorways, Doorway('top', false, self))
    end

    -- reference to player for collisions, etc.
    self.player = player
    self.player.health = 6

    -- used for centering the dungeon rendering
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y

    -- used for drawing when this room is the next room, adjacent to the active
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0
end

--[[
    Generates the walls and floors of the room, randomizing the various varieties
    of said tiles for visual variety.
]]
function BossRoom:spawn_boss()
    for i = 1, 2 do 
        table.insert(self.entities, Entity {
            animations = ENTITY_DEFS['slime'].animations, 
            walkSpeed = 120,

            -- ensure X and Y are within bounds of the map
            x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
            y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16),
            
            width = 32,
            height = 32,

            health = 20
        })

        self.entities[i].stateMachine = StateMachine {
            ['vertical'] = function() return BossVerticalState(self.entities[i]) end,
            ['horizontal'] = function() return BossHorizontalState(self.entities[i]) end
        }

        self.entities[i]:changeState('vertical')
    end
end

function BossRoom:generateWallsAndFloors()
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
            
            -- random left-hand walls, right walls, top, bottom, and floors
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
            
            table.insert(self.tiles[y], {
                id = id
            })
        end
    end
end

function BossRoom:update(dt)
    if self.entities[1].dead and self.entities[2].dead and not self.killed_bosses then 
        self.player.score = self.player.score + 2000
        self.killed_bosses = true 
    end 
    -- don't update anything if we are sliding to another room (we have offsets)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)

    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        if entity.health <= 0 and not entity.dead then 
            self.player.score = self.player.score + 100
        end

        if entity.health <= 0 then
            entity.dead = true
        elseif not entity.dead then
            entity:processAI({room = self}, dt)
            entity:update(dt)
        end

        -- collision between the player and entities in the room
        if not entity.dead and self.player:collides(entity) and not self.player.invulnerable then
            gSounds['hit-player']:play()
            self.player:damage(1)
            self.player:goInvulnerable(1.5)

            if self.player.health == 0 then
                gStateMachine:change('game-over')
            end
        end

        --collision between enemies and bullets in the room
        for k, shot in pairs(self.player.shots) do
            if shot:collides(entity) and not entity.dead then
                entity:damage(3) --gun does 3 damage, change if u want
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

    for k, object in pairs(self.objects) do
        object:update(dt)

        -- trigger collision callback on object
        if self.player:collides(object) then
            object:onCollide()
        end

        --bullet can open switch (advanced speedrun tech)
        for k, shot in pairs(self.player.shots) do 
            if shot:collides(object) and object.type == 'switch' then
                local button_unpressed = object:onCollide()
                if button_unpressed then --don't remove bullet if button is pressed
                    table.remove(self.player.shots, k) 
                    k = k - 1
                end
            end
        end
    end
end


function BossRoom:render()
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX, 
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
        end
    end

    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly
    for k, doorway in pairs(self.doorways) do
        doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, object in pairs(self.objects) do
        object:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, entity in pairs(self.entities) do
        if not entity.dead then entity:scale_render(self.adjacentOffsetX, self.adjacentOffsetY, 2) end
    end
    if not self.killed_bosses then 
        health_bar_fraction = (self.entities[1].health + self.entities[2].health) / self.total_health
        print(health_bar_fraction)
        love.graphics.printf("Slime Bosses", 0, 0, VIRTUAL_WIDTH, "left")
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 55, 2, math.floor(270 * health_bar_fraction), 10)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setFont(gFonts['medium'])
        love.graphics.printf("YOU WIN!", 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
        love.graphics.printf("THANKS FOR SAVING THE KINGDOM!", 0, VIRTUAL_HEIGHT / 2 + 20, VIRTUAL_WIDTH, "center")
    end

    -- stencil out the door arches so it looks like the player is going through
    love.graphics.stencil(function()
        
        -- left
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- right
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- top
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        
        --bottom
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)
    
    if self.player then
        self.player:render()
    end

    love.graphics.setStencilTest()
end
