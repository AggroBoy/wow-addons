local ldb = LibStub("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")

local SLOT_NAMES = {
    [1]  = "Head",
    [3]  = "Shoulder",
    [5]  = "Chest",
    [6]  = "Waist",
    [7]  = "Legs",
    [8]  = "Feet",
    [9]  = "Wrist",
    [10] = "Hands",
    [16] = "Main Hand",
    [17] = "Off Hand",
}

local durabilityData = {}
local lowestItem = nil

local function getDurabilityColor(pct)
    if pct >= 0.66 then
        local g = 1.0
        local r = (1.0 - pct) / 0.34
        return r, g, 0
    elseif pct >= 0.33 then
        local r = 1.0
        local g = (pct - 0.33) / 0.33
        return r, g, 0
    else
        return 1.0, 0, 0
    end
end

local function updateDurability()
    wipe(durabilityData)
    lowestItem = nil
    local lowestPct = 2

    for slotId, slotName in pairs(SLOT_NAMES) do
        local current, maximum = GetInventoryItemDurability(slotId)
        if current and maximum and maximum > 0 then
            local pct = current / maximum
            durabilityData[#durabilityData + 1] = {
                slot = slotName,
                current = current,
                maximum = maximum,
                pct = pct,
            }
            if pct < lowestPct then
                lowestPct = pct
                lowestItem = durabilityData[#durabilityData]
            end
        end
    end

    table.sort(durabilityData, function(a, b) return a.pct < b.pct end)
end

local function addSection(tooltip, title)
    tooltip:AddLine()
    local line = tooltip:AddHeader(title)
    tooltip:SetCellTextColor(line, 1, 1, 0.82, 0)
    tooltip:AddSeparator(1, 0.5, 0.5, 0.5, 0.5)
end

local function buildTooltip(anchor)
    local tooltip = LibQTip:Acquire("ArlDurabilityTip", 2, "LEFT", "RIGHT")

    tooltip:AddHeader("Durability")
    tooltip:AddSeparator(2)

    addSection(tooltip, "Equipment")

    if #durabilityData == 0 then
        tooltip:AddLine("No equipment with durability")
    else
        for i, item in ipairs(durabilityData) do
            local pctText = format("%d%%", item.pct * 100)
            local valueText = format("%d / %d  (%s)", item.current, item.maximum, pctText)
            local line = tooltip:AddLine(item.slot, valueText)
            local r, g, b = getDurabilityColor(item.pct)
            tooltip:SetCellTextColor(line, 2, r, g, b)
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

local dataobj = ldb:NewDataObject("arl_broker_durability", {
    type = "data source",
    text = "Durability: --",
    icon = "Interface\\ICONS\\Trade_BlackSmithing",
    OnEnter = function(self)
        updateDurability()
        buildTooltip(self)
    end,
    OnLeave = function(self)
        if LibQTip:IsAcquired("ArlDurabilityTip") then
            local tooltip = LibQTip:Acquire("ArlDurabilityTip")
            if not tooltip:IsMouseOver() then
                LibQTip:Release(tooltip)
            end
        end
    end,
})

local wasWarning = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
    updateDurability()
    local isWarning = lowestItem and lowestItem.pct < 0.66
    if isWarning then
        local r, g, b = getDurabilityColor(lowestItem.pct)
        local color = format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
        dataobj.text = format("%s: %s%d%%|r", lowestItem.slot, color, lowestItem.pct * 100)
        if not wasWarning then
            PlaySoundFile("Interface\\AddOns\\ArlBrokerDurability\\error.mp3", "Master")
        end
    else
        dataobj.text = ""
    end
    wasWarning = isWarning
end)
