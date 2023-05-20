local blockLength = 59
--In M/blocks

local component = require("component")
local thread = require("thread")
local gpu = component.gpu
--local rs = component.redstone
local x, y = gpu.getViewport()
gpu.fill(1, 1, x, y, " ")

local colours = {0x44CC00, 0xFFFF00, 0xB0B00F, 0xFF1100, 0xCC2200}
local aspects = {}


local function unparse(text)
    local out = {}
    local start, stop = string.find(text, ", ")
    out[1] = tonumber(string.sub(text, 1, (start - 1)))
    out[2] = tonumber(string.sub(text, (stop + 1)))
    return out
end
local function render(table)
    for i, t in pairs(table) do
        for k, v in ipairs(table[i]) do
            local x = (i*6) - 4
            gpu.set((x - string.len(k)) + 1, k, k..":")
            local last = gpu.setBackground(colours[v["state"]])
            gpu.set(x + 3, k, " ")
            gpu.setBackground(last)
        end
    end
end

local blinkState = nil

local function blink()
    --Iterate over all lines
    for i, l in pairs(aspects) do
        --Iterate over all signals
        for k, v in pairs(l) do
            local idx = v["state"]
            if idx == 2 or idx == 4 then
                local x = (i*6) - 4
                local last = gpu.setBackground(blinkState or colours[idx], true)
                gpu.set(x + 3, k, " ")
                gpu.setBackground(last)
            end
        end
    end
    if blinkState == 7 then blinkState = nil else blinkState = 7 end
end

event.timer(0.5, blink, math.huge)

while true do
    local name, addr, box, state = require("event").pullMultiple("aspect_changed", "interrupted", "redstone_changed")
    if name == "redstone_changed" then
        if state >= 1 then
            --event.timer(15, )
        end
    elseif name == "aspect_changed" then
        --if state == 5 then stop() end
        --That box has no label, error.
        if not box then error("Unlabeled box. Current state: "..state) end
        local boxData = unparse(box)

        --If, in the aspects table, that box's line doesn't exist, make it.
        if not aspects[boxData[2]] then aspects[boxData[2]] = {} end
        --If that box doesn't already have a table, make it.
        if not aspects[boxData[2]][boxData[1]] then aspects[boxData[2]][boxData[1]] = {} end
        --Set that box's state to what it thinks.
        aspects[boxData[2]][boxData[1]]["state"]=state

        --Speed: Check if the box was yellow.
        if state == 3 then
            --If it was, set a timer.
            aspects[boxData[2]][boxData[1]]["timer"]=require("computer").uptime()
            --Check if there was a box behind it.
            if aspects[boxData[2]][boxData[1]-1] then
                --Get it's timer, and store it.
                timer = aspects[boxData[2]][boxData[1]-1]["timer"]
                --Get this box's timer, and store it.
                speed = blockLength / string.format("%f", aspects[boxData[2]][boxData[1]]["timer"] - timer)
                gpu.set(x-string.len(speed), y, tostring(speed))
            end
        end

        
        local x = gpu.getViewport()
        gpu.set(x, 1, "↻")
        render(aspects)
        --for i, t in pairs(aspects) do
            --for k, v in ipairs(aspects[i]) do
                --local x = (i*6) - 4
                --gpu.set((x - string.len(k)) + 1, k, k..":")
                --local last = gpu.setBackground(colours[v])
                --gpu.set((x - string.len(k)) + 3, k, " ")
                --gpu.setBackground(last)
            --end
        --end
        gpu.set(x, 1, " ")
    else
        break
    end
end
