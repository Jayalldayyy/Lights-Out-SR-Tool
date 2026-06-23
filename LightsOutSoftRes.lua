print("LightsOutSoftRes Loaded")
local addonName = ...
local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("LOOT_CLOSED")

LOSR_DB = LOSR_DB or {}
LOSR_DB.reserves = LOSR_DB.reserves or {}   -- itemID -> {itemName, bossName, players = {}}
LOSR_DB.announce = LOSR_DB.announce or false
LOSR_DB.listViewMode = LOSR_DB.listViewMode or "boss"  -- "boss" or "player"

---------------------------------------------------
-- Main Display Frame 
---------------------------------------------------
local display = CreateFrame("Frame", "LOSR_DisplayFrame", UIParent)
display:SetSize(305, 140)
display:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
display:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = false,
    edgeSize = 28,
    insets = { left = 8, right = 8, top = 9, bottom = 8 },
})
display:SetBackdropColor(0, 0, 0, 1)
display:SetBackdropBorderColor(1, 1, 1, 1)
display:SetMovable(true)
display:EnableMouse(true)
display:RegisterForDrag("LeftButton")
display:SetScript("OnDragStart", display.StartMoving)
display:SetScript("OnDragStop", display.StopMovingOrSizing)
display:Hide()
display.currentItems = nil
display.itemFrames = {}

-- Global Announce All button 
local globalAnnounceBtn = CreateFrame("Button", nil, display, "UIPanelButtonTemplate")
globalAnnounceBtn:SetSize(110, 25)
globalAnnounceBtn:SetPoint("BOTTOM", 0, 15)
globalAnnounceBtn:SetText("Announce All")
display.globalAnnounceBtn = globalAnnounceBtn
globalAnnounceBtn:SetScript("OnClick", function()
    if not LOSR_DB.announce then
        print("|cffff0000Announce is OFF. Toggle with /losr announce|r")
        return
    end
    if not display.currentItems or #display.currentItems == 0 then
        print("|cffffff00No SoftRes to announce.|r")
        return
    end
    for _, item in ipairs(display.currentItems) do
        local countMap = {}
        for name in string.gmatch(item.names, "[^,]+") do
            name = name:gsub("^%s*(.-)%s*$", "%1")
            countMap[name] = (countMap[name] or 0) + 1
        end
        local parts = {}
        for name, count in pairs(countMap) do
            if count > 1 then
                table.insert(parts, name .. " (x" .. count .. ")")
            else
                table.insert(parts, name)
            end
        end
        local cleanNames = table.concat(parts, ", ")
        SendChatMessage(item.link .. " - Reserved by: " .. cleanNames, "RAID_WARNING")
    end
    print("|cff00ff00All SoftRes announced!|r")
end)

