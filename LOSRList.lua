---------------------------------------------------
-- List Window - By Boss / By Player / Dropped / Luck + Search
---------------------------------------------------

LOSR = LOSR or {}
LOSR.List = {}

local listFrame = CreateFrame("Frame", "LOSR_ListFrame", UIParent)
listFrame:SetSize(560, 580)
listFrame:SetPoint("CENTER")

listFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
})

listFrame:SetBackdropColor(0, 0, 0, 1)
listFrame:EnableMouse(true)
listFrame:SetMovable(true)
listFrame:RegisterForDrag("LeftButton")
listFrame:SetScript("OnDragStart", listFrame.StartMoving)
listFrame:SetScript("OnDragStop", listFrame.StopMovingOrSizing)
listFrame:Hide()

local RefreshList

---------------------------------------------------
-- Title / Close
---------------------------------------------------

local title = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("<LightsOut> SoftRes List")

local closeButton = CreateFrame("Button", nil, listFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", 0, 0)

---------------------------------------------------
-- Tabs
---------------------------------------------------

local bossTab = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
bossTab:SetSize(75, 22)
bossTab:SetPoint("TOPLEFT", 25, -40)
bossTab:SetText("By Boss")

local playerTab = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
playerTab:SetSize(75, 22)
playerTab:SetPoint("LEFT", bossTab, "RIGHT", 6, 0)
playerTab:SetText("By Player")

local droppedTab = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
droppedTab:SetSize(75, 22)
droppedTab:SetPoint("LEFT", playerTab, "RIGHT", 6, 0)
droppedTab:SetText("Dropped")

local luckTab = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
luckTab:SetSize(75, 22)
luckTab:SetPoint("LEFT", droppedTab, "RIGHT", 6, 0)
luckTab:SetText("Luck")
local summaryTab = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
summaryTab:SetSize(75, 22)
summaryTab:SetPoint("LEFT", luckTab, "RIGHT", 6, 0)
summaryTab:SetText("Summary")

---------------------------------------------------
-- Summary Bar
---------------------------------------------------

local summaryText = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
summaryText:SetPoint("TOPLEFT", 25, -65)
summaryText:SetWidth(430)
summaryText:SetJustifyH("LEFT")

local finalizeRaidBtn = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
finalizeRaidBtn:SetSize(130, 24)
finalizeRaidBtn:SetText("Finalize Raid")
finalizeRaidBtn:Hide()
---------------------------------------------------
-- Search
---------------------------------------------------

local searchLabel = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("TOPLEFT", 25, -84)
searchLabel:SetText("|cffffcc00Search:|r")

local searchBox = CreateFrame("EditBox", "LOSR_SearchBox", listFrame)
searchBox:SetSize(245, 20)
searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
searchBox:SetFontObject(ChatFontNormal)
searchBox:SetAutoFocus(false)
searchBox:EnableMouse(true)
searchBox:SetTextInsets(6, 6, 0, 0)

searchBox:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
searchBox:SetBackdropColor(0, 0, 0, 1)

local clearSearchBtn = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
clearSearchBtn:SetSize(55, 20)
clearSearchBtn:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
clearSearchBtn:SetText("Clear")

clearSearchBtn:SetScript("OnClick", function()
    searchBox:SetText("")
    searchBox:ClearFocus()
end)
local clearAllBtn = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
clearAllBtn:SetSize(80, 20)
clearAllBtn:SetPoint("LEFT", clearSearchBtn, "RIGHT", 6, 0)
clearAllBtn:SetText("Clear All")

clearAllBtn:SetScript("OnClick", function()
    LOSR:ClearAllData()

    if RefreshList then
        RefreshList()
    end
end)

searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
end)

searchBox:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
end)

searchBox:SetScript("OnTextChanged", function()
    if RefreshList then
        RefreshList()
    end
end)

---------------------------------------------------
-- Scroll Frame
---------------------------------------------------

local scroll = CreateFrame(
    "ScrollFrame",
    "LOSR_ListScrollFrame",
    listFrame,
    "UIPanelScrollFrameTemplate"
)

scroll:SetPoint("TOPLEFT", 25, -112)
scroll:SetPoint("BOTTOMRIGHT", -35, 20)

local content = CreateFrame("Frame", "LOSR_ListContentFrame", scroll)
content:SetWidth(400)
content:SetHeight(1)
scroll:SetScrollChild(content)

