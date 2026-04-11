local ldb = LibStub("LibDataBroker-1.1")

local HISTORY_SECONDS = 60
local UPDATE_INTERVAL = 1
local elapsed = 0
local fpsSamples = {}

local function computeStats()
    local n = #fpsSamples
    if n == 0 then return nil end

    local min, max, sum = fpsSamples[1], fpsSamples[1], 0
    for i = 1, n do
        local v = fpsSamples[i]
        if v < min then min = v end
        if v > max then max = v end
        sum = sum + v
    end

    local sorted = {}
    for i = 1, n do sorted[i] = fpsSamples[i] end
    table.sort(sorted)
    local p90Index = math.ceil(n * 0.1) -- 90th percentile = 10% worst
    local p90 = sorted[p90Index]

    return min, max, sum / n, p90
end

local dataobj = ldb:NewDataObject("SysInfo", {
    type = "data source",
    text = "FPS: --",
    icon = "Interface\\AddOns\\SysInfo\\icon",
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("SysInfo")

        tooltip:AddLine(" ")
        tooltip:AddLine("Framerate", 0.8, 0.8, 0.8)
        tooltip:AddDoubleLine("Current", format("%.1f", GetFramerate()), 1, 1, 1, 1, 1, 0)
        local min, max, avg, p90 = computeStats()
        if min then
            tooltip:AddDoubleLine("Min", format("%.1f", min), 1, 1, 1, 1, 1, 0)
            tooltip:AddDoubleLine("Max", format("%.1f", max), 1, 1, 1, 1, 1, 0)
            tooltip:AddDoubleLine("Average", format("%.1f", avg), 1, 1, 1, 1, 1, 0)
            tooltip:AddDoubleLine("90th %", format("%.1f", p90), 1, 1, 1, 1, 1, 0)
        end

        tooltip:AddLine(" ")
        tooltip:AddLine("Network", 0.8, 0.8, 0.8)
        local _, _, homeLatency, worldLatency = GetNetStats()
        tooltip:AddDoubleLine("Home", format("%d ms", homeLatency), 1, 1, 1, 1, 1, 0)
        tooltip:AddDoubleLine("World", format("%d ms", worldLatency), 1, 1, 1, 1, 1, 0)
    end,
})

local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < UPDATE_INTERVAL then return end
    elapsed = 0

    local fps = GetFramerate()
    table.insert(fpsSamples, fps)
    if #fpsSamples > HISTORY_SECONDS then
        table.remove(fpsSamples, 1)
    end

    dataobj.text = format("%.0f fps", fps)
end)