local closeBtn = CreateFrame("Button", nil, display, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", 0, 0)

---------------------------------------------------
-- CSV Import 
---------------------------------------------------
local function ImportCSV(csv)
    LOSR_DB.reserves = {}

    for line in string.gmatch(csv, "[^\r\n]+") do
        -- Format: "Item",ItemId,From,Name,...
        local itemName, itemID, bossName, playerName = string.match(line, '"?([^",]+)"?,(%d+),([^,]+),([^,]+)')

        if itemID and playerName then
            itemID = tonumber(itemID)
            bossName = bossName or "Unknown"
            playerName = playerName:gsub("^%s*(.-)%s*$", "%1")

            if not LOSR_DB.reserves[itemID] then
                LOSR_DB.reserves[itemID] = {
                    itemName = itemName or "Unknown Item",
                    bossName = bossName,
                    players = {}
                }
            end

            table.insert(LOSR_DB.reserves[itemID].players, playerName)
        end
    end

    local itemCount = 0
    local reserveCount = 0
    for _, data in pairs(LOSR_DB.reserves) do
        itemCount = itemCount + 1
        reserveCount = reserveCount + #data.players
    end

    print(string.format("|cff00ff00LightsOutSoftRes: Imported %d items with %d total reserves.|r", itemCount, reserveCount))
end

---------------------------------------------------
-- Update Display Items 
---------------------------------------------------
local function UpdateDisplayItems(hasSR)
    for _, frame in ipairs(display.itemFrames) do
        if frame and frame.Hide then frame:Hide() end
    end
    wipe(display.itemFrames)

    if not hasSR then
        display:SetHeight(140)
        local noSRText = display:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noSRText:SetPoint("CENTER", 0, 8)
        noSRText:SetText("|cffffcc00No SoftRes on this loot|r")
        table.insert(display.itemFrames, noSRText)
        globalAnnounceBtn:Hide()
    else
        globalAnnounceBtn:Show()
        local yOffset = -18
        local totalHeight = 60

        for _, item in ipairs(display.currentItems) do
            local itemFrame = CreateFrame("Frame", nil, display)
            itemFrame:SetSize(295, 48)
            itemFrame:SetPoint("TOPLEFT", 12, yOffset)
            table.insert(display.itemFrames, itemFrame)

            local linkText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            linkText:SetPoint("TOPLEFT", 4, 0)
            linkText:SetWidth(200)
            linkText:SetJustifyH("LEFT")
            linkText:SetText(item.link)

            local resText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            resText:SetPoint("TOPLEFT", 4, -15)
            resText:SetWidth(195)
            resText:SetJustifyH("LEFT")
            resText:SetWordWrap(true)
            resText:SetSpacing(1)

            local countMap = {}
            for name in string.gmatch(item.names, "[^,]+") do
                name = name:gsub("^%s*(.-)%s*$", "%1")
                countMap[name] = (countMap[name] or 0) + 1
            end

            local parts = {}
            for name, count in pairs(countMap) do
                if count > 1 then
                    table.insert(parts, "|cff00ff00" .. name .. "|r |cff888888(x" .. count .. ")|r")
                else
                    table.insert(parts, "|cffffffff" .. name .. "|r")
                end
            end

            resText:SetText("|cffffcc00Reserved by:|r " .. table.concat(parts, ", "))

            local btn = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
            btn:SetSize(62, 18)
            btn:SetPoint("TOPRIGHT", itemFrame, "TOPRIGHT", -6, -13)
            btn:SetText("Announce")
            btn.itemLink = item.link
            btn.itemNames = item.names
            btn:SetScript("OnClick", function(self)
                if not LOSR_DB.announce then
                    print("|cffff0000Announce is OFF.|r")
                    return
                end
                local countMap = {}
                for name in string.gmatch(self.itemNames, "[^,]+") do
                    name = name:gsub("^%s*(.-)%s*$", "%1")
                    countMap[name] = (countMap[name] or 0) + 1
                end
                local parts = {}
                for name, count in pairs(countMap) do
                    if count > 1 then
                        table.insert(parts, name .. " (x" .. count .. ")")
                    else
                        table.insert(parts, name)
                    end
                end
                local cleanNames = table.concat(parts, ", ")
                SendChatMessage(self.itemLink .. " - Reserved by: " .. cleanNames, "RAID_WARNING")
                print("|cff00ff00Announced: " .. self.itemLink .. "|r")
            end)

            yOffset = yOffset - 53
            totalHeight = totalHeight + 53
        end
        display:SetHeight(math.max(140, totalHeight + 48))
    end

    globalAnnounceBtn:SetText(LOSR_DB.announce and "Announce All" or "Announce All (OFF)")
end

---------------------------------------------------
-- Import UI Window 
---------------------------------------------------
local importFrame = CreateFrame("Frame", "LOSR_ImportFrame", UIParent)
importFrame:SetSize(450, 600)
importFrame:SetPoint("CENTER")
importFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
})
importFrame:SetBackdropColor(0,0,0,1)
importFrame:EnableMouse(true)
importFrame:SetMovable(true)
importFrame:RegisterForDrag("LeftButton")
importFrame:SetScript("OnDragStart", importFrame.StartMoving)
importFrame:SetScript("OnDragStop", importFrame.StopMovingOrSizing)
importFrame:Hide()
importFrame.title = importFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
importFrame.title:SetPoint("TOP", 0, -16)
importFrame.title:SetText("<LightsOut> SoftRes - Paste CSV Below")

local scrollFrame = CreateFrame("ScrollFrame", "LOSR_ImportScroll", importFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 25, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 80)
local editBox = CreateFrame("EditBox", nil, scrollFrame)
editBox:SetMultiLine(true)
editBox:SetFontObject(ChatFontNormal)
editBox:SetWidth(520)
editBox:SetAutoFocus(true)
editBox:SetScript("OnEscapePressed", function() importFrame:Hide() end)
editBox:SetScript("OnTextChanged", function(self)
    scrollFrame:UpdateScrollChildRect()
end)
scrollFrame:SetScrollChild(editBox)
editBox:SetHeight(1)

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 30
    local current = self:GetVerticalScroll()
    local new = current - (delta * step)
    local maxScroll = self:GetVerticalScrollRange()
    new = math.max(0, math.min(new, maxScroll))
    self:SetVerticalScroll(new)
