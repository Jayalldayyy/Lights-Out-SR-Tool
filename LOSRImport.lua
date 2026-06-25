---------------------------------------------------
-- Import Window
---------------------------------------------------

local importFrame = CreateFrame("Frame", "LOSR_ImportFrame", UIParent)

importFrame:SetSize(450, 600)
importFrame:SetPoint("CENTER")

importFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
})

importFrame:SetBackdropColor(0,0,0,1)

importFrame:EnableMouse(true)
importFrame:SetMovable(true)
importFrame:RegisterForDrag("LeftButton")

importFrame:SetScript("OnDragStart", importFrame.StartMoving)
importFrame:SetScript("OnDragStop", importFrame.StopMovingOrSizing)

importFrame:Hide()

---------------------------------------------------
-- Title
---------------------------------------------------

local title = importFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")

title:SetPoint("TOP", 0, -16)
title:SetText("<LightsOut> SoftRes Import")

---------------------------------------------------
-- Scroll Frame
---------------------------------------------------

local scrollFrame = CreateFrame(
    "ScrollFrame",
    "LOSR_ImportScroll",
    importFrame,
    "UIPanelScrollFrameTemplate"
)

scrollFrame:SetPoint("TOPLEFT", 25, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 80)

---------------------------------------------------
-- Edit Box
---------------------------------------------------

local editBox = CreateFrame("EditBox", nil, scrollFrame)

editBox:SetMultiLine(true)
editBox:SetFontObject(ChatFontNormal)

editBox:SetWidth(520)
editBox:SetHeight(1)

editBox:SetAutoFocus(true)

editBox:SetScript("OnEscapePressed", function()
    importFrame:Hide()
end)

editBox:SetScript("OnTextChanged", function()
    scrollFrame:UpdateScrollChildRect()
end)

scrollFrame:SetScrollChild(editBox)

---------------------------------------------------
-- Mouse Wheel
---------------------------------------------------

scrollFrame:EnableMouseWheel(true)

scrollFrame:SetScript("OnMouseWheel", function(self, delta)

    local step = 30

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
-- Import Button
---------------------------------------------------

local importButton = CreateFrame(
    "Button",
    nil,
    importFrame,
    "UIPanelButtonTemplate"
)

importButton:SetSize(120, 30)
importButton:SetPoint("BOTTOM", 0, 20)

importButton:SetText("Import")

importButton:SetScript("OnClick", function()

    LOSR:ImportCSV(editBox:GetText())

    editBox:SetText("")
    importFrame:Hide()

end)

---------------------------------------------------
-- Clear Button
---------------------------------------------------

local clearButton = CreateFrame(
    "Button",
    nil,
    importFrame,
    "UIPanelButtonTemplate"
)

clearButton:SetSize(120, 30)
clearButton:SetPoint("BOTTOM", -130, 20)

clearButton:SetText("Clear SRs")

clearButton:SetScript("OnClick", function()

    LOSR:ClearAllData()

end)

---------------------------------------------------
-- Close Button
---------------------------------------------------

local closeButton = CreateFrame(
    "Button",
    nil,
    importFrame,
    "UIPanelCloseButton"
)

closeButton:SetPoint("TOPRIGHT", 0, 0)

---------------------------------------------------
-- Public Function
---------------------------------------------------

function LOSR:ShowImportWindow()

    importFrame:Show()

    editBox:SetFocus()

end