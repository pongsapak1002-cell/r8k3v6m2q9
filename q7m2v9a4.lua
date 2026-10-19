
-- ── 1. STRICT AUTO-CLEANUP ───────────────────────────────────────────────────────
if _G.AnimeDiceCleanup then pcall(_G.AnimeDiceCleanup) end
if _G.AnimeDiceWindow and _G.AnimeDiceWindow.Destroy then pcall(function() _G.AnimeDiceWindow:Destroy() end) end
if _G.AnimeDiceMinGui then pcall(function() _G.AnimeDiceMinGui:Destroy() end) end
if _G.AnimeDiceStatusGui then pcall(function() _G.AnimeDiceStatusGui:Destroy() end) _G.AnimeDiceStatusGui = nil end
_G.AnimeDiceRunning = false

local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local StatsService      = game:GetService("Stats")

local thisRunId         = HttpService:GenerateGUID(false)
_G.AnimeDiceRunId       = thisRunId
_G.AnimeDiceRunning     = true

local _conns = {}
_G.AnimeDiceCleanup = function()
    _G.AnimeDiceRunning = false
    _G.AnimeDiceRunId   = nil
    for _, c in ipairs(_conns) do pcall(function() c:Disconnect() end) end
    table.clear(_conns)
    if _G.AnimeDiceWindow and _G.AnimeDiceWindow.Destroy then
        pcall(function() _G.AnimeDiceWindow:Destroy() end)
        _G.AnimeDiceWindow = nil
    end
    if _G.AnimeDiceMinGui then
        pcall(function() _G.AnimeDiceMinGui:Destroy() end)
        _G.AnimeDiceMinGui = nil
    end
    if _G.AnimeDiceStatusGui then
        pcall(function() _G.AnimeDiceStatusGui:Destroy() end)
        _G.AnimeDiceStatusGui = nil
    end
end

-- ── 2. SERVICES & NETWORK REMOTES ────────────────────────────────────────────────
local LP = Players.LocalPlayer
local network = RS:WaitForChild("Network")
local VirtualUser = game:GetService("VirtualUser")

local RollService            = network:WaitForChild("RollService")
local PlotService            = network:WaitForChild("PlotService")
local RebirthService         = network:WaitForChild("RebirthService")
local DiceShopService        = network:WaitForChild("DiceShopService")
local DailyRewardService     = network:WaitForChild("DailyRewardService")
local GroupRewardService     = network:WaitForChild("GroupRewardService")
local OfflineEarningsService = network:WaitForChild("OfflineEarningsService")
local SpinService            = network:WaitForChild("SpinService")
local UpgradeServiceRE       = network:WaitForChild("RE"):WaitForChild("BuyUpgrade")

-- Towers Network Remotes
local TowerNetwork           = network:FindFirstChild("Towers")
local EquipBestTowerTeamRE   = TowerNetwork and TowerNetwork:FindFirstChild("RE") and TowerNetwork.RE:FindFirstChild("EquipBestTowerTeam")
local PlayTowerRF            = TowerNetwork and TowerNetwork:FindFirstChild("RF") and TowerNetwork.RF:FindFirstChild("PlayTower")
local CancelTowerRF          = TowerNetwork and TowerNetwork:FindFirstChild("RF") and TowerNetwork.RF:FindFirstChild("CancelTower")

-- Grade Network Remotes
-- Trait reroll remotes and game definitions.
local TraitNetwork = network:FindFirstChild("TraitService")
local TraitRE = TraitNetwork and TraitNetwork:FindFirstChild("RE")
local RollTraitRE = TraitRE and TraitRE:FindFirstChild("Roll")
local SetTraitProtectedRE = TraitRE and TraitRE:FindFirstChild("SetTraitProtected")
local TraitsModule = {}
pcall(function() TraitsModule = require(RS.Framework.Features.Traits.Traits) end)

-- Quirk reroll remotes and definitions; one table keeps the top-level local count low.
local Quirk = {Defs = {}}
do
    local re = network:FindFirstChild("QuirkService")
    re = re and re:FindFirstChild("RE")
    Quirk.RollRE = re and re:FindFirstChild("Roll")
    Quirk.SetProtectedRE = re and re:FindFirstChild("SetQuirkProtected")
    pcall(function() Quirk.Defs = require(RS.Framework.Features.Quirks.Quirks) end)
    pcall(function() Quirk.Util = require(RS.Framework.Features.Quirks.QuirkUtil) end)
end

-- Quest rewards (Daily and Weekly).
local QuestNetwork = network:FindFirstChild("QuestService")
local QuestRE = QuestNetwork and QuestNetwork:FindFirstChild("RE")
local ClaimQuestRE = QuestRE and QuestRE:FindFirstChild("Claim")
local QuestConfig = nil
pcall(function()
    QuestConfig = require(RS.Framework.Features.Quests.QuestConfig)
end)

local GradeNetwork           = network:FindFirstChild("GradeService")
local SetGradeProtectedRE    = GradeNetwork and GradeNetwork:FindFirstChild("RE") and GradeNetwork.RE:FindFirstChild("SetGradeProtected")
local RollGradeRE            = GradeNetwork and GradeNetwork:FindFirstChild("RE") and GradeNetwork.RE:FindFirstChild("Roll")

-- Sell Network Remotes
local SellNetwork            = network:FindFirstChild("SellService")
local SellInventoryRF        = SellNetwork and SellNetwork:FindFirstChild("RF") and SellNetwork.RF:FindFirstChild("SellInventory")
local SellEquippedRF         = SellNetwork and SellNetwork:FindFirstChild("RF") and SellNetwork.RF:FindFirstChild("SellEquipped")

-- Boost Network Remotes & Modules
local BoostNetwork           = network:FindFirstChild("BoostService")
local BoostUseRE             = BoostNetwork and BoostNetwork:FindFirstChild("RE") and BoostNetwork.RE:FindFirstChild("Use")
local BoostController        = nil
pcall(function()
    BoostController = require(RS.Framework.Features.Inventory.Kinds.Boost.BoostController)
end)
local BoostConfig            = nil
pcall(function()
    BoostConfig = require(RS.Framework.Features.Inventory.Kinds.Boost.BoostConfig)
end)

local DataController         = require(RS.Framework.Features.Data.DataController)
local BuffController         = require(RS.Framework.Features.Buffs.BuffController)
local UnitUtil               = require(RS.Framework.Features.Inventory.Kinds.Unit.UnitUtil)
local EntryRegistry          = require(RS.Framework.Features.Inventory.EntryRegistry)
local GradesModule           = require(RS.Framework.Features.Grades.Grades)
local TreeStructure          = require(RS.Framework.Features.Upgrades.TreeStructure)
local RebirthsModule         = require(RS.Framework.Features.Rebirth.Rebirths)
local UpgradesModule         = require(RS.Framework.Features.Upgrades.Upgrades)
local DiceModule             = require(RS.Framework.Features.Rolling.Dice)
local GroupRewardConfig      = require(RS.Framework.Features.Rewards.GroupRewardConfig)
local NumberFormatter        = require(RS.Packages.NumberFormatter)

local httpRequest            = (request or http_request or (syn and syn.request) or (http and http.request))

local TowerController        = nil
pcall(function()
    TowerController = require(RS.Framework.Features.Towers.TowerController)
end)
local UIReferences           = nil
pcall(function()
    UIReferences = require(RS.Framework.Features.UI.UIReferences)
end)
local TowersModule           = nil
pcall(function()
    TowersModule = require(RS.Framework.Features.Towers.Towers)
end)

-- ── 3. UPGRADE CATEGORIES & TOWER MAPPING ────────────────────────────────────────
local UpgradeCategories = {
    ["Luck & Fortune"]      = {"Luck", "Fortune"},
    ["Roll Speed"]       = {"Roll Speed"},
    ["Money"]           = {"Money"},
    ["Unit Storage"]   = {"Unit Storage"},
    ["Damage"]              = {"Damage"},
    ["Health"]              = {"Health"},
    ["Walkspeed"]        = {"Walkspeed"},
    ["Sell"]                  = {"Sell"},
}

local function getCategoryOfKey(key)
    for catName, prefixes in pairs(UpgradeCategories) do
        for _, p in ipairs(prefixes) do
            if key:sub(1, #p) == p then
                return catName
            end
        end
    end
    return "Other"
end

-- Load current towers in the game's progression order; keep a fallback for unavailable modules.
local TowerDisplayOptions = {
    "Dragon Tower", "Cursed Tower", "Pirate Tower", "Hidden Leaf Tower",
    "Slayer Tower", "Shadow Tower", "Infinity Tower",
}
local TowerDisplayNameMap = {}
pcall(function()
    if not TowersModule or type(TowersModule.GetAll) ~= "function" then return end
    local definitions = TowersModule.GetAll()
    if type(definitions) ~= "table" then return end
    local names = {}
    for name, definition in pairs(definitions) do
        if type(name) == "string" and type(definition) == "table" then
            table.insert(names, name)
        end
    end
    table.sort(names, function(a, b)
        local aOrder = tonumber(definitions[a].order) or math.huge
        local bOrder = tonumber(definitions[b].order) or math.huge
        if aOrder == bOrder then return a < b end
        return aOrder < bOrder
    end)
    if #names > 0 then TowerDisplayOptions = names end
end)
for _, name in ipairs(TowerDisplayOptions) do
    TowerDisplayNameMap[name] = name
end

-- Grade, Rarity & Rebirth mappings
local GradeOrder = {
    ["D"] = 1,
    ["C"] = 2,
    ["B"] = 3,
    ["A"] = 4,
    ["A+"] = 5,
    ["S"] = 6,
    ["S+"] = 7,
    ["Z"] = 8,
    ["Z+"] = 9,
    ["神"] = 10,
    ["∞"] = 11
}

local RarityOrder = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5,
    ["Mythical"] = 6,
    ["Secret I"] = 10,
    ["Secret II"] = 10,
    ["Secret"] = 10,
    ["Exotic"] = 8,
    ["Celestial"] = 9,
    ["Divine"] = 7,
    ["Heavenly"] = 11,
    ["Exclusive"] = 12
}

local function isCurrentRun()
    return _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId
end

local State = {
    UITheme = "Dark",
    UIKey = "RightControl",
    AntiAFK                  = true,

    -- Auto Farming (ALL FALSE BY DEFAULT)
    AutoRoll                 = false,
    AutoCollect              = false,
    AutoEquipBest            = false,
    EquipInterval            = 3.0,
    AutoLevelSlots           = false,
    TargetUnitLevel          = 30,
    AutoRebirth              = false,
    AutoUpgrades             = false,
    OnlySelectedUpgrades     = false,
    SelectedUpgradeCategories = {
        ["Luck & Fortune"] = true,
        ["Roll Speed"] = true,
        ["Money"] = true,
    },
    AutoBuyDice              = false,
    AutoClaim                = false,
    AutoClaimQuests          = false,

    -- Auto Use Items / Boosts (ALL FALSE BY DEFAULT)
    AutoUseItems             = false,
    ItemUseCondition         = "When Expired",
    ItemUseInterval          = 2.0,
    SelectedItems            = {},

    -- Auto Sell Units (ALL FALSE / SAFE BY DEFAULT)
    AutoSellUnits            = false,
    SellInterval             = 5,
    SelectedSellRarities     = {
        ["Common"] = true,
        ["Uncommon"] = true,
        ["Rare"] = true,
    },
    ProtectPlottedUnits      = true,
    ProtectGradeSPlus        = true,
    ProtectLockedUnits       = true,

    -- Grade System (ALL FALSE BY DEFAULT)
    AutoRerollGrade          = false,
    ProtectedGrades = {},
    TargetGradeUnitKey       = "",
    TargetGrade              = "S",
    GradeRollDelay           = 0.35,

    -- Trait rerolls
    AutoRerollTrait = false,
    TargetTraitUnitKey = "",
    TargetTrait = "Samurai",
    TraitRollDelay = 0.35,
    ProtectedTraits = {},
    ProtectRareTraits = true,

    -- Quirk rerolls
    AutoRerollQuirk = false,
    TargetQuirkUnitKey = "",
    TargetQuirk = "Tycoon",
    QuirkRollDelay = 0.35,
    ProtectedQuirks = {},

    -- Halloween event
    EventPumpkinRoll = false,
    EventPumpkinMulti = false,
    EventHouseWing = "Front Yard",
    EventTrickOrTreat = false,
    EventQuests = false,
    EventPass = false,
    EventShopAuto = false,
    EventShopItems = {},

    -- Discord Webhook
    WebhookURL               = "",
    WebhookEnabled           = false,
    WebhookNotifyRolls       = true,
    WebhookMinRarity         = "Mythical",
    WebhookNotifyRebirth     = true,
    WebhookNotifyGrade       = true,
    WebhookNotifyTrait       = true,
    WebhookPeriodicSummary   = false,
    WebhookSummaryInterval   = 15,

    -- Auto Tower (ALL FALSE BY DEFAULT)
    AutoTower                = false,
    SelectedTower            = "Dragon Tower",
    AutoEquipBestTowerTeam   = true,
    HideTowerScreen          = true,
}

-- ── 5. CORE AUTOMATION ENGINE ────────────────────────────────────────────────────

-- 1. Auto Collect Money from all 13 Plot Slots
local function collectAllSlots()
    pcall(function()
        for slot = 1, 13 do
            PlotService.RE.CollectBalance:FireServer(slot)
        end
    end)
end

-- 2. Auto Equip Best Anime Units
local function equipBestUnits()
    pcall(function()
        PlotService.RE.EquipBest:FireServer()
    end)
end

local function levelUpAllSlots()
    pcall(function()
        local curMoney = DataController.Money()
        if not curMoney or curMoney <= 0 then return end
        local targetLvl = tonumber(State.TargetUnitLevel) or 30
        for slot = 1, 13 do
            local slotData = DataController.Slots[tostring(slot)] and DataController.Slots[tostring(slot)]()
            if slotData and slotData.unitId then
                local unitData = DataController.Inventory[slotData.unitId] and DataController.Inventory[slotData.unitId]()
                if unitData then
                    local currentLvl = (unitData.attributes and unitData.attributes.level) or 1
                    if currentLvl < targetLvl then
                        local price = UnitUtil.GetLevelPrice(unitData.name, unitData.attributes)
                        if price and curMoney >= price then
                            curMoney = curMoney - price
                            PlotService.RE.LevelUpSlot:FireServer(slot)
                        end
                    end
                end
            end
        end
    end)
end

