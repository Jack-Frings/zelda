--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerWalkState = Class{__includes = EntityWalkState}

function PlayerWalkState:init(player, dungeon)
    self.entity = player
    self.dungeon = dungeon

    -- render offset for spaced character sprite; negated in render function of state
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

-- mright, mleft, mup, mdown control if player is moving, 'direction' controls player sprite and NPC movement
function PlayerWalkState:update(dt)
    if (love.keyboard.isDown('left') or love.keyboard.isDown('a')) and not self.entity.mright then
        self.entity.mleft = true
        self.entity.direction = 'left'
        self.entity:changeAnimation('walk-left')
    else
        self.entity.mleft = false
    end

    if (love.keyboard.isDown('right') or love.keyboard.isDown('d')) and not self.entity.mleft then
        self.entity.mright = true
        self.entity.direction = 'right'
        self.entity:changeAnimation('walk-right')
    else
        self.entity.mright = false
    end

    if (love.keyboard.isDown('up') or love.keyboard.isDown('w')) and not self.entity.mdown then
        self.entity.mup = true
        if not self.entity.mright and not self.entity.mleft then
            self.entity.direction = 'up'
            self.entity:changeAnimation('walk-up')
        end
    else
        self.entity.mup = false
    end

    if (love.keyboard.isDown('down') or love.keyboard.isDown('s')) and not self.entity.mup then
        self.entity.mdown = true
        if not self.entity.mright and not self.entity.mleft then
            self.entity.direction = 'down'
            self.entity:changeAnimation('walk-down')
        end
    else
        self.entity.mdown = false
    end

    if not love.keyboard.isDown('up') and not love.keyboard.isDown('down') and not love.keyboard.isDown('right') and not love.keyboard.isDown('left') and not love.keyboard.isDown('w') and not love.keyboard.isDown('s') and not love.keyboard.isDown('a') and not love.keyboard.isDown('d') then -- great line of code
        self.entity:changeState('idle')
    end

    if love.keyboard.wasPressed('space') then
        self.entity:changeState('swing-sword')
    end

    -- perform base collision detection against walls
    EntityWalkState.update(self, dt)

    -- if we bumped something when checking collision, check any object collisions
    if self.bumped then
        if self.entity.mleft == true and self.entity.x <= 50 then
            
            -- temporarily adjust position into the wall, since bumping pushes outward
            self.entity.x = self.entity.x - PLAYER_WALK_SPEED * dt
            
            -- check for colliding into doorway to transition
            for k, doorway in pairs(self.dungeon.currentRoom.doorways) do
                if self.entity:collides(doorway) and doorway.open then

                    -- shift entity to center of door to avoid phasing through wall
                    self.entity.y = doorway.y + 4

                    Event.dispatch('shift-left')
                end
            end

            -- readjust
            self.entity.x = self.entity.x + PLAYER_WALK_SPEED * dt
        elseif self.entity.mright == true and self.entity.x >= VIRTUAL_WIDTH-50 then
            
            -- temporarily adjust position
            self.entity.x = self.entity.x + PLAYER_WALK_SPEED * dt
            
            -- check for colliding into doorway to transition
            for k, doorway in pairs(self.dungeon.currentRoom.doorways) do
                if self.entity:collides(doorway) and doorway.open then

                    -- shift entity to center of door to avoid phasing through wall
                    self.entity.y = doorway.y + 4

                    Event.dispatch('shift-right')
                end
            end

            -- readjust
            self.entity.x = self.entity.x - PLAYER_WALK_SPEED * dt
        elseif self.entity.mup == true then
            
            -- temporarily adjust position
            self.entity.y = self.entity.y - PLAYER_WALK_SPEED * dt
            
            -- check for colliding into doorway to transition
            for k, doorway in pairs(self.dungeon.currentRoom.doorways) do
                if self.entity:collides(doorway) and doorway.open then

                    -- shift entity to center of door to avoid phasing through wall
                    self.entity.x = doorway.x + 8
                    self.entity.direction = 'up'
                    Event.dispatch('shift-up')
                end
            end

            -- readjust
            self.entity.y = self.entity.y + PLAYER_WALK_SPEED * dt
        elseif self.entity.mdown == true then
            
            -- temporarily adjust position
            self.entity.y = self.entity.y + PLAYER_WALK_SPEED * dt
            
            -- check for colliding into doorway to transition
            for k, doorway in pairs(self.dungeon.currentRoom.doorways) do
                if self.entity:collides(doorway) and doorway.open then

                    -- shift entity to center of door to avoid phasing through wall
                    self.entity.x = doorway.x + 8
                    self.entity.direction = 'down'
                    Event.dispatch('shift-down')
                end
            end

            -- readjust
            self.entity.y = self.entity.y - PLAYER_WALK_SPEED * dt
        end
    end
end