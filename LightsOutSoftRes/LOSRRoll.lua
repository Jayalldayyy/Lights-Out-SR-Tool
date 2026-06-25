---------------------------------------------------
-- Roll System
---------------------------------------------------

LOSR = LOSR or {}

LOSR.Roll = LOSR.Roll or {}
local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

LOSR_DB = LOSR_DB or {}
LOSR_DB.roll = LOSR_DB.roll or {
    rollTime = 25,
    autoAnnounceCount = true,
    catchMultiRollers = true,
    allowAllRollRanges = true,
    showClassColors = true
}

function LOSR:GetRollSettings()
    LOSR_DB.roll = LOSR_DB.roll or {}
    LOSR_DB.roll.rollTime = LOSR_DB.roll.rollTime or 25
    LOSR_DB.roll.autoAnnounceCount = LOSR_DB.roll.autoAnnounceCount ~= false
    LOSR_DB.roll.catchMultiRollers = LOSR_DB.roll.catchMultiRollers ~= false
    LOSR_DB.roll.allowAllRollRanges = LOSR_DB.roll.allowAllRollRanges ~= false
    LOSR_DB.roll.showClassColors = LOSR_DB.roll.showClassColors ~= false

    return LOSR_DB.roll
end

function LOSR:IsRollActive()
    return self.Roll.active == true
end

function LOSR:StartRoll(item)
    if not item then
        self:Print("No item selected for roll.")
        return false
    end

    if self:IsRollActive() then
        self:Print("A roll is already active.")
        return false
    end

    local settings = self:GetRollSettings()
    local itemName = item.link or item.itemName or ("ItemID " .. tostring(item.itemID or "?"))

    self.Roll.active = true
    self.Roll.item = item
    self.Roll.startedAt = GetTime()
    self.Roll.endsAt = GetTime() + settings.rollTime
    self.Roll.rolls = {}
    self.Roll.players = {}
    self.Roll.winner = nil
	self.Roll.finished = false
	self.Roll.rollCounts = {}
self.Roll.allowedRolls = {}

if item.hasSR then
    local counts = self:GetPlayerCounts(item.players or {})

    for name, count in pairs(counts) do
        self.Roll.allowedRolls[name] = count
    end
end

    self:Print("Rolling started for " .. self:PlainItemName(itemName) .. " (" .. settings.rollTime .. " sec)")

    if self:IsAnnounceEnabled() then
        self:SendRaidMessage("Roll for " .. itemName .. " - " .. settings.rollTime .. " seconds.")
        self:SendRaidMessage("MS: /roll 100  |  OS: /roll 99")
    end

    timerFrame.elapsed = 0
    timerFrame.lastSecond = settings.rollTime

    timerFrame:Show()
	
	if LOSR.Display and LOSR.Display.Refresh then
    LOSR.Display:Refresh()
end

    return true
end

function LOSR:EndRoll()
    if not self:IsRollActive() then
        self:Print("No active roll.")
        return false
    end

    local item = self.Roll.item
    local itemName = item and (item.link or item.itemName) or "Unknown Item"

    self.Roll.active = false
    self.Roll.finished = true
    timerFrame:Hide()

    self:Print("Rolling closed for " .. self:PlainItemName(itemName))

    if self:IsAnnounceEnabled() then
        self:SendRaidMessage("Rolling closed for " .. itemName)
    end

    if LOSR.Display and LOSR.Display.Refresh then
        LOSR.Display:Refresh()
    end

    -- Do NOT clear item/rolls/winner here.
    -- We keep them visible so the loot window can show the winner.

    return true
end

timerFrame:SetScript("OnUpdate", function(self, elapsed)

    if not LOSR:IsRollActive() then
        self:Hide()
        return
    end

    self.elapsed = self.elapsed + elapsed

    local remaining = math.ceil(LOSR.Roll.endsAt - GetTime())

    if remaining < 0 then
        remaining = 0
    end

    if remaining ~= self.lastSecond then

        self.lastSecond = remaining

        if remaining == 10 or
           remaining == 5 or
           remaining == 4 or
           remaining == 3 or
           remaining == 2 or
           remaining == 1 then

            LOSR:Print("Roll ends in " .. remaining .. "...")

            if LOSR:IsAnnounceEnabled() then
                LOSR:SendRaidMessage("Rolling ends in " .. remaining .. "...")
            end
        end

        if remaining <= 0 then
            LOSR:EndRoll()
            self:Hide()
        end

    end

end)