-- Discord Webhook Helper Engine
local function sendDiscordWebhook(title, description, color, fields)
    if not State.WebhookEnabled or not State.WebhookURL or State.WebhookURL == "" or not httpRequest then return end
    task.spawn(function()
        pcall(function()
            local payload = {
                username = "Vader Script | Anime Dice",
                embeds = {
                    {
                        title = title,
                        description = description,
                        color = color or 0x00FFE0,
                        fields = fields or {},
                        footer = {
                            text = "Vader Script • Anime Dice Automation • " .. os.date("%X")
                        },
                        timestamp = DateTime.now():ToIsoDate()
                    }
                }
            }
            httpRequest({
                Url = State.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

-- Claim completed quests once per reward period; retry delayed responses after 5 seconds.
local questClaimAttempts = {}
local function claimCompletedQuests()
    if not State.AutoClaimQuests or not ClaimQuestRE or not QuestConfig
        or not DataController.Quests then return end
    local serverNow = math.floor(workspace:GetServerTimeNow())
    for _, period in ipairs({"Daily", "Weekly"}) do
        pcall(function()
            local config = QuestConfig.Periods and QuestConfig.Periods[period]
            local getter = DataController.Quests[period]
            if not config or not getter then return end
            local data = getter()
            if type(data) ~= "table" or type(data.expiresAt) ~= "number"
                or data.expiresAt <= serverNow then return end
            local progress, claimed = data.progress or {}, data.claimed or {}
            for _, quest in ipairs(config.quests or {}) do
                local key = period .. ":" .. quest.id
                local attempt = questClaimAttempts[key]
                if claimed[quest.id] == true then
                    questClaimAttempts[key] = nil
                elseif type(quest.target) == "number" and (tonumber(progress[quest.id]) or 0) >= quest.target
                    and (not attempt or attempt.ExpiresAt ~= data.expiresAt
                        or os.clock() - attempt.SentAt >= 5) then
                    ClaimQuestRE:FireServer(period, quest.id, data.expiresAt)
                    questClaimAttempts[key] = {ExpiresAt = data.expiresAt, SentAt = os.clock()}
                end
            end
        end)
    end
end

-- Auto Rebirth: react as soon as the replicated money covers the next cost.
local pendingRebirth = nil
local function checkAndRebirth()
    pcall(function()
        local curRebirth = DataController.Rebirth()
        if type(curRebirth) ~= "number" then return end

        -- Wait for server confirmation before sending another request.
        if pendingRebirth then
            if curRebirth > pendingRebirth.Level then
                local confirmed = pendingRebirth
                pendingRebirth = nil
                if State.WebhookEnabled and State.WebhookNotifyRebirth then
                    sendDiscordWebhook(
                        "Rebirth complete! (Rebirth " .. tostring(curRebirth) .. ")",
                        "Player **" .. LP.DisplayName .. "** has reached the next rebirth level.",
                        0xFFD700,
                        {
                            {name = "New Rebirth Level", value = "Rebirth " .. tostring(curRebirth), inline = true},
                            {name = "Money Multiplier", value = "x" .. tostring(confirmed.Data.moneyMultiplier or "?"), inline = true},
                            {name = "Luck Multiplier", value = "x" .. tostring(confirmed.Data.luckMultiplier or "?"), inline = true}
                        }
                    )
                end
            elseif os.clock() - pendingRebirth.SentAt < 2 then
                return
            else
                pendingRebirth = nil
            end
        end

        if not State.AutoRebirth then return end
        local curMoney = DataController.Money()
        local nextData = RebirthsModule.GetNext(curRebirth)
        if nextData and type(nextData.cost) == "number"
            and type(curMoney) == "number" and curMoney >= nextData.cost then
            RebirthService.RE.Rebirth:FireServer()
            pendingRebirth = {Level = curRebirth, Data = nextData, SentAt = os.clock()}
        end
    end)
end

table.insert(_conns, RunService.Heartbeat:Connect(function()
    if _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId
        and (State.AutoRebirth or pendingRebirth) then
        checkAndRebirth()
    end
end))

-- 4.1 Selectable Auto Sell Engine
local function sellSelectedUnits()
    local soldCount = 0
    local earned = 0
    pcall(function()
        if not SellInventoryRF then return end
        local inv = DataController.Inventory and DataController.Inventory()
        if not inv then return end

        local plotted = {}
        for slot = 1, 13 do
            local sData = DataController.Slots[tostring(slot)] and DataController.Slots[tostring(slot)]()
            if sData and sData.unitId then
                plotted[sData.unitId] = true
            end
        end

        local towerTeam = {}
        if DataController.TowerTeam then
            local tt = DataController.TowerTeam()
            if type(tt) == "table" then
                for _, uid in pairs(tt) do
                    if type(uid) == "string" then towerTeam[uid] = true end
                end
            end
        end

        local toSell = {}
        for id, unit in pairs(inv) do
            if type(unit) == "table" and unit.name and unit.attributes then
                local isPlotted = plotted[id] == true
                local isTower = towerTeam[id] == true
                local isLocked = unit.attributes and unit.attributes.locked == true

                local canSell = true
                if State.ProtectPlottedUnits and (isPlotted or isTower) then
                    canSell = false
                end
                if State.ProtectLockedUnits and isLocked then
                    canSell = false
                end
                if State.ProtectGradeSPlus and unit.attributes and unit.attributes.grade then
                    local gOrder = GradeOrder[unit.attributes.grade] or 0
                    if gOrder >= 6 then
                        canSell = false
                    end
                end

                if canSell and State.ProtectRareTraits and unit.attributes then
                    local trait = unit.attributes.trait
                    local config = trait and TraitsModule[trait]
                    if config and (config.protected or State.ProtectedTraits[trait]) then
                        canSell = false
                    end
                end

                if canSell then
                    local cfg = EntryRegistry.getEntryConfig(unit.name)
                    local rarity = (cfg and cfg.rarity) or "Unknown"
                    local match = false
                    for selName, isSelected in pairs(State.SelectedSellRarities) do
                        if isSelected and (selName == rarity) then
                            match = true
                            break
                        end
                    end

                    if match then
                        table.insert(toSell, id)
                        if #toSell >= 50 then
                            break
                        end
                    end
                end
            end
        end

        if #toSell > 0 then
            local res1, res2 = SellInventoryRF:InvokeServer(toSell)
            earned = res1 or 0
            soldCount = res2 or #toSell
        end
    end)
    return soldCount, earned
end

-- 4.2 Auto Roll Grade Engine
local pendingGradeRoll = nil
local function rollGradeForSelectedUnit()
    local ok, success, reason = pcall(function()
        local unitKey = State.TargetGradeUnitKey
        if not RollGradeRE then return false, "Grade service unavailable." end
        if not unitKey or unitKey == "" then return false, "Select a unit first." end
        local inv = DataController.Inventory
        if not inv then return true, "Waiting for inventory." end
        local getter = inv[unitKey]
        local unit = getter and getter()
        if not unit or not unit.attributes then return false, "Selected unit is no longer available." end
        local curGrade = unit.attributes.grade or "D"
        local curOrder = GradeOrder[curGrade]
        local targetOrder = GradeOrder[State.TargetGrade]
        if not curOrder or not targetOrder then return false, "Unknown grade or target." end
        if curOrder >= targetOrder then return false, "Target grade reached." end
        local gemData = inv.Gems and inv.Gems()
        local gems = gemData and tonumber(gemData.amount) or 0

        if pendingGradeRoll then
            local previous = inv[pendingGradeRoll.UnitKey]
            previous = previous and previous()
            local previousGrade = previous and previous.attributes and previous.attributes.grade
            local confirmed = gems < pendingGradeRoll.Gems or previousGrade ~= pendingGradeRoll.RawGrade
            if not confirmed and os.clock() - pendingGradeRoll.SentAt < 2 then
                return true, "Waiting for server confirmation."
            end
            pendingGradeRoll = nil
        end
        if gems < 1 then return false, "No Gems remaining." end
        local locked = DataController.ProtectedGrades and DataController.ProtectedGrades[curGrade]
        if State.ProtectedGrades[curGrade] == true or (locked and locked() == true) then
            return false, "Current grade is locked: " .. curGrade
        end
        RollGradeRE:FireServer(unitKey)
        pendingGradeRoll = {UnitKey = unitKey, Gems = gems, RawGrade = unit.attributes.grade, SentAt = os.clock()}

        task.delay(0.2, function()
            if not _G.AnimeDiceRunning or _G.AnimeDiceRunId ~= thisRunId then return end
            pcall(function()
                local updatedGetter = inv[unitKey]
                local updatedUnit = updatedGetter and updatedGetter()
                local newGrade = updatedUnit and updatedUnit.attributes and updatedUnit.attributes.grade
                local newOrder = newGrade and GradeOrder[newGrade] or 0
                if newGrade ~= curGrade and newOrder >= 6 and State.WebhookEnabled and State.WebhookNotifyGrade then
                    sendDiscordWebhook(
                        "High grade rolled! (Grade " .. newGrade .. ")",
                        "Unit **" .. updatedUnit.name .. "** rolled a high grade.", 0x9B59B6,
                        {
                            {name = "Unit", value = updatedUnit.name, inline = true},
                            {name = "Grade", value = newGrade, inline = true},
                            {name = "Gems Remaining", value = tostring(inv.Gems and inv.Gems().amount or 0), inline = true}
                        }
                    )
                end
            end)
        end)
        return true, "Reroll requested."
    end)
    if not ok then return false, "Grade request failed: " .. tostring(success) end
    return success, reason
end

-- Compare actual bonuses; Money, Damage, and Health are separate categories.
local function traitMeetsTarget(currentName, targetName)
    if currentName == targetName then return true end
    local current, target = TraitsModule[currentName], TraitsModule[targetName]
    if not current or not target then return false end
    local compared = false
    for _, stat in ipairs({"incomeMultiplier", "damageMultiplier", "healthMultiplier"}) do
        if target[stat] then
            compared = true
            if (current[stat] or 1) < target[stat] then return false end
        end
    end
    return compared
end

local pendingTraitRoll = nil
local function rollTraitForSelectedUnit()
    local ok, success, reason = pcall(function()
        local unitKey = State.TargetTraitUnitKey
        if not RollTraitRE then return false, "Trait service unavailable." end
        if not unitKey or unitKey == "" then return false, "Select a unit first." end
        if not TraitsModule[State.TargetTrait] then return false, "Select a valid target trait." end
        local inv = DataController.Inventory
        if not inv then return true, "Waiting for inventory." end
        local getter = inv[unitKey]
        local unit = getter and getter()
        if not unit or not unit.attributes then return false, "Selected unit is no longer available." end
        local currentTrait = unit.attributes.trait
        if traitMeetsTarget(currentTrait, State.TargetTrait) then
            pendingTraitRoll = nil
            return false, "Target trait reached."
        end
        local protectedGetter = currentTrait and DataController.ProtectedTraits
            and DataController.ProtectedTraits[currentTrait]
        if currentTrait and (State.ProtectedTraits[currentTrait] == true
            or (protectedGetter and protectedGetter() == true)) then
            return false, "Current trait is locked: " .. currentTrait
        end
        local item = inv["Trait Reroll"] and inv["Trait Reroll"]()
        local amount = item and tonumber(item.amount) or 0
        if pendingTraitRoll then
            local previous = inv[pendingTraitRoll.UnitKey]
            previous = previous and previous()
            local previousTrait = previous and previous.attributes and previous.attributes.trait
            if amount >= pendingTraitRoll.Amount and previousTrait == pendingTraitRoll.Trait
                and os.clock() - pendingTraitRoll.SentAt < 2 then
                return true, "Waiting for server confirmation."
            end
            pendingTraitRoll = nil
        end
        if amount < 1 then return false, "No Trait Reroll items remaining." end
        -- The game's ordinary roll path respects server protection.
        RollTraitRE:FireServer(unitKey)
        pendingTraitRoll = {UnitKey=unitKey, Amount=amount, Trait=currentTrait, SentAt=os.clock()}
        task.delay(0.2, function()
            if not _G.AnimeDiceRunning or _G.AnimeDiceRunId ~= thisRunId then return end
            pcall(function()
                local updatedGetter = inv[unitKey]
                local updated = updatedGetter and updatedGetter()
                local trait = updated and updated.attributes and updated.attributes.trait
                local config = trait and TraitsModule[trait]
                if trait ~= currentTrait and config and config.protected
                    and State.WebhookEnabled and State.WebhookNotifyTrait then
                    sendDiscordWebhook("Rare trait rolled! (" .. trait .. ")",
                        "Unit **" .. updated.name .. "** rolled " .. trait .. ".", 0x9B59B6,
                        {{name="Unit",value=updated.name,inline=true},
                         {name="Trait",value=trait,inline=true}})
                end
            end)
        end)
        return true, "Trait reroll requested."
    end)
    if not ok then return false, "Trait request failed: " .. tostring(success) end
    return success, reason
end

-- Quirks follow the trait flow, but each roll costs money and buffs are compared per stat.
function Quirk.meetsTarget(currentName, targetName)
    if currentName == targetName then return true end
    local current, target = Quirk.Defs[currentName], Quirk.Defs[targetName]
    if not current or not target or not target.buffs or next(target.buffs) == nil then return false end
    for stat, buff in pairs(target.buffs) do
        local have = current.buffs and current.buffs[stat]
        -- abs: Roll Duration buffs are negative, so a larger magnitude is better.
        if not have or math.abs(have.amount) < math.abs(buff.amount) then return false end
    end
    return true
end

function Quirk.roll()
    local ok, success, reason = pcall(function()
        local unitKey = State.TargetQuirkUnitKey
        if not Quirk.RollRE then return false, "Quirk service unavailable." end
        if not unitKey or unitKey == "" then return false, "Select a unit first." end
        if not Quirk.Defs[State.TargetQuirk] then return false, "Select a valid target quirk." end
        local inv = DataController.Inventory
        if not inv then return true, "Waiting for inventory." end
        local getter = inv[unitKey]
        local unit = getter and getter()
        if not unit or not unit.attributes then return false, "Selected unit is no longer available." end
        local currentQuirk = unit.attributes.quirk
        if Quirk.meetsTarget(currentQuirk, State.TargetQuirk) then
            Quirk.pending = nil
            return false, "Target quirk reached."
        end
        local protectedGetter = currentQuirk and DataController.ProtectedQuirks
            and DataController.ProtectedQuirks[currentQuirk]
        if currentQuirk and (State.ProtectedQuirks[currentQuirk] == true
            or (protectedGetter and protectedGetter() == true)) then
            return false, "Current quirk is locked: " .. currentQuirk
        end
        local money = tonumber(DataController.Money()) or 0
        local pending = Quirk.pending
        if pending then
            local previous = inv[pending.UnitKey]
            previous = previous and previous()
            local previousQuirk = previous and previous.attributes and previous.attributes.quirk
            -- shortcut: income can hide the money drop, so a same-quirk reroll may wait the full 2s; track a roll counter if the game exposes one.
            if money >= pending.Money and previousQuirk == pending.Quirk
                and os.clock() - pending.SentAt < 2 then
                return true, "Waiting for server confirmation."
            end
            Quirk.pending = nil
        end
        local cost = Quirk.Util and Quirk.Util.GetRollCost(unit.name, unit.attributes)
        if type(cost) == "number" and money < cost then return false, "Not enough money to roll." end
        -- One argument only: the game's second argument skips server protection.
        Quirk.RollRE:FireServer(unitKey)
        Quirk.pending = {UnitKey=unitKey, Money=money, Quirk=currentQuirk, SentAt=os.clock()}
        return true, "Quirk reroll requested."
    end)
    if not ok then return false, "Quirk request failed: " .. tostring(success) end
    return success, reason
end

-- 5. Auto Buy Upgrades with Dropdown Category Prioritization
local function buyPrioritizedUpgrades()
    pcall(function()
        if not UpgradesModule or not TreeStructure then return end
        local curMoney = DataController.Money()
        if not curMoney or curMoney <= 0 then return end

        local unownedAvailable = {}
        for key, data in pairs(UpgradesModule) do
            local isOwned = DataController.Upgrades[key] and DataController.Upgrades[key]()
            if not isOwned then
                local parent = TreeStructure.GetParent(key)
                local parentUnlocked = (not parent or parent == "Start") or (DataController.Upgrades[parent] and DataController.Upgrades[parent]())
                if parentUnlocked and data.price and curMoney >= data.price then
                    table.insert(unownedAvailable, {
                        key = key,
                        price = data.price,
                        category = getCategoryOfKey(key)
                    })
                end
            end
        end

        if #unownedAvailable == 0 then return end

        local focusedList = {}
        local otherList = {}

        for _, item in ipairs(unownedAvailable) do
            if State.SelectedUpgradeCategories[item.category] then
                table.insert(focusedList, item)
            else
                table.insert(otherList, item)
            end
        end

        table.sort(focusedList, function(a, b) return a.price < b.price end)
        table.sort(otherList, function(a, b) return a.price < b.price end)

        for _, item in ipairs(focusedList) do
            if not isCurrentRun() or not State.AutoUpgrades then return end
            if curMoney >= item.price then
                curMoney = curMoney - item.price
                UpgradeServiceRE:FireServer(item.key)
                task.wait(0.12)
            end
        end

        if not State.OnlySelectedUpgrades then
            for _, item in ipairs(otherList) do
            if not isCurrentRun() or not State.AutoUpgrades then return end
                if curMoney >= item.price then
                    curMoney = curMoney - item.price
                    UpgradeServiceRE:FireServer(item.key)
                    task.wait(0.12)
                end
            end
        end
    end)
end

-- 6. Auto Buy Affordable Unowned Dice
local function buyAffordableDice()
    pcall(function()
        if not DiceModule then return end
        local allDice = DiceModule.GetAll()
        local curMoney = DataController.Money()
        for name, data in pairs(allDice) do
            if not isCurrentRun() or not State.AutoBuyDice then return end
            local isOwned = DataController.OwnedDice[name] and DataController.OwnedDice[name]()
            if not isOwned and data.price and data.price <= curMoney then
                curMoney = curMoney - data.price
                DiceShopService.RE.BuyDice:FireServer(name)
                task.wait(0.4)
            end
        end
    end)
end

local function claimAllFreebies()
    pcall(function()
        DailyRewardService.RE.Claim:FireServer()
        OfflineEarningsService.RE.Claim:FireServer()
        SpinService.RE.Use:FireServer()

        if GroupRewardConfig and GroupRewardConfig.GroupId then
            local inGroup = false
            pcall(function()
                inGroup = LP:IsInGroup(GroupRewardConfig.GroupId)
            end)
            if inGroup and DataController.ClaimedGroupReward and not DataController.ClaimedGroupReward() then
                GroupRewardService.RE.Claim:FireServer()
            end
        end
    end)
end

-- 8. Auto Tower Automation Handler
local function handleAutoTower()
    pcall(function()
        if not State.AutoTower then return end

        local screen = UIReferences and UIReferences.Root and UIReferences.Root.Tower and UIReferences.Root.Tower.Screen
        local hidden = screen and screen.Parent and screen.Parent:FindFirstChild("Hidden")
        local inTower = (hidden and hidden.Visible == true) or (screen and screen.Visible == true)

        if inTower then
            if State.HideTowerScreen and screen and screen.Visible and hidden then
                pcall(function()
                    if firesignal then
                        firesignal(hidden.Activated)
                    end
                end)
            end

            if screen and screen:FindFirstChild("Buttons") and screen.Buttons:FindFirstChild("Auto") then
                local autoBtn = screen.Buttons.Auto
                local grad = autoBtn:FindFirstChildOfClass("UIGradient")
                local isGreen = grad and tostring(grad.Color):find("0.298")
                if not isGreen and firesignal then
                    pcall(function() firesignal(autoBtn.Activated) end)
                end
            end
        else
            if State.AutoEquipBestTowerTeam and EquipBestTowerTeamRE then
                pcall(function() EquipBestTowerTeamRE:FireServer() end)
                task.wait(0.3)
            end
            if not isCurrentRun() or not State.AutoTower then return end

            local towerTarget = State.SelectedTower or "Dragon Tower"
            local started = false
            if TowerController and TowerController.startTower then
                started = TowerController.startTower(towerTarget)
            end
            if not started and PlayTowerRF then
                PlayTowerRF:InvokeServer(towerTarget)
            end
            task.wait(1.2)

            if State.HideTowerScreen and screen and screen.Visible and hidden and firesignal then
                pcall(function() firesignal(hidden.Activated) end)
            end
        end
    end)
end

-- 9. Auto Use Items & Boosts Engine
local function getAllBoostNames()
    local names = {}
    pcall(function()
        if BoostConfig and BoostConfig.entries then
            for name, _ in pairs(BoostConfig.entries) do
                table.insert(names, name)
            end
        end
    end)
    table.sort(names)
    if #names == 0 then
        names = {
            "Cursed Damage I", "Cursed Damage II", "Cursed Damage III",
            "Cursed Income I", "Cursed Income II", "Cursed Income III",
            "Cursed Luck I", "Cursed Luck II", "Cursed Luck III",
            "Damage I", "Damage II", "Damage III", "Damage IV",
            "Dragon Damage I", "Dragon Damage II", "Dragon Damage III",
            "Dragon Income I", "Dragon Income II", "Dragon Income III",
            "Dragon Luck I", "Dragon Luck II", "Dragon Luck III",
            "Income I", "Income II", "Income III", "Income IV",
            "Leaf Damage I", "Leaf Damage II", "Leaf Damage III",
            "Leaf Income I", "Leaf Income II", "Leaf Income III",
            "Leaf Luck I", "Leaf Luck II", "Leaf Luck III",
            "Luck I", "Luck II", "Luck III", "Luck IV",
            "Pirate Damage I", "Pirate Damage II", "Pirate Damage III",
            "Pirate Income I", "Pirate Income II", "Pirate Income III",
            "Pirate Luck I", "Pirate Luck II", "Pirate Luck III",
            "Speed I", "Speed II", "Speed III", "Speed IV"
        }
    end
    return names
end

local function isBoostActive(boostName)
    local active = false
    pcall(function()
        local buffBar = LP.PlayerGui:FindFirstChild("BuffBar", true)
        if buffBar and buffBar:FindFirstChild("Boost_" .. boostName) then
            active = true
        end
    end)
    return active
end

local function useBoostItem(boostName)
    local success = false
    pcall(function()
        if BoostController and BoostController.UseBoost then
            BoostController.UseBoost(boostName)
            success = true
        elseif BoostUseRE then
            BoostUseRE:FireServer(boostName)
            success = true
        end
    end)
    return success
end

local function autoUseSelectedItems()
    if not State.AutoUseItems then return end
    pcall(function()
        local inv = DataController.Inventory and DataController.Inventory()
        if type(inv) ~= "table" then return end

        for itemName, isSelected in pairs(State.SelectedItems) do
            if not isCurrentRun() then return end
            if isSelected then
                local itemData = inv[itemName]
                local amount = itemData and tonumber(itemData.amount) or 0
                if amount > 0 then
                    local shouldUse = false
                    if State.ItemUseCondition == "Always Use" then
                        shouldUse = true
                    else
                        if not isBoostActive(itemName) then
                            shouldUse = true
                        end
                    end

                    if shouldUse then
                        local ok = useBoostItem(itemName)
                        if ok then
                            task.wait(0.15)
                        end
                    end
                end
            end
        end
    end)
end

local function useSelectedItemsNow()
    local count = 0
    pcall(function()
        local inv = DataController.Inventory and DataController.Inventory()
        if type(inv) ~= "table" then return end

        for itemName, isSelected in pairs(State.SelectedItems) do
            if not isCurrentRun() then return end
            if isSelected then
                local itemData = inv[itemName]
                local amount = itemData and tonumber(itemData.amount) or 0
                if amount > 0 then
                    local ok = useBoostItem(itemName)
                    if ok then
                        count = count + 1
                        task.wait(0.15)
                    end
                end
            end
        end
    end)
    return count
end

-- ── 5.1 ANTI-AFK & ANTI-KICK DEFENSE ENGINE (TRIPLE-LAYER ZERO-DISCONNECT) ────────

local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local function neutralizeGameAFK()
    if not isCurrentRun() or not State.AntiAFK then return end
    pcall(function()
        local afkScript = LP.PlayerScripts:FindFirstChild("AFK")
        if afkScript then
            afkScript.Disabled = true
            afkScript:Destroy()
        end
    end)
end
neutralizeGameAFK()

table.insert(_conns, LP.PlayerScripts.ChildAdded:Connect(function(child)
    if isCurrentRun() and State.AntiAFK and child.Name == "AFK" and child:IsA("LocalScript") then
        pcall(function()
            child.Disabled = true
            child:Destroy()
        end)
    end
end))

pcall(function()
    if hookfunction then
        local oldTeleport
        oldTeleport = hookfunction(TeleportService.Teleport, function(self, placeId, player, ...)
            if isCurrentRun() and State.AntiAFK then
                local trace = debug.traceback()
                if string.find(trace, "AFK") or string.find(trace, "scheduleTeleport") then
                    return
                end
            end
            return oldTeleport(self, placeId, player, ...)
        end)
    end
end)

pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if isCurrentRun() and State.AntiAFK and (method == "Teleport" or method == "teleport") and self == TeleportService then
                local trace = debug.traceback()
                if string.find(trace, "AFK") or string.find(trace, "scheduleTeleport") then
                    return
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

pcall(function()
    if getconnections then
        for _, c in ipairs(getconnections(LP.Idled)) do
            pcall(function() c:Disable() end)
        end
    end
end)

table.insert(_conns, LP.Idled:Connect(function()
    if not State.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end))

task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(40)
        if not isCurrentRun() then break end
        if State.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero)
            end)
            pcall(function()
                if VirtualInputManager then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
                    task.wait(0.03)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
                end
            end)
            neutralizeGameAFK()
        end
    end
end)

-- ── 6. ASYNC AUTOMATION THREADS ──────────────────────────────────────────────────

task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        if State.AutoCollect then
            collectAllSlots()
        end
        task.wait(0.5)
        if not isCurrentRun() then break end
    end
end)

