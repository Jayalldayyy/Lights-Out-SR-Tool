---------------------------------------------------
-- Loot Popup Display
---------------------------------------------------

LOSR = LOSR or {}
LOSR.Display = {}

local display = CreateFrame("Frame", "LOSR_DisplayFrame", UIParent)
display:SetSize(360, 140)
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
display.currentItems = {}
display.rows = {}

local closeButton = CreateFrame("Button", nil, display, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", 0, 0)

local announceAllButton = CreateFrame("Button", nil, display, "UIPanelButtonTemplate")
announceAllButton:SetSize(110, 25)
announceAllButton:SetPoint("BOTTOM", 0, 15)
announceAllButton:SetText("Announce All")

announceAllButton:SetScript("OnClick", function()
    local srItems = {}

    for _, item in ipairs(display.currentItems or {}) do
        if item.hasSR and not item.awarded then
            table.insert(srItems, item)
        end
    end

    if #srItems == 0 then
        LOSR:Print("No SoftRes to announce.")
        return
    end

    LOSR:AnnounceItems(srItems)
end)

---------------------------------------------------
-- Row Pool
---------------------------------------------------

local function GetDisplayRow(index)
    if display.rows[index] then
        local row = display.rows[index]
        row:Show()

        row.button:SetSize(72, 18)
        row.button:ClearAllPoints()
        row.button:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -13)
        row.button:Enable()
        row.button:Show()

        row.rollButton:Hide()
        row.rollButton:Enable()
        row.rollButton:SetText("Roll")

        return row
    end

    local row = CreateFrame("Frame", nil, display)
    row:SetSize(345, 48)

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 4, 0)
    row.title:SetWidth(240)
    row.title:SetJustifyH("LEFT")

    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.sub:SetPoint("TOPLEFT", 4, -15)
    row.sub:SetWidth(230)
    row.sub:SetHeight(70)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetWordWrap(true)
    row.sub:SetSpacing(1)

    row.button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.button:SetSize(72, 18)
    row.button:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -13)
    row.button:SetText("Announce")
    row.button:Hide()

    row.rollButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.rollButton:SetSize(52, 18)
    row.rollButton:SetPoint("RIGHT", row.button, "LEFT", -4, 0)
    row.rollButton:SetText("Roll")
    row.rollButton:Hide()

    display.rows[index] = row
    return row
end

local function HideUnusedRows(startIndex)
    for i = startIndex, #display.rows do
        display.rows[i]:Hide()
        display.rows[i].button:Hide()

        if display.rows[i].rollButton then
            display.rows[i].rollButton:Hide()
        end
    end
end

---------------------------------------------------
-- Text Helper
---------------------------------------------------

