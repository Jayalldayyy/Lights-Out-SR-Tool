LOSR = LOSR or {}

LOSR.VerdictVersion = 1

LOSR.Verdicts = {
    robbery = {
        normal = {
            "The Lich King claimed the good loot.",
            "Kel'Thuzad stole the good loot tonight.",
            "The loot table filed for bankruptcy.",
            "Bosses dropped hopes and dreams instead.",
            "RNG checked out early tonight.",
            "Somebody forgot to sacrifice a gnome.",
            "The loot gods are on vacation.",
            "Even the Scourge deserved better loot than this.",
            "Congratulations. You defeated the bosses. The bosses defeated your SRs.",
            "Somebody angered RNGesus.",
            "The spreadsheet is disappointed.",
            "Repairs cost more than the loot.",
            "The raid cleared Naxx. Naxx cleared your expectations.",
            "The loot table has been placed on probation.",
            "The bosses paid in exposure tonight.",
            "Tonight's loot was brought to you by disappointment.",
            "The Scourge appreciates your continued donations.",
            "This raid was inspected and found loot-deficient.",
            "Probability won. The raid did not.",
            "The good drops were apparently on another lockout."
        },
        jay = {
            "Jay is already blaming the loot tables.",
            "Jay checked the loot settings twice... supposedly.",
            "Jay swears this wasn't rigged.",
            "Even Jay can't explain this one.",
            "Jay accepts zero responsibility for tonight's RNG."
        }
    },

    rough = {
        normal = {
            "The bosses weren't feeling generous.",
            "RNG had other plans.",
            "Could've been worse... probably.",
            "Most SRs are still waiting patiently.",
            "The loot council can't even help this one.",
            "At least everyone got badges.",
            "Bosses paid minimum wage tonight.",
            "Better luck next reset.",
            "The loot table gave just enough to avoid being replaced.",
            "A few dreams survived. Most did not.",
            "Naxx gave loot. Technically.",
            "The raid received a participation trophy.",
            "The loot was there. It simply chose violence.",
            "Tonight was character-building.",
            "The SR list left with trust issues.",
            "Not the worst night. Not the best. Mostly pain.",
            "The bosses remembered loot exists, barely.",
            "The spreadsheet sighed.",
            "RNG phoned this one in.",
            "The loot gods gave a firm maybe."
        },
        jay = {
            "Jay says next week's loot will be better. Probably.",
            "Jay promises the bosses weren't paid off.",
            "Jay is pretending this raid never happened.",
            "Jay would like to remind everyone that badges are loot too.",
            "Jay has filed a complaint with the loot table."
        }
    },

    average = {
        normal = {
            "A respectable evening of loot.",
            "RNG clocked in and did its job.",
            "Nobody's complaining... yet.",
            "Pretty standard Naxx night.",
            "The loot gods approved the minimum required.",
            "A balanced raid, as all things should be.",
            "The numbers were aggressively normal.",
            "Perfectly average. Suspiciously average.",
            "The loot table met expectations and nothing more.",
            "The raid received exactly enough hope to continue.",
            "Statistics have declared this acceptable.",
            "Tonight was fine. Fine is good.",
            "No miracles. No crimes.",
            "The SR list survived with minor injuries.",
            "A normal night for abnormal people.",
            "The loot gods shrugged.",
            "Nobody should be too mad. Probably.",
            "The bosses respected the spreadsheet.",
            "The raid was neither blessed nor cursed.",
            "A clean, respectable pile of numbers."
        },
        jay = {
            "Jay calls this a perfectly respectable raid.",
            "Jay approves of these statistics.",
            "Jay has seen worse... and much better.",
            "Jay says this is what balance looks like.",
            "Jay is suspiciously calm about these numbers."
        }
    },

    great = {
        normal = {
            "RNG smiled upon the raid.",
            "The bosses were feeling generous.",
            "Tonight was a good night to SoftRes.",
            "Even the alts are jealous.",
            "Somebody definitely bribed the loot table.",
            "Guild bank donations accepted after a night like this.",
            "The loot table remembered its manners.",
            "The SR list is eating well tonight.",
            "A suspiciously generous evening.",
            "The bosses came prepared to share.",
            "The raid walked out richer and louder.",
            "The loot gods were in a good mood.",
            "Tonight's drops deserve a screenshot.",
            "The spreadsheet is glowing.",
            "SoftRes believers have been rewarded.",
            "This is how raid morale happens.",
            "The loot table briefly became friendly.",
            "RNG gave the raid a firm handshake.",
            "Naxx paid out tonight.",
            "Someone lit the good candle."
        },
        jay = {
            "Jay definitely had nothing to do with this.",
            "Jay is suddenly everyone's favorite raid leader.",
            "Jay's luck appears to be contagious.",
            "Jay will be taking credit for morale.",
            "Jay says you're welcome."
        }
    },

    legendary = {
        normal = {
            "RNGesus has blessed this raid.",
            "Buy a lottery ticket immediately.",
            "The loot table surrendered.",
            "Someone clearly made a deal with the Titans.",
            "This raid should be archived for science.",
            "Everybody got something... almost suspiciously.",
            "Don't expect next week's raid to look like this.",
            "The bosses emptied their pockets.",
            "The SR list has ascended.",
            "This lockout may never be repeated.",
            "The loot gods personally attended tonight.",
            "Statistics are requesting an investigation.",
            "The raid has achieved unreasonable fortune.",
            "This was not luck. This was divine intervention.",
            "The Titans approve. Loudly.",
            "The loot table has entered panic mode.",
            "Someone blessed the raid and forgot to stop.",
            "This raid was suspiciously legal.",
            "RNG has spoken, and it was generous.",
            "The spreadsheet is now a holy relic."
        },
        jay = {
            "Jay would like everyone to know this is totally normal.",
            "Jay is taking full credit for tonight's RNG.",
            "Jay's pre-pull speech clearly worked.",
            "Jay is now accepting donations to the guild bank.",
            "Jay accidentally found the good loot table."
        }
    },

    mythic = {
        "LEGENDARY LIGHTSOUT VERDICT: Jay accidentally found the good loot table. Please don't tell Blizzard.",
        "LEGENDARY LIGHTSOUT VERDICT: The Scourge has officially filed a complaint against Lights Out.",
        "LEGENDARY LIGHTSOUT VERDICT: Congratulations. Statistics suggest you should quit while you're ahead.",
        "LEGENDARY LIGHTSOUT VERDICT: This raid was inspected by RNGesus and found suspiciously lucky.",
        "LEGENDARY LIGHTSOUT VERDICT: Jay denies all allegations of loot table tampering."
    }
}