scroll:EnableMouseWheel(true)

scroll:SetScript("OnMouseWheel", function(self, delta)
    local step = 35
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local new = current - (delta * step)

    if new < 0 then
        new = 0
    elseif new > maxScroll then
        new = maxScroll
    end

    self:SetVerticalScroll(new)
end)

---------------------------------------------------
-- Row Pool
---------------------------------------------------

local rows = {}

local function HideAllRows()
    finalizeRaidBtn:Hide()

    for _, row in ipairs(rows) do
        row:Hide()
        row.button:Hide()
    end
end

local function GetRow(index)
if rows[index] then
    rows[index]:Show()
    return rows[index]
end

    local row = CreateFrame("Frame", nil, content)
    row:SetSize(400, 45)

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 0, 0)
    row.title:SetWidth(300)
    row.title:SetJustifyH("LEFT")
    row.title:SetWordWrap(true)

    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.sub:SetPoint("TOPLEFT", 16, -17)
    row.sub:SetWidth(365)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetWordWrap(true)
    row.sub:SetSpacing(1)

    row.button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.button:SetSize(80, 20)
    row.button:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, 0)
    row.button:SetText("Announce")
    row.button:ClearAllPoints()
row.button:SetSize(80, 20)
row.button:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, 0)
row.button:Enable()
row.button:SetText("Announce")
row.button:Hide()

    rows[index] = row
    return row
end

---------------------------------------------------
-- Helpers
---------------------------------------------------

local function GetSearch()
    return string.lower(LOSR:Trim(searchBox:GetText() or ""))
end

local function TextMatches(text, search)
    if search == "" then return true end
    return string.find(string.lower(text or ""), search, 1, true) ~= nil
end

local function PlayersMatch(players, search)
    if search == "" then return true end

    for _, name in ipairs(players or {}) do
        if TextMatches(name, search) then
            return true
        end
    end

    return false
end

local function ItemMatches(itemID, data, search)
    if search == "" then return true end

    return TextMatches(data.itemName, search)
        or TextMatches(data.bossName, search)
        or PlayersMatch(data.players, search)
        or TextMatches(tostring(itemID), search)
end

local function DropMatches(drop, search)
    if search == "" then return true end

    return TextMatches(drop.itemName, search)
        or TextMatches(drop.bossName, search)
        or PlayersMatch(drop.players, search)
        or TextMatches(tostring(drop.itemID), search)
        or TextMatches(drop.time, search)
end

local function GetItemDisplayName(itemID, data)
    local _, itemLink = GetItemInfo(itemID)

    if itemLink then
        return itemLink
    end

    return "|cffb048f8[" .. (data.itemName or "Unknown Item") .. "]|r"
end

local function UpdateTabs()
    bossTab:SetText("By Boss")
    playerTab:SetText("By Player")
    droppedTab:SetText("Dropped")
    luckTab:SetText("Luck")
	summaryTab:SetText("Summary")

    if LOSR.currentView == "player" then
        playerTab:SetText("|cff00ff00By Player|r")
    elseif LOSR.currentView == "dropped" then
        droppedTab:SetText("|cff00ff00Dropped|r")
    elseif LOSR.currentView == "luck" then
        luckTab:SetText("|cff00ff00Luck|r")
	elseif LOSR.currentView == "summary" then
    summaryTab:SetText("|cff00ff00Summary|r")
    else
        bossTab:SetText("|cff00ff00By Boss|r")
    end
end

---------------------------------------------------
-- Build Boss Data
---------------------------------------------------

local function BuildBossGroups()
    local groups = {}
    local search = GetSearch()

    for itemID, data in pairs(LOSR_DB.reserves or {}) do
        if ItemMatches(itemID, data, search) then
            local boss = data.bossName or "Unknown"
            groups[boss] = groups[boss] or {}

            table.insert(groups[boss], {
                itemID = itemID,
                data = data
            })
        end
    end

    for _, items in pairs(groups) do
        table.sort(items, function(a, b)
            return (a.data.itemName or "") < (b.data.itemName or "")
        end)
    end

    return groups
end

---------------------------------------------------
-- Build Player Data
---------------------------------------------------

