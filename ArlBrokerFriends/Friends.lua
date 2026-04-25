local ldb = LibStub("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")

local bnetOnline = {}
local charOnline = {}
local numBNetOnline = 0
local numBNetTotal = 0
local numCharOnline = 0
local numCharTotal = 0

local CLASS_COLORS = {}
local function cacheClassColors()
    for class, color in pairs(RAID_CLASS_COLORS) do
        CLASS_COLORS[class] = color
    end
end

local function updateFriends()
    wipe(bnetOnline)
    wipe(charOnline)

    -- Battle.net friends
    numBNetTotal = BNGetNumFriends()
    numBNetOnline = 0
    for i = 1, numBNetTotal do
        local info = C_BattleNet.GetFriendAccountInfo(i)
        if info and info.gameAccountInfo and info.gameAccountInfo.isOnline then
            numBNetOnline = numBNetOnline + 1
            local gameInfo = info.gameAccountInfo
            local entry = {
                bnetName = info.accountName or "Unknown",
                note = info.note,
                isWoW = gameInfo.clientProgram == BNET_CLIENT_WOW,
                charName = gameInfo.characterName,
                className = gameInfo.className,
                classFile = gameInfo.classFile,
                level = gameInfo.characterLevel,
                area = gameInfo.areaName,
                gameText = gameInfo.richPresence,
                gameAccountID = gameInfo.gameAccountID,
            }
            bnetOnline[#bnetOnline + 1] = entry
        end
    end

    -- Character friends
    numCharTotal = C_FriendList.GetNumFriends()
    numCharOnline = 0
    for i = 1, numCharTotal do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.connected then
            numCharOnline = numCharOnline + 1
            charOnline[#charOnline + 1] = {
                name = info.name,
                level = info.level,
                className = info.className,
                classFile = info.classFile or "",
                area = info.area,
                note = info.notes,
            }
        end
    end

    table.sort(bnetOnline, function(a, b) return a.bnetName < b.bnetName end)
    table.sort(charOnline, function(a, b) return a.name < b.name end)
end

local function addSection(tooltip, title)
    tooltip:AddLine()
    local line = tooltip:AddHeader(title)
    tooltip:SetCellTextColor(line, 1, 1, 0.82, 0)
    tooltip:AddSeparator(1, 0.5, 0.5, 0.5, 0.5)
end

local function classColor(classFile)
    local color = classFile and CLASS_COLORS[classFile]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

local function releaseTooltip()
    if LibQTip:IsAcquired("ArlFriendsTip") then
        LibQTip:Release(LibQTip:Acquire("ArlFriendsTip"))
    end
end

local function onBNetClick(cell, friend, button)
    if button == "LeftButton" then
        if IsAltKeyDown() and friend.isWoW and friend.gameAccountID then
            BNInviteFriend(friend.gameAccountID)
        elseif friend.isWoW and friend.charName then
            ChatFrame_SendTell(friend.charName)
        else
            ChatFrame_OpenChat("/w " .. friend.bnetName .. " ")
        end
        releaseTooltip()
    end
end

local function onCharClick(cell, friend, button)
    if button == "LeftButton" then
        if IsAltKeyDown() then
            InviteUnit(friend.name)
        else
            ChatFrame_SendTell(friend.name)
        end
        releaseTooltip()
    end
end

local function buildTooltip(anchor)
    if next(CLASS_COLORS) == nil then
        cacheClassColors()
    end

    local tooltip = LibQTip:Acquire("ArlFriendsTip", 2, "LEFT", "RIGHT")
    tooltip:Clear()

    tooltip:AddHeader("Friends")
    tooltip:AddSeparator(2)

    -- Battle.net friends
    addSection(tooltip, format("Battle.net (%d/%d)", numBNetOnline, numBNetTotal))

    if numBNetOnline == 0 then
        tooltip:AddLine("No friends online")
    else
        for _, friend in ipairs(bnetOnline) do
            local detail
            if friend.isWoW and friend.charName then
                detail = friend.charName
                if friend.area then
                    detail = detail .. " - " .. friend.area
                end
            elseif friend.gameText and friend.gameText ~= "" then
                detail = friend.gameText
            else
                detail = "Online"
            end

            local line = tooltip:AddLine(friend.bnetName, detail)
            if friend.isWoW and friend.classFile then
                local r, g, b = classColor(friend.classFile)
                tooltip:SetCellTextColor(line, 2, r, g, b)
            else
                tooltip:SetCellTextColor(line, 2, 0.6, 0.6, 0.6)
            end
            tooltip:SetLineScript(line, "OnMouseUp", onBNetClick, friend)
        end
    end

    -- Character friends
    addSection(tooltip, format("Character (%d/%d)", numCharOnline, numCharTotal))

    if numCharOnline == 0 then
        tooltip:AddLine("No friends online")
    else
        for _, friend in ipairs(charOnline) do
            local detail = ""
            if friend.level and friend.level > 0 then
                detail = "Lv" .. friend.level
            end
            if friend.className then
                if detail ~= "" then detail = detail .. " " end
                detail = detail .. friend.className
            end
            if friend.area then
                if detail ~= "" then detail = detail .. " - " end
                detail = detail .. friend.area
            end

            local line = tooltip:AddLine(friend.name, detail)
            local r, g, b = classColor(friend.classFile)
            tooltip:SetCellTextColor(line, 1, r, g, b)
            tooltip:SetCellTextColor(line, 2, 0.8, 0.8, 0.8)
            tooltip:SetLineScript(line, "OnMouseUp", onCharClick, friend)
        end
    end

    -- Hint
    tooltip:AddLine()
    local line = tooltip:AddLine("Click to whisper, Alt-click to invite")
    tooltip:SetCellTextColor(line, 1, 0.5, 0.5, 0.5)

    tooltip:SetScript("OnLeave", function(tip)
        if not tip:IsMouseOver() then
            releaseTooltip()
        end
    end)

    tooltip:SmartAnchorTo(anchor)
    tooltip:Show()
end

local dataobj = ldb:NewDataObject("arl_broker_friends", {
    type = "data source",
    text = "Friends: --",
    icon = "Interface\\ICONS\\INV_Misc_GroupLooking",
    OnEnter = function(self)
        updateFriends()
        buildTooltip(self)
    end,
    OnLeave = function(self)
        if LibQTip:IsAcquired("ArlFriendsTip") then
            local tooltip = LibQTip:Acquire("ArlFriendsTip")
            if not tooltip:IsMouseOver() then
                LibQTip:Release(tooltip)
            end
        end
    end,
})

local frame = CreateFrame("Frame")
frame:RegisterEvent("FRIENDLIST_UPDATE")
frame:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_FriendList.ShowFriends()
    end
    updateFriends()
    local totalOnline = numBNetOnline + numCharOnline
    local totalFriends = numBNetTotal + numCharTotal
    dataobj.text = format("%d/%d", totalOnline, totalFriends)
end)
