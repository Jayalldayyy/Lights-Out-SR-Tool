LOSR = LOSR or {}

local function GetMostContestedItem()
    local bestName = nil
    local bestCount = 0

    for _, data in pairs(LOSR_DB.reserves or {}) do
        local count = #(data.players or {})

        if count > bestCount then
            bestCount = count
            bestName = data.itemName or "Unknown Item"
        end
    end

    return bestName, bestCount
end

local function GetMostGenerousBoss()
    local bossCounts = {}

    for _, drop in ipairs(LOSR_DB.dropped or {}) do
        local boss = drop.bossName or "Unknown"
        bossCounts[boss] = (bossCounts[boss] or 0) + 1
    end

    local bestBoss = nil
    local bestCount = 0

    for boss, count in pairs(bossCounts) do
        if count > bestCount then
            bestBoss = boss
            bestCount = count
        end
    end

    return bestBoss, bestCount
end

local function GetLuckLeaders()
    local reserveCounts = LOSR:GetPlayerReserveCounts()
    local hitCounts = LOSR:GetPlayerDropCounts() or {}

    local bestRateName = nil
    local bestRate = 0
    local bestHitsName = nil
    local bestHits = 0

    for player, reserves in pairs(reserveCounts) do
        local hits = hitCounts[player] or 0
        local rate = 0

        if reserves > 0 then
            rate = (hits / reserves) * 100
        end

        if rate > bestRate then
            bestRate = rate
            bestRateName = player
        end

        if hits > bestHits then
            bestHits = hits
            bestHitsName = player
        end
    end

    return bestRateName, bestRate, bestHitsName, bestHits
end

function LOSR:GetSummaryLines()
    local stats = LOSR:GetReserveStats()
    local drops = (LOSR.GetDroppedCount and LOSR:GetDroppedCount()) or 0
    local raidLuck = LOSR:GetRaidLuckRate()

    local contestedItem, contestedCount = GetMostContestedItem()
    local generousBoss, bossDropCount = GetMostGenerousBoss()
    local luckName, luckRate, hitsName, hitsCount = GetLuckLeaders()

    local lines = {}

    table.insert(lines, "=== LightsOut SoftRes Summary ===")
    table.insert(lines, "Items: " .. stats.items .. " | SRs: " .. stats.reserves .. " | Players: " .. stats.players)
    table.insert(lines, "SR Drops: " .. drops .. " | Raid Luck: " .. string.format("%.1f%%", raidLuck))

    if luckName then
        table.insert(lines, "Luckiest: " .. luckName .. " (" .. string.format("%.1f%%", luckRate) .. ")")
    end

    if hitsName then
        table.insert(lines, "Most SR Hits: " .. hitsName .. " (" .. hitsCount .. ")")
    end

    if contestedItem then
        table.insert(lines, "Most Contested: " .. contestedItem .. " (" .. contestedCount .. " SRs)")
    end

    if generousBoss then
    table.insert(lines, "Most Generous Boss: " .. generousBoss .. " (" .. bossDropCount .. " drops)")
end

local verdict, verdictColor = nil, nil

if LOSR.GetFinalVerdict then
    verdict, verdictColor = LOSR:GetFinalVerdict()
end

if not verdict and LOSR.GetLightsOutVerdict then
    verdict, verdictColor = LOSR:GetLightsOutVerdict()
end

if verdict then
    table.insert(lines, "LightsOut Verdict:")
    table.insert(lines, verdict)
end

return lines

end

function LOSR:PrintSummary()
    local lines = self:GetSummaryLines()

    for _, line in ipairs(lines) do
        self:Print(line)
    end
end

function LOSR:AnnounceSummary()
    local lines = self:GetSummaryLines()

    for _, line in ipairs(lines) do
        self:SendRaidMessage(line)
    end
end