local function BuildPlayerGroups()
    local groups = {}
    local search = GetSearch()

    for itemID, data in pairs(LOSR_DB.reserves or {}) do
        for _, playerName in ipairs(data.players or {}) do
            playerName = LOSR:Trim(playerName)

            local matches =
                search == ""
                or TextMatches(playerName, search)
                or TextMatches(data.itemName, search)
                or TextMatches(data.bossName, search)
                or TextMatches(tostring(itemID), search)

            if matches then
                groups[playerName] = groups[playerName] or {}

                table.insert(groups[playerName], {
                    itemID = itemID,
                    itemName = data.itemName or "Unknown Item",
                    bossName = data.bossName or "Unknown"
                })
            end
        end
    end

    for _, items in pairs(groups) do
        table.sort(items, function(a, b)
            if a.bossName ~= b.bossName then
                return a.bossName < b.bossName
            end

            return a.itemName < b.itemName
        end)
    end

    return groups
end

---------------------------------------------------
-- Build Dropped Data
---------------------------------------------------

local function BuildDroppedGroups()
    local groups = {}
    local search = GetSearch()

    for _, drop in ipairs(LOSR_DB.dropped or {}) do
        if DropMatches(drop, search) then
            local boss = drop.bossName or "Unknown"
            groups[boss] = groups[boss] or {}

            table.insert(groups[boss], drop)
        end
    end

    for _, drops in pairs(groups) do
        table.sort(drops, function(a, b)
            return (a.itemName or "") < (b.itemName or "")
        end)
    end

    return groups
end

---------------------------------------------------
-- Build Luck Data
---------------------------------------------------

local function BuildLuckData()
    local allPlayers = {}
    local hitCounts = {}
    local hitItems = {}
    local reserveCounts = LOSR:GetPlayerReserveCounts()
    local search = GetSearch()

    for _, data in pairs(LOSR_DB.reserves or {}) do
        for _, playerName in ipairs(data.players or {}) do
            playerName = LOSR:Trim(playerName)
            if playerName ~= "" then
                allPlayers[playerName] = true
            end
        end
    end

    for _, drop in ipairs(LOSR_DB.dropped or {}) do
        local seen = {}

        for _, playerName in ipairs(drop.players or {}) do
            playerName = LOSR:Trim(playerName)

            if playerName ~= "" and not seen[playerName] then
                seen[playerName] = true
                hitCounts[playerName] = (hitCounts[playerName] or 0) + 1
                hitItems[playerName] = hitItems[playerName] or {}

                table.insert(hitItems[playerName], {
                    itemName = drop.itemName or "Unknown Item",
                    bossName = drop.bossName or "Unknown"
                })
            end
        end
    end

    local lucky = {}
    local waiting = {}

    for playerName in pairs(allPlayers) do
        if TextMatches(playerName, search) then
            local hits = hitCounts[playerName] or 0

            if hits > 0 then
                local reserves = reserveCounts[playerName] or 0
local rate = 0

if reserves > 0 then
    rate = (hits / reserves) * 100
end

table.insert(lucky, {
    name = playerName,
    hits = hits,
    reserves = reserves,
    rate = rate,
    items = hitItems[playerName] or {}
})
            else
                table.insert(waiting, {
                    name = playerName,
                    hits = 0
                })
            end
        end
    end

    table.sort(lucky, function(a, b)
        if a.hits ~= b.hits then
            return a.hits > b.hits
        end
        return a.name < b.name
    end)

    table.sort(waiting, function(a, b)
        return a.name < b.name
    end)

    return lucky, waiting
end

---------------------------------------------------
-- Draw Boss View
---------------------------------------------------