function LOSR:GetVerdictTier(rate)
    rate = rate or 0

    if rate < 5 then
        return "robbery", "|cffff4040"
    elseif rate < 10 then
        return "rough", "|cffff8040"
    elseif rate < 15 then
        return "average", "|cffffff40"
    elseif rate < 20 then
        return "great", "|cff40ff40"
    end

    return "legendary", "|cff40c0ff"
end

function LOSR:GetLightsOutVerdict()
    if LOSR_DB and LOSR_DB.session and LOSR_DB.session.finalized and LOSR_DB.session.verdict then
        return LOSR_DB.session.verdict, LOSR_DB.session.verdictColor, LOSR_DB.session.verdictTier
    end

    local rate = (self.GetRaidLuckRate and self:GetRaidLuckRate()) or 0

    if math.random(1, 1000) == 1 then
        return LOSR.Verdicts.mythic[math.random(#LOSR.Verdicts.mythic)], "|cffff80ff", "mythic"
    end

    local tier, color = self:GetVerdictTier(rate)
    local poolType = "normal"

    if LOSR.Verdicts[tier].jay and math.random(1, 20) == 1 then
        poolType = "jay"
    end

    local pool = LOSR.Verdicts[tier][poolType]

    return pool[math.random(#pool)], color, tier
end