--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Player = Class{__includes = Entity}

function Player:init(def)
    Entity.init(self, def)
    self.shots = {}
end

function Player:update(dt)
    Entity.update(self, dt)

    for k, shot in pairs(self.shots) do
        shot:update(dt)
    end
end

function Player:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        self.bullets = self.bullets - 1
        table.insert(self.shots, Projectile{character = self, mousex = x, mousey = y})
    end
end

function Player:collides(target)
    local selfY, selfHeight = self.y + self.height / 2, self.height - self.height / 2
    
    return not (self.x + self.width < target.x or self.x > target.x + target.width or
                selfY + selfHeight < target.y or selfY > target.y + target.height)
end

function Player:render()
    for k, shot in pairs(self.shots) do
        shot:render()
    end
    Entity.render(self)
    
    -- love.graphics.setColor(255, 0, 255, 255)
    -- love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    -- love.graphics.setColor(255, 255, 255, 255)
end