end)

local importButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
importButton:SetSize(120, 30)
importButton:SetPoint("BOTTOM", 0, 20)
importButton:SetText("Import")
importButton:SetScript("OnClick", function()
    local text = editBox:GetText()
    ImportCSV(text)
    editBox:SetText("")
    importFrame:Hide()
end)

local clearButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
clearButton:SetSize(120, 30)
clearButton:SetPoint("BOTTOM", -130, 20)
clearButton:SetText("Clear SRs")
clearButton:SetScript("OnClick", function()
    LOSR_DB.reserves = {}
    print("|cffff0000LightsOutSoftRes: All saved SoftRes data cleared.|r")
end)

---------------------------------------------------
-- /losr list  
---------------------------------------------------
local listFrame = CreateFrame("Frame", "LOSR_ListFrame", UIParent)
listFrame:SetSize(420, 500)
listFrame:SetPoint("CENTER")
listFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
})
listFrame:SetBackdropColor(0,0,0,1)
listFrame:EnableMouse(true)
listFrame:SetMovable(true)
listFrame:RegisterForDrag("LeftButton")
listFrame:SetScript("OnDragStart", listFrame.StartMoving)
listFrame:SetScript("OnDragStop", listFrame.StopMovingOrSizing)
listFrame:Hide()

listFrame.title = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
listFrame.title:SetPoint("TOP", 0, -16)
listFrame.title:SetText("<LightsOut> SoftRes - All Reservations")

-- Tab buttons for switching views
local bossTabBtn = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
bossTabBtn:SetSize(80, 20)
bossTabBtn:SetPoint("TOPLEFT", 20, -35)
bossTabBtn:SetText("By Boss")

local playerTabBtn = CreateFrame("Button", nil, listFrame, "UIPanelButtonTemplate")
playerTabBtn:SetSize(80, 20)
playerTabBtn:SetPoint("LEFT", bossTabBtn, "RIGHT", 5, 0)
playerTabBtn:SetText("By Player")

-- Tab state tracking
local function UpdateTabButtons()
    if LOSR_DB.listViewMode == "boss" then
        bossTabBtn:Enable()
        playerTabBtn:Enable()
        bossTabBtn:SetText("|cff00ff00By Boss|r")
        playerTabBtn:SetText("By Player")
    else
        bossTabBtn:Enable()
        playerTabBtn:Enable()
        bossTabBtn:SetText("By Boss")
        playerTabBtn:SetText("|cff00ff00By Player|r")
    end
end

-- Scroll area - don't use fixed names
local listScroll
local listContent
local frameCounter = 0

local function CreateListScrollFrame()
    -- Hide and destroy old scroll frame completely
    if listScroll then
        listScroll:Hide()
        for _, child in ipairs({listScroll:GetChildren()}) do
            child:Hide()
        end
        listScroll = nil
    end
    
    -- Create unique scroll frame (avoid name collision)
    frameCounter = frameCounter + 1
    listScroll = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 20, -60)
    listScroll:SetPoint("BOTTOMRIGHT", -30, 60)
    
    listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetWidth(360)
    listContent:SetHeight(1)
    
    listScroll:SetScrollChild(listContent)
    
    -- Enable mouse wheel scrolling 
    listScroll:EnableMouseWheel(true)
    listScroll:SetScript("OnMouseWheel", function(self, delta)
        local step = 30
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()

        local new = current - (delta * step)
        new = math.max(0, math.min(new, maxScroll))

        listScroll:SetVerticalScroll(new)
    end)
end

-- Create initial scroll frame
CreateListScrollFrame()

local closeListBtn = CreateFrame("Button", nil, listFrame, "UIPanelCloseButton")
closeListBtn:SetPoint("TOPRIGHT", 0, 0)