local function DrawBossView()
    HideAllRows()

    local rowIndex = 1
    local y = 0
    local groups = BuildBossGroups()
    local bosses = LOSR:SortedKeys(groups)

    if #bosses == 0 then
        local row = GetRow(rowIndex)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetHeight(30)
        row.title:SetText("|cffffcc00No matching soft reserves.|r")
        row.sub:SetText("")
        row.button:Hide()

        content:SetHeight(80)
        return
    end

    for _, bossName in ipairs(bosses) do
        local bossItems = groups[bossName]

        local srCount = 0
        for _, entry in ipairs(bossItems) do
            srCount = srCount + #(entry.data.players or {})
        end

        local header = GetRow(rowIndex)
        header:SetPoint("TOPLEFT", 0, y)
        header:SetHeight(28)
        header.title:SetText("|cffffcc00" .. bossName .. " (" .. srCount .. " SRs)|r")
        header.sub:SetText("")
        header.button:Show()
        header.button:SetText("Announce")
        header.button:SetScript("OnClick", function()
            LOSR:AnnounceBoss(bossName, bossItems)
        end)

        rowIndex = rowIndex + 1
        y = y - 32

        for _, entry in ipairs(bossItems) do
            local data = entry.data

            local row = GetRow(rowIndex)
            row:SetPoint("TOPLEFT", 18, y)
            row:SetHeight(48)

            row.title:SetText("|cff87ceeb•|r " .. GetItemDisplayName(entry.itemID, data))
            row.sub:SetText("|cffffcc00Reserved by:|r " .. LOSR:FormatPlayers(data.players or {}, true))

            row.button:Show()
            row.button:SetText("Announce")
            row.button:SetScript("OnClick", function()
                LOSR:AnnounceItem(entry.itemID, data)
            end)

            rowIndex = rowIndex + 1
            y = y - 54
        end

        y = y - 8
    end

    content:SetHeight(math.max(80, math.abs(y) + 40))
end

---------------------------------------------------
-- Draw Player View
---------------------------------------------------

