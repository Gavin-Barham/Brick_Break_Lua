--[[
    GD50
    Breakout Remake

    -- Brick Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a brick in the world space that the ball can collide with;
    differently colored bricks have different point values. On collision,
    the ball will bounce away depending on the angle of collision. When all
    bricks are cleared in the current map, the player should be taken to a new
    layout of bricks.
]]

Powerup = Class{}

function Powerup:init(params)
    -- used for coloring and score calculation
    self.x = params.x
    self.y = params.y
    self.dy = 0
    self.width = 16
    self.height = 16
    self.brick = params.brick
    self.powerupType = params.powerupType
    self.isUsed = false
    self.isCollected = false
    
    -- used to determine whether this brick should be rendered
    self.inPlay = true

end

--[[
    Triggers a hit on the brick, taking it out of play if at 0 health or
    changing its color otherwise.
]]
function Powerup:caught(length)
    self.x = 18 * length
    self.y = 5
    self.dy = 0
    self.inPlay = false
end
function Powerup:update(dt)
    if not self.brick.inPlay and self.inPlay then
        self.dy = self.dy + 1
    end
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    love.graphics.draw(gTextures['main'], 
        -- multiply color by 4 (-1) to get our color offset, then add tier to that
        -- to draw the correct tier and color brick onto the screen
        gFrames['power-ups'][self.powerupType],
        self.x, self.y)
end