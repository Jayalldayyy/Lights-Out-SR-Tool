---------------------------------------------------
-- Whisper SR Lookup
---------------------------------------------------

LOSR = LOSR or {}

LOSR_DB = LOSR_DB or {}
LOSR_DB.whisperLookup = LOSR_DB.whisperLookup ~= false

---------------------------------------------------
-- Helpers
---------------------------------------------------

local function NormalizeName(name)
    name = tostring(name or "")
    name = name:gsub("%-.*$", "")
    name = name:gsub("^%s*(.-)%s*$", "%1")
    return string.lower(name)
end

function LOSR:GetPlayerSRLookup(playerName)
    local wantedName = NormalizeName(playerName)
    local items = {}

    for itemID, data in pairs(LOSR_DB.reserves or {}) do
        local count = 0

        for _, reservedName in ipairs(data.players or {}) do
            if NormalizeName(reservedName) == wantedName then
                count = count + 1
            end
        end

        if count > 0 then
            table.insert(items, {
                itemID = itemID,
                itemName = data.itemName or ("ItemID " .. tostring(itemID)),
                count = count,
                fulfilled = self:IsSRFulfilled(itemID, playerName) and true or false
            })
        end
    end

    table.sort(items, function(a, b)
        return a.itemName < b.itemName
    end)

    return items
end

function LOSR:FormatPlayerSRLookup(playerName)
    local items = self:GetPlayerSRLookup(playerName)

    if #items == 0 then
        return nil
    end

    local parts = {}

    for _, item in ipairs(items) do
        local text = item.itemName

        if item.count > 1 then
            text = text .. " x" .. item.count
        end

        if item.fulfilled then
            text = text .. " [FULFILLED]"
        end

        table.insert(parts, text)
    end

    return table.concat(parts, ", ")
end

---------------------------------------------------
-- Whisper Response
---------------------------------------------------

function LOSR:HandleSRWhisper(message, sender)
    if LOSR_DB.whisperLookup == false then
        return
    end

    message = string.lower(
        tostring(message or ""):gsub("^%s*(.-)%s*$", "%1")
    )

    if message ~= "sr" and
   message ~= "softres" and
   message ~= "losr" then
    return
end

    local response = self:FormatPlayerSRLookup(sender)

    if not response then
        SendChatMessage(
            "LightsOutSoftRes: You have no SoftRes reservations.",
            "WHISPER",
            nil,
            sender
        )

        return
    end

    SendChatMessage(
        "Your SoftRes: " .. response,
        "WHISPER",
        nil,
        sender
    )
end

---------------------------------------------------
-- Whisper Event
---------------------------------------------------

local whisperFrame = CreateFrame("Frame")
whisperFrame:RegisterEvent("CHAT_MSG_WHISPER")

whisperFrame:SetScript("OnEvent", function(self, event, message, sender)
    LOSR:Print("Whisper received from " .. tostring(sender) .. ": " .. tostring(message))
    LOSR:HandleSRWhisper(message, sender)
end)