---------------------------------------------------
-- Display function for By Boss view
---------------------------------------------------
local function ShowFullListByBoss()
    local yOffset = 0
    local hasAny = false

    -- Sort by boss name then item name
    local sortedItems = {}
    for itemID, data in pairs(LOSR_DB.reserves) do
        table.insert(sortedItems, {id = itemID, data = data})
    end
    table.sort(sortedItems, function(a, b)
        if a.data.bossName ~= b.data.bossName then
            return a.data.bossName < b.data.bossName
        end
        return a.data.itemName < b.data.itemName
    end)

    -- Group by boss
    local bossByName = {}
    for _, entry in ipairs(sortedItems) do
        local bossName = entry.data.bossName
        if not bossByName[bossName] then
            bossByName[bossName] = {}
        end
        table.insert(bossByName[bossName], entry)
    end

    local sortedBosses = {}
    for bossName, _ in pairs(bossByName) do
        table.insert(sortedBosses, bossName)
    end
    table.sort(sortedBosses)

    for _, bossName in ipairs(sortedBosses) do
        local bossItems = bossByName[bossName]
        hasAny = true

        -- Boss header with announce button
        local bossFrame = CreateFrame("Frame", nil, listContent)
        bossFrame:SetSize(340, 25)
        bossFrame:SetPoint("TOPLEFT", 10, yOffset)

        local bossText = bossFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        bossText:SetPoint("TOPLEFT", 0, 0)
        bossText:SetWidth(220)
        bossText:SetJustifyH("LEFT")
        bossText:SetText("|cffffcc00" .. bossName .. "|r")

        local announceBtn = CreateFrame("Button", nil, bossFrame, "UIPanelButtonTemplate")
        announceBtn:SetSize(80, 20)
        announceBtn:SetPoint("TOPRIGHT", 0, 2)
        announceBtn:SetText("Announce")
        announceBtn.bossName = bossName
        announceBtn.bossItems = bossItems

        announceBtn:SetScript("OnClick", function(self)
            if not LOSR_DB.announce then
                print("|cffff0000Announce is OFF. Toggle with /losr announce|r")
                return
            end

            for _, entry in ipairs(self.bossItems) do
                local data = entry.data
                local countMap = {}
                for _, name in ipairs(data.players) do
                    countMap[name] = (countMap[name] or 0) + 1
                end

                local playerParts = {}
                for name, count in pairs(countMap) do
                    if count > 1 then
                        table.insert(playerParts, name .. " (x" .. count .. ")")
                    else
                        table.insert(playerParts, name)
                    end
                end

                SendChatMessage(data.itemName .. " - Reserved by: " .. table.concat(playerParts, ", "), "RAID_WARNING")
            end

            print("|cff00ff00Announced all SRs for " .. self.bossName .. "|r")
        end)

        yOffset = yOffset - 28

        -- Items under this boss
        for _, entry in ipairs(bossItems) do
            local data = entry.data

            local line = listContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            line:SetPoint("TOPLEFT", 25, yOffset)
            line:SetWidth(315)
            line:SetJustifyH("LEFT")
            line:SetWordWrap(true)

            local countMap = {}
            for _, name in ipairs(data.players) do
                countMap[name] = (countMap[name] or 0) + 1
            end

            local playerParts = {}
            for name, count in pairs(countMap) do
                if count > 1 then
                    table.insert(playerParts, "|cff00ff00" .. name .. "|r |cff888888(x" .. count .. ")|r")
                else
                    table.insert(playerParts, name)
                end
            end

            line:SetText("|cff87ceeb• " .. data.itemName .. "|r\n  |cffffcc00Reserved by:|r " .. table.concat(playerParts, ", "))

            yOffset = yOffset - line:GetHeight() - 12
        end

        yOffset = yOffset - 10  -- Extra space between bosses
    end

    if not hasAny then
        local empty = listContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("CENTER", 0, 0)
        empty:SetText("No soft reserves imported yet.")
    end

    listContent:SetHeight(math.abs(yOffset) + 50)
end

