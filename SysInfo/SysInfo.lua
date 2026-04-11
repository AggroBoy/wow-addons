local ldb = LibStub("LibDataBroker-1.1")

local HISTORY_SECONDS = 60
local UPDATE_INTERVAL = 1
local MEMORY_UPDATE_INTERVAL = 10
local elapsed = 0
local memoryElapsed = MEMORY_UPDATE_INTERVAL -- force immediate first update
local fpsSamples = {}
local addonMemoryData = {}
local totalAddonMemory = 0
local numAddons = 0

local function updateAddonMemory()
    UpdateAddOnMemoryUsage()
    numAddons = C_AddOns.GetNumAddOns()
    totalAddonMemory = 0
    addonMemoryData = {}
    for i = 1, numAddons do
        local mem = GetAddOnMemoryUsage(i)
        totalAddonMemory = totalAddonMemory + mem
        addonMemoryData[i] = { name = C_AddOns.GetAddOnInfo(i), memory = mem }
    end
    table.sort(addonMemoryData, function(a, b) return a.memory > b.memory end)
end

local function formatMemory(kb)
    if kb >= 1024 then
        return format("%.1f MB", kb / 1024)
    end
    return format("%.0f KB", kb)
end

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

        tooltip:AddLine(" ")
        tooltip:AddLine("Memory", 0.8, 0.8, 0.8)
        tooltip:AddDoubleLine("Total", formatMemory(gcinfo()), 1, 1, 1, 1, 1, 0)
        tooltip:AddDoubleLine("Addons", formatMemory(totalAddonMemory), 1, 1, 1, 1, 1, 0)
        if numAddons > 0 then
            tooltip:AddLine(" ")
            tooltip:AddLine(format("Top 5 (of %d) addons", numAddons), 0.8, 0.8, 0.8)
            for i = 1, math.min(5, #addonMemoryData) do
                local entry = addonMemoryData[i]
                tooltip:AddDoubleLine(entry.name, formatMemory(entry.memory), 1, 1, 1, 1, 1, 0)
            end
        end
    end,
})

local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    memoryElapsed = memoryElapsed + dt

    if memoryElapsed >= MEMORY_UPDATE_INTERVAL then
        memoryElapsed = 0
        updateAddonMemory()
    end

    if elapsed < UPDATE_INTERVAL then return end
    elapsed = 0

    local fps = GetFramerate()
    table.insert(fpsSamples, fps)
    if #fpsSamples > HISTORY_SECONDS then
        table.remove(fpsSamples, 1)
    end

    dataobj.text = format("%.0f fps", fps)
end)
