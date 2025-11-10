--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

BossHorizontalState = Class{__includes = BaseState}

function BossHorizontalState:init(entity, dungeon)
    self.entity = entity

    self.dungeon = dungeon

    if self.entity.x < VIRTUAL_WIDTH / 2 then 
        self.entity.direction = "right"
    else 
      self.entity.direction = "left"
    end

    self.entity:changeAnimation("walk-" .. self.entity.direction)

    -- keeps track of whether we just hit a wall
    self.bumped = false
end

function BossHorizontalState:update(dt)
    
    -- assume we didn't hit a wall
    self.bumped = false

    -- player movement variables for diagonal movement (moveright, moveleft, moveup, movedown)
    if self.entity.mright and not self.entity.mleft then
        if self.entity.mup or self.entity.mdown then
            self.entity.x = self.entity.x + (self.entity.walkSpeed/math.sqrt(2))*dt
        else
            self.entity.x = self.entity.x + self.entity.walkSpeed * dt
        end

        if self.entity.x + self.entity.width >= VIRTUAL_WIDTH - TILE_SIZE * 2 then
            self.entity.x = VIRTUAL_WIDTH - TILE_SIZE * 2 - self.entity.width
            self.bumped = true
        end
    end
    if self.entity.mleft and not self.entity.mright then
        if self.entity.mup or self.entity.mdown then
            self.entity.x = self.entity.x - (self.entity.walkSpeed/math.sqrt(2))*dt
        else
            self.entity.x = self.entity.x - self.entity.walkSpeed * dt
        end

        if self.entity.x <= MAP_RENDER_OFFSET_X + TILE_SIZE then 
            self.entity.x = MAP_RENDER_OFFSET_X + TILE_SIZE
            self.bumped = true
        end
    end
    if self.entity.mup and not self.entity.mdown then
        if self.entity.mright or self.entity.mleft then
            self.entity.y = self.entity.y - (self.entity.walkSpeed/math.sqrt(2))*dt
        else
            self.entity.y = self.entity.y - self.entity.walkSpeed * dt
        end

        if self.entity.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - self.entity.height / 2 then 
            self.entity.y = MAP_RENDER_OFFSET_Y + TILE_SIZE - self.entity.height / 2
            self.bumped = true
        end
    end
    if self.entity.mdown and not self.entity.mup then
        if self.entity.mleft or self.entity.mright then
            self.entity.y = self.entity.y + (self.entity.walkSpeed/math.sqrt(2))*dt
        else
            self.entity.y = self.entity.y + self.entity.walkSpeed * dt
        end

        local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) 
            + MAP_RENDER_OFFSET_Y - TILE_SIZE

        if self.entity.y + self.entity.height >= bottomEdge then
            self.entity.y = bottomEdge - self.entity.height
            self.bumped = true
        end
    end

    -- enemy / npc movement (Harvard code)
    -- boundary checking on all sides, allowing us to avoid collision detection on tiles
    if self.entity.direction == 'left' and not self.entity.mdown and not self.entity.mup and not self.entity.mright and not self.entity.mleft then
        self.entity.x = self.entity.x - self.entity.walkSpeed * dt
        
        if self.entity.x <= MAP_RENDER_OFFSET_X + TILE_SIZE then 
            self.entity.x = MAP_RENDER_OFFSET_X + TILE_SIZE
            self.bumped = true
        end
    elseif self.entity.direction == 'right' and not self.entity.mdown and not self.entity.mup and not self.entity.mright and not self.entity.mleft then
        self.entity.x = self.entity.x + self.entity.walkSpeed * dt

        if self.entity.x + self.entity.width >= VIRTUAL_WIDTH - TILE_SIZE * 2 then
            self.entity.x = VIRTUAL_WIDTH - TILE_SIZE * 2 - self.entity.width
            self.bumped = true
        end
    elseif self.entity.direction == 'up' and not self.entity.mdown and not self.entity.mup and not self.entity.mright and not self.entity.mleft then
        self.entity.y = self.entity.y - self.entity.walkSpeed * dt

        if self.entity.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - self.entity.height / 2 then 
            self.entity.y = MAP_RENDER_OFFSET_Y + TILE_SIZE - self.entity.height / 2
            self.bumped = true
        end
    elseif self.entity.direction == 'down' and not self.entity.mdown and not self.entity.mup and not self.entity.mright and not self.entity.mleft then
        self.entity.y = self.entity.y + self.entity.walkSpeed * dt

        local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) 
            + MAP_RENDER_OFFSET_Y - TILE_SIZE

        if self.entity.y + self.entity.height >= bottomEdge then
            self.entity.y = bottomEdge - self.entity.height
            self.bumped = true
        end
    end
end

function BossHorizontalState:processAI(params, dt)
    local room = params.room
    if self.bumped then 
        self.entity:changeState("vertical")
    end
end

function BossHorizontalState:render()
    local anim = self.entity.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.entity.x - self.entity.offsetX), math.floor(self.entity.y - self.entity.offsetY))
    
    -- debug code
    -- love.graphics.setColor(255, 0, 255, 255)
    -- love.graphics.rectangle('line', self.entity.x, self.entity.y, self.entity.width, self.entity.height)
    -- love.graphics.setColor(255, 255, 255, 255)
end

function BossHorizontalState:scale_render(scale)
    local anim = self.entity.currentAnimation
    love.graphics.draw(gTextures[anim.texture], 
                       gFrames[anim.texture][anim:getCurrentFrame()],
                       math.floor(self.entity.x - self.entity.offsetX), 
                       math.floor(self.entity.y - self.entity.offsetY),
                       0,            -- rotation
                       scale,        -- scale X
                       scale)        -- scale Y
    
    -- love.graphics.setColor(255, 0, 255, 255)
    -- love.graphics.rectangle('line', self.entity.x, self.entity.y, self.entity.width, self.entity.height)
    -- love.graphics.setColor(255, 255, 255, 255)
end
    