---------------------------------------------------
-- Display function for By Player view
---------------------------------------------------
local function ShowFullListByPlayer()
    local yOffset = 0
    local hasAny = false

    -- Collect all items by player, counting duplicates per item
    local playerReserves = {}
    for itemID, data in pairs(LOSR_DB.reserves) do
        for _, playerName in ipairs(data.players) do
            if not playerReserves[playerName] then
                playerReserves[playerName] = {}
            end
            table.insert(playerReserves[playerName], {
                itemName = data.itemName,
                bossName = data.bossName,
                itemID = itemID
            })
        end
    end

    -- Sort players alphabetically
    local sortedPlayers = {}
    for playerName, _ in pairs(playerReserves) do
        table.insert(sortedPlayers, playerName)
    end
    table.sort(sortedPlayers)

    for _, playerName in ipairs(sortedPlayers) do
        local items = playerReserves[playerName]
        hasAny = true

        -- Player header
        local playerFrame = CreateFrame("Frame", nil, listContent)
        playerFrame:SetSize(340, 25)
        playerFrame:SetPoint("TOPLEFT", 10, yOffset)

        local playerText = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        playerText:SetPoint("TOPLEFT", 0, 0)
        playerText:SetWidth(340)
        playerText:SetJustifyH("LEFT")
        playerText:SetText("|cffffcc00" .. playerName .. "|r")

        yOffset = yOffset - 28

        -- Count duplicate items for this player
        local itemCounts = {}
        for _, item in ipairs(items) do
            local key = item.itemID
            itemCounts[key] = (itemCounts[key] or 0) + 1
        end

        -- Display items, consolidating duplicates
        local displayedItems = {}
        for _, item in ipairs(items) do
            local key = item.itemID
            if not displayedItems[key] then
                displayedItems[key] = true
                local count = itemCounts[key]
                
                local line = listContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                line:SetPoint("TOPLEFT", 25, yOffset)
                line:SetWidth(315)
                line:SetJustifyH("LEFT")
                line:SetWordWrap(true)

                if count > 1 then
                    line:SetText("|cff87ceeb• " .. item.itemName .. "|r |cff00ff00(x" .. count .. ")|r\n  |cffffcc00Boss:|r " .. item.bossName)
                else
                    line:SetText("|cff87ceeb• " .. item.itemName .. "|r\n  |cffffcc00Boss:|r " .. item.bossName)
                end

                yOffset = yOffset - line:GetHeight() - 12
            end
        end

        yOffset = yOffset - 10  -- Extra space between players
    end

    if not hasAny then
        local empty = listContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("CENTER", 0, 0)
        empty:SetText("No soft reserves imported yet.")
    end

    listContent:SetHeight(math.abs(yOffset) + 50)
end

---------------------------------------------------
-- Refresh function that shows correct view
---------------------------------------------------
local function RefreshListDisplay()
    -- Recreate scroll frame to clear all old content
    CreateListScrollFrame()
    listScroll:SetVerticalScroll(0)
    UpdateTabButtons()
    
    if LOSR_DB.listViewMode == "boss" then
        ShowFullListByBoss()
    else
        ShowFullListByPlayer()
    end
end

---------------------------------------------------
-- Tab button click handlers
---------------------------------------------------
bossTabBtn:SetScript("OnClick", function()
    LOSR_DB.listViewMode = "boss"
    RefreshListDisplay()
end)

playerTabBtn:SetScript("OnClick", function()
    LOSR_DB.listViewMode = "player"
    RefreshListDisplay()
end)

---------------------------------------------------
-- Show list frame wrapper
---------------------------------------------------
local function ShowFullList()
    RefreshListDisplay()
    listFrame:Show()
end

---------------------------------------------------
-- Slash Commands
---------------------------------------------------
SLASH_LOSR1 = "/losr"
SlashCmdList["LOSR"] = function(msg)
    local cmd = strlower(msg or "")
    if cmd == "import" then
        importFrame:Show()
    elseif cmd == "list" then
        ShowFullList()
    elseif cmd == "announce" then
        LOSR_DB.announce = not LOSR_DB.announce
        print("Raid announce:", LOSR_DB.announce and "|cff00ff00ON|r" or "|cffff0000OFF|r")
        if display:IsShown() then
            display.globalAnnounceBtn:SetText(LOSR_DB.announce and "Announce All" or "Announce All (OFF)")
        end
    else
        print("|cff00ffffLightsOut SoftRes Commands:|r")
        print("/losr import   - Open CSV import window")
        print("/losr list     - Show all soft reserves (with bosses)")
        print("/losr announce - Toggle raid announcements")
    end
end

---------------------------------------------------
-- Loot Detection
---------------------------------------------------
f:SetScript("OnEvent", function(self, event)
    if event == "LOOT_OPENED" then
        local foundItems = {}
        for i = 1, GetNumLootItems() do
            local link = GetLootSlotLink(i)
            if link then
                local itemID = tonumber(string.match(link, "item:(%d+)"))
                if itemID and LOSR_DB.reserves[itemID] then
                    local names = table.concat(LOSR_DB.reserves[itemID].players, ", ")
                    table.insert(foundItems, {
                        link = link,
                        names = names
                    })
                end
            end
        end
        display.currentItems = foundItems
        UpdateDisplayItems(#foundItems > 0)
        display:Show()
    elseif event == "LOOT_CLOSED" then
        display:Hide()
        display.currentItems = nil
        for _, frame in ipairs(display.itemFrames) do
            if frame and frame.Hide then frame:Hide() end
        end
        wipe(display.itemFrames)
        globalAnnounceBtn:Show()
        display:SetHeight(140)
    end
end)