function LOSR:RerollTie()
    if not self.Roll or not self.Roll.finished or not self.Roll.tie or #self.Roll.tie < 2 then
        self:Print("No tie to reroll.")
        return false
    end

    local item = self.Roll.item
    local itemName = item and (item.link or item.itemName) or "Unknown Item"

    local tiedPlayers = {}

    for _, r in ipairs(self.Roll.tie) do
        tiedPlayers[r.name] = true
    end

    self.Roll.active = true
    self.Roll.finished = false
    self.Roll.startedAt = GetTime()
    self.Roll.endsAt = GetTime() + self:GetRollSettings().rollTime
    self.Roll.rolls = {}
    self.Roll.rollCounts = {}
    self.Roll.allowedRolls = {}
    self.Roll.winner = nil

    for name in pairs(tiedPlayers) do
        self.Roll.allowedRolls[name] = 1
    end

    self.Roll.tie = nil

    self:Print("Tie reroll started for " .. self:PlainItemName(itemName))

    if self:IsAnnounceEnabled() then
        local names = {}

        for name in pairs(tiedPlayers) do
            table.insert(names, name)
        end

        table.sort(names)

        self:SendRaidMessage("Tie reroll for " .. itemName .. " - " .. table.concat(names, ", ") .. " only.")
    end

    timerFrame.elapsed = 0
    timerFrame.lastSecond = self:GetRollSettings().rollTime
    timerFrame:Show()

    if LOSR.Display and LOSR.Display.Refresh then
        LOSR.Display:Refresh()
    end

    return true
end

function LOSR:FindMasterLootCandidateIndex(lootSlot, playerName)
    if not playerName then
        return nil
    end

    playerName = self:Trim(playerName)

    for i = 1, 40 do
        local candidate = GetMasterLootCandidate(i)

        if candidate then
            candidate = self:Trim(candidate)

            if string.lower(candidate) == string.lower(playerName) then
                return i
            end
        end
    end

    return nil
end


function LOSR:ConfirmAwardLoot(item, winner, candidateIndex)
    if not item or not winner or not candidateIndex then
        self:Print("Cannot award loot. Missing item, winner, or candidate.")
        return false
    end

    local itemName = item.link or item.itemName or ("ItemID " .. tostring(item.itemID or "?"))

    StaticPopupDialogs["LOSR_CONFIRM_AWARD"] = {
        text = "Award " .. itemName .. " to " .. winner.name .. "?",
        button1 = "Award",
        button2 = "Cancel",
        OnAccept = function()
            GiveMasterLoot(item.lootSlot, candidateIndex)

            LOSR:Print("Loot awarded: " .. LOSR:PlainItemName(itemName) .. " -> " .. winner.name)

            if LOSR:IsAnnounceEnabled() then
                LOSR:SendRaidMessage("Awarded: " .. itemName .. " -> " .. winner.name)
            end

            item.awarded = true
            item.awardedTo = winner.name
            item.awardRoll = winner.roll
            item.awardType = winner.rollType

            LOSR.Roll.active = false
            LOSR.Roll.finished = false
            LOSR.Roll.item = nil
            LOSR.Roll.rolls = {}
            LOSR.Roll.players = {}
            LOSR.Roll.rollCounts = {}
            LOSR.Roll.allowedRolls = {}
            LOSR.Roll.winner = nil
            LOSR.Roll.tie = nil

            if LOSR.Display and LOSR.Display.Refresh then
                LOSR.Display:Refresh()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }

    StaticPopup_Show("LOSR_CONFIRM_AWARD")
    return true
end


function LOSR:AwardRollWinner()
    if not self.Roll or not self.Roll.finished then
        self:Print("No finished roll to award.")
        return false
    end

    local item = self.Roll.item
    local winner = self.Roll.winner
	if self.Roll.tie and #self.Roll.tie > 1 then
    self:Print("Cannot award yet. Tie detected.")
    return false
