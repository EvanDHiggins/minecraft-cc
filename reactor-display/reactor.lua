
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

Rectangle = {
    p1 = Point:new{x = 0, y = 0},
    p2 = Point:new{x = 1, y = 1},
    color = colors.white,
    onClick = function() end
}

function Rectangle:new( rect )
    rect = rect or {}
    setmetatable(rect, self)
    self.__index = self
    return rect
end

function Rectangle:toString()
    return "Rectangle{"..(self.p1:toString())..", "..(self.p2:toString()).."}"
end

function Rectangle:bottom()
    return math.max(self.p1.y, self.p2.y)
end

function Rectangle:top()
    return math.min(self.p1.y, self.p2.y)
end

function Rectangle:left()
    return math.min(self.p1.x, self.p2.x)
end

function Rectangle:right()
    return math.max(self.p1.x, self.p2.x)
end

function Rectangle:translateX( dx )
    self.p1.x = self.p1.x + dx
    self.p2.x = self.p2.x + dx
end

function Rectangle:translateY( dy )
    self.p1.y = self.p1.y + dy
    self.p2.y = self.p2.y + dy
end

function Rectangle:height()
    return math.abs(self.p1.y - self.p2.y)
end

function Rectangle:width()
    return math.abs(self.p1.x - self.p2.x)
end

-- 0 < porportion < 1
-- Returns two rectangles created by splitting self
-- proportionally.
-- The first rectangle returned will be the requested
-- proportion from the left, the second will be the remaining portion.
function Rectangle:splitByProportionX( p )
    local newX = self:left() + math.floor(p * self:width())
    return Rectangle:new{
        p1 = Point:new{x = self:left(), y = self:top()},
        p2 = Point:new{x = newX, y = self:bottom()}
    }, Rectangle:new{
        p1 = Point:new{x = newX, y = self:top()},
        p2 = Point:new{x = self:right(), y = self:bottom()}
    }
end

-- 0 < p < 1
-- p is the proprotion of the first rectangle returned.
-- Returns two rectangles created by splitting self
-- proportionally.
-- The first rectangle returned will be the requested
-- proportion from the bottom, the second will be the remaining portion.
function Rectangle:splitByProportionY( p )
    debug("p = "..p)
    local newY = self:bottom() - math.floor(p * self:height())
    return Rectangle:new{
        p1 = Point:new{x = self:left(), y = newY},
        p2 = Point:new{x = self:right(), y = self:bottom()}
    }, Rectangle:new{
        p1 = Point:new{x = self:left(), y = self:top()},
        p2 = Point:new{x = self:right(), y = newY}
    }
end

function Rectangle:new(rect)
    rect = rect or {}
    setmetatable(rect, self)
    self.__index = self
    return rect
end

function Rectangle:draw( c )
    for row = self:top(), self:bottom() do
        local color
        if c then
            color = c.color
        else
            color = self.color
        end
        paintutils.drawLine(self.p1.x, row, self.p2.x, row, color)
    end
end

function Rectangle:contains( pos )
    local xBound = pos.x >= math.min(self.p1.x, self.p2.x) and pos.x <= math.max(self.p1.x, self.p2.x)
    local yBound = pos.y >= math.min(self.p1.y, self.p2.y) and pos.y <= math.max(self.p1.y, self.p2.y)
    return xBound and yBound
end

function Rectangle:click()
    self.onClick()
end

MultiValueFilledBar = Rectangle:new{
    capacity = 100,

    -- integer Quantities represented by the bar
    -- Must sum to <= capacity
    quantities = {},

    -- colors[i] represents the portion of the bar filled
    -- for quantities[i]. Unfilled space uses self.color
    colors = {},

    -- function returning #quantities values
    getQuantities = nil,

    -- orientation of 1 means the bar fills from bottom to top.
    -- 2 is a 90 degree turn, 3 is another 90, and 4 is a further 90
    orientation = 1
}

function MultiValueFilledBar:updateQuantities()
    if type(self.getQuantities) == "function" then
        local newQuantities = { self.getQuantities() }
        for i=1, #newQuantities do
            self.quantities[i] = newQuantities[i]
        end
    end
end

function MultiValueFilledBar:setQuantities( newQuantities )
    quantities = newQuantities
end

function MultiValueFilledBar:setSingleQuantity( index, quantity )
    if index <= #self.quantities and index > 0 then
        self.quantities[index] = quantity
    end
end

function MultiValueFilledBar:draw()
    self:updateQuantities()
    local tempCapacity = self.capacity
    local prev = self
    local split = function( prev, orientation, proportion )
        if orientation == 1 then
            return prev:splitByProportionY(proportion)
        elseif orientation == 2 then
            return prev:splitByProportionX(proportion)
        elseif orientation == 3 then
            local r1, r2 = prev:splitByProportionY(1 - proportion)
            return r2, r1
        elseif orientation == 4 then
            local r1, r2 = prev:splitByProportionX(1 - proportion)
            return r2, r1
        end
    end
    for i=1, #self.quantities - 1 do
        local r1, r2 = split(prev, self.orientation, self.quantities[i] / tempCapacity)
        prev = r2
        tempCapacity = tempCapacity - self.quantities[i]
        r1:draw{color = self.colors[i]}
    end
    prev:draw{ color = self.colors[#self.colors]}
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

local reactor = peripheral.wrap("BigReactors-Reactor_1")

function quit()
    exiting = true
end

function addDrawable( d )
    table.insert(drawables, d)
end

addDrawable(MultiValueFilledBar:new{
    p1 = Point:new{x = 15, y = 8},
    p2 = Point:new{x = 25, y = 38},
    capacity = 2000,
    labels = {"<1350", ">=1350", "none"},
    quantities = {0, 0},
    quantities = {0, 0, 0},
    colors = {colors.blue, colors.red, colors.gray},
    orientation = 3,

    getQuantities = function()
        local temp = reactor.getFuelTemperature()
        return math.floor(math.min(temp, 1350)), math.floor(math.max(temp - 1350, 0)), math.floor(math.max(0, 2000 - temp))
    end
})

--addDrawable(MultiValueFilledBar:new{
    --p1 = Point:new{x = 3, y = 8},
    --p2 = Point:new{x = 13, y = 38}, 
    --capacity = reactor.getFuelAmountMax(),
    --labels = {"fuel", "waste", "empty"},
    --quantities = {0, 0, 0},
    --colors = {colors.yellow, colors.cyan, colors.gray},
    --getQuantities = function()
        --local fuel = reactor.getFuelAmount()
        --local waste = reactor.getWasteAmount()
        --return fuel, waste, reactor.getFuelAmountMax() - fuel - waste
    --end,
    --onClick = quit
--})

run()