local function DrawPlayerView()
    HideAllRows()

    local rowIndex = 1
    local y = 0
    local groups = BuildPlayerGroups()
    local players = LOSR:SortedKeys(groups)

    if #players == 0 then
        local row = GetRow(rowIndex)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetHeight(30)
        row.title:SetText("|cffffcc00No matching soft reserves.|r")
        row.sub:SetText("")
        row.button:Hide()

        content:SetHeight(80)
        return
    end

    for _, playerName in ipairs(players) do
        local items = groups[playerName]

        local header = GetRow(rowIndex)
        header:SetPoint("TOPLEFT", 0, y)
        header:SetHeight(28)
        header.title:SetText("|cffffcc00" .. playerName .. " (" .. #items .. " SRs)|r")
        header.sub:SetText("")
        header.button:Hide()

        rowIndex = rowIndex + 1
        y = y - 32

        for _, item in ipairs(items) do
            local row = GetRow(rowIndex)
            row:SetPoint("TOPLEFT", 18, y)
            row:SetHeight(48)

            row.title:SetText("|cff87ceeb•|r " .. item.itemName)
            row.sub:SetText("|cffffcc00Boss:|r " .. item.bossName)
            row.button:Hide()

            rowIndex = rowIndex + 1
            y = y - 54
        end

        y = y - 8
    end

    content:SetHeight(math.max(80, math.abs(y) + 40))
end

---------------------------------------------------
-- Draw Dropped View
---------------------------------------------------

local function DrawDroppedView()
    HideAllRows()

    local rowIndex = 1
    local y = 0
    local groups = BuildDroppedGroups()
    local bosses = LOSR:SortedKeys(groups)

    if #bosses == 0 then
        local row = GetRow(rowIndex)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetHeight(30)
        row.title:SetText("|cffffcc00No dropped SR items tracked yet.|r")
        row.sub:SetText("")
        row.button:Hide()

        content:SetHeight(80)
        return
    end

    for _, bossName in ipairs(bosses) do
        local drops = groups[bossName]

        local header = GetRow(rowIndex)
        header:SetPoint("TOPLEFT", 0, y)
        header:SetHeight(28)
        header.title:SetText("|cffffcc00" .. bossName .. " (" .. #drops .. " drops)|r")
        header.sub:SetText("")
        header.button:Hide()

        rowIndex = rowIndex + 1
        y = y - 32

        for _, drop in ipairs(drops) do
            local row = GetRow(rowIndex)
            row:SetPoint("TOPLEFT", 18, y)
            row:SetHeight(50)

            row.title:SetText("|cff87ceeb•|r " .. (drop.itemName or ("ItemID " .. tostring(drop.itemID))))
            row.sub:SetText(
                "|cffffcc00Reserved by:|r " ..
                LOSR:FormatPlayers(drop.players or {}, true) ..
                "  |cff888888[" .. tostring(drop.time or "?") .. "]|r"
            )

            row.button:Show()
            row.button:SetText("Announce")
            row.button:SetScript("OnClick", function()
                LOSR:AnnounceLootItem({
                    itemID = drop.itemID,
                    itemName = drop.itemName,
                    link = drop.itemName,
                    players = drop.players or {}
                })
            end)

            rowIndex = rowIndex + 1
            y = y - 56
        end

        y = y - 8
    end

    content:SetHeight(math.max(80, math.abs(y) + 40))
end

---------------------------------------------------
-- Draw Luck View
---------------------------------------------------

local function DrawLuckView()
    HideAllRows()

    local rowIndex = 1
    local y = 0
    local lucky, waiting = BuildLuckData()

    local totalDrops = (LOSR.GetDroppedCount and LOSR:GetDroppedCount()) or 0
    local raidLuck = LOSR:GetRaidLuckRate()
    local verdict, verdictColor

if LOSR:IsRaidFinalized() then
    verdict, verdictColor = LOSR:GetFinalVerdict()
else
    verdict = "Pending raid finalization..."
    verdictColor = "|cff888888"
end

    local summary = GetRow(rowIndex)
    summary:SetPoint("TOPLEFT", 0, y)
    summary:SetHeight(34)
    summary.title:SetText("|cffffcc00Luck Rankings|r")
    summary.sub:SetText(
        "|cff87ceebTracked SR Drops:|r " ..
        totalDrops ..
        "    |cff87ceebRaid Luck:|r " ..
        string.format("%.1f%%", raidLuck)
    )
    summary.button:Hide()

    rowIndex = rowIndex + 1
    y = y - 44

    local verdictRow = GetRow(rowIndex)
    verdictRow:SetPoint("TOPLEFT", 0, y)
    verdictRow:SetHeight(44)
    verdictRow.title:SetText(verdictColor .. "LightsOut Verdict|r")
    verdictRow.sub:SetText(verdictColor .. verdict .. "|r")
    verdictRow.button:Hide()

    rowIndex = rowIndex + 1
    y = y - 54

    local luckyHeader = GetRow(rowIndex)
    luckyHeader:SetPoint("TOPLEFT", 0, y)
    luckyHeader:SetHeight(28)
    luckyHeader.title:SetText("|cff00ff00Luckiest Raiders|r")
    luckyHeader.sub:SetText("")
    luckyHeader.button:Hide()

    rowIndex = rowIndex + 1
    y = y - 32

    if #lucky == 0 then
        local row = GetRow(rowIndex)
        row:SetPoint("TOPLEFT", 18, y)
        row:SetHeight(28)
        row.title:SetText("|cff888888No SR hits yet.|r")
        row.sub:SetText("")
        row.button:Hide()

        rowIndex = rowIndex + 1
        y = y - 34
    else
        local lastHits = nil
        local displayRank = 0

        for i, entry in ipairs(lucky) do
            if entry.hits ~= lastHits then
                displayRank = i
                lastHits = entry.hits
            end

            local row = GetRow(rowIndex)
            row:SetPoint("TOPLEFT", 18, y)
            row:SetHeight(42)

            row.title:SetText(
                "|cffffffff#" .. displayRank .. " " .. entry.name .. "|r - |cff00ff00" ..
                entry.hits .. " hit" .. (entry.hits == 1 and "" or "s") ..
                "|r |cff888888(" ..
                (entry.reserves or 0) .. " SRs, " ..
                string.format("%.1f", entry.rate or 0) ..
                "%)|r"
            )

            local itemNames = {}
            for _, item in ipairs(entry.items or {}) do
                table.insert(itemNames, item.itemName)
            end

            row.sub:SetText("|cff888888" .. table.concat(itemNames, ", ") .. "|r")
            row.button:Hide()

            rowIndex = rowIndex + 1
            y = y - 48
        end
    end

    y = y - 8

    local waitingHeader = GetRow(rowIndex)
    waitingHeader:SetPoint("TOPLEFT", 0, y)
    waitingHeader:SetHeight(28)
    waitingHeader.title:SetText("|cffff5555Still Waiting|r")
    waitingHeader.sub:SetText("")
    waitingHeader.button:Hide()

    rowIndex = rowIndex + 1
    y = y - 32

    if #waiting == 0 then
        local row = GetRow(rowIndex)
        row:SetPoint("TOPLEFT", 18, y)
        row:SetHeight(28)
        row.title:SetText("|cff888888Nobody is waiting. Suspiciously lucky raid.|r")
        row.sub:SetText("")
        row.button:Hide()

        rowIndex = rowIndex + 1
        y = y - 34
    else
        for _, entry in ipairs(waiting) do
            local row = GetRow(rowIndex)
            row:SetPoint("TOPLEFT", 18, y)
            row:SetHeight(30)
            row.title:SetText("|cffffffff" .. entry.name .. "|r - |cff8888880 hits|r")
            row.sub:SetText("")
            row.button:Hide()

            rowIndex = rowIndex + 1
            y = y - 34
        end
    end

    content:SetHeight(math.max(80, math.abs(y) + 40))
end

local function DrawSummaryView()
    HideAllRows()

    local rowIndex = 1
    local y = 0

    local lines = {}

    if LOSR.GetSummaryLines then
        lines = LOSR:GetSummaryLines()
    else
        table.insert(lines, "Summary module not loaded.")
    end

    for i, line in ipairs(lines) do
        local row = GetRow(rowIndex)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetHeight(34)

        if i == 1 then
            row.title:SetText("|cffffcc00" .. line .. "|r")
        else
            row.title:SetText("|cffffffff" .. line .. "|r")
        end

        row.sub:SetText("")
        row.button:Hide()

        rowIndex = rowIndex + 1
        y = y - 38
    end
	
y = y - 10

local finalizeRow = GetRow(rowIndex)
finalizeRow:SetPoint("TOPLEFT", 0, y)
finalizeRow:SetHeight(55)
finalizeRow.title:SetText("")
finalizeRow.sub:SetText("")
finalizeRow.button:Hide()

if LOSR:IsRaidFinalized() then
    local session = LOSR:EnsureSession()

    finalizeRow.title:SetText("|cff00ff00Raid Finalized|r")

    if session.finalizedTime then
        finalizeRow.sub:SetText("|cff888888Finalized at " .. session.finalizedTime .. "|r")
    else
        finalizeRow.sub:SetText("")
    end
else
    finalizeRaidBtn:ClearAllPoints()
    finalizeRaidBtn:SetPoint("TOPLEFT", finalizeRow, "TOPLEFT", 115, 0)
    finalizeRaidBtn:SetText("Finalize Raid")
    finalizeRaidBtn:Show()
    finalizeRaidBtn:Enable()

    finalizeRaidBtn:SetScript("OnClick", function()
        LOSR:FinalizeRaid()

        if RefreshList then
            RefreshList()
        end
    end)
end

rowIndex = rowIndex + 1
y = y - 60

    content:SetHeight(math.max(80, math.abs(y) + 40))
end

---------------------------------------------------
-- Refresh
---------------------------------------------------

RefreshList = function()
    local stats = LOSR:GetReserveStats()
    local dropped = (LOSR.GetDroppedCount and LOSR:GetDroppedCount()) or 0

    summaryText:SetText(
        string.format(
            "|cff87ceebItems:|r %d   |cff87ceebSRs:|r %d   |cff87ceebPlayers:|r %d   |cff87ceebDrops:|r %d",
            stats.items,
            stats.reserves,
            stats.players,
            dropped
        )
    )

    scroll:SetVerticalScroll(0)
    UpdateTabs()

    if LOSR.currentView == "player" then
        DrawPlayerView()
    elseif LOSR.currentView == "dropped" then
        DrawDroppedView()
    elseif LOSR.currentView == "luck" then
    DrawLuckView()
elseif LOSR.currentView == "summary" then
    DrawSummaryView()
else
    DrawBossView()
end
end

---------------------------------------------------
-- Tab Handlers
---------------------------------------------------

bossTab:SetScript("OnClick", function()
    LOSR.currentView = "boss"
    RefreshList()
end)

playerTab:SetScript("OnClick", function()
    LOSR.currentView = "player"
    RefreshList()
end)

droppedTab:SetScript("OnClick", function()
    LOSR.currentView = "dropped"
    RefreshList()
end)

luckTab:SetScript("OnClick", function()
    LOSR.currentView = "luck"
    RefreshList()
end)

summaryTab:SetScript("OnClick", function()
    LOSR.currentView = "summary"
    RefreshList()
end)

---------------------------------------------------
-- Public Function
---------------------------------------------------

function LOSR:ShowListWindow()
    RefreshList()
    listFrame:Show()
end