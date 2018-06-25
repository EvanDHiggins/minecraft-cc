print("Testing works!")

local colors = { green = 32, red = 16384, black = 32768}

local function setScreenColor( color )
    if colors[color] == nil then
        term.setBackgroundColor(colors["black"])
        term.clear()
        return
    end
    term.setBackgroundColor(colors[color])
    term.clear()
end

local function debug( str )
    local dbgm = peripheral.wrap("top")
    dbgm.setTextScale(0.5)
    dbgm.write(str)
    local x, y = dbgm.getCursorPos()
    dbgm.setCursorPos(1, y + 1)
end

local function presentMonitorForMouseClick() 
    print("blah")
    local currColor = "green"
    local monitor = peripheral.wrap("right")
    term.redirect(monitor)

    setScreenColor(currColor)
    monitor.setTextScale(1)

    while not exiting do
        local event, side, xPos, yPos = os.pullEvent("monitor_touch")
        debug("Click: ("..xPos..", "..yPos..")")
        if xPos <= 4 and yPos <= 4 then
            exiting = true
            setScreenColor("black")
            term.restore()
            return
        end
        if currColor == "green" then
            currColor = "red"
            setScreenColor(currColor)
        else
            currColor = "green"
            setScreenColor(currColor)
        end
    end
end

exiting = false

local function adjustFuelRods()
    print("Running fuel rods thingy...")
    local reactor = peripheral.wrap("BigReactors-Reactor_0")
    if reactor == nil then
        print("Error connecting to reactor. Exiting.")
        return
    end
    local dir = 1
    while not exiting do
        local level = reactor.getControlRodLevel(0)
        print("Fuel rod level = "..level)
        if level == 100 then
            dir = -1
        elseif level == 0 then
            dir = 1
        end
        reactor.setControlRodLevel(0, level + dir)
        os.sleep(1)
    end
end

parallel.waitForAll(adjustFuelRods, presentMonitorForMouseClick)
