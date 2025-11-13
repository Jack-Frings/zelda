Achievements = Class{}

function Achievements:init()
    self.achievements = {
        Slayer = { unlocked = false, progress = 0, goal = 25 },
        Pacifist = { unlocked = false, noKillRoom = true },
        Survivalist = { unlocked = false, timer = 0, goal = 20 }
    }

    self.notification = nil
    self.notificationTimer = 0
    self.notificationDuration = 3
end

function Achievements:increment(key, amount)
    amount = amount or 1
    local a = self.achievements[key]
    if not a or a.unlocked then return end

    if a.progress ~= nil then
        a.progress = a.progress + amount
        if a.progress >= a.goal then
            self:unlock(key)
        end
    end
end

-- Unlock an achievement and trigger notification
function Achievements:unlock(key)
    local a = self.achievements[key]
    if not a or a.unlocked then return end

    a.unlocked = true
    self.notification = "Achievement Unlocked: " .. key
    self.notificationTimer = self.notificationDuration
end


function Achievements:startNewRoom()
    local pacifist = self.achievements['Pacifist']
    if pacifist then
        pacifist.noKillRoom = true
    end
end

function Achievements:checkPacifist()
    local pacifist = self.achievements['Pacifist']
    if pacifist and not pacifist.unlocked and pacifist.noKillRoom then
        self:unlock('Pacifist')
    end
end

function Achievements:registerKill()
    local pacifist = self.achievements['Pacifist']
    if pacifist then
        pacifist.noKillRoom = false
    end
end

function Achievements:update(dt)
    if self.notificationTimer > 0 then
        self.notificationTimer = self.notificationTimer - dt
        if self.notificationTimer <= 0 then
            self.notification = nil
        end
    end
end

function Achievements:render()
    if self.notification then
        love.graphics.setFont(gFonts['small'] or love.graphics.newFont(12))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(self.notification, 0, 5, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Achievements
