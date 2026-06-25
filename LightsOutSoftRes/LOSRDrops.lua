LOSR = LOSR or {}

LOSR_DB = LOSR_DB or {}

if type(LOSR_DB.dropped) ~= "table" then
    LOSR_DB.dropped = {}
end

local recentDrops = {}

function LOSR:RecordDroppedItem(itemID, link, data)
    if not itemID or not data then return end

    if type(LOSR_DB.dropped) ~= "table" then
        LOSR_DB.dropped = {}
    end

    local now = GetTime and GetTime() or 0

    -- Prevent duplicate logging from reopening same corpse/chest
    if recentDrops[itemID] and (now - recentDrops[itemID]) < 30 then
        return
    end

    recentDrops[itemID] = now

    local playerCopy = {}
    for _, name in ipairs(data.players or {}) do
        table.insert(playerCopy, name)
    end

    table.insert(LOSR_DB.dropped, {
        itemID = itemID,
        itemName = data.itemName or link or ("ItemID " .. itemID),
        bossName = data.bossName or "Unknown",
        players = playerCopy,
        time = date("%H:%M")
    })

    LOSR:Print("Tracked dropped SR: " .. (data.itemName or link or itemID))
end

function LOSR:ClearDroppedItems()
    LOSR_DB.dropped = {}
    recentDrops = {}
    LOSR:Print("Dropped SR history cleared.")
end

function LOSR:GetDroppedCount()
    return #(LOSR_DB.dropped or {})
end

function LOSR:GetDroppedGroupsByBoss()
    local groups = {}

    for _, drop in ipairs(LOSR_DB.dropped or {}) do
        local boss = drop.bossName or "Unknown"
        groups[boss] = groups[boss] or {}
        table.insert(groups[boss], drop)
    end

    return groups
end

function LOSR:GetPlayerDropCounts()
    local counts = {}

    for _, drop in ipairs(LOSR_DB.dropped or {}) do
        local seen = {}

        for _, player in ipairs(drop.players or {}) do
            player = LOSR:Trim(player)

            if player ~= "" then
                seen[player] = true
            end
        end

        for player in pairs(seen) do
            counts[player] = (counts[player] or 0) + 1
        end
    end

    return counts
end