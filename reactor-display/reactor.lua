FRAME_LENGTH = 0.5 --seconds

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
    return math.abs(self.p1.y - self.p2.y) + 1
end

function Rectangle:width()
    return math.abs(self.p1.x - self.p2.x) + 1
end

-- 0 < porportion < 1
-- Returns two rectangles created by splitting self
-- proportionally.
-- The first rectangle returned will be the requested
-- proportion from the left, the second will be the remaining portion.
function Rectangle:splitByProportionX( p )
    local newX = self:left() + math.floor(p * (self:width() - 1))
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
        if tempCapacity == 0 then
            return
        end
    end
    prev:draw{ color = self.colors[#self.colors]}
end

StaticTextBox = Rectangle:new{
    text = "",
    textColor = colors.white,
    getText = nil,
    backgroundColor = colors.black
}

function StaticTextBox:new( box )
    box = box or {}
    setmetatable(box, self)
    self.__index = self
    box:calcP2()
    return box
end

function StaticTextBox:calcP2()
    self.p2 = Point:new{x = self.p1.x + string.len(self.text) - 1, y = self.p1.y}
end

function StaticTextBox:updateText()
    if type(self.getText) == "function" then
        self.text = self.getText()
        self:calcP2()
    end
end

function StaticTextBox:draw()
    self:updateText()
    term.setCursorPos(self.p1.x, self.p1.y)
    term.setBackgroundColor(self.backgroundColor)
    term.setTextColor(self.textColor)
    term.write(string.sub(self.text, 1, self:width() + 1))
end


local exiting = false

function run()
    local monitor = peripheral.wrap("right")
    --monitor.setTextScale(0.5)
    term.redirect(monitor)

    drawScreen()
    os.startTimer(FRAME_LENGTH)
    while not exiting do
        debug("exiting == "..tostring(exiting))
        local event, p1, p2, p3 = os.pullEventRaw()
        if event == 'timer' then
            drawScreen()
            os.startTimer(FRAME_LENGTH)
        elseif event == 'monitor_touch' then
            handleClickEvent(p1, p2, p3)
            drawScreen()
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


function quit()
    exiting = true
end

function addDrawable( d )
    table.insert(drawables, d)
end

function clamp(min, val, max)
    return math.min(max, math.max(min, val))
end

--Reactor = {
    --networkLabel = "BigReactors-Reactor_1"
--}

--function Reactor:new( r )
    --r = r or {}
    --setmetatable(r, self)
    --self.__index = self
    --return r
--end

--function Reactor:conn()
    --if self.connection ~= nil then
        --return self.connection
    --end
    --self.connection = peripheral.wrap(self.networkLabel)
    --return self.connection
--end

--function Reactor:getFuelAmount()
    --if self:conn() == nil then
        --return 0
    --end
    --return self:conn().getFuelAmount()
--end

--function Reactor:getFuelAmountMax()
    --if self:conn() == nil then
        --return 0
    --end
    --return self:conn().getFuelAmountMax()
--end

--function Reactor:getWasteAmount()
    --if self:conn() == nil then
        --return 0
    --end
--end


local reactor = peripheral.wrap("BigReactors-Reactor_1")
--reactor = Reactor:new{
    --networkLabel = "BigReactors-Reactor_1"
--}

BAR_GRAPH_LEFT_X_MARGIN = 12
BAR_GRAPH_RIGHT_X_MARGIN = 38
GRAPH_TEXT_X_MARGIN = 2

REACTOR_MAX_STORED_ENERGY = 10000000

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = GRAPH_TEXT_X_MARGIN, y = 2},
    text = "Fuel Amt"
})

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = GRAPH_TEXT_X_MARGIN, y = 3},
    text = "----- mB",
    getText = function()
        return string.format("% 5d mB", reactor.getFuelAmount() or 0)
    end
})

---     Fuel Guage      ---
addDrawable(MultiValueFilledBar:new{
    p1 = Point:new{x = BAR_GRAPH_LEFT_X_MARGIN, y = 2},
    p2 = Point:new{x = BAR_GRAPH_RIGHT_X_MARGIN, y = 3}, 
    capacity = reactor.getFuelAmountMax(),
    labels = {"waste", "fuel", "empty"},
    quantities = {0, 0, 0},
    colors = {colors.cyan, colors.yellow, colors.gray},
    orientation = 2,
    getQuantities = function()
        local fuel = reactor.getFuelAmount() or 0
        local waste = reactor.getWasteAmount() or 0
        return waste, fuel, (reactor.getFuelAmountMax() or 0) - fuel - waste
    end,
    onClick = quit
})

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = GRAPH_TEXT_X_MARGIN, y = 5},
    text = "Fuel Temp"
})

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = GRAPH_TEXT_X_MARGIN, y = 6},
    text = "---- C",
    getText = function()
        return string.format("% 4d C", reactor.getFuelTemperature() or 0)
    end
})
debug(drawables[#drawables].p2:toString())

---   Fuel Temperature   ---
addDrawable(MultiValueFilledBar:new{
    p1 = Point:new{x = BAR_GRAPH_LEFT_X_MARGIN, y = 5},
    p2 = Point:new{x = BAR_GRAPH_RIGHT_X_MARGIN, y = 6},
    capacity = 2000,
    labels = {"<1350", ">=1350", "none"},
    quantities = {0, 0, 0},
    colors = {colors.blue, colors.red, colors.gray},
    orientation = 2,

    getQuantities = function()
        local temp = reactor.getFuelTemperature() or 0
        return math.floor(math.min(temp, 1350)), math.floor(math.max(temp - 1350, 0)), math.floor(math.max(0, 2000 - temp))
    end,

    onClick = quit
})

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = GRAPH_TEXT_X_MARGIN, y = 8},
    text = "Energy"
})

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = GRAPH_TEXT_X_MARGIN, y = 9},
    text = "--- %",
    getText = function()
        local percentage = ((reactor.getEnergyStored() or 0) / REACTOR_MAX_STORED_ENERGY) * 100
        return string.format("% 3d", percentage).."% Full"
    end
})