task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        if State.AutoEquipBest then
            equipBestUnits()
        end
        local delaySec = tonumber(State.EquipInterval) or 3.0
        if delaySec < 1.0 then delaySec = 1.0 end
        task.wait(delaySec)
        if not isCurrentRun() then break end
    end
end)

-- Thread 3: Slot Level Ups
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(0.7)
        if not isCurrentRun() then break end
        if State.AutoLevelSlots then
            levelUpAllSlots()
        end
    end
end)

task.spawn(function()
    local lastRollTime = 0
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(0.1)
        if not isCurrentRun() then break end
        if State.AutoRoll then
            pcall(function()
                if not DataController.AutoRoll() then
                    RollService.RE.SetAutoRoll:FireServer(true)
                end
            end)

            local duration = 1.9
            pcall(function()
                local d = BuffController.GetBuff("Roll Duration")
                if type(d) == "number" and d > 0 then
                    duration = d
                end
            end)

            if os.clock() - lastRollTime >= (duration + 0.1) then
                lastRollTime = os.clock()
                pcall(function()
                    RollService.RF.RollDice:InvokeServer()
                end)
            end
        else
            pcall(function()
                if DataController.AutoRoll() then
                    RollService.RE.SetAutoRoll:FireServer(false)
                end
            end)
        end
    end
end)

-- Thread 5: Upgrades, Dice & Claims
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(1.5)
        if not isCurrentRun() then break end
        if State.AutoUpgrades then
            buyPrioritizedUpgrades()
        end
        if State.AutoBuyDice then
            buyAffordableDice()
        end
        if State.AutoClaim then
            claimAllFreebies()
        end
    end
end)

-- Thread 6: Auto Tower Loop
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(1.5)
        if not isCurrentRun() then break end
        if State.AutoTower then
            handleAutoTower()
        end
    end
end)

task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        if State.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero)
            end)
        end
        task.wait(45)
        if not isCurrentRun() then break end
    end
end)

-- Thread 8: Selectable Auto Sell Units Loop
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        local interval = tonumber(State.SellInterval) or 5
        if interval < 1 then interval = 1 end
        task.wait(interval)
        if not isCurrentRun() then break end
        if State.AutoSellUnits then
            pcall(sellSelectedUnits)
        end
    end
end)

-- Thread 9: Auto Roll Grade Loop
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(math.clamp(tonumber(State.GradeRollDelay) or 0.35, 0.15, 1))
        if not _G.AnimeDiceRunning or _G.AnimeDiceRunId ~= thisRunId then break end
        if State.AutoRerollGrade then
            local ok, reason = rollGradeForSelectedUnit()
            if not ok then
                State.AutoRerollGrade = false
                local ui = _G.AnimeDiceVaderUI
                local toggle = ui and ui.Options and ui.Options.TogAutoRerollGrade
                if toggle then toggle:SetValue(false) end
                if ui and reason then
                    ui:Notify({Title = "Auto Reroll Stopped", Content = reason, Duration = 3})
                end
            end
        end
    end
end)

-- Thread 10: Webhook High-Tier Rolls Watcher
task.spawn(function()
    local knownUnits = {}
    pcall(function()
        local inv = DataController.Inventory and DataController.Inventory()
        if inv then
            for id, _ in pairs(inv) do knownUnits[id] = true end
        end
    end)

    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(0.6)
        if not isCurrentRun() then break end
        pcall(function()
            local inv = DataController.Inventory and DataController.Inventory()
            if not inv then return end

            for id, unit in pairs(inv) do
                if not knownUnits[id] and type(unit) == "table" and unit.name and unit.attributes then
                    knownUnits[id] = true

                    local cfg = EntryRegistry.getEntryConfig(unit.name)
                    local rarity = (cfg and cfg.rarity) or "Unknown"
                    local rarityRank = RarityOrder[rarity] or 0
                    local minRank = RarityOrder[State.WebhookMinRarity] or 6

                    if State.WebhookEnabled and State.WebhookNotifyRolls and rarityRank >= minRank then
                        local grade = unit.attributes.grade or "D"
                        local trait = unit.attributes.trait or "None"
                        local mutation = unit.attributes.mutation or "None"
                        sendDiscordWebhook(
                            "High rarity unit rolled! (" .. rarity .. ")",
                            "Player **" .. LP.DisplayName .. "** rolled a new unit.",
                            0x00FFE0,
                            {
                                {name = "Unit", value = unit.name, inline = true},
                                {name = "Rarity", value = rarity, inline = true},
                                {name = "Grades", value = grade, inline = true},
                                {name = "Trait", value = trait, inline = true},
                                {name = "Mutation", value = mutation, inline = true},
                                {name = "Rebirth Level", value = "Rebirth " .. tostring(DataController.Rebirth()), inline = true}
                            }
                        )
                    end
                end
            end
        end)
    end
end)

-- Thread 11: Webhook Periodic Stats Summary
task.spawn(function()
    local lastSummaryTime = os.clock()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(10)
        if not isCurrentRun() then break end
        if State.WebhookEnabled and State.WebhookPeriodicSummary then
            local intervalSec = (tonumber(State.WebhookSummaryInterval) or 15) * 60
            if os.clock() - lastSummaryTime >= intervalSec then
                lastSummaryTime = os.clock()
                pcall(function()
                    local moneyStr = NumberFormatter.FormatCompact(DataController.Money() or 0)
                    local rebirthLvl = tostring(DataController.Rebirth() or 0)
                    local diceName = tostring(DataController.Dice() or "Default")
                    local invCount = 0
                    local inv = DataController.Inventory and DataController.Inventory()
                    if inv then
                        for _, u in pairs(inv) do
                            if type(u) == "table" and u.name then invCount = invCount + 1 end
                        end
                    end

                    sendDiscordWebhook(
                        "Status Summary",
                        "Progress summary for **" .. LP.DisplayName .. "** (@" .. LP.Name .. ")",
                        0x4287F5,
                        {
                            {name = "Cash Balance", value = "$" .. moneyStr, inline = true},
                            {name = "Rebirth Level", value = "Rebirth " .. rebirthLvl, inline = true},
                            {name = "Current Dice", value = diceName, inline = true},
                            {name = "Inventory Units", value = tostring(invCount) .. " units", inline = true},
                            {name = "Selected Tower", value = State.SelectedTower or "None", inline = true},
                            {name = "Session Duration", value = string.format("%.1f minutes", (os.clock()) / 60), inline = true}
                        }
                    )
                end)
            end
        end
    end
end)

-- Thread 12: Auto Use Items / Boosts Loop
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        local interval = tonumber(State.ItemUseInterval) or 2.0
        if interval < 0.5 then interval = 0.5 end
        task.wait(interval)
        if not isCurrentRun() then break end
        if State.AutoUseItems then
            pcall(autoUseSelectedItems)
        end
    end
end)

task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        if State.AutoClaimQuests then
            pcall(claimCompletedQuests)
        end
        task.wait(1)
        if not isCurrentRun() then break end
    end
end)

-- Trait reroll worker uses the same stop and confirmation behavior as Grade.
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(math.clamp(tonumber(State.TraitRollDelay) or 0.35, 0.15, 1))
        if not _G.AnimeDiceRunning or _G.AnimeDiceRunId ~= thisRunId then break end
        if State.AutoRerollTrait then
            local ok, reason = rollTraitForSelectedUnit()
            if not ok then
                State.AutoRerollTrait = false
                local ui = _G.AnimeDiceVaderUI
                local toggle = ui and ui.Options and ui.Options.TogAutoRerollTrait
                if toggle then toggle:SetValue(false) end
                if ui then ui:Notify({Title="Auto Trait Reroll Stopped",Content=reason,Duration=3}) end
            end
        end
    end
end)

-- Quirk reroll worker, same stop behavior as Trait.
task.spawn(function()
    while isCurrentRun() do
        task.wait(math.clamp(tonumber(State.QuirkRollDelay) or 0.35, 0.15, 1))
        if not isCurrentRun() then break end
        if State.AutoRerollQuirk then
            local ok, reason = Quirk.roll()
            if not ok then
                State.AutoRerollQuirk = false
                local ui = _G.AnimeDiceVaderUI
                local toggle = ui and ui.Options and ui.Options.TogAutoRerollQuirk
                if toggle then toggle:SetValue(false) end
                if ui then ui:Notify({Title="Auto Quirk Reroll Stopped",Content=reason,Duration=3}) end
            end
        end
    end
end)

-- Load VaderUI from GitHub.
local VaderUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
_G.AnimeDiceVaderUI = VaderUI

-- Keep startup and restored control values quiet; user actions still notify.
local initializingUI = true
local originalNotify = VaderUI.Notify
function VaderUI:Notify(config)
    if initializingUI then
        return { Closed = true, Close = function() end }
    end
    return originalNotify(self, config)
end

