local ldb = LibStub("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")

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
    local p90Index = math.ceil(n * 0.9)
    local p90 = sorted[p90Index]

    return min, max, sum / n, p90
end

local function addSection(tooltip, title)
    tooltip:AddLine()
    local line = tooltip:AddHeader(title)
    tooltip:SetCellTextColor(line, 1, 1, 0.82, 0)
    tooltip:AddSeparator(1, 0.5, 0.5, 0.5, 0.5)
end

local function addRow(tooltip, label, value)
    local line = tooltip:AddLine(label, value)
    tooltip:SetCellTextColor(line, 2, 1, 1, 0)
end

local function buildTooltip(anchor)
    local tooltip = LibQTip:Acquire("SysInfoTip", 2, "LEFT", "RIGHT")

    tooltip:AddHeader("SysInfo")
    tooltip:AddSeparator(2)

    -- Framerate
    addSection(tooltip, "Framerate")
    addRow(tooltip, "Current", format("%.1f", GetFramerate()))
    local min, max, avg, p90 = computeStats()
    if min then
        addRow(tooltip, "Min", format("%.1f", min))
        addRow(tooltip, "Max", format("%.1f", max))
        addRow(tooltip, "Average", format("%.1f", avg))
        addRow(tooltip, "90th %", format("%.1f", p90))
    end

    -- Network
    addSection(tooltip, "Network")
    local _, _, homeLatency, worldLatency = GetNetStats()
    addRow(tooltip, "Home", format("%d ms", homeLatency))
    addRow(tooltip, "World", format("%d ms", worldLatency))

    -- Memory
    addSection(tooltip, "Memory")
    addRow(tooltip, "Total", formatMemory(gcinfo()))
    addRow(tooltip, "Addons", formatMemory(totalAddonMemory))

    if numAddons > 0 then
        tooltip:AddLine()
        local line = tooltip:AddLine(format("  Top 5 (of %d) addons:", numAddons))
        tooltip:SetCellTextColor(line, 1, 0.6, 0.6, 0.6)
        for i = 1, math.min(5, #addonMemoryData) do
            local entry = addonMemoryData[i]
            line = tooltip:AddLine("    " .. entry.name, formatMemory(entry.memory))
            tooltip:SetCellTextColor(line, 1, 0.9, 0.9, 0.9)
            tooltip:SetCellTextColor(line, 2, 0.8, 0.8, 0)
        end
    end

    tooltip:SetScript("OnLeave", function(tip)
        if not tip:IsMouseOver() then
            LibQTip:Release(tip)
        end
    end)

    tooltip:SmartAnchorTo(anchor)
    tooltip:Show()
end

local dataobj = ldb:NewDataObject("arl_broker_sysinfo", {
    type = "data source",
    text = "FPS: --",
    icon = "Interface\\AddOns\\ArlBrokerSysInfo\\icon",
    OnEnter = function(self)
        buildTooltip(self)
    end,
    OnLeave = function(self)
        if LibQTip:IsAcquired("SysInfoTip") then
            local tooltip = LibQTip:Acquire("SysInfoTip")
            if not tooltip:IsMouseOver() then
                LibQTip:Release(tooltip)
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
