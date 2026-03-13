print("LightsOutSoftRes Loaded")
local addonName = ...
local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("LOOT_CLOSED")
LOSR_DB = LOSR_DB or {}
LOSR_DB.reserves = LOSR_DB.reserves or {}
LOSR_DB.announce = LOSR_DB.announce or false

---------------------------------------------------
-- Main Display Frame
---------------------------------------------------
local display = CreateFrame("Frame", "LOSR_DisplayFrame", UIParent)
display:SetSize(300, 120)  -- Slightly wider for per-item buttons
display:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
display:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
})
display:SetBackdropColor(0, 0, 0, 0.9)
display:SetMovable(true)
display:EnableMouse(true)
display:RegisterForDrag("LeftButton")
display:SetScript("OnDragStart", display.StartMoving)
display:SetScript("OnDragStop", display.StopMovingOrSizing)
display:Hide()
display.currentItems = nil
display.itemFrames = {}  -- Per-item subframes

-- Global Announce All button
local globalAnnounceBtn = CreateFrame("Button", nil, display, "UIPanelButtonTemplate")
globalAnnounceBtn:SetSize(100, 25)
globalAnnounceBtn:SetPoint("BOTTOM", 0, 15)
globalAnnounceBtn:SetText("Announce All")
display.globalAnnounceBtn = globalAnnounceBtn
globalAnnounceBtn:SetScript("OnClick", function()
    if not LOSR_DB.announce then
        print("|cffff0000Announce is OFF. Toggle with /losr announce|r")
        return
    end
    if not display.currentItems or #display.currentItems == 0 then return end
    for _, item in ipairs(display.currentItems) do
        SendChatMessage(item.link .. " - Reserved by: " .. item.names, "RAID_WARNING")
    end
    print("|cff00ff00All SoftRes announced!|r")
end)

-- Close Button
local closeBtn = CreateFrame("Button", nil, display, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", 0, 0)

-- Function to build/update per-item display
local function UpdateDisplayItems()
    -- Clear previous item frames
    for _, frame in ipairs(display.itemFrames) do
        frame:Hide()
    end
    wipe(display.itemFrames)

    if not display.currentItems or #display.currentItems == 0 then return end

    local yOffset = -20
    local totalHeight = 0

    for i, item in ipairs(display.currentItems) do
        local itemFrame = CreateFrame("Frame", nil, display)
        itemFrame:SetSize(330, 65)
        itemFrame:SetPoint("TOPLEFT", 15, yOffset)
        table.insert(display.itemFrames, itemFrame)

        -- Item link
        local linkText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        linkText:SetPoint("TOPLEFT", -10, 0)
        linkText:SetWidth(230)
        linkText:SetJustifyH("LEFT")
        linkText:SetText(item.link)

        -- Soft Res line
        local resText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        resText:SetPoint("TOPLEFT", -10, -18)
        resText:SetWidth(200)
        resText:SetJustifyH("LEFT")
        resText:SetText("|cffffcc00Reserved by:|r " .. item.names)

        -- Per-item Announce button
        local btn = CreateFrame("Button", nil, itemFrame, "UIPanelButtonTemplate")
        btn:SetSize(70, 20)
        btn:SetPoint("TOPRIGHT", itemFrame, "TOPRIGHT", -50, -12)
        btn:SetText("Announce")
        btn.itemLink = item.link
        btn.itemNames = item.names
        btn:SetScript("OnClick", function(self)
            if not LOSR_DB.announce then
                print("|cffff0000Announce is OFF.|r")
                return
            end
            SendChatMessage(self.itemLink .. " - Reserved by: " .. self.itemNames, "RAID_WARNING")
            print("|cff00ff00Announced: " .. self.itemLink .. "|r")
        end)

        yOffset = yOffset - 70
        totalHeight = totalHeight + 70
    end

    -- Adjust main frame height
    display:SetHeight(math.max(140, totalHeight + 80))  -- + buffer for global button

    -- Update global button text
    globalAnnounceBtn:SetText(LOSR_DB.announce and "Announce All" or "Announce All (OFF)")
end

---------------------------------------------------
-- CSV Import Logic
---------------------------------------------------
local function ImportCSV(csv)
    LOSR_DB.reserves = {}
    for line in string.gmatch(csv, "[^\r\n]+") do
        local item, itemID, from, name = string.match(line, '"?([^",]+)"?,(%d+),([^,]+),([^,]+)')
        if itemID and name then
            itemID = tonumber(itemID)
            LOSR_DB.reserves[itemID] = LOSR_DB.reserves[itemID] or {}
            table.insert(LOSR_DB.reserves[itemID], name)
        end
    end
    local count = 0
for _, players in pairs(LOSR_DB.reserves) do
    count = count + #players
end

print("|cff00ff00LightsOutSoftRes: Imported " .. count .. " reserves.|r")
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

---------------------------------------------------
-- ScrollFrame for CSV input
---------------------------------------------------

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

-- Allow mousewheel scrolling
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 30
    local current = self:GetVerticalScroll()
    local new = current - (delta * step)

    local maxScroll = self:GetVerticalScrollRange()

    if new < 0 then
        new = 0
    elseif new > maxScroll then
        new = maxScroll
    end

    self:SetVerticalScroll(new)
end)
---------------------------------------------------
-- Import Button
---------------------------------------------------

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
---------------------------------------------------
-- Slash Commands
---------------------------------------------------
SLASH_LOSR1 = "/losr"
SlashCmdList["LOSR"] = function(msg)
    if msg == "import" then
        importFrame:Show()
    elseif msg == "announce" then
        LOSR_DB.announce = not LOSR_DB.announce
        print("Raid announce:", LOSR_DB.announce and "|cff00ff00ON|r" or "|cffff0000OFF|r")
        if display:IsShown() then
            display.globalAnnounceBtn:SetText(LOSR_DB.announce and "Announce All" or "Announce All (OFF)")
        end
    else
        print("|cff00ffffLightsOut SoftRes Commands:|r")
        print("/losr import - Open CSV import window")
        print("/losr announce - Toggle raid announcements (|cffff0000OFF|r by default)")
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
                    local names = table.concat(LOSR_DB.reserves[itemID], ", ")
                    table.insert(foundItems, {
                        link = link,
                        names = names
                    })
                end
            end
        end
        if #foundItems > 0 then
            display.currentItems = foundItems
            UpdateDisplayItems()
            display:Show()
        end
    elseif event == "LOOT_CLOSED" then
        display:Hide()
        display.currentItems = nil
        for _, frame in ipairs(display.itemFrames) do frame:Hide() end
        wipe(display.itemFrames)
    end
end)