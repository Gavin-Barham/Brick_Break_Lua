--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.powerups = params.powerups
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    self.recoverPoints = params.recoverPoints
    self.resizePoints = params.resizePoints
    self.powerupTimer = params.powerupTimer

    -- give ball random starting velocity
    for k, ball in pairs(self.balls) do
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end
    Timer.every(1, function()
        self.powerupTimer = self.powerupTimer - 1
    end)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    elseif love.keyboard.wasPressed('v') then
        Timer.clear()
        gStateMachine:change('victory', {
            level = self.level,
            paddle = self.paddle,
            health = self.health,
            score = self.score,
            highScores = self.highScores,
            balls = self.balls,
            powerups = {},
            recoverPoints = self.recoverPoints,
            resizePoints = self.resizePoints,
            powerupTimer = self.powerupTimer
        })
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self:removeLostBalls()
    self:removeUsedPowerups()
    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end
    for k, powerup in pairs(self.powerups) do
        if powerup.powerupType == 1 and #self.balls == 1 and powerup.isCollected then
            powerup.isUsed = true
        end
        if powerup.inPlay and self.paddle:collides(powerup) or powerup.inPlay and powerup.powerupType == 2 and powerup.y >= VIRTUAL_HEIGHT then
            powerup:caught(#self.powerups + 1)
            if powerup.powerupType == 1 then
                local currentSkin = self.balls[1].skin
                local currentX = self.balls[1].x
                local currentDX = self.balls[1].dx
                local currentY = self.balls[1].y
                local currentDY = self.balls[1].dy
                
                local ball1 = Ball()
                local ball2 = Ball()

                ball1.skin = currentSkin
                ball2.skin = currentSkin

                ball1.x = currentX + math.random(10, 20)
                ball2.x = currentX - math.random(10, 20)

                ball1.dx = currentDX
                ball2.dx = currentDX

                ball1.y = currentY + math.random(5, 10)
                ball2.y = currentY - math.random(5, 10)

                ball1.dy = currentDY
                ball2.dy = currentDY

                powerup.isCollected = true
                table.insert(self.balls, ball1)
                table.insert(self.balls, ball2)
            elseif powerup.powerupType == 2 then
                table.insert(self.paddle.powerups, powerup)
            end
        end
        powerup:update(dt)
    end

    for k, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        for key, ball in pairs(self.balls) do
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger the brick's hit function, which removes it from play
                brick:hit(self.paddle.powerups)

                -- if we have enough points, recover a point of health
                if self.score >= self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end
                if self.score >= self.resizePoints then
                    self.paddle:grow()

                    self.resizePoints = math.min(100000, self.resizePoints * 2)
                    -- play grow sound effect
                    gSounds['recover']:play()
                end
                -- shouldRandomPowerupIntervalTrigger = math.random(1 ,2) == 1
                if self.powerupTimer <= 0 then
                    extraBallsPower = Powerup({
                        x = math.random(10, VIRTUAL_WIDTH),
                        y = math.random(0, VIRTUAL_HEIGHT / 3),
                        brick = {},
                        lockedBrick = {},
                        powerupType = 1,
                    })
                    table.insert(self.powerups, extraBallsPower)
                    -- play powerup sound effect
                    gSounds['recover']:play()
                    self.powerupTimer = 10
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()
                    Timer.clear()
                    self.paddle.powerups = {}
                    if self.paddle.size == 1 then
                        self.paddle:grow()
                    end
                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        powerups = {},
                        recoverPoints = self.recoverPoints,
                        powerupTimer = self.powerupTimer,
                        resizePoints = self.resizePoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health

    if self:lostAllBalls() then
        self.health = self.health - 1
        self.paddle:shrink()
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                powerups = self.powerups,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                powerupTimer = self.powerupTimer,
                resizePoints = self.resizePoints
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end
    Timer.update(dt)

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    if #self.powerups ~= 0 then
        for k, powerup in pairs(self.powerups) do
            powerup:render()
        end
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

function PlayState:lostAllBalls()
    for k, ball in pairs(self.balls) do
        if ball.y < VIRTUAL_HEIGHT then
            return false
        end
    end
    return true
end

function PlayState:removeLostBalls()
    if #self.balls == 1 then
        return
    end
    local idx = {}
    for k, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            table.insert(idx, k)
        end
    end
    for k, i in pairs(idx) do
        table.remove(self.balls, i)
    end
end
function PlayState:removeUsedPowerups()
    local idx = {}
    for k, powerup in pairs(self.powerups) do
        if powerup.isUsed then
            table.insert(idx, k)
        end
    end
    for k, i in pairs(idx) do
        table.remove(self.powerups, i)
    end
end