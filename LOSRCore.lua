print("LightsOutSoftRes v2.0 Loaded")

LOSR = LOSR or {}

---------------------------------------------------
-- Saved Variables
---------------------------------------------------

LOSR_DB = LOSR_DB or {}

LOSR_DB.reserves = LOSR_DB.reserves or {}
LOSR_DB.announce = LOSR_DB.announce or false
LOSR_DB.dropped = LOSR_DB.dropped or {}

---------------------------------------------------
-- Session State
---------------------------------------------------

function LOSR:EnsureSession()
    LOSR_DB.session = LOSR_DB.session or {
        finalized = false,
        verdict = nil,
        verdictColor = nil,
        verdictTier = nil,
        finalizedTime = nil
    }

    return LOSR_DB.session
end

function LOSR:StartNewSession()
    LOSR_DB.session = {
        finalized = false,
        verdict = nil,
        verdictColor = nil,
        verdictTier = nil,
        finalizedTime = nil
    }

    return LOSR_DB.session
end

function LOSR:ClearAllData()
    LOSR_DB.reserves = {}
    LOSR_DB.dropped = {}
    LOSR:StartNewSession()

    self:Print("All SoftRes, dropped item, and raid session data cleared.")
end

function LOSR:FinalizeRaid()
    local session = self:EnsureSession()

    if session.finalized then
        self:Print("Raid is already finalized.")
        return false
    end

    local verdict, color, tier = self:GetLightsOutVerdict()

    session.finalized = true
    session.verdict = verdict
    session.verdictColor = color
    session.verdictTier = tier
    session.finalizedTime = date("%H:%M")

    self:Print("Raid successfully finalized.")
    self:Print("LightsOut Verdict: " .. verdict)

    if self:IsAnnounceEnabled() and self.AnnounceSummary then
        self:AnnounceSummary()
    end

    return true
end

function LOSR:IsRaidFinalized()
    local session = self:EnsureSession()
    return session.finalized
end

function LOSR:GetFinalVerdict()
    local session = self:EnsureSession()

    if session.finalized and session.verdict then
        return session.verdict, session.verdictColor, session.verdictTier
    end

    return nil, nil, nil
end

---------------------------------------------------
-- Runtime State
---------------------------------------------------

LOSR.currentView = LOSR.currentView or "boss"

---------------------------------------------------
-- CSV Import
---------------------------------------------------

function LOSR:ImportCSV(csv)
    LOSR_DB.reserves = {}

    for line in string.gmatch(csv or "", "[^\r\n]+") do
        local itemName, itemID, bossName, playerName =
            string.match(line, '"?([^",]+)"?,(%d+),([^,]+),([^,]+)')

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
        reserveCount = reserveCount + #(data.players or {})
    end

    LOSR:StartNewSession()

    LOSR:Print(
        string.format(
            "Imported %d items with %d reserves. New raid session started.",
            itemCount,
            reserveCount
        )
    )
end

---------------------------------------------------
-- Announce Helpers
---------------------------------------------------

function LOSR:IsAnnounceEnabled()
    return LOSR_DB.announce
end

function LOSR:ToggleAnnounce()
    LOSR_DB.announce = not LOSR_DB.announce

    LOSR:Print(
        "Raid announce: " ..
        (LOSR_DB.announce and "|cff00ff00ON|r" or "|cffff0000OFF|r")
    )

    return LOSR_DB.announce
end

---------------------------------------------------
-- Slash Commands
---------------------------------------------------

SLASH_LOSR1 = "/losr"

SlashCmdList["LOSR"] = function(msg)
    local cmd = strlower(msg or "")

    if cmd == "announce" then

        LOSR:ToggleAnnounce()

    elseif cmd == "import" then

        if LOSR.ShowImportWindow then
            LOSR:ShowImportWindow()
        end

    elseif cmd == "list" then

        if LOSR.ShowListWindow then
            LOSR:ShowListWindow()
        end

    elseif cmd == "summary" then

        if LOSR.PrintSummary then
            LOSR:PrintSummary()
        else
            LOSR:Print("Summary module not loaded.")
        end

    elseif cmd == "summaryraid" then

        if LOSR.AnnounceSummary then
            LOSR:AnnounceSummary()
        else
            LOSR:Print("Summary module not loaded.")
        end

    elseif cmd == "finalize" then

        if LOSR.FinalizeRaid then
            LOSR:FinalizeRaid()
        end

    else

        print("|cff00ffffLightsOut SoftRes Commands:|r")
        print("/losr import")
        print("/losr list")
        print("/losr announce")
        print("/losr summary")
        print("/losr summaryraid")
        print("/losr finalize")

    end
end

---------------------------------------------------
-- Loot Events
---------------------------------------------------

local lootFrame = CreateFrame("Frame")

lootFrame:RegisterEvent("LOOT_OPENED")
lootFrame:RegisterEvent("LOOT_CLOSED")

lootFrame:SetScript("OnEvent", function(self, event)

    if event == "LOOT_OPENED" then

        if LOSR.HandleLootOpened then
            LOSR:HandleLootOpened()
        end

    elseif event == "LOOT_CLOSED" then

        if LOSR.HandleLootClosed then
            LOSR:HandleLootClosed()
        end

    end
end)

---------------------------------------------------
-- If you're reading this...
--
-- Thanks for taking a look under the hood.
-- This addon was built one raid night, one bug,
-- and one cup of coffee at a time.
--
-- Keep the lights out.
---------------------------------------------------