addDrawable(MultiValueFilledBar:new{
    p1 = Point:new{x = BAR_GRAPH_LEFT_X_MARGIN, y = 8},
    p2 = Point:new{x = BAR_GRAPH_RIGHT_X_MARGIN, y = 9},
    capacity = 100,
    labels = {"filled", "empty"},
    quantities = {0, 0},
    colors = {colors.red, colors.gray},
    orientation = 2,

    getQuantities = function()
        local v = clamp(0, 100 * ((reactor.getEnergyStored() or 0) / REACTOR_MAX_STORED_ENERGY), 100)
        debug("v = "..v)
        return v, 100 - v
    end
})

CONTROL_ROD_Y_START = 11
CONTROL_ROD_Y_END = CONTROL_ROD_Y_START + reactor.getNumberOfControlRods() * 2

for i=0, reactor.getNumberOfControlRods() - 1 do
    yPos = CONTROL_ROD_Y_START + i*2
    --debug("Control Rod "..i.." level = "..reactor.getControlRodLevel(i))
    addDrawable(StaticTextBox:new{
        p1 = Point:new{x = 3, y = yPos},
        text = "Control Rod "..i
    })

    offset = 4

    incrementControlRod = function( rodIdx )
        reactor.setControlRodLevel(rodIdx, math.min(100, reactor.getControlRodLevel(rodIdx) + 10))
    end

    decrementControlRod = function( rodIdx )
        reactor.setControlRodLevel(rodIdx, math.max(0, reactor.getControlRodLevel(rodIdx) - 10))
    end

    addDrawable(StaticTextBox:new{
        p1 = Point:new{x = 16 + offset, y = yPos},
        text = "X",
        onClick = function()
            reactor.setControlRodLevel(i, 0)
        end,
        backgroundColor = colors.red
    })

    addDrawable(StaticTextBox:new{
        p1 = Point:new{x = 18 + offset, y = yPos},
        text = "-",
        onClick = function()
            decrementControlRod(i)
        end,
        backgroundColor = colors.brown

    })

    addDrawable(MultiValueFilledBar:new{
        p1 = Point:new{x = 20 + offset, y = yPos},
        p2 = Point:new{x = 29 + offset, y = yPos},
        capacity = 100,
        labels = {"inserted", "empty"},
        quantities = {0, 0},
        colors = {colors.white, colors.gray},
        orientation = 2,

        getQuantities = function()
            local level = reactor.getControlRodLevel(i) or 0
            return level, 100 - level
        end
    })

    addDrawable(StaticTextBox:new{
        p1 = Point:new{x = 31 + offset, y = yPos},
        text = "+",
        onClick = function()
            incrementControlRod(i)
        end,
        backgroundColor = colors.brown
    })

    addDrawable(StaticTextBox:new{
        p1 = Point:new{x = 33 + offset, y = yPos},
        text = "=",
        onClick = function()
            reactor.setControlRodLevel(i, 100)
        end,
        backgroundColor = colors.green
    })
end

function getButtonColor()
    if reactor.getActive() then
        return colors.green
    end
    return colors.red
end

powerLabel = StaticTextBox:new{
    p1 = Point:new{x = 32, y = CONTROL_ROD_Y_END + 2},
    text = "Power",
    textColor = colors.black,
    backgroundColor = getButtonColor()
}

powerButton = Rectangle:new{
    p1 = Point:new{x = 30, y = CONTROL_ROD_Y_END},
    p2 = Point:new{x = 38, y = CONTROL_ROD_Y_END + 4},
    color = getButtonColor(),
    onClick = function()
        if powerButton.color == colors.green then
            reactor.setActive(false)
            powerButton.color = getButtonColor()
            powerLabel.backgroundColor = getButtonColor()
        elseif powerButton.color == colors.red then
            reactor.setActive(true)
            powerButton.color = colors.green
            powerLabel.backgroundColor = getButtonColor()
        end
    end
}
addDrawable(powerButton)
addDrawable(powerLabel)

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = 2, y = CONTROL_ROD_Y_END},
    text = "Fuel Consumption: "
})
addDrawable(StaticTextBox:new{
    p1 = Point:new{x = 2, y = CONTROL_ROD_Y_END + 1},
    text = "-.------ mB/t",
    getText = function()
        return string.format("%f", reactor.getFuelConsumedLastTick() or 0):sub(1, 7).." mB/t"
    end
})

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = 2, y = CONTROL_ROD_Y_END + 3},
    text = "Energy Output:"
})

addDrawable(StaticTextBox:new{
    p1 = Point:new{x = 2, y = CONTROL_ROD_Y_END + 4},
    text = "------ RF/t",
    getText = function()
        local energy = tostring(reactor.getEnergyProducedLastTick() or 0)
        local pIdx = energy:find('%.')
        if pIdx ~= nil then
            return energy:sub(1, pIdx + 2)
        end
        return energy
    end
})

run()
