--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

--Bullet class, basically, unless there is another projectile to be added

Projectile = Class{}

function Projectile:init(def)
    self.x = def.character.x + def.character.width/2
    self.y = def.character.y + def.character.height/2
    self.width = 4
    self.height = 4
    self.dx = 0
    self.dy = 0
    self:calcSlope(def)
    self.rotation = self:calcRotation(def)

    self.BULLET_SPEED = 400
end

function Projectile:calcSlope(def) -- calculate dx and dy
    self.mx = def.mousex * (VIRTUAL_WIDTH/WINDOW_WIDTH) --convert to virtual coords
    self.my = def.mousey * (VIRTUAL_HEIGHT/WINDOW_HEIGHT)

    self.dx = self.mx - self.x
    self.dy = self.my - self.y

    --Pythagorean Thm to find diagonal distance from cursor to player
    self.total_distance = math.sqrt(math.pow(self.dx,2) + math.pow(self.dy,2))
    
    --divide dx and dy by total length so each value is < 1, otherwise
    --distance from mouse to player would affect bullet speed
    --dividing each by the same number doesnt change slope (dy/dx)
    self.dx = self.dx / self.total_distance
    self.dy = self.dy / self.total_distance
end

function Projectile:calcRotation(def)
    if self.dx >= 0 then
        self.y = self.y - 5
        return math.atan(self.dy/self.dx)
    end
    self.y = self.y + 5
    return math.atan(self.dy/self.dx) + math.pi
end

function Projectile:update(dt)
    self.x = self.x + self.dx*dt*self.BULLET_SPEED
    self.y = self.y + self.dy*dt*self.BULLET_SPEED
end

function Projectile:collides(target)
    return not (self.x + self.width < target.x or self.x > target.x + target.width or
                self.y + self.height < target.y or self.y > target.y + target.height)
end

function Projectile:offscreen()
    return self.x < 0 or self.x > VIRTUAL_WIDTH or self.y < 0 or self.y > VIRTUAL_HEIGHT
end

function Projectile:render()
    love.graphics.draw(gTextures['bullet'], gFrames['bullet'][1],self.x,self.y,self.rotation,0.75,0.75)
end