end

    if not item or not winner then
        self:Print("No winner found for this roll.")
        return false
    end

    local itemName = item.link or item.itemName or ("ItemID " .. tostring(item.itemID or "?"))

    self:Print("Awarding " .. self:PlainItemName(itemName) .. " to " .. winner.name)
	if item.lootSlot then
    self:Print("Loot slot remembered: " .. tostring(item.lootSlot))
else
    self:Print("No loot slot found for this item.")
end
local candidateIndex = nil

if item.lootSlot then
    candidateIndex = self:FindMasterLootCandidateIndex(item.lootSlot, winner.name)
end

if candidateIndex then
    self:Print("Master loot candidate found: " .. winner.name .. " (#" .. candidateIndex .. ")")
else
    self:Print("Could not find master loot candidate for " .. winner.name)
end
	if not candidateIndex then
    self:Print("Cannot award loot. Candidate not found for " .. winner.name)
    return false
end

return self:ConfirmAwardLoot(item, winner, candidateIndex)
end

---------------------------------------------------
-- Roll Parsing
---------------------------------------------------

local rollEventFrame = CreateFrame("Frame")
rollEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")

local function ParseRollMessage(msg)
    if not msg then return nil end

    -- Example: Jayallday rolls 97 (1-100)
    local name, roll, low, high = string.match(msg, "^(.-) rolls (%d+) %((%d+)%-(%d+)%)$")

    if name and roll and low and high then
        return name, tonumber(roll), tonumber(low), tonumber(high)
    end

    return nil
end

function LOSR:UpdateRollWinner()
    self.Roll.winner = nil
    self.Roll.tie = nil

    local rolls = self.Roll.rolls or {}
    if #rolls == 0 then return end

    local top = rolls[1]
    local tied = {}

    for _, r in ipairs(rolls) do
        if r.high == top.high and r.roll == top.roll then
            table.insert(tied, r)
        end
    end

    if #tied > 1 then
        self.Roll.tie = tied
    else
        self.Roll.winner = top
    end
end

function LOSR:RecordRoll(playerName, roll, low, high)
    if not self:IsRollActive() then
        return false
    end

    if not playerName or not roll then
        return false
    end

    playerName = self:Trim(playerName)

    self.Roll.rolls = self.Roll.rolls or {}
    self.Roll.players = self.Roll.players or {}

    self.Roll.rollCounts = self.Roll.rollCounts or {}
self.Roll.allowedRolls = self.Roll.allowedRolls or {}

local isSRRoll = self.Roll.item and self.Roll.item.hasSR
local allowed = self.Roll.allowedRolls[playerName] or 0

if not isSRRoll then
    allowed = 1
end

if allowed <= 0 then
    self:Print("Ineligible roll ignored: " .. playerName .. " rolled " .. roll)

    if self:IsAnnounceEnabled() then
        self:SendRaidMessage("Ineligible roll ignored: " .. playerName)
    end

    return false
end

local used = self.Roll.rollCounts[playerName] or 0

if used >= allowed then
    self:Print("Extra roll ignored: " .. playerName .. " rolled " .. roll)

    if self:GetRollSettings().catchMultiRollers and self:IsAnnounceEnabled() then
        self:SendRaidMessage("Extra roll ignored: " .. playerName)
    end

    return false
end

self.Roll.rollCounts[playerName] = used + 1

    local rollType = "MS"

    if high == 99 then
        rollType = "OS"
    end

    local entry = {
    name = playerName,
    roll = roll,
    low = low,
    high = high,
    rollType = rollType,
    rollNumber = self.Roll.rollCounts[playerName],
    allowedRolls = allowed
}

    table.insert(self.Roll.rolls, entry)
   

    table.sort(self.Roll.rolls, function(a, b)
        if a.high ~= b.high then
            return a.high > b.high
        end

        if a.roll ~= b.roll then
            return a.roll > b.roll
        end

        return a.name < b.name
    end)

    self:UpdateRollWinner()
	if LOSR.Display and LOSR.Display.Refresh then
    LOSR.Display:Refresh()
end

    self:Print(playerName .. " rolled " .. roll .. " (" .. rollType .. ")")

    return true
end

rollEventFrame:SetScript("OnEvent", function(self, event, msg)
    local playerName, roll, low, high = ParseRollMessage(msg)
	
	

    if playerName then
        LOSR:RecordRoll(playerName, roll, low, high)
    end
end)