local Window = VaderUI:CreateWindow({
    Title = "Anime Dice",
    SubTitle = "by vaderhug",
    TabWidth = 180,
    Size = UDim2.fromOffset(600, 460),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

-- Both VaderUI's close button and the settings button stop this script's workers.
local destroyVaderUI = VaderUI.Destroy
local closingVaderUI = false
function VaderUI:Destroy()
    if closingVaderUI or self.Unloaded then return end
    closingVaderUI = true
    destroyVaderUI(self)
    if _G.AnimeDiceRunId == thisRunId and _G.AnimeDiceCleanup then
        _G.AnimeDiceCleanup()
    end
    if _G.AnimeDiceVaderUI == self then
        _G.AnimeDiceVaderUI = nil
    end
    closingVaderUI = false
end
_G.AnimeDiceWindow = VaderUI

-- getgenv().TH = true before running switches the UI to Thai by swapping label text as it appears.
if ((getgenv and getgenv()) or _G).TH == true and VaderUI.GUI then
    local TH = {
        -- Tabs and sections
        ["Main"] = "หลัก", ["Items & Boosts"] = "ไอเทมและบูสต์", ["Towers"] = "หอคอย", ["Plots"] = "แปลง",
        ["Auto Sell"] = "ขายอัตโนมัติ", ["Grades"] = "เกรด", ["Traits"] = "เทรต", ["Quirks"] = "เควิร์ก",
        ["Upgrades & Dice"] = "อัปเกรดและลูกเต๋า", ["Webhook"] = "เว็บฮุก", ["Settings"] = "ตั้งค่า",
        ["Rolling"] = "ทอยลูกเต๋า", ["Rebirth & Claims"] = "รีเบิร์ธและรับรางวัล", ["Quests"] = "เควส",
        ["Collect Balance"] = "เก็บเงิน", ["Auto Use Items"] = "ใช้ไอเทมอัตโนมัติ", ["Quick Actions"] = "คำสั่งด่วน",
        ["Auto Tower"] = "ลงหอคอยอัตโนมัติ", ["Manual Controls"] = "ควบคุมเอง", ["Anime Units"] = "ยูนิต",
        ["Level Up Units"] = "อัปเลเวลยูนิต", ["Inventory Sell"] = "ขายของในกระเป๋า", ["Safety Lock"] = "กันขายพลาด",
        ["Manual Actions"] = "สั่งเอง", ["Auto Reroll"] = "สุ่มใหม่อัตโนมัติ", ["Manual Reroll"] = "สุ่มเอง",
        ["Server Lock"] = "ล็อกบนเซิร์ฟเวอร์", ["Upgrades"] = "อัปเกรด", ["Dice Shop"] = "ร้านลูกเต๋า",
        ["Discord Webhook Settings"] = "ตั้งค่าเว็บฮุกดิสคอร์ด", ["Event Alerts"] = "แจ้งเตือนเหตุการณ์",
        ["Periodic Summary"] = "สรุปผลตามเวลา", ["Theme Settings"] = "ธีม", ["Anti-AFK"] = "กัน AFK",
        ["Community & Support"] = "ชุมชนและช่วยเหลือ",
        -- Main
        ["Auto Roll"] = "ทอยอัตโนมัติ", ["Roll nonstop."] = "ทอยต่อเนื่องเร็วสุดที่เซิร์ฟให้",
        ["Auto Rebirth"] = "รีเบิร์ธอัตโนมัติ", ["Rebirth when affordable."] = "รีเบิร์ธทันทีที่เงินพอ",
        ["Auto Claim"] = "รับรางวัลอัตโนมัติ", ["Daily, spin and offline rewards."] = "รับรางวัลรายวัน วงล้อ และออฟไลน์",
        ["Auto Claim Quests"] = "รับรางวัลเควสอัตโนมัติ",
        ["Daily and weekly quests."] = "รับรางวัลเควสรายวันและรายสัปดาห์ที่ทำเสร็จ",
        ["Auto Collect"] = "เก็บเงินอัตโนมัติ", ["Collect from all slots."] = "เก็บเงินทุกช่องทุก 0.5 วินาที",
        ["Collect Now"] = "เก็บเงินตอนนี้", ["Collect once."] = "เก็บเงินทุกช่องทันที",
        -- Items
        ["Use selected boosts."] = "ใช้ไอเทมและบูสต์ที่เลือก",
        ["Select Items"] = "เลือกไอเทม", ["Items to use."] = "เลือกไอเทมที่จะใช้",
        ["Condition"] = "เงื่อนไข", ["When to use."] = "เลือกว่าจะใช้ตอนไหน",
        ["Check Interval (seconds)"] = "เช็กทุก (วินาที)", ["Check delay."] = "ระยะห่างการเช็กไอเทม",
        ["Select Owned"] = "เลือกที่มีทั้งหมด", ["Pick all owned."] = "เลือกทุกไอเทมในกระเป๋า",
        ["Clear All"] = "ล้างทั้งหมด", ["Clear selection."] = "ยกเลิกการเลือกทั้งหมด",
        ["Use Now"] = "ใช้ตอนนี้", ["Use once."] = "ใช้ไอเทมที่เลือกอย่างละครั้ง",
        -- Towers
        ["Select Tower"] = "เลือกหอคอย", ["Tower to farm."] = "เลือกหอคอยที่จะฟาร์ม",
        ["Replay after each run."] = "เริ่มใหม่ทุกครั้งที่ชนะหรือแพ้",
        ["Equip Best Team"] = "ใส่ทีมที่ดีที่สุด", ["Best team first."] = "ใส่ยูนิตดาเมจและเลือดดีสุด",
        ["Hide Screen"] = "ซ่อนหน้าจอ", ["Hide battle screen."] = "ซ่อนหน้าจอต่อสู้ในหอคอย",
        ["Play Tower Now"] = "เข้าหอคอยตอนนี้", ["Start one run."] = "เล่นหอคอยที่เลือกหนึ่งรอบ",
        ["Exit Tower"] = "ออกจากหอคอย", ["Leave now."] = "ออกจากหอคอยทันที",
        -- Plots
        ["Auto Equip Best"] = "ใส่ยูนิตดีสุดอัตโนมัติ", ["Keep best units on slots."] = "ใส่ยูนิตดีสุดในช่องเสมอ",
        ["Equip Interval (seconds)"] = "เช็กทุก (วินาที)", ["Equip delay."] = "ระยะห่างการเช็กยูนิตดีสุด",
        ["Equip Best Now"] = "ใส่ยูนิตดีสุดตอนนี้", ["Auto Level Up"] = "อัปเลเวลอัตโนมัติ",
        ["Level slotted units."] = "อัปเลเวลยูนิตในช่องเมื่อเงินพอ",
        ["Preset Level"] = "เลเวลสำเร็จรูป", ["Target level."] = "เลือกเลเวลเป้าหมาย",
        ["Level Limit (10 - 150)"] = "เลเวลสูงสุด (10 - 150)", ["Max level."] = "ตั้งเลเวลสูงสุดของยูนิต",
        ["Level Up Now"] = "อัปเลเวลตอนนี้", ["Level once."] = "อัปยูนิตในช่องหนึ่งครั้ง",
        -- Auto Sell
        ["Sell selected rarities."] = "ขายยูนิตระดับที่เลือก",
        ["Sell Interval (seconds)"] = "ขายทุก (วินาที)", ["Sell delay."] = "ระยะห่างการขาย",
        ["Rarities"] = "ระดับความหายาก", ["Rarities to sell."] = "ขายเฉพาะระดับที่เลือก",
        ["Protect Equipped"] = "กันยูนิตที่ใส่อยู่", ["Skip plot and tower units."] = "ไม่ขายยูนิตบนแปลงหรือทีมหอคอย",
        ["Protect Grade S and Above"] = "กันเกรด S ขึ้นไป",
        ["Skip grade S and up."] = "ไม่ขายเกรด S, S+, Z, Z+, God, Infinity",
        ["Protect Rare Traits"] = "กันเทรตหายาก",
        ["Skip rare or locked traits."] = "ไม่ขายเทรตหายากหรือเทรตที่ล็อกไว้",
        ["Protect Locked"] = "กันยูนิตที่ล็อก", ["Skip locked units."] = "ไม่ขายยูนิตที่ล็อกไว้",
        ["Sell Now"] = "ขายตอนนี้", ["Sell up to 50 now."] = "ขายยูนิตที่ตรงเงื่อนไข สูงสุด 50 ตัว",
        -- Grades / Traits / Quirks
        ["Grade Guide"] = "วิธีใช้เกรด",
        ["1 Gem per roll."] = "สุ่มครั้งละ 1 เจม หยุดเมื่อถึงเป้าหรือเจมหมด",
        ["Select Unit"] = "เลือกยูนิต", ["Unit to reroll."] = "เลือกยูนิตที่จะสุ่ม",
        ["Refresh Units"] = "รีเฟรชยูนิต", ["Reload units."] = "อัปเดตรายชื่อยูนิต",
        ["Reload trait units."] = "อัปเดตรายชื่อยูนิต",
        ["Reload quirk units."] = "อัปเดตรายชื่อยูนิต",
        ["Target Grade"] = "เกรดเป้าหมาย", ["This grade or higher."] = "สุ่มจนได้เกรดนี้หรือสูงกว่า",
        ["Reroll Interval (seconds)"] = "สุ่มทุก (วินาที)",
        ["0.25-0.40 recommended."] = "แนะนำ 0.25-0.40 วินาที",
        ["Roll to target grade."] = "สุ่มจนถึงเกรดเป้าหมาย",
        ["Reroll 1x"] = "สุ่ม 1 ครั้ง", ["Roll once for 1 Gem."] = "สุ่มหนึ่งครั้ง ใช้ 1 เจม",
        ["Trait Guide"] = "วิธีใช้เทรต",
        ["1 Trait Reroll per roll."] = "สุ่มครั้งละ 1 ไอเทม Trait Reroll หยุดเมื่อได้เป้าหรือดีกว่า",
        ["Target Trait"] = "เทรตเป้าหมาย", ["This trait or stronger."] = "หยุดเมื่อได้เทรตนี้หรือดีกว่า",
        ["Trait roll delay."] = "ระยะห่างการสุ่ม",
        ["Roll to target trait."] = "สุ่มจนได้เป้า เจอเทรตที่ล็อก หรือไอเทมหมด",
        ["Roll once for 1 item."] = "สุ่มหนึ่งครั้ง ใช้ 1 ไอเทม",
        ["Stop on this trait."] = "หยุดสุ่มเมื่อเจอเทรตนี้",
        ["Quirk Guide"] = "วิธีใช้เควิร์ก",
        ["Costs money. Podium units only."] = "สุ่มใช้เงิน หยุดเมื่อได้เป้าหรือดีกว่า มีผลเฉพาะยูนิตที่อยู่บนแท่น",
        ["Target Quirk"] = "เควิร์กเป้าหมาย", ["This quirk or stronger."] = "หยุดเมื่อได้เควิร์กนี้หรือดีกว่า",
        ["Quirk roll delay."] = "ระยะห่างการสุ่ม",
        ["Roll to target quirk."] = "สุ่มจนได้เป้า เจอเควิร์กที่ล็อก หรือเงินหมด",
        ["Roll once."] = "สุ่มหนึ่งครั้ง", ["Stop on this quirk."] = "หยุดสุ่มเมื่อเจอเควิร์กนี้",
        -- Upgrades & Dice
        ["Auto Upgrades"] = "อัปเกรดอัตโนมัติ", ["Buy when affordable."] = "ซื้ออัปเกรดหมวดที่เลือกเมื่อเงินพอ",
        ["Focus Categories"] = "หมวดที่เน้น", ["Buy these first."] = "เลือกหมวดที่จะซื้อก่อน",
        ["Only Selected"] = "เฉพาะที่เลือก", ["Skip other categories."] = "ซื้อเฉพาะหมวดที่เลือก",
        ["Buy Upgrades Now"] = "ซื้ออัปเกรดตอนนี้", ["Auto Buy Dice"] = "ซื้อลูกเต๋าอัตโนมัติ",
        ["Buy new dice."] = "ซื้อลูกเต๋าที่ยังไม่มีเมื่อเงินพอ", ["Buy Available Dice"] = "ซื้อลูกเต๋าที่ซื้อได้",
        -- Webhook
        ["Discord Notifications"] = "แจ้งเตือนดิสคอร์ด",
        ["Roll alerts and summaries."] = "ใส่ลิงก์เว็บฮุกเพื่อรับแจ้งเตือนและสรุปผล",
        ["Discord Webhook URL"] = "ลิงก์เว็บฮุก", ["Webhook link."] = "วางลิงก์เว็บฮุกที่นี่",
        ["Confirm URL"] = "ยืนยันลิงก์", ["Save the link."] = "บันทึกและตรวจลิงก์ (สะดวกบนมือถือ)",
        ["Paste Clipboard"] = "วางจากคลิปบอร์ด", ["Paste link."] = "วางลิงก์จากคลิปบอร์ด",
        ["Enable"] = "เปิดใช้", ["Send alerts."] = "ส่งแจ้งเตือนไปดิสคอร์ด",
        ["Test Webhook"] = "ทดสอบเว็บฮุก", ["Send a test."] = "ส่งข้อความทดสอบ",
        ["High Rolls"] = "ทอยได้ของดี", ["Alert on rare units."] = "แจ้งยูนิต เกรด และเทรต",
        ["Min Rarity"] = "ระดับขั้นต่ำ", ["Lowest rarity to alert."] = "ระดับต่ำสุดที่จะแจ้ง",
        ["Rebirth Alert"] = "แจ้งรีเบิร์ธ", ["Alert on rebirth."] = "แจ้งเลเวลรีเบิร์ธและโบนัส",
        ["High Grade"] = "เกรดสูง", ["Alert on grade S and up."] = "แจ้งเกรด S ขึ้นไป",
        ["Rare Trait"] = "เทรตหายาก", ["Alert on rare traits."] = "แจ้งเมื่อสุ่มได้เทรตหายาก",
        ["Auto Summary"] = "สรุปผลอัตโนมัติ", ["Timed stats."] = "ส่งสรุปเงิน รีเบิร์ธ และยูนิตตามเวลา",
        ["Summary Interval (minutes)"] = "สรุปทุก (นาที)", ["5-60 minutes."] = "ระยะห่าง 5-60 นาที",
        ["Send Summary Now"] = "ส่งสรุปตอนนี้", ["Send stats now."] = "ส่งสถิติตอนนี้ไปดิสคอร์ด",
        -- Settings
        ["Theme"] = "ธีม", ["Show / Hide Key"] = "ปุ่มเปิด/ปิด UI", ["Unload UI"] = "ปิดสคริปต์",
        ["Save and close."] = "บันทึก หยุดทุกอย่าง แล้วปิด UI",
        ["Stay connected."] = "กันโดนเตะเพราะยืนนิ่ง", ["Copy Discord Invite"] = "คัดลอกลิงก์ดิสคอร์ด",
        ["Copy invite."] = "คัดลอกลิงก์เชิญดิสคอร์ด",
        ["Vader updates, support and community.\nDiscord: https://discord.gg/sghjJ7WyWJ"] = "อัปเดต ช่วยเหลือ และพูดคุย\nDiscord: https://discord.gg/sghjJ7WyWJ",
        ["Close"] = "ปิด", ["Unload the interface? Anything it is running stops."] = "ปิดสคริปต์? ทุกอย่างที่รันอยู่จะหยุด",
        ["Unload"] = "ปิดสคริปต์", ["Cancel"] = "ยกเลิก", ["Search"] = "ค้นหา",
        -- Notifications
        ["Auto Roll enabled."] = "เปิดทอยอัตโนมัติแล้ว", ["Auto Roll disabled."] = "ปิดทอยอัตโนมัติแล้ว",
        ["Collected money from all slots."] = "เก็บเงินทุกช่องแล้ว",
        ["Auto Use Items enabled."] = "เปิดใช้ไอเทมอัตโนมัติแล้ว", ["Auto Use Items disabled."] = "ปิดใช้ไอเทมอัตโนมัติแล้ว",
        ["Item selection cleared."] = "ล้างการเลือกไอเทมแล้ว", ["Auto Tower disabled."] = "ปิดลงหอคอยอัตโนมัติแล้ว",
        ["Left the tower."] = "ออกจากหอคอยแล้ว", ["Equipped the best units."] = "ใส่ยูนิตดีสุดแล้ว",
        ["Auto Sell enabled."] = "เปิดขายอัตโนมัติแล้ว", ["Auto Sell disabled."] = "ปิดขายอัตโนมัติแล้ว",
        ["No eligible units to sell. Units may be protected."] = "ไม่มียูนิตที่ขายได้ อาจถูกกันไว้",
        ["Unit list refreshed."] = "รีเฟรชรายชื่อยูนิตแล้ว", ["Trait unit list refreshed."] = "รีเฟรชรายชื่อยูนิตแล้ว",
        ["Quirk unit list refreshed."] = "รีเฟรชรายชื่อยูนิตแล้ว",
        ["Auto Reroll enabled."] = "เปิดสุ่มอัตโนมัติแล้ว", ["Auto Reroll disabled."] = "ปิดสุ่มอัตโนมัติแล้ว",
        ["Auto Trait Reroll enabled."] = "เปิดสุ่มเทรตอัตโนมัติแล้ว", ["Auto Trait Reroll disabled."] = "ปิดสุ่มเทรตอัตโนมัติแล้ว",
        ["Auto Quirk Reroll enabled."] = "เปิดสุ่มเควิร์กอัตโนมัติแล้ว", ["Auto Quirk Reroll disabled."] = "ปิดสุ่มเควิร์กอัตโนมัติแล้ว",
        ["Auto Reroll Stopped"] = "หยุดสุ่มอัตโนมัติ", ["Auto Trait Reroll Stopped"] = "หยุดสุ่มเทรต",
        ["Auto Quirk Reroll Stopped"] = "หยุดสุ่มเควิร์ก", ["Trait Reroll"] = "สุ่มเทรต", ["Trait Reroll Stopped"] = "หยุดสุ่มเทรต",
        ["Quirk Reroll"] = "สุ่มเควิร์ก", ["Quirk Reroll Stopped"] = "หยุดสุ่มเควิร์ก",
        ["Select a unit to reroll first."] = "เลือกยูนิตก่อน", ["Reroll requested."] = "ส่งคำขอสุ่มแล้ว",
        ["Could not reroll."] = "สุ่มไม่ได้", ["Purchased available upgrades in selected categories."] = "ซื้ออัปเกรดแล้ว",
        ["Purchased affordable dice."] = "ซื้อลูกเต๋าแล้ว",
        ["Enter or paste a webhook URL first."] = "ใส่ลิงก์เว็บฮุกก่อน", ["Webhook URL saved and validated."] = "บันทึกลิงก์แล้ว",
        ["Saved. The URL does not match the usual Discord webhook format."] = "บันทึกแล้ว แต่ลิงก์ไม่เหมือนเว็บฮุกดิสคอร์ด",
        ["Webhook URL pasted from the clipboard."] = "วางลิงก์แล้ว",
        ["Could not read the clipboard. Paste directly into the input."] = "อ่านคลิปบอร์ดไม่ได้ ให้วางในช่องเอง",
        ["Discord Webhook enabled."] = "เปิดเว็บฮุกแล้ว", ["Discord Webhook disabled."] = "ปิดเว็บฮุกแล้ว",
        ["Enter a webhook URL before testing."] = "ใส่ลิงก์ก่อนทดสอบ", ["Test message sent to Discord."] = "ส่งข้อความทดสอบแล้ว",
        ["Could not send the webhook. Check the URL and network."] = "ส่งไม่ได้ ตรวจลิงก์และเน็ต",
        ["Enter a webhook URL before sending a summary."] = "ใส่ลิงก์ก่อนส่งสรุป",
        ["Statistics summary sent to Discord."] = "ส่งสรุปแล้ว", ["Could not send. Check the webhook URL."] = "ส่งไม่ได้ ตรวจลิงก์",
        ["Discord invite copied to the clipboard."] = "คัดลอกลิงก์ดิสคอร์ดแล้ว",
        ["Auto Save"] = "บันทึกอัตโนมัติ", ["Profile Load Failed"] = "โหลดโปรไฟล์ไม่สำเร็จ",
        ["Auto Save Unavailable"] = "บันทึกอัตโนมัติใช้ไม่ได้",
        ["This executor does not provide the required file APIs."] = "ตัวรันนี้ไม่รองรับการบันทึกไฟล์",
        -- Stop reasons returned by the reroll engines
        ["Select a unit first."] = "เลือกยูนิตก่อน", ["Target grade reached."] = "ได้เกรดเป้าหมายแล้ว",
        ["Target trait reached."] = "ได้เทรตเป้าหมายแล้ว", ["Target quirk reached."] = "ได้เควิร์กเป้าหมายแล้ว",
        ["No Gems remaining."] = "เจมหมด", ["No Trait Reroll items remaining."] = "ไอเทม Trait Reroll หมด",
        ["Not enough money to roll."] = "เงินไม่พอสุ่ม", ["Selected unit is no longer available."] = "ไม่พบยูนิตที่เลือก",
        ["Trait reroll requested."] = "ส่งคำขอสุ่มเทรตแล้ว", ["Quirk reroll requested."] = "ส่งคำขอสุ่มเควิร์กแล้ว",
        ["Waiting for server confirmation."] = "รอเซิร์ฟเวอร์ยืนยัน",
        ["Lock on server."] = "ล็อกบนเซิร์ฟเวอร์",
        -- Event
        ["Event"] = "อีเวนต์", ["No Event"] = "ไม่มีอีเวนต์", ["No event is running."] = "ตอนนี้ไม่มีอีเวนต์",
        ["Pumpkin Dice"] = "ลูกเต๋าฟักทอง", ["Auto Pumpkin Dice"] = "ทอยลูกเต๋าฟักทองอัตโนมัติ",
        ["Several dice per roll."] = "ทอยหลายลูกต่อครั้ง",
        ["Game sells these on roll."] = "เกมขายตัวที่เลือกทันทีที่ทอยได้",
        ["Pumpkin Dice Stopped"] = "หยุดทอยลูกเต๋าฟักทอง",
        ["Haunted House"] = "บ้านผีสิง", ["Wing"] = "โซน", ["Wing to farm."] = "โซนที่จะฟาร์ม",
        ["Auto Haunted House"] = "ฟาร์มบ้านผีสิงอัตโนมัติ", ["Farms Pumpkins and Candy."] = "ฟาร์มฟักทองและขนม",
        ["Trick or Treat"] = "ทริกออร์ทรีต", ["Auto Trick or Treat"] = "เคาะประตูอัตโนมัติ",
        ["Visits doors for Candy."] = "เดินเคาะประตูเก็บขนม", ["Go to Island"] = "ไปเกาะอีเวนต์",
        ["Event island."] = "วาร์ปไปเกาะ", ["Back to Hub"] = "กลับจุดเกิด", ["Main area."] = "วาร์ปกลับ",
        ["Rewards"] = "รางวัล", ["Auto Event Quests"] = "รับเควสอีเวนต์อัตโนมัติ", ["Hourly and daily."] = "รายชั่วโมงและรายวัน",
        ["Auto Pumpkin Pass"] = "รับ Pumpkin Pass อัตโนมัติ", ["Claims unlocked tiers."] = "รับขั้นที่ปลดล็อกแล้ว",
        ["Candy Shop"] = "ร้านขนม", ["Items to buy."] = "ของที่จะซื้อ", ["Auto Buy"] = "ซื้ออัตโนมัติ",
        ["Spends Candy on selected items."] = "ใช้ขนมซื้อของที่เลือก",
    }
    -- Labels built from data keep their variable part.
    local patterns = {
        {"^Lock Grade (.+)$", "ล็อกเกรด %1"},
        {"^(%d+) Pumpkins per roll%.$", "ใช้ %1 ฟักทองต่อครั้ง"}, {"^Roll (%d+)x$", "ทอย %1 ลูก"},
        {"^Lock Trait (.+)$", "ล็อกเทรต %1"}, {"^Lock Quirk (.+)$", "ล็อกเควิร์ก %1"},
        {"^Current grade is locked: (.+)$", "เกรดปัจจุบันถูกล็อก: %1"},
        {"^Current trait is locked: (.+)$", "เทรตปัจจุบันถูกล็อก: %1"},
        {"^Current quirk is locked: (.+)$", "เควิร์กปัจจุบันถูกล็อก: %1"},
        {"^Auto Tower enabled: (.+)$", "เปิดลงหอคอยอัตโนมัติ: %1"},
    }
    local function translate(label)
        local text = TH[label.Text]
        if not text then
            for _, p in ipairs(patterns) do
                if label.Text:match(p[1]) then text = label.Text:gsub(p[1], p[2]) break end
            end
        end
        if text and text ~= label.Text then label.Text = text end
    end
    local function hook(item)
        -- TextBox is skipped so typed input is never rewritten.
        if not (item:IsA("TextLabel") or item:IsA("TextButton")) then return end
        translate(item)
        table.insert(_conns, item:GetPropertyChangedSignal("Text"):Connect(function() translate(item) end))
    end
    for _, item in ipairs(VaderUI.GUI:GetDescendants()) do hook(item) end
    table.insert(_conns, VaderUI.GUI.DescendantAdded:Connect(hook))
end

-- Tabs
local Tabs = {
    Main     = Window:AddTab({Title = "Main"}),
    Items    = Window:AddTab({Title = "Items & Boosts"}),
    Tower    = Window:AddTab({Title = "Towers"}),
    Plot     = Window:AddTab({Title = "Plots"}),
    AutoSell = Window:AddTab({Title = "Auto Sell"}),
    Grades   = Window:AddTab({Title = "Grades"}),
    Traits   = Window:AddTab({Title = "Traits"}),
    Quirks   = Window:AddTab({Title = "Quirks"}),
    Event    = Window:AddTab({Title = "Event"}),
    Upgrades = Window:AddTab({Title = "Upgrades & Dice"}),
    Webhook  = Window:AddTab({Title = "Webhook"}),
    Settings = Window:AddTab({Title = "Settings"}),
}

local secRoll = Tabs.Main:AddSection("Rolling")

secRoll:AddToggle("TogAutoRoll", {
    Title       = "Auto Roll",
    Description = "Roll nonstop.",
    Default     = false,
    Callback    = function(v)
        State.AutoRoll = v
        VaderUI:Notify({Title = "Vader Script", Content = v and "Auto Roll enabled." or "Auto Roll disabled.", Duration = 2})
    end
})

local secProg = Tabs.Main:AddSection("Rebirth & Claims")

secProg:AddToggle("TogAutoRebirth", {
    Title       = "Auto Rebirth",
    Description = "Rebirth when affordable.",
    Default     = false,
    Callback    = function(v)
        State.AutoRebirth = v
        if v then checkAndRebirth() end
    end
})

secProg:AddToggle("TogAutoClaim", {
    Title       = "Auto Claim",
    Description = "Daily, spin and offline rewards.",
    Default     = false,
    Callback    = function(v) State.AutoClaim = v end
})

local secQuests = Tabs.Main:AddSection("Quests")
secQuests:AddToggle("TogAutoClaimQuests", {
    Title = "Auto Claim Quests",
    Description = "Daily and weekly quests.",
    Default = false,
    Callback = function(value)
        State.AutoClaimQuests = value
        if value then claimCompletedQuests() end
    end
})

local secCollect = Tabs.Main:AddSection("Collect Balance")

secCollect:AddToggle("TogAutoCollect", {
    Title       = "Auto Collect",
    Description = "Collect from all slots.",
    Default     = false,
    Callback    = function(v) State.AutoCollect = v end
})

secCollect:AddButton({
    Title       = "Collect Now",
    Description = "Collect once.",
    Callback    = function()
        collectAllSlots()
        VaderUI:Notify({Title = "Vader Script", Content = "Collected money from all slots.", Duration = 2})
    end
})


local secItems = Tabs.Items:AddSection("Auto Use Items")

secItems:AddToggle("TogAutoUseItems", {
    Title       = "Auto Use Items",
    Description = "Use selected boosts.",
    Default     = false,
    Callback    = function(v)
        State.AutoUseItems = v
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = v and "Auto Use Items enabled." or "Auto Use Items disabled.",
            Duration = 2.5
        })
    end
})

