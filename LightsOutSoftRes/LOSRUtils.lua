LOSR = LOSR or {}

function LOSR:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00LightsOutSoftRes:|r " .. tostring(msg))
end

function LOSR:Trim(text)
    return (text or ""):gsub("^%s*(.-)%s*$", "%1")
end

function LOSR:GetPlayerCounts(players)
    local counts = {}

    for _, name in ipairs(players or {}) do
        name = self:Trim(name)

        if name ~= "" then
            counts[name] = (counts[name] or 0) + 1
        end
    end

    return counts
end

function LOSR:GetSortedPlayerParts(players)
    local counts = self:GetPlayerCounts(players)
    local parts = {}

    for name, count in pairs(counts) do
        table.insert(parts, {
            name = name,
            count = count
        })
    end

    table.sort(parts, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end

        return a.name < b.name
    end)

    return parts
end

function LOSR:FormatPlayers(players, colored)
    local sorted = self:GetSortedPlayerParts(players)
    local output = {}

    for _, entry in ipairs(sorted) do
        local name = entry.name
        local count = entry.count
        local text

        if colored then
            if count > 1 then
                text = "|cff00ff00" .. name .. "|r |cff00ff00(x" .. count .. ")|r"
            else
                text = "|cffffffff" .. name .. "|r"
            end
        else
            text = name

            if count > 1 then
                text = text .. " (x" .. count .. ")"
            end
        end

        table.insert(output, text)
    end

    return table.concat(output, ", ")
end

function LOSR:SortedKeys(tbl)
    local keys = {}

    for key in pairs(tbl or {}) do
        table.insert(keys, key)
    end

    table.sort(keys)

    return keys
end

function LOSR:HideRows(rows)
    for _, row in ipairs(rows or {}) do
        if row and row.Hide then
            row:Hide()
        end
    end
end

function LOSR:GetReserveStats()
    local itemCount = 0
    local reserveCount = 0
    local playerMap = {}

    for _, data in pairs(LOSR_DB.reserves or {}) do
        itemCount = itemCount + 1

        for _, player in ipairs(data.players or {}) do
            reserveCount = reserveCount + 1
            playerMap[player] = true
        end
    end

    local playerCount = 0

    for _ in pairs(playerMap) do
        playerCount = playerCount + 1
    end

    return {
        items = itemCount,
        reserves = reserveCount,
        players = playerCount
    }
end
function LOSR:GetPlayerReserveCounts()
    local counts = {}

    for _, data in pairs(LOSR_DB.reserves or {}) do
        for _, player in ipairs(data.players or {}) do
            player = self:Trim(player)

            if player ~= "" then
                counts[player] = (counts[player] or 0) + 1
            end
        end
    end

    return counts
end
function LOSR:GetRaidLuckRate()
    local totalReserves = 0

    for _, data in pairs(LOSR_DB.reserves or {}) do
        totalReserves = totalReserves + #(data.players or {})
    end

    local totalDrops = 0

    if LOSR_DB.dropped then
        totalDrops = #LOSR_DB.dropped
    end

    if totalReserves == 0 then
        return 0
    end

    return (totalDrops / totalReserves) * 100
end