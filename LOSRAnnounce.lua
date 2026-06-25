LOSR = LOSR or {}

function LOSR:GetAnnounceChannel()
    local raidCount = GetNumRaidMembers and GetNumRaidMembers() or 0
    local partyCount = GetNumPartyMembers and GetNumPartyMembers() or 0

    if raidCount > 0 then
        return "RAID_WARNING"
    elseif partyCount > 0 then
        return "PARTY"
    end

    return nil
end
function LOSR:PlainItemName(text)
    text = tostring(text or "")

    -- Extract item name from a WoW item link if present
    local name = string.match(text, "%[(.-)%]")

    if name then
        return name
    end

    -- Remove any leftover WoW escape pieces
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|H.-|h", "")
    text = text:gsub("|h", "")

    return text
end

function LOSR:SendRaidMessage(message)
    if not self:IsAnnounceEnabled() then
        self:Print("Announce is OFF. Toggle with /losr announce")
        return false
    end

    local channel = self:GetAnnounceChannel()

    if not channel then
        self:Print("Not in a group or raid. Message not sent.")
        return false
    end

    message = tostring(message or "")

-- Allow proper WoW links/colors, but protect simple separator pipes.
-- If this is not an item/spell/etc link, replace pipes with dashes.
if not string.find(message, "|H", 1, true) then
    message = message:gsub("|", "-")
end

SendChatMessage(message, channel)
    return true
end

function LOSR:AnnounceItem(itemID, data)
    if not data then return false end

    local _, itemLink = GetItemInfo(itemID)
    local itemName = itemLink or self:PlainItemName(data.itemName or ("ItemID " .. tostring(itemID)))

    local players = data.players or {}
    local names = self:FormatPlayers(players, false)

    if names == "" then
        names = "None"
    end

    local sent = self:SendRaidMessage(itemName .. " - Reserved by: " .. names)

    if sent then
        self:Print("Announced: " .. self:PlainItemName(itemName))
    end

    return sent
end

function LOSR:AnnounceLootItem(item)
    if not item then return false end

    local itemName = item.link or self:PlainItemName(item.itemName or ("ItemID " .. tostring(item.itemID or "?")))
    local names = self:FormatPlayers(item.players or {}, false)

    if names == "" then
        names = "None"
    end

    local sent = self:SendRaidMessage(itemName .. " - Reserved by: " .. names)

    if sent then
        self:Print("Announced: " .. self:PlainItemName(itemName))
    end

    return sent
end

function LOSR:AnnounceItems(items)
    local sentAny = false

    for _, item in ipairs(items or {}) do
        if item.data then
            if self:AnnounceItem(item.itemID, item.data) then
                sentAny = true
            end
        else
            if self:AnnounceLootItem(item) then
                sentAny = true
            end
        end
    end

    return sentAny
end

function LOSR:AnnounceBoss(bossName, bossItems)
    local sentAny = self:AnnounceItems(bossItems)

    if sentAny then
        self:Print("Announced all SRs for " .. tostring(bossName))
    end

    return sentAny
end