local dropSelectedItemsRef = nil
local allBoostOptions = getAllBoostNames()

dropSelectedItemsRef = secItems:AddDropdown("DropSelectedItems", {
    Title       = "Select Items",
    Description = "Items to use.",
    Values      = allBoostOptions,
    Multi       = true,
    Default     = {},
    Callback    = function(val)
        table.clear(State.SelectedItems)
        if type(val) == "table" then
            for k, v in pairs(val) do
                if v == true then
                    State.SelectedItems[k] = true
                elseif type(k) == "number" and type(v) == "string" then
                    State.SelectedItems[v] = true
                end
            end
        end
    end
})

local itemConditions = {
    "When Expired",
    "Always Use"
}

secItems:AddDropdown("DropItemCondition", {
    Title       = "Condition",
    Description = "When to use.",
    Values      = itemConditions,
    Default     = State.ItemUseCondition or "When Expired",
    Callback    = function(v)
        State.ItemUseCondition = v
    end
})

secItems:AddSlider("SlideItemInterval", {
    Title       = "Check Interval (seconds)",
    Description = "Check delay.",
    Min         = 1,
    Max         = 10,
    Default     = State.ItemUseInterval or 2.0,
    Rounding    = 1,
    Callback    = function(v)
        State.ItemUseInterval = v
    end
})

local secItemQuick = Tabs.Items:AddSection("Quick Actions")

secItemQuick:AddButton({
    Title       = "Select Owned",
    Description = "Pick all owned.",
    Callback    = function()
        local owned = {}
        pcall(function()
            local inv = DataController.Inventory and DataController.Inventory()
            if type(inv) == "table" then
                for id, it in pairs(inv) do
                    if type(it) == "table" and it.name and tonumber(it.amount) and tonumber(it.amount) > 0 then
                        local cfg = EntryRegistry.getEntryConfig(it.name)
                        if cfg and cfg.kind == "Boost" then
                            owned[it.name] = true
                        end
                    end
                end
            end
        end)
        table.clear(State.SelectedItems)
        for k, _ in pairs(owned) do
            State.SelectedItems[k] = true
        end
        if dropSelectedItemsRef and dropSelectedItemsRef.SetValue then
            pcall(function() dropSelectedItemsRef:SetValue(owned) end)
        end
        local c = 0
        for _ in pairs(owned) do c = c + 1 end
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = string.format("Selected %d owned item types.", c),
            Duration = 3
        })
    end
})

secItemQuick:AddButton({
    Title       = "Clear All",
    Description = "Clear selection.",
    Callback    = function()
        table.clear(State.SelectedItems)
        if dropSelectedItemsRef and dropSelectedItemsRef.SetValue then
            pcall(function() dropSelectedItemsRef:SetValue({}) end)
        end
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = "Item selection cleared.",
            Duration = 2
        })
    end
})

secItemQuick:AddButton({
    Title       = "Use Now",
    Description = "Use once.",
    Callback    = function()
        local count = useSelectedItemsNow()
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = count > 0 and string.format("Used %d item types.", count) or "No selected items in inventory",
            Duration = 2.5
        })
    end
})

local secTower = Tabs.Tower:AddSection("Auto Tower")

secTower:AddDropdown("DropSelectTower", {
    Title       = "Select Tower",
    Description = "Tower to farm.",
    Values      = TowerDisplayOptions,
    Default     = 1,
    Callback    = function(v)
        State.SelectedTower = TowerDisplayNameMap[v] or "Dragon Tower"
    end
})

secTower:AddToggle("TogAutoTower", {
    Title       = "Auto Tower",
    Description = "Replay after each run.",
    Default     = false,
    Callback    = function(v)
        State.AutoTower = v
        VaderUI:Notify({
            Title = "Vader Script",
            Content = v and ("Auto Tower enabled: " .. State.SelectedTower) or "Auto Tower disabled.",
            Duration = 2.5
        })
    end
})

secTower:AddToggle("TogAutoEquipTowerTeam", {
    Title       = "Equip Best Team",
    Description = "Best team first.",
    Default     = true,
    Callback    = function(v)
        State.AutoEquipBestTowerTeam = v
    end
})

secTower:AddToggle("TogHideTowerScreen", {
    Title       = "Hide Screen",
    Description = "Hide battle screen.",
    Default     = true,
    Callback    = function(v)
        State.HideTowerScreen = v
    end
})

local secTowerActions = Tabs.Tower:AddSection("Manual Controls")

secTowerActions:AddButton({
    Title       = "Play Tower Now",
    Description = "Start one run.",
    Callback    = function()
        pcall(function()
            if State.AutoEquipBestTowerTeam and EquipBestTowerTeamRE then
                EquipBestTowerTeamRE:FireServer()
                task.wait(0.3)
            end
            local towerName = State.SelectedTower or "Dragon Tower"
            if TowerController and TowerController.startTower then
                TowerController.startTower(towerName)
            elseif PlayTowerRF then
                PlayTowerRF:InvokeServer(towerName)
            end
            VaderUI:Notify({Title = "Vader Script", Content = "Started " .. towerName .. ".", Duration = 2})
        end)
    end
})

secTowerActions:AddButton({
    Title       = "Exit Tower",
    Description = "Leave now.",
    Callback    = function()
        pcall(function()
            if CancelTowerRF then
                CancelTowerRF:InvokeServer()
            end
            VaderUI:Notify({Title = "Vader Script", Content = "Left the tower.", Duration = 2})
        end)
    end
})

local secUnits = Tabs.Plot:AddSection("Anime Units")

secUnits:AddToggle("TogAutoEquip", {
    Title       = "Auto Equip Best",
    Description = "Keep best units on slots.",
    Default     = false,
    Callback    = function(v) State.AutoEquipBest = v end
})

secUnits:AddSlider("SlideEquipInterval", {
    Title    = "Equip Interval (seconds)",
    Description = "Equip delay.",
    Min      = 1,
    Max      = 30,
    Default  = State.EquipInterval,
    Rounding = 0,
    Callback = function(v)
        State.EquipInterval = v
    end
})

secUnits:AddButton({
    Title       = "Equip Best Now",
    Callback    = function()
        equipBestUnits()
        VaderUI:Notify({Title = "Vader Script", Content = "Equipped the best units.", Duration = 2})
    end
})

local secSlots = Tabs.Plot:AddSection("Level Up Units")

secSlots:AddToggle("TogAutoLevelSlots", {
    Title       = "Auto Level Up",
    Description = "Level slotted units.",
    Default     = false,
    Callback    = function(v) State.AutoLevelSlots = v end
})

local levelPresetOptions = {
    "Level 20",
    "Level 30",
    "Level 40",
    "Level 50",
    "Level 60",
    "Level 70",
    "Level 80",
    "Level 90",
    "Level 100",
    "MAX",
}

local slideLevelRef = nil

local dropTargetLvl = secSlots:AddDropdown("DropTargetLevel", {
    Title       = "Preset Level",
    Description = "Target level.",
    Values      = levelPresetOptions,
    Default     = "Level 30",
    Callback    = function(val)
        if val == "MAX" then
            State.TargetUnitLevel = 999999
        else
            local num = tonumber(string.match(val or "", "%d+"))
            if num then
                State.TargetUnitLevel = num
                if slideLevelRef and slideLevelRef.SetValue then
                    pcall(function() slideLevelRef:SetValue(num) end)
                end
            end
        end
    end
})

slideLevelRef = secSlots:AddSlider("SlideTargetUnitLevel", {
    Title       = "Level Limit (10 - 150)",
    Description = "Max level.",
    Min         = 10,
    Max         = 150,
    Default     = 30,
    Rounding    = 0,
    Callback    = function(v)
        State.TargetUnitLevel = v
    end
})

secSlots:AddButton({
    Title       = "Level Up Now",
    Description = "Level once.",
    Callback    = function()
        levelUpAllSlots()
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = "Upgraded eligible units toward level " .. tostring(State.TargetUnitLevel) .. ".",
            Duration = 2.5
        })
    end
})

local secSell = Tabs.AutoSell:AddSection("Inventory Sell")

secSell:AddToggle("TogAutoSellUnits", {
    Title       = "Auto Sell",
    Description = "Sell selected rarities.",
    Default     = false,
    Callback    = function(v)
        State.AutoSellUnits = v
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = v and "Auto Sell enabled." or "Auto Sell disabled.",
            Duration = 2.5
        })
    end
})

secSell:AddSlider("SlideSellInterval", {
    Title       = "Sell Interval (seconds)",
    Description = "Sell delay.",
    Min         = 1,
    Max         = 30,
    Default     = State.SellInterval,
    Rounding    = 0,
    Callback    = function(v)
        State.SellInterval = v
    end
})

local sellRarityOptions = {
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythical",
    "Divine",
    "Exotic",
    "Celestial",
    "Secret I",
    "Secret II",
    "Heavenly",
    "Exclusive"
}

local defaultSellRarities = {
    "Common",
    "Uncommon",
    "Rare"
}

