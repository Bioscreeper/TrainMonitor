local blockLength = 59
--In M/blocks

local component = require("component")
local thread = require("thread")
local gpu = component.gpu
local x, y = gpu.getViewport()
gpu.fill(1, 1, x, y, " ")

local colours = {5, 13, 1, 13, 14}

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
            local last = gpu.setBackground(colours[v["state"]], true)
            gpu.set(x + 3, k, " ")
            gpu.setBackground(last)
        end
    end
end

local aspects = {}

local function send(table)
    if component.list("modem") then
        local data = require("serialization").serialize(table)
        local modem = component.modem
        modem.broadcast(1029, data)
    else
        return false, "no modem"
    end
end

while true do
    local name, addr, box, state = require("event").pullMultiple("aspect_changed", "interrupted", "redstone_changed")
    if name == "aspect_changed" then
        local boxData = unparse(box)
        if not aspects[boxData[2]] then aspects[boxData[2]] = {} end
        if not aspects[boxData[2]][boxData[1]] then aspects[boxData[2]][boxData[1]] = {} end
        aspects[boxData[2]][boxData[1]]["state"]=state
        if state == 3 then
            aspects[boxData[2]][boxData[1]]["timer"]=require("computer").uptime()
            if aspects[boxData[2]][boxData[1]-1] then
                local timer = aspects[boxData[2]][boxData[1]-1]["timer"]
                local time = aspects[boxData[2]][boxData[1]]["timer"] - timer
                local speed =  string.format("%.2f",(blockLength / time))
                gpu.set(x-string.len(speed), y, tostring(speed))
            end
        end
        send(aspects)
        render(aspects)
    else
        break
    end
end