local function GetLootSubText(item)
    local baseText = ""

    if item.hasSR then
        baseText = "|cffffcc00Reserved by:|r " .. LOSR:FormatPlayers(item.players or {}, true)
    else
        baseText = "|cff888888No SoftRes|r"
    end

    if item.awarded then
        return "|cff00ff00Awarded to:|r " ..
            tostring(item.awardedTo or "?") ..
            " |cff888888(" ..
            tostring(item.awardRoll or "?") ..
            " " ..
            tostring(item.awardType or "?") ..
            ")|r"
    end

    if LOSR.Roll.item and LOSR.Roll.item.itemID == item.itemID then
        local winner = LOSR.Roll.winner
        local rolls = LOSR.Roll.rolls or {}
        local tie = LOSR.Roll.tie

        if LOSR:IsRollActive() then
            if #rolls > 0 then
                local lines = {}

                for i = 1, math.min(3, #rolls) do
                    local r = rolls[i]
                    table.insert(lines, "|cffffffff#" .. i .. " " .. r.name .. "|r - |cff00ff00" .. r.roll .. "|r |cff888888" .. r.rollType .. "|r")
                end

                return baseText .. "\n|cffffcc00Standings:|r\n" .. table.concat(lines, "\n")
            end

            return baseText .. "\n|cffffcc00Rolling...|r |cff888888Waiting for rolls|r"

        elseif LOSR.Roll.finished then
            if tie and #tie > 1 then
                local names = {}

                for _, r in ipairs(tie) do
                    table.insert(names, r.name)
                end

                return baseText .. "\n|cffff5555Tie:|r " ..
                    table.concat(names, ", ") ..
                    " |cff888888(" .. tie[1].roll .. " " .. tie[1].rollType .. ")|r"

            elseif winner then
                return baseText .. "\n|cff00ff00Winner:|r |cffffffff" ..
                    winner.name ..
                    "|r - |cff00ff00" ..
                    winner.roll ..
                    "|r |cff888888" ..
                    winner.rollType ..
                    "|r"
            end
        end
    end

    return baseText
end

---------------------------------------------------
-- Draw Loot Window
---------------------------------------------------

function LOSR.Display:ShowItems(items)
    display.currentItems = items or {}

    local count = #display.currentItems
    local srCount = 0

    for _, item in ipairs(display.currentItems) do
        if item.hasSR and not item.awarded then
            srCount = srCount + 1
        end
    end

    if count == 0 then
        announceAllButton:Hide()

        local row = GetDisplayRow(1)
        row:SetPoint("TOPLEFT", 12, -45)
        row.title:SetText("")
        row.sub:SetText("|cffffcc00No loot found.|r")
        row.button:Hide()
        row.rollButton:Hide()

        HideUnusedRows(2)

        display:SetHeight(140)
        display:Show()
        return
    end

    if srCount > 0 then
        announceAllButton:Show()
        announceAllButton:SetText(LOSR:IsAnnounceEnabled() and "Announce All" or "Announce All (OFF)")
    else
        announceAllButton:Hide()
    end

    local yOffset = -18
    local totalHeight = 60

    for index, item in ipairs(display.currentItems) do
        local row = GetDisplayRow(index)

        row:SetPoint("TOPLEFT", 12, yOffset)

        if item.hasSR then
            row.title:SetText("|cff00ff00[SR]|r " .. item.link)
        else
            row.title:SetText("|cff888888[Open]|r " .. item.link)
        end

        row.sub:SetText(GetLootSubText(item))

        row.button.item = item
        row.rollButton.item = item

        if item.awarded then
            row.button:Hide()
            row.rollButton:Hide()
        elseif item.hasSR then
            row.button:Show()
            row.rollButton:Show()

            row.button:SetText("Announce")

            if LOSR.Roll.finished and LOSR.Roll.item and LOSR.Roll.item.itemID == item.itemID then
    if LOSR.Roll.tie and #LOSR.Roll.tie > 1 then
        row.rollButton:SetText("Reroll")
    else
        row.rollButton:SetText("Award")
    end
else
    row.rollButton:SetText("Roll")
end

            row.button:SetScript("OnClick", function(self)
                LOSR:AnnounceLootItem(self.item)
            end)

            row.rollButton:SetScript("OnClick", function(self)
                if LOSR.Roll.finished and LOSR.Roll.item and LOSR.Roll.item.itemID == self.item.itemID then
        if LOSR.Roll.tie and #LOSR.Roll.tie > 1 then
        LOSR:RerollTie()
        else
        LOSR:AwardRollWinner()       
	end
	
else
    LOSR:StartRoll(self.item)
end
            end)
        else
            row.rollButton:Hide()
            row.button:Show()

            if LOSR.Roll.finished and LOSR.Roll.item and LOSR.Roll.item.itemID == item.itemID then
    if LOSR.Roll.tie and #LOSR.Roll.tie > 1 then
        row.button:SetText("Reroll")
    else
        row.button:SetText("Award")
    end
else
    row.button:SetText("Open Roll")
end

            row.button:SetScript("OnClick", function(self)
                if LOSR.Roll.finished and LOSR.Roll.item and LOSR.Roll.item.itemID == self.item.itemID then
    if LOSR.Roll.tie and #LOSR.Roll.tie > 1 then
        LOSR:RerollTie()
    else
        LOSR:AwardRollWinner()
    end
else
    LOSR:StartRoll(self.item)
end

            end)
        end

        local rowHeight = 53

row.sub:SetHeight(18)

if item.awarded then
    rowHeight = 60
    row.sub:SetHeight(24)
elseif LOSR.Roll.item and LOSR.Roll.item.itemID == item.itemID then
    if LOSR:IsRollActive() and #(LOSR.Roll.rolls or {}) > 0 then
        rowHeight = 116
        row.sub:SetHeight(92)
    else
        rowHeight = 78
        row.sub:SetHeight(48)
    end
end

        row:SetHeight(rowHeight)

        yOffset = yOffset - rowHeight
        totalHeight = totalHeight + rowHeight
    end

    HideUnusedRows(count + 1)

    display:SetHeight(math.max(140, totalHeight + 48))
    display:Show()
end

function LOSR.Display:Hide()
    display:Hide()
end

function LOSR.Display:UpdateAnnounceText()
    announceAllButton:SetText(LOSR:IsAnnounceEnabled() and "Announce All" or "Announce All (OFF)")
end

function LOSR.Display:Refresh()
    if display:IsShown() then
        LOSR.Display:ShowItems(display.currentItems or {})
    end
end

---------------------------------------------------
-- Loot Event Handlers
---------------------------------------------------

function LOSR:HandleLootOpened()
    local foundItems = {}

    for i = 1, GetNumLootItems() do
        local link = GetLootSlotLink(i)

        if link then
            local itemID = tonumber(string.match(link, "item:(%d+)"))

            if itemID then
                local data = LOSR_DB.reserves[itemID]
                local hasSR = data ~= nil

                table.insert(foundItems, {
    lootSlot = i,
    itemID = itemID,
    link = link,
    itemName = data and data.itemName or LOSR:PlainItemName(link),
    players = data and data.players or {},
    hasSR = hasSR
})

                if hasSR and LOSR.RecordDroppedItem then
                    LOSR:RecordDroppedItem(itemID, link, data)
                end
            end
        end
    end

    LOSR.Display:ShowItems(foundItems)
end

function LOSR:HandleLootClosed()
    LOSR.Display:Hide()
end