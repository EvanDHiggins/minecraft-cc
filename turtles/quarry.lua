local tArgs = { ... }

if #tArgs ~= 2 then
    print("Run with: quarry <length of quarry side> <quarry depth>")
    print("Quarry sides must be at least 4 blocks.")
    return
end

local quarrySideLength = tonumber( tArgs[1] )
local quarryDepth = tonumber( tArgs[2] )
print("quarrySideLength = "..quarrySideLength)
print("quarryDepth = "..quarryDepth)

position = {x = 0, y = 0}
local vectors = {
    north = {dx =  0, dy =  1},
    south = {dx =  0, dy = -1},
    east  = {dx =  1, dy =  0},
    west  = {dx = -1, dy =  0}
}
local dirs = {"north", "east", "south", "west"}
local facingIndex = 1

local function currDir()
    return dirs[facingIndex]
end

local function indexOfDir( dir )
    for i=1, #dirs do
        if dirs[i] == dir then
            return i
        end
    end
end

local function forward( distance )
    for i=1, distance do
        while turtle.detect() do
            turtle.dig()
            os.sleep(0.5)
        end
        turtle.forward()
        position.x = position.x + vectors[dirs[facingIndex]].dx
        position.y = position.y + vectors[dirs[facingIndex]].dy
    end
end

local function turnRight()
    facingIndex = (facingIndex % 4) + 1
    turtle.turnRight()
end

local function turnLeft()
    facingIndex = facingIndex - 1
    if facingIndex < 1 then
        facingIndex = 4
    end
    turtle.turnLeft()
end

local function turnAround()
    turnRight()
    turnRight()
end

local function isDirection( dir ) 
    return dir == "north" or dir == "south" or dir == "east" or dir == "west"
end

local function rightDistance(a, b)
    return (a - b) % 4
end

local function leftDistance(a, b)
    return (b - a) % 4
end

local function setDirection( dir )
    if not isDirection(dir) then
        print("invalid direction. Doing nothing.")
        return
    end
    local index = indexOfDir(dir)
    local format = function(idx) return "("..dirs[idx]..", "..idx..")" end
    print("rotating from "..format(facingIndex).." to "..format(index))
    local leftDist = leftDistance(index, facingIndex)
    local rightDist = rightDistance(index, facingIndex)
    print("rDist = "..rightDist..", lDist = "..leftDist)
    if leftDist == 1 then
        turnLeft()
    elseif rightDist == 1 then
        turnRight()
    elseif dir ~= dirs[facingIndex] then
        turnAround()
    end
end

local function down( distance )
    for i=1, distance do
        while turtle.detectDown() do
            turtle.digDown()
            os.sleep(0.5)
        end
        turtle.down()
    end
end

local function strDir(x, y)
    return "("..x..", "..y..")"
end

local function moveTo( x, y )
    print("moving from "..strDir(position.x, position.y).." to "..strDir(x, y))
    local dx = x - position.x
    local dy = y - position.y
    print("offset Vector = "..strDir(dx, dy))
    if dx < 0 then
        setDirection("west")
        forward(math.abs(dx))
    elseif dx > 0 then
        setDirection("east")
        forward(dx)
    end

    if dy < 0 then
        setDirection("south")
        forward(math.abs(dy))
    elseif dy > 0 then
        setDirection("north")
        forward(dy)
    end
end

local function preHalfPointCoords( linearPos, side )
    local x
    if linearPos < side then 
        x = 0 
    else 
        x = linearPos - side 
    end

    local y
    if linearPos < side then
        y = linearPos - 1 
    else 
        y = side - 1
    end

    return x, y
end

local function getStepPosForDepth( side, currDepth ) 
    print("calling getStepPosForDepth")
    local halfPoint = 2*side - 1
    local linearPos = ((currDepth - 1) % (2 * side + 2 * (side - 2))) + 1
    print("halfPoint = "..halfPoint)
    print("linearPos = "..linearPos)

    if linearPos <= halfPoint then
        return preHalfPointCoords( linearPos, side )
    end

    local x, y = preHalfPointCoords( halfPoint - (linearPos - halfPoint), side )
    return y, x
end

local function printCurrPos()
    print("Current position = ("..position.x..", "..position.y..")")
end

local function placeStairs( side, currDepth )
    print("calling placeStairs")
    if currDepth <= 1 then
        return
    else
        local x, y = getStepPosForDepth( side, currDepth - 1 )
        print("stair position for depth "..currDepth.." is ("..x..", "..y..")")
        printCurrPos()
        moveTo(x, y)
        turtle.select(2)
        turtle.placeUp()
    end
end

-- quarry's n x n layer
local function quarryLayerRec( n )
    print("Calling quarryLayer with n = "..n)
    if n <= 1 then
        print("Digging 1x1 layer, noop")
        return
    elseif n == 2 then
        print("Digging 2x2 layer")
        forward(1)
        turnRight()
        forward(1)
        turnRight()
        forward(1)
    else
        forward(n-1)
        turnRight()
        forward(n-1)
        turnRight()
        forward(n-1)
        turnRight()
        forward(n-2)
        turnRight()
        forward(1)
        quarryLayerRec(n - 2)
    end
end

local function quarryLayer( side )
    moveTo(0, 0)
    setDirection("north")
    quarryLayerRec( side )
end

for currDepth=1, quarryDepth do
    moveTo(0, 0)
    down(1)
    quarryLayer(quarrySideLength)
    print("finished quarryLayer call")
    placeStairs(quarrySideLength, currDepth)
end
