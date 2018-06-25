
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
    start = Point:new{x = 0, y = 0},
    xWidth = 1,
    yHeight = 1,
    color = 1,
    onClick = function() debug("asdfasdf") end
}

function DrawableRect:new(rect)
    rect = rect or {}
    setmetatable(rect, self)
    self.__index = self
    return rect
end

function DrawableRect:draw()
    local pt = self:getBottomRightPoint()
    for row=self.start.y, pt.y do
        paintutils.drawLine(self.start.x, row, pt.x, row, self.color)
    end
end

function DrawableRect:getBottomRightPoint()
    return Point:new{x = self.start.x + self.xWidth, y = self.start.y + self.yHeight}
end

function DrawableRect:contains( pos )
    local bottom = self:getBottomRightPoint()
    return pos.x >= self.start.x and pos.y >= self.start.y and pos.x <= bottom.x and pos.y <= bottom.y
end

function DrawableRect:click()
    self.onClick()
end


ProgressBar = DrawableRect:new()

function ProgressBar:new(bar)
    bar = bar or {backgroundColor = ""}
    setmetatable(bar, self)
    self.__index = self
    return bar
end

local exiting = false

function run()
    local monitor = peripheral.wrap("right")
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

local rect = DrawableRect:new{start = Point:new{x = 3, y = 2}, xWidth = 10, yHeight = 2, onClick = quit}
table.insert(drawables, rect)
local rect = DrawableRect:new{start = Point:new{x = 20, y = 20}, xWidth = 4, yHeight = 1, color = colors.red, onClick = quit }
table.insert(drawables, rect)
run()