secSell:AddDropdown("DropSellRarities", {
    Title       = "Rarities",
    Description = "Rarities to sell.",
    Values      = sellRarityOptions,
    Multi       = true,
    Default     = defaultSellRarities,
    Callback    = function(val)
        table.clear(State.SelectedSellRarities)
        if type(val) == "table" then
            for k, v in pairs(val) do
                if v == true then
                    State.SelectedSellRarities[k] = true
                elseif type(k) == "number" and type(v) == "string" then
                    State.SelectedSellRarities[v] = true
                end
            end
        end
    end
})

local secSellSafety = Tabs.AutoSell:AddSection("Safety Lock")

secSellSafety:AddToggle("TogProtectPlot", {
    Title       = "Protect Equipped",
    Description = "Skip plot and tower units.",
    Default     = true,
    Callback    = function(v) State.ProtectPlottedUnits = v end
})

secSellSafety:AddToggle("TogProtectGradeS", {
    Title       = "Protect Grade S and Above",
    Description = "Skip grade S and up.",
    Default     = true,
    Callback    = function(v) State.ProtectGradeSPlus = v end
})

secSellSafety:AddToggle("TogProtectTraits",{Title="Protect Rare Traits",
    Description="Skip rare or locked traits.",
    Default=true,Callback=function(value) State.ProtectRareTraits=value end})

secSellSafety:AddToggle("TogProtectLocked", {
    Title       = "Protect Locked",
    Description = "Skip locked units.",
    Default     = true,
    Callback    = function(v) State.ProtectLockedUnits = v end
})

local secSellManual = Tabs.AutoSell:AddSection("Manual Actions")

secSellManual:AddButton({
    Title       = "Sell Now",
    Description = "Sell up to 50 now.",
    Callback    = function()
        local count, earned = sellSelectedUnits()
        if count > 0 then
            VaderUI:Notify({
                Title   = "Vader Script",
                Content = string.format("Sold %d units for $%s.", count, NumberFormatter.FormatCompact(earned)),
                Duration = 3.5
            })
        else
            VaderUI:Notify({
                Title   = "Vader Script",
                Content = "No eligible units to sell. Units may be protected.",
                Duration = 2.5
            })
        end
    end
})

local function getInventoryUnitOptions(attribute)
    attribute = attribute or "grade"
    local opts = {}
    local map = {}
    pcall(function()
        local inv = DataController.Inventory and DataController.Inventory()
        if not inv then return end
        for id, item in pairs(inv) do
            if type(item) == "table" and item.name then
                local cfg = EntryRegistry.getEntryConfig(item.name)
                if cfg and cfg.kind == "Unit" then
                    local grade = (item.attributes and item.attributes[attribute]) or (attribute == "grade" and "D" or "None")
                    local lvl = (item.attributes and item.attributes.level) or 1
                    local label = string.format("%s [Lv.%s | %s] (ID: %s...)", item.name, tostring(lvl), grade, string.sub(id, 1, 8))
                    table.insert(opts, label)
                    map[label] = id
                end
            end
        end
    end)
    table.sort(opts)
    if #opts == 0 then
        table.insert(opts, "No units in inventory")
    end
    return opts, map
end

local unitLabels, unitIdMap = getInventoryUnitOptions()
if unitLabels[1] and unitIdMap[unitLabels[1]] then
    State.TargetGradeUnitKey = unitIdMap[unitLabels[1]]
end

local secGrade = Tabs.Grades:AddSection("Auto Reroll")

secGrade:AddParagraph({
    Title   = "Grade Guide",
    Content = "1 Gem per roll."
})

local dropSelectUnitRef = nil

dropSelectUnitRef = secGrade:AddDropdown("DropGradeUnit", {
    Title       = "Select Unit",
    Description = "Unit to reroll.",
    Values      = unitLabels,
    Default     = unitLabels[1] or "",
    Callback    = function(val)
        local uId = unitIdMap[val]
        if uId then
            State.TargetGradeUnitKey = uId
        end
    end
})

secGrade:AddButton({
    Title       = "Refresh Units",
    Description = "Reload units.",
    Callback    = function()
        local newOpts, newMap = getInventoryUnitOptions()
        unitLabels = newOpts
        unitIdMap = newMap
        if dropSelectUnitRef and dropSelectUnitRef.SetValues then
            dropSelectUnitRef:SetValues(newOpts)
            local selectedLabel = nil
            for label, unitKey in pairs(newMap) do
                if unitKey == State.TargetGradeUnitKey then selectedLabel = label; break end
            end
            dropSelectUnitRef:SetValue(selectedLabel)
            if not selectedLabel then
                State.TargetGradeUnitKey = ""
                local toggle = VaderUI.Options.TogAutoRerollGrade
                if toggle then toggle:SetValue(false) end
            end
        end
        VaderUI:Notify({Title = "Vader Script", Content = "Unit list refreshed.", Duration = 2})
    end
})

local gradeTargetOptions = {
    "A",
    "A+",
    "S",
    "S+",
    "Z",
    "Z+",
    "God",
    "Infinity"
}

secGrade:AddDropdown("DropTargetGrade", {
    Title       = "Target Grade",
    Description = "This grade or higher.",
    Values      = gradeTargetOptions,
    Default     = "S",
    Callback    = function(v)
        local cleanGrade = ({God = "神", Infinity = "∞"})[v] or (string.match(v, "^[^%s]+") or v)
        State.TargetGrade = cleanGrade
    end
})

secGrade:AddSlider("SlideGradeDelay", {
    Title       = "Reroll Interval (seconds)",
    Description = "0.25-0.40 recommended.",
    Min         = 0.15,
    Max         = 1.0,
    Default     = State.GradeRollDelay,
    Rounding    = 2,
    Callback    = function(v)
        State.GradeRollDelay = v
    end
})

secGrade:AddToggle("TogAutoRerollGrade", {
    Title       = "Auto Reroll",
    Description = "Roll to target grade.",
    Default     = false,
    Callback    = function(v)
        State.AutoRerollGrade = v
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = v and "Auto Reroll enabled." or "Auto Reroll disabled.",
            Duration = 2
        })
    end
})

local secGradeManual = Tabs.Grades:AddSection("Manual Reroll")

secGradeManual:AddButton({
    Title       = "Reroll 1x",
    Description = "Roll once for 1 Gem.",
    Callback    = function()
        if not State.TargetGradeUnitKey or State.TargetGradeUnitKey == "" then
            VaderUI:Notify({Title = "Vader Script", Content = "Select a unit to reroll first.", Duration = 2.5})
            return
        end
        local ok, reason = rollGradeForSelectedUnit()
        if ok then
            VaderUI:Notify({Title = "Vader Script", Content = reason or "Reroll requested.", Duration = 2})
        else
            VaderUI:Notify({Title = "Vader Script", Content = reason or "Could not reroll.", Duration = 2.5})
        end
    end
})

local secGradeServerProtect = Tabs.Grades:AddSection("Server Lock")

local serverProtectList = {"S", "S+", "Z", "Z+", "神", "∞"}
for _, g in ipairs(serverProtectList) do
    local getter = DataController.ProtectedGrades and DataController.ProtectedGrades[g]
    State.ProtectedGrades[g] = getter and getter() == true or false
    secGradeServerProtect:AddToggle("TogServerProt_" .. g, {
        Title       = "Lock Grade " .. (({["神"] = "God", ["∞"] = "Infinity"})[g] or g),
        Description = "Lock on server.",
        Default     = State.ProtectedGrades[g],
        Callback    = function(val)
            State.ProtectedGrades[g] = val
            pcall(function()
                if SetGradeProtectedRE then
                    SetGradeProtectedRE:FireServer(g, val)
                end
            end)
        end
    })
end

-- Traits UI mirrors Grade controls, using the game's live trait definitions.
local traitLabels, traitUnitIdMap = getInventoryUnitOptions("trait")
if traitLabels[1] and traitUnitIdMap[traitLabels[1]] then
    State.TargetTraitUnitKey = traitUnitIdMap[traitLabels[1]]
end
local traitTargetOptions = {}
for name in pairs(TraitsModule) do table.insert(traitTargetOptions, name) end
table.sort(traitTargetOptions, function(a,b) return TraitsModule[a].order < TraitsModule[b].order end)

local secTrait = Tabs.Traits:AddSection("Auto Reroll")
secTrait:AddParagraph({Title="Trait Guide",
    Content="1 Trait Reroll per roll."})
local dropTraitUnitRef = secTrait:AddDropdown("DropTraitUnit", {
    Title="Select Unit", Description="Unit to reroll.",
    Values=traitLabels, Default=traitLabels[1],
    Callback=function(label)
        State.TargetTraitUnitKey = traitUnitIdMap[label] or ""
    end
})
secTrait:AddButton({Title="Refresh Units",Description="Reload trait units.",
    Callback=function()
        traitLabels, traitUnitIdMap = getInventoryUnitOptions("trait")
        dropTraitUnitRef:SetValues(traitLabels)
        local selected = nil
        for label,key in pairs(traitUnitIdMap) do
            if key == State.TargetTraitUnitKey then selected=label;break end
        end
        dropTraitUnitRef:SetValue(selected)
        if not selected then
            State.TargetTraitUnitKey=""
            local toggle=VaderUI.Options.TogAutoRerollTrait
            if toggle then toggle:SetValue(false) end
        end
        VaderUI:Notify({Title="Vader Script",Content="Trait unit list refreshed.",Duration=2})
    end})
secTrait:AddDropdown("DropTargetTrait",{Title="Target Trait",
    Description="This trait or stronger.",
    Values=traitTargetOptions,Default=State.TargetTrait,
    Callback=function(value) if TraitsModule[value] then State.TargetTrait=value end end})
secTrait:AddSlider("SlideTraitDelay",{Title="Reroll Interval (seconds)",
    Description="Trait roll delay.",Min=0.15,Max=1,Default=State.TraitRollDelay,Rounding=2,
    Callback=function(value) State.TraitRollDelay=value end})
secTrait:AddToggle("TogAutoRerollTrait",{Title="Auto Reroll",
    Description="Roll to target trait.",Default=false,
    Callback=function(value)
        State.AutoRerollTrait=value
        VaderUI:Notify({Title="Vader Script",Content=value and "Auto Trait Reroll enabled." or "Auto Trait Reroll disabled.",Duration=2})
    end})
local secTraitManual=Tabs.Traits:AddSection("Manual Reroll")
secTraitManual:AddButton({Title="Reroll 1x",Description="Roll once for 1 item.",
    Callback=function()
        local ok,reason=rollTraitForSelectedUnit()
        VaderUI:Notify({Title=ok and "Trait Reroll" or "Trait Reroll Stopped",Content=reason,Duration=3})
    end})
local secTraitLocks=Tabs.Traits:AddSection("Server Lock")
for _, name in ipairs(traitTargetOptions) do
    local config=TraitsModule[name]
    if config.weight < 100 then
        local getter=DataController.ProtectedTraits and DataController.ProtectedTraits[name]
        local locked=getter and getter() == true or false
        State.ProtectedTraits[name]=locked
        secTraitLocks:AddToggle("TogTraitProt_"..name,{Title="Lock Trait "..name,
            Description="Stop on this trait.",Default=locked,
            Callback=function(value)
                State.ProtectedTraits[name]=value
                local currentGetter=DataController.ProtectedTraits and DataController.ProtectedTraits[name]
                if SetTraitProtectedRE and (not currentGetter or currentGetter() ~= value) then
                    SetTraitProtectedRE:FireServer(name,value)
                end
            end})
    end
end

-- Quirks UI mirrors Traits, using the game's live quirk definitions.
do
    Quirk.labels, Quirk.unitIdMap = getInventoryUnitOptions("quirk")
    if Quirk.unitIdMap[Quirk.labels[1]] then
        State.TargetQuirkUnitKey = Quirk.unitIdMap[Quirk.labels[1]]
    end
    Quirk.targetOptions = {}
    for name in pairs(Quirk.Defs) do table.insert(Quirk.targetOptions, name) end
    table.sort(Quirk.targetOptions, function(a,b) return Quirk.Defs[a].order < Quirk.Defs[b].order end)

    local secQuirk = Tabs.Quirks:AddSection("Auto Reroll")
    secQuirk:AddParagraph({Title="Quirk Guide",
        Content="Costs money. Podium units only."})
    local dropQuirkUnitRef = secQuirk:AddDropdown("DropQuirkUnit", {
        Title="Select Unit", Description="Unit to reroll.",
        Values=Quirk.labels, Default=Quirk.labels[1],
        Callback=function(label)
            State.TargetQuirkUnitKey = Quirk.unitIdMap[label] or ""
        end
    })
    secQuirk:AddButton({Title="Refresh Units",Description="Reload quirk units.",
        Callback=function()
            Quirk.labels, Quirk.unitIdMap = getInventoryUnitOptions("quirk")
            dropQuirkUnitRef:SetValues(Quirk.labels)
            local selected = nil
            for label,key in pairs(Quirk.unitIdMap) do
                if key == State.TargetQuirkUnitKey then selected=label;break end
            end
            dropQuirkUnitRef:SetValue(selected)
            if not selected then
                State.TargetQuirkUnitKey=""
                local toggle=VaderUI.Options.TogAutoRerollQuirk
                if toggle then toggle:SetValue(false) end
            end
            VaderUI:Notify({Title="Vader Script",Content="Quirk unit list refreshed.",Duration=2})
        end})
    secQuirk:AddDropdown("DropTargetQuirk",{Title="Target Quirk",
        Description="This quirk or stronger.",
        Values=Quirk.targetOptions,Default=State.TargetQuirk,
        Callback=function(value) if Quirk.Defs[value] then State.TargetQuirk=value end end})
    secQuirk:AddSlider("SlideQuirkDelay",{Title="Reroll Interval (seconds)",
        Description="Quirk roll delay.",Min=0.15,Max=1,Default=State.QuirkRollDelay,Rounding=2,
        Callback=function(value) State.QuirkRollDelay=value end})
    secQuirk:AddToggle("TogAutoRerollQuirk",{Title="Auto Reroll",
        Description="Roll to target quirk.",Default=false,
        Callback=function(value)
            State.AutoRerollQuirk=value
            VaderUI:Notify({Title="Vader Script",Content=value and "Auto Quirk Reroll enabled." or "Auto Quirk Reroll disabled.",Duration=2})
        end})
    local secQuirkManual=Tabs.Quirks:AddSection("Manual Reroll")
    secQuirkManual:AddButton({Title="Reroll 1x",Description="Roll once.",
        Callback=function()
            local ok,reason=Quirk.roll()
            VaderUI:Notify({Title=ok and "Quirk Reroll" or "Quirk Reroll Stopped",Content=reason,Duration=3})
        end})
    local secQuirkLocks=Tabs.Quirks:AddSection("Server Lock")
    for _, name in ipairs(Quirk.targetOptions) do
        if Quirk.Defs[name].weight < 100 then
            local getter=DataController.ProtectedQuirks and DataController.ProtectedQuirks[name]
            local locked=getter and getter() == true or false
            State.ProtectedQuirks[name]=locked
            secQuirkLocks:AddToggle("TogQuirkProt_"..name,{Title="Lock Quirk "..name,
                Description="Stop on this quirk.",Default=locked,
                Callback=function(value)
                    State.ProtectedQuirks[name]=value
                    local currentGetter=DataController.ProtectedQuirks and DataController.ProtectedQuirks[name]
                    if Quirk.SetProtectedRE and (not currentGetter or currentGetter() ~= value) then
                        Quirk.SetProtectedRE:FireServer(name,value)
                    end
                end})
        end
    end
end

