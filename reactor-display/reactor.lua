
local dbgm = peripheral.wrap("top")
dbgm.setTextScale(0.5)

function debug( str )
    local x, y = dbgm.getCursorPos()
    local xDim, yDim = dbgm.getSize()
    if y > yDim then
        dbgm.scroll(1)
        dbgm.setCursorPos(1, yDim)
        y = yDim
    end
    dbgm.write(str)
    dbgm.setCursorPos(1, y + 1)
end


Point = {
    x = 0,
    y = 0
}

local drawables = {}

function Point:new(pnt)
    pnt = pnt or {}
    setmetatable(pnt, self)
    self.__index = self
    return pnt
end

function Point:toString()
    return "("..self.x..", "..self.y..")"
end

DrawableRect = {
    p1 = Point:new{x = 0, y = 0},
    p2 = Point:new{x = 1, y = 1},
    color = colors.white,
    onClick = function() debug("asdfasdf") end
}

function DrawableRect:new(rect)
    rect = rect or {}
    setmetatable(rect, self)
    self.__index = self
    return rect
end

function drawRectangle(p1, p2, color)
    for row = math.min(p1.y, p2.y), math.max(p1.y, p2.y) do
        paintutils.drawLine(p1.x, row, p2.x, row, color)
    end
end

function DrawableRect:draw()
    drawRectangle(self.p1, self.p2, self.color)
end

function DrawableRect:contains( pos )
    local xBound = pos.x >= math.min(self.p1.x, self.p2.x) and pos.x <= math.max(self.p1.x, self.p2.x)
    local yBound = pos.y >= math.min(self.p1.y, self.p2.y) and pos.y <= math.max(self.p1.y, self.p2.y)
    return xBound and yBound
end

function DrawableRect:click()
    self.onClick()
end


-- Bar which is filled based on the proportion of its value
-- to its value range. Good for temperature guages, progress bars,
-- loading screens, etc.
ProgressBar = DrawableRect:new{
    foregroundColor = colors.white,
    backgroundColor = colors.lightGray,
    minValue = 0,
    maxValue = 100,

    -- current value stored in progress bar.
    value = 50,

    -- orientation of 1 means the bar fills from bottom to top.
    -- 2 is a 90 degree turn, 3 is another 90, and 4 is a further 90
    orientation = 1
}

function ProgressBar:new(bar)
    bar = bar or {
        foregroundColor = colors.white,
        backgroundColor = colors.lightGray}
    setmetatable(bar, self)
    self.__index = self
    return bar
end

function ProgressBar:draw()
    local p1, p2, q1, q2 = self:getRectangles()
    drawRectangle(p1, p2, self.foregroundColor)
    drawRectangle(q1, q2, self.backgroundColor)
end

function round( n )
    return math.floor(n + 0.5)
end

function ProgressBar:getRectangles()
    local minX = math.min(self.p1.x, self.p2.x)
    local maxX = math.max(self.p1.x, self.p2.x)
    local minY = math.min(self.p1.y, self.p2.y)
    local maxY = math.max(self.p1.y, self.p2.y)

    local calcPixels = function(scale)
        return round(scale * ((self.value - self.minValue) / (self.maxValue - self.minValue)))
    end

    if self:xOriented() then
        local width = math.abs(self.p1.x - self.p2.x)
        local pixels = calcPixels(width)
        if self.orientation == 2 then
            local newX = minX + pixels
            return Point:new{x = minX, y = minY},
                   Point:new{x = newX, y = maxY},
                   Point:new{x = newX, y = minY},
                   Point:new{x = maxX, y = maxY}
        else
            local newX = maxX - pixels
            return Point:new{x = newX, y = minY},
                   Point:new{x = maxX, y = maxY},
                   Point:new{x = minX, y = minY},
                   Point:new{x = newX, y = maxY}
        end
    else
        local height = math.abs(self.p1.y - self.p2.y)
        local pixels = calcPixels(height)
        if self.orientation == 1 then
            local newY = maxY - pixels
            return Point:new{x = minX, y = newY},
                   Point:new{x = maxX, y = maxY},
                   Point:new{x = minX, y = minY},
                   Point:new{x = maxX, y = newY}
        else
            local newY = minY + pixels
            return Point:new{x = minX, y = minY},
                   Point:new{x = maxX, y = newY},
                   Point:new{x = minX, y = newY},
                   Point:new{x = maxX, y = maxY}

        end

    end

end

function ProgressBar:revesed()
end

function ProgressBar:xOriented()
    return self.orientation == 2 or self.orientation == 4
end

function ProgressBar:increment()
    self.value = math.min(self.value + 1, self.maxValue)
end

function ProgressBar:decrement()
    self.value = math.max(self.value - 1, self.minValue)
end

function ProgressBar:setValue( newValue )
    self.value = math.min(maxValue, math.max(minValue, newValue))
end

local exiting = false

function run()
    local monitor = peripheral.wrap("right")
    monitor.setTextScale(0.5)
    term.redirect(monitor)

    drawScreen()
    os.startTimer(2)
    while not exiting do
        debug("exiting == "..tostring(exiting))
        local event, p1, p2, p3 = os.pullEventRaw()
        if event == 'timer' then
            drawScreen()
            os.startTimer(1)
        elseif event == 'monitor_touch' then
            handleClickEvent(p1, p2, p3)
        else
            debug("Unknown event found: "..event)
        end
    end

    term.clear()
    term.restore()
end

function handleClickEvent(side, x, y)
    local clickPos = Point:new{x = x, y = y}
    for i = 1, #drawables do
        if drawables[i]:contains(clickPos) then
            drawables[i]:click()
        end
    end
end

function drawScreen()
    term.setBackgroundColor(colors.black)
    term.clear()
    for _, drawable in pairs(drawables) do
        drawable:draw()
    end
end

local reactor = peripheral.wrap("BigReactors-Reactor_0")

function setReactorControlRods()
    if reactor == nil then
        return
    end

    reactor.setAllControlRodLevels(0)
end

function quit()
    exiting = true
end

local rect = DrawableRect:new{p1 = Point:new{x = 3, y = 2}, p2 = Point:new{x = 13, y = 4}, onClick = quit}
table.insert(drawables, rect)
local rect = DrawableRect:new{p1 = Point:new{x = 20, y = 20}, p2 = Point:new{x = 24, y = 21}, color = colors.red, onClick = quit }
table.insert(drawables, rect)
local rect = DrawableRect:new{p1 = Point:new{x = 2, y = 20}, p2 = Point:new{x = 4, y = 10}, color = colors.green, onClick = quit }
table.insert(drawables, rect)
local rect = DrawableRect:new{p1 = Point:new{x = 8, y = 23}, p2 = Point:new{x = 6, y = 20}, color = colors.green, onClick = quit }
table.insert(drawables, rect)

local bar
bar = ProgressBar:new{
    p1 = Point:new{x = 40, y = 42},
    p2 = Point:new{x = 50, y = 10},
    value = 20,
    orientation = 1,
    onClick = function()
        bar:increment()
    end
}
table.insert(drawables, bar)

run()
