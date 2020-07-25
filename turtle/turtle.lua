_TURTLEIMAGE = "turtle/turtle.png"
local image_exists = love.filesystem.getInfo(_TURTLEIMAGE)
print(image_exists)
if image_exists then 
    turtleimage = love.graphics.newImage(_TURTLEIMAGE)
end

local turtle = {}
turtle.__index = turtle

local newline = function(x1, y1, x2, y2, c, dir) 
    return {p1 = {x = x1, y = y1 }
    , p2 = {x = x2, y = y2}
    , pd = {x = x1, y = y1 }
    , dx = x2 - x1
    , dy = y2 - y1
    , c = c or {1, 0, 0}, direction = dir}
end

local sign = function(x)
    return (x<0 and -1) or 1
end

local getcolor = function(color, mode)  
    local c = color
    if mode ~= false then
        c = {love.math.random(0, 1), love.math.random(0, 1),love.math.random(0, 1)}
    end 
    return c
end 

local function new(x, y, speed, color) 
    linesegments = {}
    currentline = 1
    currentposition = {}
    currentposition.x = x or love.graphics.getHeight() / 2
    currentposition.y = y or love.graphics.getWidth() / 2
    drawspeed = speed or 2
    color = color or {1, 1, 1}
    direction = 0
    size = 1
    rainbowmode = false
    turtlevisible = true
    return setmetatable(
    { linesegments = linesegments
    , currentposition = currentposition
    , currentline = currentline
    , direction = direction
    , drawspeed = drawspeed
    , color = color, drawspeed = speed
    , rainbowmode = rainbowmode
    , turtlevisible = turtlevisible
}
,
turtle)
end

function turtle:setcolor(...)
    self.rainbowmode = false
    local c = self.color
    local nargs = select("#", ...)
    if nargs == 3 then
        c = {...}
    elseif nargs == 1 then 
        c = ... 
    end
    self.color = c
    return self
end

function turtle:getlines() 
    return self.lineSegments
end

function turtle:draw()
    local dt = love.timer.getDelta()
    if #self.linesegments ~= self.currentline then
        --draw completed linesegments
        if self.currentline > 1 then
            for i=1, self.currentline - 1 do
                local l = self.linesegments[i]
                love.graphics.setColor(l.c)
                love.graphics.line(l.p1.x,l.p1.y, l.p2.x, l.p2.y)
            end
        end

        local line = self.linesegments[self.currentline]
        local distance = math.sqrt(line.dx * line.dx, line.dy * line.dy) 

        local sx, sy = -sign(line.dx) * self.drawspeed, -sign(line.dy) * self.drawspeed

        print(sx, sy)
        local newpdx, newpdy = line.pd.x + sx, line.pd.y + sy  
        local newdistance = math.sqrt(((line.p2.x - newpdx)* (line.p2.x - newpdx)), ((line.p2.y - newpdy)* (line.p2.y - newpdy))) 

        if newdistance >= distance then
            line.pd.x, line.pd.y = line.p2.x, line.p2.y  
        else 
            line.pd.x, line.pd.y = line.pd.x + sx, line.pd.y + sy  
        end

        if line.pd.x == line.p2.x and line.pd.y == line.p2.y then
            self.currentline = self.currentline + 1
        end

        love.graphics.line(line.p1.x, line.p1.y, line.pd.x, line.pd.y)
        if image_exists then
            local x, y = line.pd.x - turtleimage:getWidth() / 2, line.pd.y - turtleimage:getHeight() / 2
            love.graphics.draw(turtleimage, line.pd.x, line.pd.y, line.direction, 1, 1, 0 + turtleimage:getWidth() / 2, 0 + turtleimage:getHeight() / 2)
        end
    else 
        for _,line in pairs(self.linesegments) do
            love.graphics.setColor(line.c)
            love.graphics.line(line.p1.x,line.p1.y, line.p2.x, line.p2.y)
        end
        local lastline = self.linesegments[self.currentline]
        if image_exists then
            print(image_exists)
            love.graphics.draw(turtleimage, lastline.p2.x, lastline.p2.y, lastline.direction, 1, 1, 0 + turtleimage:getWidth() / 2, 0 + turtleimage:getHeight() / 2)
        end
    end
end

function turtle:clear()
    love.graphics.setColor(1, 1, 1)
    self.color = {1, 1, 1}
    self.lineSegments = {}
    love.graphics.setLineWidth(1)
    self.rainbowmode = false
    return self
end

function turtle:penup()
    self.drawing = false
    return self
end

function turtle:pendown()
    self.drawing = true
    return self
end

function turtle:rainbow()
    self.rainbowmode = true
    return self
end

function turtle:showturtle()
    self.turtleVisibility = true
    return self
end

function turtle:hideturtle()
    self.turtleVisibility = false
    return self
end

function turtle:isvisible()
    return self.turtleVisibility
end

function turtle:pensize(size)
    self.size = size
    love.graphics.setLineWidth(size)
end

function turtle:speed(speed)
    self.drawspeed = speed
    return self
end

function turtle:forward(distance)
    local x, y = self.currentposition.x + distance * math.cos(self.direction), self.currentposition.y + distance * math.sin(self.direction)

    local c = getcolor(self.color, self.rainbowmode)
    local line = newline(self.currentposition.x, self.currentposition.y, x, y, c, self.direction) 
    if self.drawing ~= false then
        table.insert(self.linesegments, line) 
    end

    self.currentposition.x, self.currentposition.y = x, y
    return self
end

function turtle:backward(distance)
    self:forward(-distance)
    return self
end

function turtle:go_to(x, y)
    local c = getcolor(self.color, self.rainbowmode)
    local line = newline(self.currentposition.x, self.currentposition.y, x, y, c, self.direction)
    table.insert(self.linesegments, line)
    return self
end

function turtle:right(angle)
    self.direction = self.direction - math.rad(angle)
    return self
end

function turtle:left(angle)
    self.direction = self.direction + math.rad(angle)
    return self
end

return setmetatable({new = new},
{__call = function(_, ...) return new(...) end})