-- Halloween event: uses the game's own event modules, so values follow future balance changes.
do
    local H = RS.Framework.Features:FindFirstChild("Halloween")
    local function find(...)
        local cur = network
        for _, name in ipairs({...}) do cur = cur and cur:FindFirstChild(name) end
        return cur
    end
    local function req(name)
        local ok, m = pcall(function() return require(H[name]) end)
        return ok and m or nil
    end
    local Ev = {
        RollRF = find("PumpkinDiceService", "RF", "Roll"),
        AutoSellRE = find("PumpkinDiceService", "RE", "SetAutoSell"),
        QuestRE = find("HalloweenQuestService", "RE", "Claim"),
        PassRE = find("HalloweenService", "RE", "ClaimAllPath"),
        BuyRE = find("HalloweenService", "RE", "BuyOffer"),
        TeleportRF = find("HalloweenService", "RF", "Teleport"),
        KnockedRE = find("TrickOrTreatService", "RE", "Knocked"),
        Dice = H and req("PumpkinDice"), Quests = H and req("HalloweenQuests"),
        Shop = H and req("HalloweenShop"), House = H and req("HauntedHouse"),
    }
    local function amount(item)
        local getter = DataController.Inventory and DataController.Inventory[item]
        local data = getter and getter()
        return data and tonumber(data.amount) or 0
    end
    local function stopToggle(id, title, message)
        local toggle = VaderUI.Options[id]
        if toggle then toggle:SetValue(false) end
        VaderUI:Notify({Title=title, Content=message, Duration=3})
    end

    if not H then
        Tabs.Event:AddSection("Event"):AddParagraph({Title="No Event", Content="No event is running."})
    end

    -- Pumpkin Dice: the server allows one roll per 2s and costs Pumpkins.
    if Ev.RollRF and Ev.Dice then
        local sec = Tabs.Event:AddSection("Pumpkin Dice")
        sec:AddToggle("TogEventPumpkin", {Title="Auto Pumpkin Dice", Description=Ev.Dice.COST .. " Pumpkins per roll.",
            Default=false, Callback=function(v) State.EventPumpkinRoll = v end})
        sec:AddToggle("TogEventPumpkinMulti", {Title="Roll " .. Ev.Dice.MULTI .. "x", Description="Several dice per roll.",
            Default=false, Callback=function(v) State.EventPumpkinMulti = v end})
        if Ev.AutoSellRE then
            local names, sold = {}, {}
            for _, unit in ipairs(Ev.Dice.Units) do
                table.insert(names, unit.id)
                local getter = DataController.Halloween and DataController.Halloween.DiceAutoSell
                    and DataController.Halloween.DiceAutoSell[unit.id]
                sold[unit.id] = getter and getter() == true or nil
            end
            sec:AddDropdown("DropEventAutoSell", {Title="Auto Sell", Description="Game sells these on roll.",
                Values=names, Multi=true, Default=sold,
                Callback=function(selected)
                    task.spawn(function()
                        for _, name in ipairs(names) do
                            local want = selected[name] == true
                            if (sold[name] == true) ~= want then
                                sold[name] = want or nil
                                Ev.AutoSellRE:FireServer(name, want)
                                task.wait(0.25) -- server debounce is 0.2s
                            end
                        end
                    end)
                end})
        end
        task.spawn(function()
            while isCurrentRun() do
                task.wait(2.6)
                if State.EventPumpkinRoll then
                    local count = State.EventPumpkinMulti and Ev.Dice.MULTI or 1
                    if amount("Pumpkins") >= Ev.Dice.COST * count then
                        local ok, res = pcall(function() return Ev.RollRF:InvokeServer(count) end)
                        if ok and type(res) == "table" and res.ok == false and res.message then
                            State.EventPumpkinRoll = false
                            stopToggle("TogEventPumpkin", "Pumpkin Dice Stopped", res.message)
                        end
                    end
                end
            end
        end)
    end

    -- Haunted House wings are towers, so this drives the existing Auto Tower controls.
    if Ev.House then
        local sec = Tabs.Event:AddSection("Haunted House")
        local wings = {}
        for _, wing in ipairs(Ev.House.Wings) do table.insert(wings, wing.name) end
        sec:AddDropdown("DropEventWing", {Title="Wing", Description="Wing to farm.", Values=wings,
            Default=State.EventHouseWing, Callback=function(v) State.EventHouseWing = v end})
        sec:AddToggle("TogEventHouse", {Title="Auto Haunted House", Description="Farms Pumpkins and Candy.", Default=false,
            Callback=function(v)
                local opt = VaderUI.Options
                if v and opt.DropSelectTower then opt.DropSelectTower:SetValue(State.EventHouseWing) end
                if opt.TogAutoTower then opt.TogAutoTower:SetValue(v) end
            end})
    end

    -- Trick or Treat: the server counts a knock only while standing near a door,
    -- with a 30s cooldown per door and no faster than 60 studs/s between doors.
    if Ev.KnockedRE then
        local CollectionService = game:GetService("CollectionService")
        local sec = Tabs.Event:AddSection("Trick or Treat")
        sec:AddToggle("TogEventTreat", {Title="Auto Trick or Treat", Description="Visits doors for Candy.", Default=false,
            Callback=function(v) State.EventTrickOrTreat = v end})
        if Ev.TeleportRF then
            sec:AddButton({Title="Go to Island", Description="Event island.",
                Callback=function() pcall(function() Ev.TeleportRF:InvokeServer("Island") end) end})
            sec:AddButton({Title="Back to Hub", Description="Main area.",
                Callback=function() pcall(function() Ev.TeleportRF:InvokeServer("Hub") end) end})
        end
        local knocked = false
        table.insert(_conns, Ev.KnockedRE.OnClientEvent:Connect(function() knocked = true end))
        task.spawn(function()
            local readyAt, lastKnock, lastPos = {}, 0, nil
            while isCurrentRun() do
                task.wait(0.5)
                local character = LP.Character
                if State.EventTrickOrTreat and character and character:FindFirstChild("HumanoidRootPart")
                    and workspace:GetServerTimeNow() >= (LP:GetAttribute("TrickOrTreatReadyAt") or 0) then
                    local doors = CollectionService:GetTagged("TrickOrTreatDoor")
                    if #doors == 0 and Ev.TeleportRF then
                        pcall(function() Ev.TeleportRF:InvokeServer("Island") end)
                        task.wait(2)
                    end
                    for _, door in ipairs(doors) do
                        if not (State.EventTrickOrTreat and isCurrentRun()) then break end
                        if door:IsA("BasePart") and os.clock() >= (readyAt[door] or 0) then
                            character = LP.Character
                            if not (character and character:FindFirstChild("HumanoidRootPart")) then break end
                            -- Arrive at once and stand until the server's travel gap passes; it knocks as soon as it does.
                            local gap = lastPos and math.max(2, (door.Position - lastPos).Magnitude / 60) - (os.clock() - lastKnock) or 0
                            local front = door:GetAttribute("TrickOrTreatFront") or door.CFrame.LookVector
                            knocked = false
                            character:PivotTo(CFrame.new(door.Position + front * 5, door.Position))
                            local arrived = os.clock()
                            while not knocked and os.clock() - arrived < math.max(gap, 0) + 0.8 do task.wait(0.05) end
                            if knocked then
                                -- The candy is granted server-side, so there is no need to stay for the animation.
                                lastKnock, lastPos = os.clock(), door.Position
                                readyAt[door] = os.clock() + 31
                            else
                                readyAt[door] = os.clock() + 10
                            end
                        end
                    end
                end
            end
        end)
    end

    -- Claims: quests, Pumpkin Pass, and the Candy Shop.
    local sec = H and Tabs.Event:AddSection("Rewards")
    if sec and Ev.QuestRE and Ev.Quests then
        sec:AddToggle("TogEventQuests", {Title="Auto Event Quests", Description="Hourly and daily.", Default=false,
            Callback=function(v) State.EventQuests = v end})
        task.spawn(function()
            while isCurrentRun() do
                task.wait(2)
                if State.EventQuests and DataController.Halloween then
                    for _, period in ipairs(Ev.Quests.PERIODS) do
                        pcall(function()
                            local config = Ev.Quests[period]
                            local data = DataController.Halloween[config.dataKey]()
                            if type(data) ~= "table" then return end
                            local progress, claimed = data.progress or {}, data.claimed or {}
                            for _, quest in ipairs(config.pool) do
                                if table.find(data.ids or {}, quest.id) and not claimed[quest.id]
                                    and (progress[quest.id] or 0) >= quest.target then
                                    Ev.QuestRE:FireServer(period, quest.id)
                                    task.wait(0.3)
                                end
                            end
                        end)
                    end
                end
            end
        end)
    end
    if sec and Ev.PassRE then
        sec:AddToggle("TogEventPass", {Title="Auto Pumpkin Pass", Description="Claims unlocked tiers.", Default=false,
            Callback=function(v) State.EventPass = v end})
        task.spawn(function()
            while isCurrentRun() do
                -- The server skips tiers that are locked or already claimed.
                if State.EventPass then pcall(function() Ev.PassRE:FireServer() end) end
                task.wait(30)
            end
        end)
    end
    if sec and Ev.BuyRE and Ev.Shop then
        local labels, indexOf = {}, {}
        for i, offer in ipairs(Ev.Shop) do
            local label = offer.name .. " (" .. offer.candy .. ")"
            table.insert(labels, label)
            indexOf[label] = i
        end
        sec:AddDropdown("DropEventShop", {Title="Candy Shop", Description="Items to buy.", Values=labels, Multi=true,
            Default=State.EventShopItems, Callback=function(v) State.EventShopItems = v end})
        sec:AddToggle("TogEventShop", {Title="Auto Buy", Description="Spends Candy on selected items.", Default=false,
            Callback=function(v) State.EventShopAuto = v end})
        task.spawn(function()
            while isCurrentRun() do
                task.wait(3)
                if State.EventShopAuto then
                    local candy = amount("Candy")
                    for label, selected in pairs(State.EventShopItems) do
                        local index = indexOf[label]
                        if selected and index and candy >= Ev.Shop[index].candy then
                            candy = candy - Ev.Shop[index].candy
                            Ev.BuyRE:FireServer(index)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end)
    end
end

local secUpgrades = Tabs.Upgrades:AddSection("Upgrades")

secUpgrades:AddToggle("TogAutoUpgrades", {
    Title       = "Auto Upgrades",
    Description = "Buy when affordable.",
    Default     = false,
    Callback    = function(v) State.AutoUpgrades = v end
})

local upgradeOptions = {
    "Luck & Fortune",
    "Roll Speed",
    "Money",
    "Unit Storage",
    "Damage",
    "Health",
    "Walkspeed",
    "Sell"
}

local defaultSelections = {
    "Luck & Fortune",
    "Roll Speed",
    "Money"
}

local dropUpgradeFocus = secUpgrades:AddDropdown("DropUpgradeFocus", {
    Title       = "Focus Categories",
    Description = "Buy these first.",
    Values      = upgradeOptions,
    Multi       = true,
    Default     = defaultSelections,
    Callback    = function(val)
        table.clear(State.SelectedUpgradeCategories)
        if type(val) == "table" then
            for k, v in pairs(val) do
                if v == true then
                    State.SelectedUpgradeCategories[k] = true
                elseif type(k) == "number" and type(v) == "string" then
                    State.SelectedUpgradeCategories[v] = true
                end
            end
        end
    end
})

secUpgrades:AddToggle("TogOnlySelected", {
    Title       = "Only Selected",
    Description = "Skip other categories.",
    Default     = false,
    Callback    = function(v) State.OnlySelectedUpgrades = v end
})

secUpgrades:AddButton({
    Title       = "Buy Upgrades Now",
    Callback    = function()
        buyPrioritizedUpgrades()
        VaderUI:Notify({Title = "Vader Script", Content = "Purchased available upgrades in selected categories.", Duration = 2})
    end
})

local secDice = Tabs.Upgrades:AddSection("Dice Shop")

secDice:AddToggle("TogAutoBuyDice", {
    Title       = "Auto Buy Dice",
    Description = "Buy new dice.",
    Default     = false,
    Callback    = function(v) State.AutoBuyDice = v end
})

secDice:AddButton({
    Title       = "Buy Available Dice",
    Callback    = function()
        buyAffordableDice()
        VaderUI:Notify({Title = "Vader Script", Content = "Purchased affordable dice.", Duration = 2})
    end
})

local secWebhook = Tabs.Webhook:AddSection("Discord Webhook Settings")

secWebhook:AddParagraph({
    Title   = "Discord Notifications",
    Content = "Roll alerts and summaries."
})

local inputWebhookRef = nil

inputWebhookRef = secWebhook:AddInput("InputWebhookUrl", {
    Title       = "Discord Webhook URL",
    Description = "Webhook link.",
    Default     = State.WebhookURL,
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric     = false,
    Finished    = false,
    Callback    = function(val)
        State.WebhookURL = string.gsub(val or "", "%s+", "")
    end
})

secWebhook:AddButton({
    Title       = "Confirm URL",
    Description = "Save the link.",
    Callback    = function()
        local currentVal = (inputWebhookRef and inputWebhookRef.Value) or (VaderUI.Options and VaderUI.Options.InputWebhookUrl and VaderUI.Options.InputWebhookUrl.Value) or State.WebhookURL
        local clean = string.gsub(currentVal or "", "%s+", "")
        if clean == "" then
            VaderUI:Notify({Title = "Vader Script", Content = "Enter or paste a webhook URL first.", Duration = 3})
            return
        end
        State.WebhookURL = clean
        if clean:find("discord.com/api/webhooks") or clean:find("discordapp.com/api/webhooks") then
            VaderUI:Notify({
                Title   = "Vader Script",
                Content = "Webhook URL saved and validated.",
                Duration = 3.5
            })
        else
            VaderUI:Notify({
                Title   = "Vader Script",
                Content = "Saved. The URL does not match the usual Discord webhook format.",
                Duration = 4
            })
        end
    end
})

secWebhook:AddButton({
    Title       = "Paste Clipboard",
    Description = "Paste link.",
    Callback    = function()
        local pasteFn = getclipboard or (Clipboard and Clipboard.get)
        if pasteFn then
            local ok, clip = pcall(pasteFn)
            if ok and clip and type(clip) == "string" and #clip > 0 then
                local clean = string.gsub(clip, "%s+", "")
                State.WebhookURL = clean
                if inputWebhookRef and inputWebhookRef.SetValue then
                    pcall(function() inputWebhookRef:SetValue(clean) end)
                end
                VaderUI:Notify({
                    Title   = "Vader Script",
                    Content = "Webhook URL pasted from the clipboard.",
                    Duration = 3
                })
                return
            end
        end
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = "Could not read the clipboard. Paste directly into the input.",
            Duration = 3
        })
    end
})

secWebhook:AddToggle("TogWebhookEnabled", {
    Title       = "Enable",
    Description = "Send alerts.",
    Default     = false,
    Callback    = function(v)
        State.WebhookEnabled = v
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = v and "Discord Webhook enabled." or "Discord Webhook disabled.",
            Duration = 2.5
        })
    end
})

secWebhook:AddButton({
    Title       = "Test Webhook",
    Description = "Send a test.",
    Callback    = function()
        if not State.WebhookURL or State.WebhookURL == "" then
            VaderUI:Notify({Title = "Vader Script", Content = "Enter a webhook URL before testing.", Duration = 2.5})
            return
        end
        local ok = sendDiscordWebhook(
            "Webhook connection test successful!",
            "**Vader Script - Anime Dice** notifications are connected to your Discord.",
            0x00FF88,
            {
                {name = "Player", value = LP.DisplayName .. " (@" .. LP.Name .. ")", inline = true},
                {name = "Status", value = "Ready", inline = true},
                {name = "Time", value = os.date("%H:%M:%S - %d/%m/%Y"), inline = true}
            }
        )
        VaderUI:Notify({
            Title   = "Vader Script",
            Content = ok and "Test message sent to Discord." or "Could not send the webhook. Check the URL and network.",
            Duration = 3.5
        })
    end
})

local secWebhookEvents = Tabs.Webhook:AddSection("Event Alerts")

secWebhookEvents:AddToggle("TogNotifRolls", {
    Title       = "High Rolls",
    Description = "Alert on rare units.",
    Default     = true,
    Callback    = function(v) State.WebhookNotifyRolls = v end
})

local webhookRarityOptions = table.clone(sellRarityOptions)

secWebhookEvents:AddDropdown("DropMinRarity", {
    Title       = "Min Rarity",
    Description = "Lowest rarity to alert.",
    Values      = webhookRarityOptions,
    Default     = "Mythical",
    Callback    = function(v) State.WebhookMinRarity = v end
})

secWebhookEvents:AddToggle("TogNotifRebirth", {
    Title       = "Rebirth Alert",
    Description = "Alert on rebirth.",
    Default     = true,
    Callback    = function(v) State.WebhookNotifyRebirth = v end
})

secWebhookEvents:AddToggle("TogNotifGrade", {
    Title       = "High Grade",
    Description = "Alert on grade S and up.",
    Default     = true,
    Callback    = function(v) State.WebhookNotifyGrade = v end
})

secWebhookEvents:AddToggle("TogNotifTrait",{Title="Rare Trait",
    Description="Alert on rare traits.",Default=true,
    Callback=function(value) State.WebhookNotifyTrait=value end})

local secWebhookSummary = Tabs.Webhook:AddSection("Periodic Summary")

secWebhookSummary:AddToggle("TogWebhookSummary", {
    Title       = "Auto Summary",
    Description = "Timed stats.",
    Default     = false,
    Callback    = function(v) State.WebhookPeriodicSummary = v end
})

secWebhookSummary:AddSlider("SlideSummaryInterval", {
    Title       = "Summary Interval (minutes)",
    Description = "5-60 minutes.",
    Min         = 5,
    Max         = 60,
    Default     = State.WebhookSummaryInterval,
    Rounding    = 0,
    Callback    = function(v) State.WebhookSummaryInterval = v end
})

secWebhookSummary:AddButton({
    Title       = "Send Summary Now",
    Description = "Send stats now.",
    Callback    = function()
        if not State.WebhookURL or State.WebhookURL == "" then
            VaderUI:Notify({Title = "Vader Script", Content = "Enter a webhook URL before sending a summary.", Duration = 2.5})
            return
        end
        pcall(function()
            local moneyStr = NumberFormatter.FormatCompact(DataController.Money() or 0)
            local rebirthLvl = tostring(DataController.Rebirth() or 0)
            local diceName = tostring(DataController.Dice() or "Default")
            local invCount = 0
            local inv = DataController.Inventory and DataController.Inventory()
            if inv then
                for _, u in pairs(inv) do
                    if type(u) == "table" and u.name then invCount = invCount + 1 end
                end
            end

            local ok = sendDiscordWebhook(
                "Status Summary",
                "Progress summary for **" .. LP.DisplayName .. "** (@" .. LP.Name .. ")",
                0x4287F5,
                {
                    {name = "Cash Balance", value = "$" .. moneyStr, inline = true},
                    {name = "Rebirth Level", value = "Rebirth " .. rebirthLvl, inline = true},
                    {name = "Current Dice", value = diceName, inline = true},
                    {name = "Inventory Units", value = tostring(invCount) .. " units", inline = true},
                    {name = "Selected Tower", value = State.SelectedTower or "None", inline = true},
                    {name = "Session Duration", value = string.format("%.1f minutes", (os.clock()) / 60), inline = true}
                }
            )
            VaderUI:Notify({
                Title   = "Vader Script",
                Content = ok and "Statistics summary sent to Discord." or "Could not send. Check the webhook URL.",
                Duration = 3
            })
        end)
    end
})

