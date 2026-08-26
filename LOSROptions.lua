---------------------------------------------------
-- LightsOut SoftRes Options
---------------------------------------------------

LOSR = LOSR or {}

local optionsFrame = CreateFrame("Frame", "LOSR_OptionsFrame", UIParent)
optionsFrame:SetSize(360, 300)
optionsFrame:SetPoint("CENTER")
optionsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {
        left = 8,
        right = 8,
        top = 8,
        bottom = 8
    }
})

optionsFrame:SetBackdropColor(0, 0, 0, 1)
optionsFrame:SetMovable(true)
optionsFrame:EnableMouse(true)
optionsFrame:RegisterForDrag("LeftButton")
optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
optionsFrame:Hide()

---------------------------------------------------
-- Title
---------------------------------------------------

local title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("LightsOut SoftRes Options")

---------------------------------------------------
-- Close Button
---------------------------------------------------

local closeButton = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -3, -3)

---------------------------------------------------
-- General Header
---------------------------------------------------

local generalHeader = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
generalHeader:SetPoint("TOPLEFT", 25, -55)
generalHeader:SetText("|cffffcc00General|r")

---------------------------------------------------
-- Roll Timer
---------------------------------------------------

local rollTimerLabel = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rollTimerLabel:SetPoint("TOPLEFT", 35, -90)
rollTimerLabel:SetText("Roll Timer")

local timerValue = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
timerValue:SetPoint("TOP", optionsFrame, "TOP", 0, -118)

local minusButton = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
minusButton:SetSize(40, 22)
minusButton:SetPoint("RIGHT", timerValue, "LEFT", -15, 0)
minusButton:SetText("-")

local plusButton = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
plusButton:SetSize(40, 22)
plusButton:SetPoint("LEFT", timerValue, "RIGHT", 15, 0)
plusButton:SetText("+")

local function RefreshTimerText()
    local settings = LOSR:GetRollSettings()
    timerValue:SetText(settings.rollTime .. " seconds")
end

minusButton:SetScript("OnClick", function()
    local settings = LOSR:GetRollSettings()

    settings.rollTime = settings.rollTime - 5

    if settings.rollTime < 5 then
        settings.rollTime = 5
    end

    RefreshTimerText()
end)

plusButton:SetScript("OnClick", function()
    local settings = LOSR:GetRollSettings()

    settings.rollTime = settings.rollTime + 5

    if settings.rollTime > 60 then
        settings.rollTime = 60
    end

    RefreshTimerText()
end)

---------------------------------------------------
-- Raid Announcements
---------------------------------------------------

local announceCheck = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
announceCheck:SetPoint("TOPLEFT", 30, -155)

local announceText = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
announceText:SetPoint("LEFT", announceCheck, "RIGHT", 3, 1)
announceText:SetText("Raid Announcements")

announceCheck:SetScript("OnClick", function(self)
    LOSR_DB.announce = self:GetChecked() and true or false

    LOSR:Print(
        "Raid announce: " ..
        (LOSR_DB.announce and "|cff00ff00ON|r" or "|cffff0000OFF|r")
    )

    if LOSR.Display and LOSR.Display.UpdateAnnounceText then
        LOSR.Display:UpdateAnnounceText()
    end
end)

---------------------------------------------------
-- Whisper SR Lookup
---------------------------------------------------

local whisperCheck = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
whisperCheck:SetPoint("TOPLEFT", 30, -185)

local whisperText = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
whisperText:SetPoint("LEFT", whisperCheck, "RIGHT", 3, 1)
whisperText:SetText('Enable SR Whisper Lookup ("sr")')

whisperCheck:SetScript("OnClick", function(self)
    LOSR_DB.whisperLookup = self:GetChecked() and true or false

    LOSR:Print(
        "SR whisper lookup: " ..
        (LOSR_DB.whisperLookup and "|cff00ff00ON|r" or "|cffff0000OFF|r")
    )
end)

---------------------------------------------------
-- Bottom Close Button
---------------------------------------------------

local bottomClose = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
bottomClose:SetSize(90, 25)
bottomClose:SetPoint("BOTTOM", 0, 20)
bottomClose:SetText("Close")

bottomClose:SetScript("OnClick", function()
    optionsFrame:Hide()
end)

---------------------------------------------------
-- Show Options
---------------------------------------------------

function LOSR:ShowOptionsWindow()
    RefreshTimerText()

    announceCheck:SetChecked(
        LOSR_DB.announce == true
    )

    whisperCheck:SetChecked(
        LOSR_DB.whisperLookup ~= false
    )

    optionsFrame:Show()
end