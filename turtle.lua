local Vector2 = require "vector"

_TURTLEIMAGE = "turtle.png"

local turtle = {}
turtle.__index = turtle

local loadSprite = function (name)
    local fileLoc = "sprites/" .. name
    local f = io.open(fileLoc)
    if f then
        f:close()
        return love.graphics.newImage(fileLoc)
    end
end

local function Node(x, y)
    return {
        _pos = Vector2(x, y) ,
        _distance = 0 ,
        _angle = 0 ,
        _color = nil ,
        _speed = 0 ,
        _distance = 0
    }
end

local function new(name, x, y, callback)
    _x, _y = x or love.graphics.getWidth() / 2, y or love.graphics.getHeight() / 2
    pos = Vector2(_x, _y) 
    return setmetatable(
    {
        _name = name ,
        _pos = pos ,
        _currentPos = pos ,
        _sprite = loadSprite(_TURTLEIMAGE) ,
        _speed = 10 ,
        _nodes = {} ,
        _color = {1, 1, 1} ,
        _ratio = 0 ,
        _angle = 0 ,
        _drawAngle = 0 ,
        _currentDistance = 0 ,
        _totalDistance = 0 ,
        _dt = 0 ,
        _playing = false ,
        _nodeIndex = -1 ,
        _lastNodeDrawPos = nil ,
        _finalized = false ,
        _callback = callback

    }, turtle)
end

function turtle:_createNode(x, y)
    local node = Node(x, y)
    node._speed = self._speed
    node._color = self._color
    node._angle = self._angle
    return node
end

function turtle:setCallback(callback) self._callback = callback end

function turtle:_forward(d)
    local pos = self._pos
    if next(self._nodes) ~= nil then
        pos = self._nodes[#self._nodes]._pos
    end
    
    pos = addScalarWithAngle(pos, d, self._angle)
    self._nodes[#self._nodes+1] = self:_createNode(pos.x, pos.y)

    self:_calculateTotalDistance()
    return self
end

function turtle:undo(c)
    c = c or 1

    for i = #self._nodes, math.max(0, #self._nodes - c), -1 do
        table.remove(self._nodes, i)
    end

    self._nodeIndex = math.min(#self._nodes, self._nodeIndex)
    self:_calculateTotalDistance()
    return self
end

function turtle:_calculateTotalDistance()
    local dist = 0
    local lastPos = self._pos
    for i = 1, #self._nodes, 1 do
        local node = self._nodes[i]
        local vd = node._pos:distance(lastPos)

        node._distance = vd
        dist = dist + vd

        lastPos = node._pos
    end
    self._totalDistance = dist
end

function turtle:clear()
    self._currentPos = self._pos
    self._currentDistance = 0
    self._playing = false
    self._nodeIndex = -1
    self._lastNodeDrawPos = nil
    self._dt = 0
    self._finalized = false
end

function turtle:play() self._playing = true end     -- Play
function turtle:pause() self._playing = false end   -- Pause
function turtle:toggle() self._playing = not self._playing end
function turtle:tl() return self:rot(-90) end       -- Turn left
function turtle:tr() return self:rot(90) end        -- Turn right
function turtle:f(d) return self:_forward(d) end    -- Forward
function turtle:rl(a) return self:rot(-a) end       -- Rotate left
function turtle:rr(a) return self:rot(a) end        -- Rotate right
function turtle:rot(deg)                            -- Rotate by degree
    self._angle = self._angle + math.rad(deg)
    return self
end
function turtle:speed(speed)                        -- Set speed
    self._speed = speed
    return self
end
function turtle:color(...)                          -- Set color
    local c = self._color
    local nargs = select("#", ...)
    if nargs == 3 then
        c = {...}
    elseif nargs == 1 then 
        c = ... 
    end
    self._color = c
    return self
end

function turtle:_drawPath()
    local lastPos = self._pos
    for i = 1, self._nodeIndex, 1 do
        local node = self._nodes[i]
        love.graphics.setColor(node._color)
        if i == self._nodeIndex then
            love.graphics.line(lastPos.x, lastPos.y, self._lastNodeDrawPos.x, self._lastNodeDrawPos.y)
            break
        else
            love.graphics.line(lastPos.x, lastPos.y, node._pos.x, node._pos.y)
        end
        lastPos = node._pos
    end
end

function turtle:draw()
    self:_drawPath()
    love.graphics.setColor({1,1,1})
    if self._sprite then
        love.graphics.draw(self._sprite, self._currentPos.x, self._currentPos.y, self._drawAngle, 1, 1, 8, 8)
    end
end

function turtle:update(dt)
    if next(self._nodes) == nil then return end
    if self._finalized or not self._playing then return end

    local lastPos = self._pos
    local node = self._nodes[math.max(self._nodeIndex, 1)]
    local speed = node._speed
    local angle = node._angle

    self._dt = self._dt + dt * speed

    local ratio = math.min(1.0, math.max(0.0, self._dt / self._totalDistance))
    local reachDistance = self._totalDistance * ratio

    for i = 1, #self._nodes, 1 do
        local node = self._nodes[i]
        local diff = reachDistance - node._distance

        if diff < 0 then
            self._nodeIndex = i
            self._lastNodeDrawPos = lerp(lastPos, node._pos, reachDistance / node._distance)
            self._currentPos = self._lastNodeDrawPos
            break
        end

        reachDistance = diff
        lastPos = node._pos
        self._currentPos = lastPos
    end
    
    self._drawAngle = angle

    if ratio == 1.0 and not self._finalized then
        self._nodeIndex = #self._nodes
        self._lastNodeDrawPos = self._nodes[self._nodeIndex]._pos
        self._finalized = true
        if self._callback ~= nil then self._callback() end
    end
end

function turtle:print()
    for _, value in ipairs(self._path.nodes) do
        print(value)
    end
end

return setmetatable({new = new},
{__call = function(_, ...) return new(...) end})