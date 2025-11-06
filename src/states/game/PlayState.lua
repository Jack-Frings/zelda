--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.player = Player {
        animations = ENTITY_DEFS['player'].animations,
        walkSpeed = ENTITY_DEFS['player'].walkSpeed,
        
        x = VIRTUAL_WIDTH / 2 - 8,
        y = VIRTUAL_HEIGHT / 2 - 11,
        
        width = 16,
        height = 22,

        -- one heart == 2 health
        health = 6,

        -- rendering and collision offset for spaced sprites
        offsetY = 5
    }

    self.dungeon = Dungeon(self.player)
    self.currentRoom = Room(self.player)
    
    self.player.stateMachine = StateMachine {
        ['walk'] = function() return PlayerWalkState(self.player, self.dungeon) end,
        ['idle'] = function() return PlayerIdleState(self.player) end,
        ['swing-sword'] = function() return PlayerSwingSwordState(self.player, self.dungeon) end
    }
    self.player:changeState('idle')
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    self.dungeon:update(dt)
end

function PlayState:passtoplayer(x, y, button, istouch, presses)
    self.player:mousepressed(x, y, button, istouch, presses)
end

function PlayState:render()
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf("Score: " .. tostring(self.player.score), 0, 2, VIRTUAL_WIDTH - 4, 'right')
    -- render dungeon and all entities separate from hearts GUI
    love.graphics.push()
    self.dungeon:render()
    love.graphics.pop()

    -- draw player hearts, top of screen
    local healthLeft = self.player.health
    local heartFrame = 1

    for i = 1, 3 do
        if healthLeft > 1 then
            heartFrame = 5
        elseif healthLeft == 1 then
            heartFrame = 3
        else
            heartFrame = 1
        end

        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][heartFrame],
            (i - 1) * (TILE_SIZE + 1) + 2, 2)
        
        healthLeft = healthLeft - 2
    end

    local bullet_shade
    for i = 1, 3 do
        if self.player.bullets >= i then
            love.graphics.draw(gTextures['bullet'], gFrames['bullet'][1],
                (i-1) * (TILE_SIZE+1) + 2, VIRTUAL_HEIGHT-18)
        else
            love.graphics.draw(gTextures['bullet_empty'], gFrames['bullet_empty'][1],
                (i-1) * (TILE_SIZE+1) + 2, VIRTUAL_HEIGHT-18)
        end
    end
end