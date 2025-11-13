-- PlayState.lua
PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.player = Player {
        animations = ENTITY_DEFS['player'].animations,
        walkSpeed = ENTITY_DEFS['player'].walkSpeed,
        x = VIRTUAL_WIDTH / 2 - 8,
        y = VIRTUAL_HEIGHT / 2 - 11,
        width = 16,
        height = 22,
        health = 6,
        offsetY = 5
    }

    self.player.hitCounter = 0
    self.player.bullets = 3

    self.dungeon = Dungeon(self.player)
    self.currentRoom = self.dungeon.currentRoom

    self.player.stateMachine = StateMachine {
        ['walk'] = function() return PlayerWalkState(self.player, self.dungeon) end,
        ['idle'] = function() return PlayerIdleState(self.player) end,
        ['swing-sword'] = function() return PlayerSwingSwordState(self.player, self.dungeon) end
    }
    self.player:changeState('idle')

    -- Achievements manager
    self.achievementManager = Achievements()
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- Update dungeon (rooms, entities, player)
    self.dungeon:update(dt)

    -- Update achievements (notifications, etc.)
    self.achievementManager:update(dt)

    -- Survivalist: start timer only after 5 hits
    local survival = self.achievementManager.achievements['Survivalist']
    if self.player.hitCounter >= 5 and not survival.unlocked then
        survival.timer = survival.timer + dt
        if survival.timer >= survival.goal then
            self.achievementManager:unlock('Survivalist')
        end
    end
end

-- Pass mouse input to player
function PlayState:passtoplayer(x, y, button, istouch, presses)
    self.player:mousepressed(x, y, button, istouch, presses)
end

-- Called when leaving a room to check Pacifist
function PlayState:leaveRoom()
    if self.achievementManager then
        self.achievementManager:checkPacifist()
    end
end

function PlayState:render()
    love.graphics.setFont(gFonts['small'])
    love.graphics.printf("Score: " .. tostring(self.player.score), 0, 2, VIRTUAL_WIDTH - 4, 'right')

    -- Render dungeon and all entities
    love.graphics.push()
    self.dungeon:render()
    love.graphics.pop()

    -- Draw hearts
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

    -- Draw bullets
    for i = 1, 3 do
        if self.player.bullets >= i then
            love.graphics.draw(gTextures['bullet'], gFrames['bullet'][1],
                (i - 1) * (TILE_SIZE + 1) + 2, VIRTUAL_HEIGHT - 18)
        else
            love.graphics.draw(gTextures['bullet_empty'], gFrames['bullet_empty'][1],
                (i - 1) * (TILE_SIZE + 1) + 2, VIRTUAL_HEIGHT - 18)
        end
    end

    -- Render achievement notifications
    self.achievementManager:render()
end
