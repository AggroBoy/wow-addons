local ldb = LibStub("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")

local UPDATE_INTERVAL = 1
local elapsed = UPDATE_INTERVAL
local sessionStart = GetTime and GetTime() or 0

local function getLocalTimeText()
    if type(date) ~= "function" then
        return "--:--"
    end

    local ok, text = pcall(date, "%H:%M")
    if ok and type(text) == "string" and text ~= "" then
        return text
    end

    return "--:--"
end

local function getServerTimeText()
    if type(GetGameTime) ~= "function" then
        return "--:--"
    end

    local hour, minute = GetGameTime()
    if type(hour) ~= "number" or type(minute) ~= "number" then
        return "--:--"
    end

    return format("%02d:%02d", hour, minute)
end

local function getSessionDurationText()
    if type(GetTime) ~= "function" then
        return "--:--"
    end

    local totalSeconds = math.max(0, math.floor(GetTime() - sessionStart))
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60

    if hours > 0 then
        return format("%d:%02d:%02d", hours, minutes, seconds)
    end

    return format("%02d:%02d", minutes, seconds)
end

local function releaseTooltip()
    if LibQTip:IsAcquired("ArlClockTip") then
        LibQTip:Release(LibQTip:Acquire("ArlClockTip"))
    end
end

local function populateTooltip(tooltip)
    tooltip:Clear()
    tooltip:AddHeader("Clock")
    tooltip:AddSeparator(2)

    local line = tooltip:AddLine("Local time", getLocalTimeText())
    tooltip:SetCellTextColor(line, 2, 1, 1, 0)
    line = tooltip:AddLine("Server time", getServerTimeText())
    tooltip:SetCellTextColor(line, 2, 1, 1, 0)

    tooltip:AddSeparator(2)

    line = tooltip:AddLine("Session", getSessionDurationText())
    tooltip:SetCellTextColor(line, 2, 1, 1, 0)

    tooltip:AddLine()
    line = tooltip:AddLine("Click to open the calendar")
    tooltip:SetCellTextColor(line, 1, 0.5, 0.5, 0.5)

    tooltip:SetScript("OnLeave", function(tip)
        if not tip:IsMouseOver() then
            releaseTooltip()
        end
    end)
end

local function refreshTooltip()
    if not LibQTip:IsAcquired("ArlClockTip") then
        return
    end

    local tooltip = LibQTip:Acquire("ArlClockTip")
    populateTooltip(tooltip)
end

local function buildTooltip(anchor)
    local tooltip = LibQTip:Acquire("ArlClockTip", 2, "LEFT", "RIGHT")
    populateTooltip(tooltip)

    tooltip:SmartAnchorTo(anchor)
    tooltip:Show()
end

local function openCalendar()
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.LoadAddOn then
        if not C_AddOns.IsAddOnLoaded("Blizzard_Calendar") then
            C_AddOns.LoadAddOn("Blizzard_Calendar")
        end
    end

    if Calendar_Toggle then
        Calendar_Toggle()
    elseif ToggleCalendar then
        ToggleCalendar()
    end
end

local dataobj = ldb:NewDataObject("arl_broker_clock", {
    type = "data source",
    text = "--:--",
    icon = "Interface\\ICONS\\INV_Misc_PocketWatch_01",
    OnEnter = function(self)
        buildTooltip(self)
    end,
    OnLeave = function(self)
        if LibQTip:IsAcquired("ArlClockTip") then
            local tooltip = LibQTip:Acquire("ArlClockTip")
            if not tooltip:IsMouseOver() then
                LibQTip:Release(tooltip)
            end
        end
    end,
    OnClick = function(_, button)
        if button == "LeftButton" then
            openCalendar()
        end
    end,
})

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
    dataobj.text = getLocalTimeText()
end)
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < UPDATE_INTERVAL then
        return
    end

    elapsed = 0
    dataobj.text = getLocalTimeText()
    refreshTooltip()
end)
