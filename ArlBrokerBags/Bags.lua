local ldb = LibStub("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")

local BAG_IDS = {
    Enum.BagIndex.Backpack,
    Enum.BagIndex.Bag_1,
    Enum.BagIndex.Bag_2,
    Enum.BagIndex.Bag_3,
    Enum.BagIndex.Bag_4,
}
if Enum.BagIndex.ReagentBag then
    BAG_IDS[#BAG_IDS + 1] = Enum.BagIndex.ReagentBag
end
local junkItems = {}
local totalFree = 0
local totalSlots = 0
local totalJunkValue = 0

local function isJunkItem(itemID)
    if Scrap and Scrap.IsJunk then
        return Scrap:IsJunk(itemID)
    end
    local _, _, itemQuality = C_Item.GetItemInfo(itemID)
    return itemQuality == Enum.ItemQuality.Poor
end

local function scanBags()
    wipe(junkItems)
    totalFree = 0
    totalSlots = 0
    totalJunkValue = 0

    for _, bag in ipairs(BAG_IDS) do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        local freeSlots = C_Container.GetContainerNumFreeSlots(bag)
        totalSlots = totalSlots + numSlots
        totalFree = totalFree + freeSlots

        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                if isJunkItem(info.itemID) then
                    local vendorPrice = select(11, C_Item.GetItemInfo(info.itemID)) or 0
                    local stackValue = vendorPrice * info.stackCount
                    junkItems[#junkItems + 1] = {
                        bag = bag,
                        slot = slot,
                        itemID = info.itemID,
                        name = info.itemName or "",
                        icon = info.iconFileID,
                        quality = info.quality,
                        stackCount = info.stackCount,
                        stackValue = stackValue,
                    }
                    totalJunkValue = totalJunkValue + stackValue
                end
            end
        end
    end

    table.sort(junkItems, function(a, b) return a.stackValue < b.stackValue end)
end

local GOLD_COLOR = "|cffffd700"
local SILVER_COLOR = "|cffc7c7cf"
local COPPER_COLOR = "|cffeda55f"

local function formatMoney(copper)
    if copper <= 0 then return COPPER_COLOR .. "0c|r" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = format("%s%dg|r", GOLD_COLOR, gold)
    end
    if silver > 0 or gold > 0 then
        parts[#parts + 1] = format("%s%ds|r", SILVER_COLOR, silver)
    end
    parts[#parts + 1] = format("%s%dc|r", COPPER_COLOR, cop)
    return table.concat(parts, " ")
end

local function qualityColor(quality)
    local color = quality and ITEM_QUALITY_COLORS[quality]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

local function releaseTooltip()
    if LibQTip:IsAcquired("ArlBagsTip") then
        LibQTip:Release(LibQTip:Acquire("ArlBagsTip"))
    end
end

local function addSection(tooltip, title)
    tooltip:AddLine()
    local line = tooltip:AddHeader(title)
    tooltip:SetCellTextColor(line, 1, 1, 0.82, 0)
    tooltip:AddSeparator(1, 0.5, 0.5, 0.5, 0.5)
end

local function buildTooltip(anchor)
    local tooltip = LibQTip:Acquire("ArlBagsTip", 2, "LEFT", "RIGHT")
    tooltip:Clear()

    tooltip:AddHeader("Bags")
    tooltip:AddSeparator(2)

    -- Summary
    local line = tooltip:AddLine("Free slots", format("%d / %d", totalFree, totalSlots))
    if totalFree <= 2 then
        tooltip:SetCellTextColor(line, 2, 1, 0, 0)
    elseif totalFree <= 8 then
        tooltip:SetCellTextColor(line, 2, 1, 0.82, 0)
    else
        tooltip:SetCellTextColor(line, 2, 0, 1, 0)
    end

    -- Junk items
    local junkSource = Scrap and "Scrap" or "grey"
    addSection(tooltip, format("Junk items — %s (%d)", junkSource, #junkItems))

    if #junkItems == 0 then
        tooltip:AddLine("No junk items")
    else
        for _, item in ipairs(junkItems) do
            local label = item.name
            if item.stackCount > 1 then
                label = label .. " x" .. item.stackCount
            end
            local line = tooltip:AddLine(label, formatMoney(item.stackValue))
            local r, g, b = qualityColor(item.quality)
            tooltip:SetCellTextColor(line, 1, r, g, b)
        end

        tooltip:AddSeparator(1, 0.5, 0.5, 0.5, 0.5)
        local line = tooltip:AddLine("Total vendor value", formatMoney(totalJunkValue))
        tooltip:SetCellTextColor(line, 1, 1, 0.82, 0)
    end

    -- Hint
    if #junkItems > 0 then
        tooltip:AddLine()
        local cheapest = junkItems[1]
        local hint = format("Ctrl-click to destroy: %s (%s)", cheapest.name, formatMoney(cheapest.stackValue))
        local line = tooltip:AddLine(hint)
        tooltip:SetCellTextColor(line, 1, 0.5, 0.5, 0.5)
    end

    tooltip:SetScript("OnLeave", function(tip)
        if not tip:IsMouseOver() then
            releaseTooltip()
        end
    end)

    tooltip:SmartAnchorTo(anchor)
    tooltip:Show()
end

local dataobj = ldb:NewDataObject("arl_broker_bags", {
    type = "data source",
    text = "Bags: --",
    icon = 133633,
    OnEnter = function(self)
        scanBags()
        buildTooltip(self)
    end,
    OnLeave = function(self)
        if LibQTip:IsAcquired("ArlBagsTip") then
            local tooltip = LibQTip:Acquire("ArlBagsTip")
            if not tooltip:IsMouseOver() then
                LibQTip:Release(tooltip)
            end
        end
    end,
    OnClick = function(self, button)
        if button == "LeftButton" and IsControlKeyDown() then
            scanBags()
            if #junkItems == 0 then return end
            if GetCursorInfo() then return end
            local item = junkItems[1]
            local msg = format("Destroyed %s", item.name)
            if item.stackCount > 1 then
                msg = msg .. " x" .. item.stackCount
            end
            msg = msg .. " (" .. formatMoney(item.stackValue) .. ")"
            C_Container.PickupContainerItem(item.bag, item.slot)
            local cursorType, itemID = GetCursorInfo()
            if cursorType ~= "item" or itemID ~= item.itemID then
                ClearCursor()
                return
            end
            print("|cff888888[ArlBrokerBags]|r " .. msg)
            DeleteCursorItem()
        end
    end,
})

local frame = CreateFrame("Frame")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
    scanBags()
    dataobj.text = format("%d/%d", totalFree, totalSlots)
end)