-- Per-player automatic persistence
local ConfigFolder = "Vaderhug/AnimeDice"
local PlayerConfigName = LP.Name

local function ensureConfigFolder()
    pcall(function()
        if makefolder and isfolder then
            if not isfolder("Vaderhug") then
                makefolder("Vaderhug")
            end
            if not isfolder(ConfigFolder) then
                makefolder(ConfigFolder)
            end
        end
    end)
end

local function saveConfigFile(configName)
    ensureConfigFolder()
    if not configName or configName == "" or configName == "No configs (empty)" then
        return false, "Invalid config name."
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    if #safeName == 0 then
        return false, "Config names must contain letters or numbers."
    end

    local dataToSave = {
        Version = "1.0",
        Timestamp = os.time(),
        State = State
    }

    local success, encoded = pcall(function()
        return HttpService:JSONEncode(dataToSave)
    end)
    if not success or not encoded then
        return false, "Could not encode config JSON."
    end

    local filePath = ConfigFolder .. "/" .. safeName .. ".json"
    local writeOk = pcall(function()
        writefile(filePath, encoded)
    end)
    if not writeOk then
        return false, "Could not write the config file."
    end
    return true, safeName
end

local function loadConfigFile(configName)
    ensureConfigFolder()
    if not configName or configName == "" or configName == "No configs (empty)" then
        return false, "Select a config to load."
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    local filePath = ConfigFolder .. "/" .. safeName .. ".json"
    if not isfile(filePath) then
        return false, "Config file not found: " .. safeName
    end

    local content
    local readOk = pcall(function()
        content = readfile(filePath)
    end)
    if not readOk or not content or #content == 0 then
        return false, "Could not read the config file."
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not decodeOk or type(decoded) ~= "table" then
        return false, "Invalid config format."
    end

    local loadedState = decoded.State or decoded
    if type(loadedState) ~= "table" then
        return false, "Config does not contain settings."
    end

    for k, v in pairs(loadedState) do
        if State[k] ~= nil and type(State[k]) == type(v) then
            State[k] = v
        end
    end

    local syncOk, syncError = pcall(function()
        local opt = VaderUI.Options
        if not opt then return end

        if opt.DropThemeSelect then opt.DropThemeSelect:SetValue(State.UITheme) end
        if opt.MinimizeKey and type(State.UIKey) == "string" and Enum.KeyCode[State.UIKey] then opt.MinimizeKey:SetValue(State.UIKey) end

        -- Main Tab
        if opt.TogAutoRoll then opt.TogAutoRoll:SetValue(State.AutoRoll) end
        if opt.TogAutoRebirth then opt.TogAutoRebirth:SetValue(State.AutoRebirth) end
        if opt.TogAutoClaim then opt.TogAutoClaim:SetValue(State.AutoClaim) end
        if opt.TogAutoClaimQuests then opt.TogAutoClaimQuests:SetValue(State.AutoClaimQuests) end
        if opt.TogAntiAFK then opt.TogAntiAFK:SetValue(State.AntiAFK) end

        -- Items Tab
        if opt.TogAutoUseItems then opt.TogAutoUseItems:SetValue(State.AutoUseItems) end
        if opt.DropSelectedItems then opt.DropSelectedItems:SetValue(State.SelectedItems) end
        if opt.DropItemCondition then opt.DropItemCondition:SetValue(State.ItemUseCondition) end
        if opt.SlideItemInterval then opt.SlideItemInterval:SetValue(State.ItemUseInterval) end

        -- Tower Tab
        if opt.DropSelectTower and TowerDisplayNameMap then
            for dispName, realName in pairs(TowerDisplayNameMap) do
                if realName == State.SelectedTower then
                    opt.DropSelectTower:SetValue(dispName)
                    break
                end
            end
        end
        if opt.TogAutoTower then opt.TogAutoTower:SetValue(State.AutoTower) end
        if opt.TogAutoEquipTowerTeam then opt.TogAutoEquipTowerTeam:SetValue(State.AutoEquipBestTowerTeam) end
        if opt.TogHideTowerScreen then opt.TogHideTowerScreen:SetValue(State.HideTowerScreen) end

        -- Plot Tab
        if opt.TogAutoCollect then opt.TogAutoCollect:SetValue(State.AutoCollect) end
        if opt.TogAutoEquip then opt.TogAutoEquip:SetValue(State.AutoEquipBest) end
        if opt.SlideEquipInterval then opt.SlideEquipInterval:SetValue(State.EquipInterval) end
        if opt.TogAutoLevelSlots then opt.TogAutoLevelSlots:SetValue(State.AutoLevelSlots) end
        if State.TargetUnitLevel == 999999 then
            if opt.DropTargetLevel then opt.DropTargetLevel:SetValue("MAX") end
        elseif opt.SlideTargetUnitLevel then
            opt.SlideTargetUnitLevel:SetValue(State.TargetUnitLevel)
        end

        -- Auto Sell Tab
        if opt.TogAutoSellUnits then opt.TogAutoSellUnits:SetValue(State.AutoSellUnits) end
        if opt.SlideSellInterval then opt.SlideSellInterval:SetValue(State.SellInterval) end
        if opt.DropSellRarities then opt.DropSellRarities:SetValue(State.SelectedSellRarities) end
        if opt.TogProtectPlot then opt.TogProtectPlot:SetValue(State.ProtectPlottedUnits) end
        if opt.TogProtectGradeS then opt.TogProtectGradeS:SetValue(State.ProtectGradeSPlus) end
        if opt.TogProtectTraits then opt.TogProtectTraits:SetValue(State.ProtectRareTraits) end
        if opt.TogProtectLocked then opt.TogProtectLocked:SetValue(State.ProtectLockedUnits) end

        -- Grades Tab
        if opt.DropGradeUnit then
            local selectedLabel = nil
            for label, unitKey in pairs(unitIdMap) do
                if unitKey == State.TargetGradeUnitKey then selectedLabel = label; break end
            end
            if selectedLabel then
                opt.DropGradeUnit:SetValue(selectedLabel)
            else
                State.TargetGradeUnitKey = ""
                State.AutoRerollGrade = false
                opt.DropGradeUnit:SetValue(nil)
            end
        end
        if opt.DropTargetGrade then
            local targetLabel = ({["神"] = "God", ["∞"] = "Infinity"})[State.TargetGrade] or State.TargetGrade
            opt.DropTargetGrade:SetValue(targetLabel)
        end
        if opt.SlideGradeDelay then opt.SlideGradeDelay:SetValue(State.GradeRollDelay) end
        for _, grade in ipairs(serverProtectList) do
            local lock = opt["TogServerProt_" .. grade]
            if lock then lock:SetValue(State.ProtectedGrades[grade] == true) end
        end
        if opt.TogAutoRerollGrade then opt.TogAutoRerollGrade:SetValue(State.AutoRerollGrade) end

        -- Traits: restore selection and locks before enabling rerolls.
        if opt.DropTraitUnit then
            local selected=nil
            for label,key in pairs(traitUnitIdMap) do
                if key == State.TargetTraitUnitKey then selected=label;break end
            end
            opt.DropTraitUnit:SetValue(selected)
            if not selected then State.TargetTraitUnitKey="";State.AutoRerollTrait=false end
        end
        if opt.DropTargetTrait then opt.DropTargetTrait:SetValue(State.TargetTrait) end
        if opt.SlideTraitDelay then opt.SlideTraitDelay:SetValue(State.TraitRollDelay) end
        for _,name in ipairs(traitTargetOptions) do
            local lock=opt["TogTraitProt_"..name]
            if lock then lock:SetValue(State.ProtectedTraits[name] == true) end
        end
        if opt.TogAutoRerollTrait then opt.TogAutoRerollTrait:SetValue(State.AutoRerollTrait) end

        -- Quirks: restore selection and locks before enabling rerolls.
        if opt.DropQuirkUnit then
            local selected=nil
            for label,key in pairs(Quirk.unitIdMap) do
                if key == State.TargetQuirkUnitKey then selected=label;break end
            end
            opt.DropQuirkUnit:SetValue(selected)
            if not selected then State.TargetQuirkUnitKey="";State.AutoRerollQuirk=false end
        end
        if opt.DropTargetQuirk then opt.DropTargetQuirk:SetValue(State.TargetQuirk) end
        if opt.SlideQuirkDelay then opt.SlideQuirkDelay:SetValue(State.QuirkRollDelay) end
        for _,name in ipairs(Quirk.targetOptions) do
            local lock=opt["TogQuirkProt_"..name]
            if lock then lock:SetValue(State.ProtectedQuirks[name] == true) end
        end
        if opt.TogAutoRerollQuirk then opt.TogAutoRerollQuirk:SetValue(State.AutoRerollQuirk) end

        -- Event Tab
        if opt.TogEventPumpkin then opt.TogEventPumpkin:SetValue(State.EventPumpkinRoll) end
        if opt.TogEventPumpkinMulti then opt.TogEventPumpkinMulti:SetValue(State.EventPumpkinMulti) end
        if opt.DropEventWing then opt.DropEventWing:SetValue(State.EventHouseWing) end
        if opt.TogEventTreat then opt.TogEventTreat:SetValue(State.EventTrickOrTreat) end
        if opt.TogEventQuests then opt.TogEventQuests:SetValue(State.EventQuests) end
        if opt.TogEventPass then opt.TogEventPass:SetValue(State.EventPass) end
        if opt.DropEventShop then opt.DropEventShop:SetValue(State.EventShopItems) end
        if opt.TogEventShop then opt.TogEventShop:SetValue(State.EventShopAuto) end

        -- Upgrades Tab
        if opt.TogAutoUpgrades then opt.TogAutoUpgrades:SetValue(State.AutoUpgrades) end
        if opt.DropUpgradeFocus then opt.DropUpgradeFocus:SetValue(State.SelectedUpgradeCategories) end
        if opt.TogOnlySelected then opt.TogOnlySelected:SetValue(State.OnlySelectedUpgrades) end
        if opt.TogAutoBuyDice then opt.TogAutoBuyDice:SetValue(State.AutoBuyDice) end

        -- Webhook Tab
        if opt.InputWebhookUrl then opt.InputWebhookUrl:SetValue(State.WebhookURL) end
        if opt.TogWebhookEnabled then opt.TogWebhookEnabled:SetValue(State.WebhookEnabled) end
        if opt.TogNotifRolls then opt.TogNotifRolls:SetValue(State.WebhookNotifyRolls) end
        if opt.DropMinRarity then opt.DropMinRarity:SetValue(State.WebhookMinRarity) end
        if opt.TogNotifRebirth then opt.TogNotifRebirth:SetValue(State.WebhookNotifyRebirth) end
        if opt.TogNotifTrait then opt.TogNotifTrait:SetValue(State.WebhookNotifyTrait) end
        if opt.TogNotifGrade then opt.TogNotifGrade:SetValue(State.WebhookNotifyGrade) end
        if opt.TogWebhookSummary then opt.TogWebhookSummary:SetValue(State.WebhookPeriodicSummary) end
        if opt.SlideSummaryInterval then opt.SlideSummaryInterval:SetValue(State.WebhookSummaryInterval) end
    end)

    if not syncOk then return false, "Could not restore UI settings: " .. tostring(syncError) end
    return true, safeName
end

local secTheme = Tabs.Settings:AddSection("Theme Settings")

secTheme:AddDropdown("DropThemeSelect", {
    Title       = "Theme",
    Values      = VaderUI.Themes,
    Default     = "Dark",
    Callback    = function(themeName)
        pcall(function()
            VaderUI:SetTheme(themeName)
            State.UITheme = VaderUI.Theme
        end)
    end
})

local minimizeKey = secTheme:AddKeybind("MinimizeKey", {
    Title = "Show / Hide Key", Default = "RightControl", Mode = "Toggle",
})
VaderUI.MinimizeKeybind = minimizeKey
local setMinimizeKey = minimizeKey.SetValue
function minimizeKey:SetValue(key, mode)
    setMinimizeKey(self, key, mode)
    State.UIKey = self.Value
end

secTheme:AddButton({
    Title       = "Unload UI",
    Description = "Save and close.",
    Callback    = function()
        if _G.AnimeDiceCleanup then
            _G.AnimeDiceCleanup()
        end
    end
})

local secAfk = Tabs.Settings:AddSection("Anti-AFK")

secAfk:AddToggle("TogAntiAFK", {
    Title       = "Anti-AFK",
    Description = "Stay connected.",
    Default     = true,
    Callback    = function(v) State.AntiAFK = v end
})

local secCommunity = Tabs.Settings:AddSection("Community & Support")
secCommunity:AddParagraph({
    Title = "Vader Script Official Discord",
    Content = "Vader updates, support and community.\nDiscord: https://discord.gg/sghjJ7WyWJ",
})
secCommunity:AddButton({
    Title = "Copy Discord Invite",
    Description = "Copy invite.",
    Callback = function()
        local copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
        if type(copy) == "function" then
            local ok = pcall(copy, "https://discord.gg/sghjJ7WyWJ")
            VaderUI:Notify({
                Title = "Vader Script",
                Content = ok and "Discord invite copied to the clipboard." or "Could not copy the invite. Discord: discord.gg/sghjJ7WyWJ",
                Duration = 3,
            })
        else
            VaderUI:Notify({ Title = "Vader Script", Content = "Discord: discord.gg/sghjJ7WyWJ", Duration = 4 })
        end
    end,
})




Window:SelectTab(1)

-- ── TYPOGRAPHY ENHANCEMENT (BOLD FONT ENGINE) ──────────────────────────────────
local function applyBoldTypography(inst)
    if inst:IsA("TextLabel") or inst:IsA("TextBox") or inst:IsA("TextButton") then
        inst.Font = Enum.Font.GothamBold
        inst.FontFace = Font.fromEnum(Enum.Font.GothamBold)
        if inst.TextSize <= 12 then
            inst.TextSize = 13
        end
        if inst.TextTransparency > 0.25 then
            inst.TextTransparency = 0.15
        end
    end
end

task.spawn(function()
    task.wait(0.1)
    pcall(function()
        local sg = Window.Root
        while sg and not sg:IsA("ScreenGui") do
            sg = sg.Parent
        end
        local target = sg or Window.Root
        for _, d in ipairs(target:GetDescendants()) do
            applyBoldTypography(d)
        end
        table.insert(_conns, target.DescendantAdded:Connect(applyBoldTypography))
    end)
end)

VaderUI:Notify({
    Title   = "Vader Script",
    Content = "Anime Dice | discord.gg/sghjJ7WyWJ",
    Duration = 5
})

-- Per-player profile: load before starting the autosave worker.
do
    local canPersist = type(isfile) == "function" and type(readfile) == "function"
        and type(writefile) == "function" and type(makefolder) == "function"
        and type(isfolder) == "function"
    local ready = false
    local lastSaved = nil
    local lastError = nil

    local function sameSettings(a, b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= "table" then return a == b end
        for key, value in pairs(a) do
            if not sameSettings(value, b[key]) then return false end
        end
        for key in pairs(b) do
            if a[key] == nil then return false end
        end
        return true
    end

    local function savePlayerProfile()
        if not ready or _G.AnimeDiceRunId ~= thisRunId then return end
        if lastSaved and sameSettings(State, lastSaved) then return end
        local ok, message = saveConfigFile(PlayerConfigName)
        if ok then
            lastSaved = HttpService:JSONDecode(HttpService:JSONEncode(State))
            lastError = nil
        elseif message ~= lastError then
            lastError = message
            VaderUI:Notify({Title = "Auto Save", Content = tostring(message), Duration = 5})
        end
    end

    if canPersist then
        local loaded, problem = pcall(function()
            ensureConfigFolder()
            local path = ConfigFolder .. "/" .. PlayerConfigName .. ".json"
            if isfile(path) then
                local ok, message = loadConfigFile(PlayerConfigName)
                if not ok then error(message) end
                lastSaved = HttpService:JSONDecode(HttpService:JSONEncode(State))
            end
        end)
        initializingUI = false
        ready = loaded
        if not loaded then
            VaderUI:Notify({Title = "Profile Load Failed", Content = tostring(problem)
                .. " Auto-save is paused to preserve the existing file.", Duration = 8})
        else
            savePlayerProfile()
        end
    else
        initializingUI = false
        VaderUI:Notify({Title = "Auto Save Unavailable",
            Content = "This executor does not provide the required file APIs.", Duration = 6})
    end

    local previousCleanup = _G.AnimeDiceCleanup
    _G.AnimeDiceCleanup = function()
        if _G.AnimeDiceRunId ~= thisRunId then return end
        pcall(savePlayerProfile)
        ready = false
        previousCleanup()
    end
    table.insert(_conns, Players.PlayerRemoving:Connect(function(player)
        if player == LP then pcall(savePlayerProfile) end
    end))
    task.spawn(function()
        while ready and _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
            task.wait(2)
            if ready and _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId then
                local ok, problem = pcall(savePlayerProfile)
                if not ok then warn("[VaderUI] Auto-save: " .. tostring(problem)) end
            end
        end
    end)
end
