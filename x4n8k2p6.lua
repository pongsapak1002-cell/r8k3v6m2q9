-- Vader Script | Ride a Pet
if _G.VaderEggFarmUI then pcall(function() _G.VaderEggFarmUI:Destroy() end) end

-- variables

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local Game = Remotes.Game

local Mount = Game.Mounting


-- module

local RebirthConfig = require(ReplicatedStorage.GameData.Rebirths)
local HatchLuck = require(ReplicatedStorage.GameData.HatchLuck)
local Foods = require(ReplicatedStorage.GameData.Foods)
local ShopConfig = require(ReplicatedStorage.GameData.Shop)
local eggs = require(ReplicatedStorage.GameData.Eggs)
local GrowthConfig = require(ReplicatedStorage.GameData.General)
local DayNight = require(ReplicatedStorage.GameServices.DayNight)

-- Settings, following the original Vader State layout.
local State = {
    AutoFeedPet = false,
    FeedFoods = {},
    FeedPetRarities = {},
    AutoSellPet = false,
    SellPetRarities = {},
    AutoRebirth = false,
    AutoUpgradeLuck = false,
    AutoBuyFood = false,
    AutoBuyGears = false,
    ShopSelected = {Food = {}, Gears = {}},
    AutoFarm = false,
    AutoPlace = false,
    AutoHatch = false,
    AutoPlaceBest = false,
    PlacementRarities = {},
    SelectedRarities = {},
}

-- Worker state: pending requests, cooldowns and movement cleanup.
local Runtime = {
    FeedRevision = 0,
    FeedLastAttempt = -math.huge,
    FeedLastKey = nil,
    SellRevision = 0,
    SellLastAttempt = -math.huge,
    RebirthPending = nil,
    RebirthLastAttempt = -math.huge,
    LuckPending = nil,
    LuckLastBuy = -math.huge,
    ShopStock = {},
    ShopConnection = nil,
    ShopPending = nil,
    ShopLastBuy = -math.huge,
    ShopLastRefresh = -math.huge,
    PetStopped = false,
    LastPetCheck = -math.huge,
    HatchRevision = 0,
    HatchRetry = setmetatable({}, {__mode = "k"}),
    LastHatchScan = -math.huge,
    PlaceRevision = 0,
    LastPlaceAt = -math.huge,
    PendingDelivery = nil,
    PickedEggIds = {},
    HeldRoot = nil,
    HeldVelocity = nil,
    LastPickupAt = -math.huge,
}

-- functions

local get_eggs_rarity = function()
    local egg_list = {}
    for i,v in eggs do
        if not table.find(egg_list,v.Rarity) then
            table.insert(egg_list,v.Rarity)
        end
    end
    return egg_list
end

local get_eggs = function(name)
    for i,v in eggs do
        if i == name then
            return v.Rarity
        end
    end
    return nil
end

local release_movement = function()
    if Runtime.HeldVelocity then Runtime.HeldVelocity:Destroy() end
    if Runtime.HeldRoot and Runtime.HeldRoot.Parent then
        Runtime.HeldRoot.AssemblyLinearVelocity = Vector3.zero
        Runtime.HeldRoot.AssemblyAngularVelocity = Vector3.zero
    end
    Runtime.HeldRoot,Runtime.HeldVelocity = nil,nil
end

local teleport = function(target)
    if not State.AutoFarm then return false end
    local char = LocalPlayer.Character
    local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    if not root then return false end
    target = typeof(target) == "CFrame" and target or CFrame.new(target)
    if Runtime.HeldRoot ~= root then
        release_movement()
        Runtime.HeldRoot = root
        Runtime.HeldVelocity = Instance.new("BodyVelocity")
        Runtime.HeldVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
        Runtime.HeldVelocity.Velocity = Vector3.zero
        Runtime.HeldVelocity.Parent = root
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Anchored = false
    root.CFrame = target
    task.wait(0.35)
    return State.AutoFarm and LocalPlayer.Character == char and root.Parent ~= nil
end

local is_carrying_eggs = function()
    return #LocalPlayer.Basket:GetChildren() > 0
end

local get_my_plot = function()
    for i,v in workspace.Plots:GetChildren() do
        if v:GetAttribute("NestsOwnerLoaded") == LocalPlayer.UserId then
            return v
        end
    end
    return nil
end

local pickup_egg = function(uid)
    if not State.AutoFarm or os.clock()-Runtime.LastPickupAt < 0.75 then return end
    Runtime.LastPickupAt = os.clock()
    Runtime.PickedEggIds[uid] = true
    return Game.EggPickup:FireServer(uid)
end

local get_plot_edge = function(plot,position)
    local bounds,size = plot:GetBoundingBox()
    local offset = bounds:PointToObjectSpace(position)
    local half_x,half_z = size.X / 2,size.Z / 2
    local x,z = offset.X,offset.Z
    if math.abs(x) < 0.001 and math.abs(z) < 0.001 then z = -1 end
    local scale = math.max(math.abs(x) / math.max(half_x,1),math.abs(z) / math.max(half_z,1))
    x,z = x / scale,z / scale
    local outward = Vector3.new(x,0,z).Unit * 6
    local edge = bounds:PointToWorldSpace(Vector3.new(x,0,z) + outward)
    return CFrame.new(edge.X,plot:GetPivot().Position.Y,edge.Z)
end

local wait_for_carrying = function(expected,timeout)
    local deadline = os.clock() + timeout
    while State.AutoFarm and os.clock() < deadline do
        if is_carrying_eggs() == expected then return true end
        task.wait(0.1)
    end
    return false
end

local return_plot = function()
    if not State.AutoFarm then return false end
    local plot = get_my_plot()
    if not plot then return false end
    if not Runtime.PendingDelivery then
        local char = LocalPlayer.Character
        local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
        if not root or not is_carrying_eggs() then return false end
        if not teleport(get_plot_edge(plot,root.Position)) or not State.AutoFarm then return false end

        local carried = LocalPlayer.Basket:GetChildren()
        if #carried == 0 then return false end
        local existing,carried_ids,targets = {},{},{}
        for _,egg in ReplicatedStorage.ServerData.ActiveEggs:GetChildren() do
            existing[egg] = {position = egg:GetAttribute("Position")}
        end
        for _,egg in carried do carried_ids[egg.Name] = true end
        for uid in Runtime.PickedEggIds do targets[uid] = true end
        Runtime.PendingDelivery = {
            stage = "drop",position = root.Position,count = #carried,
            existing = existing,carried_ids = carried_ids,targets = targets,
            started_at = os.clock(),
        }
        Game:WaitForChild("BasketDrop"):FireServer()
    end

    local delivery = Runtime.PendingDelivery
    if os.clock()-delivery.started_at > 25 and delivery.stage ~= "home" then
        if is_carrying_eggs() then
            delivery.stage = "home"
        else
            Runtime.PendingDelivery = nil
            Runtime.PickedEggIds = {}
            release_movement()
            return false
        end
    end
    if delivery.stage == "drop" then
        if not wait_for_carrying(false,5) then return false end
        delivery.stage = "pickup"
    end

    if delivery.stage == "pickup" then
        local deadline = os.clock() + 8
        while State.AutoFarm and os.clock() < deadline do
            if #LocalPlayer.Basket:GetChildren() >= delivery.count then
                delivery.stage = "home"
                break
            end
            local active_eggs = ReplicatedStorage.ServerData.ActiveEggs
            for _,egg in active_eggs:GetChildren() do
                local position = egg:GetAttribute("Position")
                local previous = delivery.existing[egg]
                if egg:IsA("Configuration") and typeof(position) == "Vector3"
                    and (position-delivery.position).Magnitude <= 35
                    and (delivery.carried_ids[egg.Name] or delivery.targets[egg.Name]
                        or not previous or previous.position ~= position) then
                    delivery.targets[egg.Name] = true
                end
            end
            for uid in delivery.targets do
                if not State.AutoFarm then return false end
                local egg = active_eggs:FindFirstChild(uid)
                local position = egg and egg:GetAttribute("Position")
                if typeof(position) == "Vector3" and (position-delivery.position).Magnitude <= 35 then
                    if not teleport(CFrame.new(position + Vector3.new(0,3,0))) or not State.AutoFarm then return false end
                    pickup_egg(uid)
                    task.wait(0.1)
                end
            end
            task.wait(0.1)
        end
        if delivery.stage ~= "home" then return false end
    end

    if not State.AutoFarm or not teleport(plot:GetPivot()) then return false end
    if not wait_for_carrying(false,5) then return false end
    Runtime.PendingDelivery = nil
    Runtime.PickedEggIds = {}
    release_movement()
    return true
end

local is_in_volcano = function()
    return LocalPlayer:GetAttribute("InVolcano") == true
end

local is_riding_pet = function()
    return LocalPlayer:GetAttribute("IsRiding") == true
end

local riding_pet = function()
    local selected_pet
    local lowest_weight = math.huge
    for _, v in LocalPlayer.Backpack:GetChildren() do
        if v:IsA("Tool") and v:GetAttribute("PetName") ~= nil then
            local weight = v:GetAttribute("Weight")

            if type(weight) == "number" and weight < lowest_weight then
                lowest_weight = weight
                selected_pet = v
            end
        end
    end
    if not selected_pet then
        return
    end
    selected_pet.Parent = LocalPlayer.Character
    repeat task.wait() until LocalPlayer.Character:FindFirstChild(selected_pet.Name)
    task.wait()
    Mount:FireServer()
end

local collect_eggs = function()
    if not State.AutoFarm then return end
    if Runtime.PendingDelivery or (is_carrying_eggs() and not is_in_volcano()) then
        return_plot()
        return
    end
    for i, v in ReplicatedStorage.ServerData.ActiveEggs:GetChildren() do
        local weight = v:GetAttribute("Weight")
        local spawn_size = v:GetAttribute("SpawnSize")
        if v:GetAttribute("Egg") == "Volcanic Egg" and State.SelectedRarities[get_eggs(v:GetAttribute("Egg"))] then
            if not is_in_volcano() and is_carrying_eggs() then
                return_plot()
                return
            end
            if is_in_volcano() and is_carrying_eggs() then
                if LocalPlayer:DistanceFromCharacter(Vector3.new(-4924.9033203125, 41287.4609375, -3700.96435546875)) > 10 then
                    teleport(workspace.Volcano.VolcanoValidate.CFrame)
                    task.wait()
                    teleport(CFrame.new(-4924.9033203125, 41287.4609375, -3700.96435546875))
                end
                return
            end
            if not is_in_volcano() then
                if not is_riding_pet() then
                    riding_pet()
                    task.wait(2)
                    return
                end
                repeat task.wait()
                if LocalPlayer:DistanceFromCharacter(workspace.Volcano.VolcanoEntrance.CFrame.Position) > 20 then
                    teleport(CFrame.new(-4924.9033203125, 41287.4609375, -3700.96435546875))
                    task.wait(1)
                    teleport(workspace.Volcano.VolcanoValidate.CFrame)
                end
                until is_in_volcano() or not State.AutoFarm
                return
            end
            if is_in_volcano() and not is_carrying_eggs() and State.SelectedRarities[get_eggs(v:GetAttribute("Egg"))] and v:IsA("Configuration") then
                repeat task.wait()
                    if LocalPlayer:DistanceFromCharacter(v:GetAttribute("Position")) > 20 then
                        if not teleport(CFrame.new(v:GetAttribute("Position"))) or not State.AutoFarm then return end
                    end
                    pickup_egg(v.Name)
                    task.wait()
                until is_carrying_eggs() or not State.AutoFarm
                if LocalPlayer:DistanceFromCharacter(Vector3.new(-4924.9033203125, 41287.4609375, -3700.96435546875)) > 10 then
                    teleport(workspace.Volcano.VolcanoValidate.CFrame)
                    task.wait()
                    teleport(CFrame.new(-4924.9033203125, 41287.4609375, -3700.96435546875))
                end
            end
            return
        end
        if v:IsA("Configuration") and State.SelectedRarities[get_eggs(v:GetAttribute("Egg"))] and State.AutoFarm and not is_carrying_eggs() then
            local deadline = os.clock() + 10
            repeat task.wait()
                if not State.AutoFarm or not v.Parent then return end
                if LocalPlayer:DistanceFromCharacter(v:GetAttribute("Position")) > 20 then
                    if not teleport(CFrame.new(v:GetAttribute("Position"))) or not State.AutoFarm then return end
                end
                pickup_egg(v.Name)
                task.wait(0.2)
            until is_carrying_eggs() or not State.AutoFarm or os.clock() >= deadline
            if State.AutoFarm and is_carrying_eggs() then return_plot() end
        end
    end
end

-- Equip a matching inventory egg before placing it on our own plot.
local function selected_inventory_egg()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    for _, container in ipairs({character, backpack}) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool:HasTag("Egg")
                    and tool:GetAttribute("EggInventoryId")
                    and State.PlacementRarities[get_eggs(tool.Name)] then
                    return tool
                end
            end
        end
    end
end

local function placement_target(plot)
    if LocalPlayer:GetAttribute("NoNest") ~= true then
        local nests = plot:FindFirstChild("Nests")
        if not nests then return end
        for _, nest in ipairs(nests:GetChildren()) do
            if nest:GetAttribute("Unlocked") == true and not nest:GetAttribute("Occupied") then
                local model = nest:FindFirstChild("Model")
                if model and model:IsA("Model") then
                    return {NestId = nest.Name}, model:GetPivot().Position, nest
                end
            end
        end
        return
    end
    local base = plot:FindFirstChild("Baseplate")
    if not base or not base:IsA("BasePart") then return end
    local placed = plot:FindFirstChild("Eggs")
    local halfX, halfZ = base.Size.X / 2 - 5, base.Size.Z / 2 - 5
    for x = -halfX, halfX, 8 do
        for z = -halfZ, halfZ, 8 do
            local position = base.CFrame:PointToWorldSpace(Vector3.new(x, base.Size.Y / 2, z))
            local clear = true
            if placed then
                for _, egg in ipairs(placed:GetChildren()) do
                    if egg:IsA("Model") then
                        local bounds, size = egg:GetBoundingBox()
                        local delta = bounds.Position - position
                        local radius = math.max(size.X, size.Z) / 2 + 4
                        if Vector2.new(delta.X, delta.Z).Magnitude < radius then
                            clear = false
                            break
                        end
                    end
                end
            end
            if clear then return {PlantPosition = position}, position end
        end
    end
end

local function place_inventory_egg()
    if not State.AutoPlace or os.clock() - Runtime.LastPlaceAt < 0.2 then return end
    local revision = Runtime.PlaceRevision
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local plot = get_my_plot()
    if not humanoid or humanoid.Health <= 0 or not root or not plot then return end
    if LocalPlayer:GetAttribute("IsRiding") == true or LocalPlayer:GetAttribute("InVolcano") == true then return end
    if Runtime.PendingDelivery or is_carrying_eggs() then return end
    local tool = selected_inventory_egg()
    if not tool then return end
    local payload, position, nest = placement_target(plot)
    if not payload then return end
    local function active()
        return State.AutoPlace and Runtime.PlaceRevision == revision and LocalPlayer.Character == character
            and humanoid.Health > 0 and plot.Parent ~= nil
            and plot:GetAttribute("NestsOwnerLoaded") == LocalPlayer.UserId
    end
    if not active() then return end
    if tool.Parent ~= character then humanoid:EquipTool(tool) end
    local deadline = os.clock() + 2
    while active() and tool.Parent ~= character and os.clock() < deadline do task.wait() end
    if not active() or tool.Parent ~= character or not State.PlacementRarities[get_eggs(tool.Name)] then return end
    release_movement()
    root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.1)
    if not active() or tool.Parent ~= character then return end
    if nest and (nest:GetAttribute("Unlocked") ~= true or nest:GetAttribute("Occupied")) then return end
    local remote = Game:FindFirstChild("EggPlaced")
    if not remote or not remote:IsA("RemoteEvent") then return end
    local confirmed = false
    local connection = remote.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" or data.Owner ~= LocalPlayer or data.Snapshot then return end
        if data.EggName ~= tool.Name then return end
        if payload.NestId then
            confirmed = tostring(data.NestId) == payload.NestId
        elseif typeof(data.Coordinate) == "CFrame" then
            confirmed = (data.Coordinate.Position - position).Magnitude < 4
        end
    end)
    Runtime.LastPlaceAt = os.clock()
    local ok, err = pcall(function()
        remote:FireServer(payload)
        local timeout = os.clock() + 5
        while active() and not confirmed and os.clock() < timeout do task.wait() end
    end)
    connection:Disconnect()
    if not ok then error(err) end
    if active() and not confirmed then
        Runtime.LastPlaceAt = os.clock() + 5
        warn("[Vader] Egg placement was not confirmed; waiting before retrying.")
    end
end

local function egg_ready_to_hatch(egg, plot)
    local folder = plot:FindFirstChild("Eggs")
    if not folder or egg.Parent ~= folder or not egg:IsA("Model") or not egg.PrimaryPart then return false end
    if not egg:GetAttribute("EggKey") or egg:HasTag("Hatching") then return false end
    if (Runtime.HatchRetry[egg] or 0) > os.clock() then return false end
    if LocalPlayer:GetAttribute("TutorialHatchLocked") == true then
        local locked = LocalPlayer:GetAttribute("TutorialLockedEggKey")
        if locked == nil or locked == egg:GetAttribute("EggKey") then return false end
    end
    local data = egg:FindFirstChild("EggData")
    local placed = data and data:FindFirstChild("PlaceTime")
    local weight = data and data:FindFirstChild("Weight")
    local config = eggs[egg.Name]
    if not config or not placed or placed.Value <= 0 then return false end
    local elapsed
    if egg:GetAttribute("FlatGrow") == true then
        elapsed = workspace:GetServerTimeNow() - placed.Value
    else
        elapsed = DayNight.GrowthElapsed(placed.Value)
    end
    return elapsed >= GrowthConfig.GrowthTimeFor(config.GrowthTime, weight and weight.Value or 1)
end

local function hatch_ready_eggs()
    if not State.AutoHatch or os.clock() - Runtime.LastHatchScan < 0.2 then return end
    Runtime.LastHatchScan = os.clock()
    local revision = Runtime.HatchRevision
    local plot = get_my_plot()
    local folder = plot and plot:FindFirstChild("Eggs")
    local remote = Game:FindFirstChild("Hatch")
    if not folder or not remote or not remote:IsA("RemoteEvent") then return end
    for _, egg in ipairs(folder:GetChildren()) do
        if not State.AutoHatch or revision ~= Runtime.HatchRevision then return end
        if plot:GetAttribute("NestsOwnerLoaded") ~= LocalPlayer.UserId then return end
        if egg_ready_to_hatch(egg, plot) then
            Runtime.HatchRetry[egg] = os.clock() + 3
            remote:FireServer({EggKey = egg:GetAttribute("EggKey")})
            task.wait(0.1)
        end
    end
end
local PetAging = require(ReplicatedStorage.GameServices.PetAging)
local Pets = require(ReplicatedStorage.GameData.Pets)
local Mutations = require(ReplicatedStorage.GameData.Mutations)
local General = require(ReplicatedStorage.GameServices.General)
local PetRenderer = require(LocalPlayer.PlayerScripts.Game.Pets.PetRenderer)
local PlacePet = Game:WaitForChild("PlacePet")
local PickupPet = Game:WaitForChild("PickupPet")
local function IncomeOf(p54) 
    
    local v55 = Pets[p54:GetAttribute("PetName") or p54.Name];
    local v56 = v55 and tonumber(v55.Income) or 0;

    if v56 <= 0 then
        return 0;
    end;

    local v57 = tonumber(p54:GetAttribute("Weight")) or 1;
    local v58 = Mutations.CombinedFactor(p54:GetAttribute("Mutation"), p54:GetAttribute("SpawnMutation"));
    local v59 = math.floor(v56 * (v57 / PetAging.WeightStandardKG)) * v58;

    return math.floor(v59);
end;

local function CollectOwnedPets() 
    
    local v61 = {};

    for _, v in pairs(PetRenderer.GetAll()) do
        if v.OwnerUserId == LocalPlayer.UserId and (v.Model and v.Model.Parent) then
            local v62 = {
                Placed = true,
                Key = v.PetKey,
                Income = tonumber(v.DisplayIncome) or 0,
                Position = v.Model:GetPivot().Position
            };
            table.insert(v61, v62);
        end;
    end;

    for _, v in { LocalPlayer.Character, (LocalPlayer:FindFirstChildOfClass("Backpack")) } do
        if v then
            for _, child in v:GetChildren() do
                if child:IsA("Tool") and (child:HasTag("Pet") and child:GetAttribute("PetKey")) then
                    local v63 = {
                        Placed = false,
                        Key = child:GetAttribute("PetKey"),
                        Income = IncomeOf(child),
                        Tool = child
                    };
                    table.insert(v61, v63);
                end;
            end;
        end;
    end;

    table.sort(v61, function(p64, p65) 
        return p64.Income > p65.Income;
    end);

    return v61;
end;

local function PlacementFor(p66, p67) 
    
    local v68 = math.floor((p67 - 1) / 3) * 4 + 8;
    local Position3 = (p66.CFrame * CFrame.new(((p67 - 1) % 3 - 1) * 4, 0, -v68)).Position;
    local Plot = General:GetPlot(LocalPlayer);

    if Plot then
        Plot = Plot:FindFirstChild("Baseplate");
    end;

    if not Plot then
        return Position3;
    end;

    local v69 = Plot.CFrame:PointToObjectSpace(Position3);
    local v70 = Plot.Size.X / 2 - 2;
    local v71 = Plot.Size.Z / 2 - 2;
    local CFrame2 = Plot.CFrame;
    local math_clamp_ret = math.clamp(v69.X, -v70, v70);
    local Y = v69.Y;
    local math_clamp_ret2 = math.clamp(v69.Z, -v71, v71);

    return CFrame2:PointToWorldSpace((Vector3.new(math_clamp_ret, Y, math_clamp_ret2)));
end;

local function place_best_pets(silent) 
    
    if Runtime.PetStopped then return end
    if LocalPlayer:GetAttribute("IsRiding") == true or LocalPlayer:GetAttribute("InVolcano") == true then return end
    if Runtime.PendingDelivery or is_carrying_eggs() then return end
    local Character = LocalPlayer.Character;
    local v72;

    if Character then
        v72 = Character:FindFirstChildOfClass("Humanoid");
    else
        v72 = Character;
    end;

    local v73;

    if Character then
        v73 = Character:FindFirstChild("HumanoidRootPart");
    else
        v73 = Character;
    end;

    if not (v72 and (v73 and v72.Health > 0)) then
        return;
    end;

    local v74 = LocalPlayer:GetAttribute("MaxPets") or 5;
    local v75 = CollectOwnedPets();

    if #v75 == 0 then
        if silent then return end
        local u76 = "No Pets To Place";
        pcall(function() 
            
            require(LocalPlayer.PlayerGui.Reusable.GameMessages.Handler):AddMessage(u76);
        end);

        return;
    end;

    local v77 = {};
    local v78 = {};

    for i = 1, math.min(v74, #v75) do
        v77[i] = v75[i];
        v78[v75[i].Key] = true;
        local _ = i;
    end;

    local v79 = {};
    local v80 = 0;

    for _, v in v75 do
        if Runtime.PetStopped or LocalPlayer.Character ~= Character then return end
        if v.Placed and not v78[v.Key] then
            table.insert(v79, v.Position);
            PickupPet:FireServer(v.Key);
            v80 = v80 + 1;
            task.wait(0.2);
        end;
    end;

    local v81 = 0;

    for i, v in v77 do
        if Runtime.PetStopped or LocalPlayer.Character ~= Character then return end
        if not v.Placed then
            if not Runtime.PetStopped and LocalPlayer.Character == Character then
                local position = table.remove(v79, 1) or PlacementFor(v73, i)
                PlacePet:FireServer(v.Key, position)
                v81 = v81 + 1
                task.wait(0.2)
            end
        end;
    end;

    if v81 == 0 and v80 == 0 and not silent then
        local u86 = "Best Pets Already Placed";
        pcall(function() 
            
            require(LocalPlayer.PlayerGui.Reusable.GameMessages.Handler):AddMessage(u86);
        end);
    end;

end;


local function shop_item_names(category)
    local names = {}
    for name in pairs(ShopConfig.Categories[category] or {}) do table.insert(names, name) end
    table.sort(names, function(a, b)
        local items = ShopConfig.Categories[category]
        local priceA, priceB = tonumber(items[a].Price) or 0, tonumber(items[b].Price) or 0
        if priceA == priceB then return a < b end
        return priceA < priceB
    end)
    return names
end

local function feed_pet_options()
    local names, seen = {}, {}
    local order = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5,
        Mythic = 6, Mythical = 6, Divine = 7, Ethereal = 8}
    for _, config in pairs(Pets) do
        if type(config) == "table" and type(config.Rarity) == "string" and not seen[config.Rarity] then
            seen[config.Rarity] = true
            table.insert(names, config.Rarity)
        end
    end
    table.sort(names, function(a, b)
        if (order[a] or 99) == (order[b] or 99) then return a < b end
        return (order[a] or 99) < (order[b] or 99)
    end)
    return names
end
local function feed_food_options()
    local names = {}
    for name in pairs(Foods) do table.insert(names, name) end
    table.sort(names, function(a, b)
        local costA, costB = tonumber(Foods[a].Cost) or 0, tonumber(Foods[b].Cost) or 0
        if costA == costB then return a < b end
        return costA < costB
    end)
    return names
end

local function available_feed_food()
    local function scan(container, name)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool:HasTag("Food") and tool.Name == name then
                local data = tool:FindFirstChild("Data")
                local amount = data and data:FindFirstChild("Amount")
                if not amount or (tonumber(amount.Value) or 0) > 0 then return tool end
            end
        end
    end
    for _, name in ipairs(feed_food_options()) do
        if State.FeedFoods[name] then
            local tool = scan(LocalPlayer.Character, name) or scan(LocalPlayer:FindFirstChildOfClass("Backpack"), name)
            if tool then return tool end
        end
    end
end

local function auto_feed_placed_pets()
    if not State.AutoFeedPet or os.clock() - Runtime.FeedLastAttempt < 1 then return end
    if Runtime.RebirthPending or Runtime.PendingDelivery or is_carrying_eggs() then return end
    if LocalPlayer:GetAttribute("InVolcano") == true or LocalPlayer:GetAttribute("IsRiding") == true then return end
    if next(State.FeedPetRarities) == nil or next(State.FeedFoods) == nil then return end
    local revision = Runtime.FeedRevision
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local plot = get_my_plot()
    if not humanoid or humanoid.Health <= 0 or not root or not plot then return end
    local food = available_feed_food()
    if not food then return end
    local targets = {}
    for _, pet in pairs(PetRenderer.GetAll()) do
        if pet.OwnerUserId == LocalPlayer.UserId and pet.Model and pet.Model.Parent
            and pet.Model.PrimaryPart and Pets[pet.Model.Name] and State.FeedPetRarities[Pets[pet.Model.Name].Rarity] then table.insert(targets, pet) end
    end
    table.sort(targets, function(a, b) return tostring(a.PetKey) < tostring(b.PetKey) end)
    if #targets == 0 then return end
    local index = 1
    for i, pet in ipairs(targets) do
        if pet.PetKey == Runtime.FeedLastKey then index = i % #targets + 1 break end
    end
    local pet = targets[index]
    local function active()
        return State.AutoFeedPet and revision == Runtime.FeedRevision and LocalPlayer.Character == character
            and humanoid.Health > 0 and pet.Model.Parent ~= nil
            and pet.OwnerUserId == LocalPlayer.UserId
    end
    if not active() then return end
    if food.Parent ~= character then humanoid:EquipTool(food) end
    local deadline = os.clock() + 2
    while active() and food.Parent ~= character and os.clock() < deadline do task.wait() end
    if not active() or food.Parent ~= character then return end
    local petRoot = pet.Model.PrimaryPart
    if not petRoot then return end
    if (root.Position - petRoot.Position).Magnitude > 8 then
        release_movement()
        root.CFrame = CFrame.new(petRoot.Position + Vector3.new(0, 3, 4))
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.2)
    end
    if not active() or food.Parent ~= character then return end
    local remote = Game:FindFirstChild("FeedPet")
    local confirmation = Game:FindFirstChild("PetFed")
    if not remote or not remote:IsA("RemoteEvent") or not confirmation or not confirmation:IsA("RemoteEvent") then return end
    local confirmed = false
    local connection = confirmation.OnClientEvent:Connect(function(data)
        if type(data) == "table" and tonumber(data.Owner) == LocalPlayer.UserId and data.PetKey == pet.PetKey then
            confirmed = true
        end
    end)
    Runtime.FeedLastAttempt = os.clock()
    Runtime.FeedLastKey = pet.PetKey
    local ok, err = pcall(function()
        remote:FireServer(pet.PetKey, food.Name)
        local timeout = os.clock() + 4
        while active() and not confirmed and os.clock() < timeout do task.wait(0.1) end
    end)
    connection:Disconnect()
    if not ok then error(err) end
    if active() and not confirmed then
        Runtime.FeedLastAttempt = os.clock() + 3
        warn("[Vader] Feeding was not confirmed; waiting before retrying.")
    end
end
local function sell_rarity_options()
    local list, seen = {}, {}
    local order = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5,
        Mythic = 6, Mythical = 6, Divine = 7, Ethereal = 8}
    for _, config in pairs(Pets) do
        if type(config) == "table" and type(config.Rarity) == "string" and not seen[config.Rarity] then
            seen[config.Rarity] = true
            table.insert(list, config.Rarity)
        end
    end
    table.sort(list, function(a, b)
        if (order[a] or 99) == (order[b] or 99) then return a < b end
        return (order[a] or 99) < (order[b] or 99)
    end)
    return list
end

local function sell_pet_candidates()
    local result, seen = {}, {}
    local data = LocalPlayer:FindFirstChild("SavedData")
    local tutorial = data and data:FindFirstChild("HasFinishedTutorial")
    local function scan(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool:HasTag("Pet") then
                local key = tool:GetAttribute("PetKey")
                local name = tool:GetAttribute("PetName")
                local config = name and Pets[name]
                local locked = tool:GetAttribute("Favorited") == true
                    or (key == "TUTORIAL_Snail" and not (tutorial and tutorial.Value == true))
                if type(key) == "string" and config and State.SellPetRarities[config.Rarity]
                    and not locked and not seen[key] then
                    seen[key] = true
                    table.insert(result, key)
                end
            end
        end
    end
    scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
    scan(LocalPlayer.Character)
    return result
end

local function auto_sell_inventory_pets()
    if not State.AutoSellPet or os.clock() - Runtime.SellLastAttempt < 2 then return end
    if next(State.SellPetRarities) == nil or Runtime.RebirthPending then return end
    local revision = Runtime.SellRevision
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return end
    if Runtime.PendingDelivery or is_carrying_eggs() then return end
    if LocalPlayer:GetAttribute("IsRiding") == true or LocalPlayer:GetAttribute("InVolcano") == true then return end
    local keys = sell_pet_candidates()
    if #keys == 0 then return end
    local stalls = workspace:FindFirstChild("Stalls")
    local stall = stalls and stalls:FindFirstChild("Sell")
    local richie = stall and stall:FindFirstChild("Richie")
    local npcRoot = richie and (richie.PrimaryPart or richie:FindFirstChild("HumanoidRootPart"))
    local remote = Game:FindFirstChild("SellItems")
    if not npcRoot or not remote or not remote:IsA("RemoteEvent") then return end
    local function active()
        return State.AutoSellPet and Runtime.SellRevision == revision and LocalPlayer.Character == character
            and humanoid.Health > 0
    end
    if (root.Position - npcRoot.Position).Magnitude > 12 then
        release_movement()
        root.CFrame = npcRoot.CFrame * CFrame.new(0, 0, -5)
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.2)
    end
    if not active() or (root.Position - npcRoot.Position).Magnitude > 12 then return end
    keys = sell_pet_candidates()
    if #keys == 0 then return end
    local confirmRemote = Game:FindFirstChild("ConfirmRequest")
    if not confirmRemote or not confirmRemote:IsA("RemoteEvent") then return end
    local confirmationId
    local confirmationText
    local clicked = false
    local confirmConnection = confirmRemote.OnClientEvent:Connect(function(id, question, options)
        if type(id) ~= "string" or type(question) ~= "string" or type(options) ~= "table" then return end
        local count = tonumber(question:match("^Sell (%d+) pets? for"))
        if active() and options.Title == "Sell" and options.YesText == "Sell" and count == #keys then
            confirmationId = id
            confirmationText = question
        end
    end)
    local function confirm_sale()
        if clicked or not confirmationId or not active() then return end
        local gui = LocalPlayer.PlayerGui:FindFirstChild("ChoiceGui")
        local container = gui and gui:FindFirstChild("Container")
        local poll = container and container:FindFirstChild("Poll")
        local title = container and container:FindFirstChild("TopLeft")
        title = title and title:FindFirstChild("Title")
        local question = poll and poll:FindFirstChild("MainTitle")
        local choices = poll and poll:FindFirstChild("Choices")
        local yes = choices and choices:FindFirstChild("Yes")
        local label = yes and yes:FindFirstChild("TextLabel")
        if not container or not container.Visible or not title or title.Text ~= "Sell"
            or not question or question.Text ~= confirmationText or not label or label.Text ~= "Sell" then return end
        if type(getconnections) ~= "function" then
            clicked = true
            warn("[Vader] Auto Sell confirmation requires getconnections in this executor.")
            return
        end
        for _, connection in ipairs(getconnections(yes.Activated)) do
            if type(connection.Function) == "function" and connection.Enabled ~= false then
                clicked = true
                connection.Function()
                break
            end
        end
    end
    local response
    local connection = remote.OnClientEvent:Connect(function(data)
        if type(data) == "table" then response = data end
    end)
    Runtime.SellLastAttempt = os.clock()
    local ok, err = pcall(function()
        remote:FireServer({Pets = keys, Eggs = {}})
        local deadline = os.clock() + 18
        while active() and not response and os.clock() < deadline do
            confirm_sale()
            task.wait(0.1)
        end
    end)
    connection:Disconnect()
    confirmConnection:Disconnect()
    if not ok then error(err) end
    if not response or not (tonumber(response.Sold) and response.Sold > 0) then
        Runtime.SellLastAttempt = os.clock() + 3
        if response then warn("[Vader] Auto Sell Pet: " .. tostring(response.Reason or "Nothing sold")) end
    end
end
local function owns_rebirth_pet(name)
    for _, pet in pairs(PetRenderer.GetAll()) do
        if pet.OwnerUserId == LocalPlayer.UserId and pet.Model and pet.Model.Parent
            and pet.Model.Name == name then return true end
    end
    local function scan(container)
        if not container then return false end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("PetKey") then
                local baseName = tool.Name:match("^(.-) %[") or tool.Name
                if baseName == name then return true end
            end
        end
        return false
    end
    if scan(LocalPlayer:FindFirstChildOfClass("Backpack")) or scan(LocalPlayer.Character) then return true end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local joint = root and root:FindFirstChild("PetMountJoint")
    local mount = joint and joint.Part1 and joint.Part1.Parent
    return mount ~= nil and mount:GetAttribute("PetName") == name
end

local function auto_rebirth_when_ready()
    local data = LocalPlayer:FindFirstChild("SavedData")
    local rebirths = data and data:FindFirstChild("Rebirths")
    local cash = data and data:FindFirstChild("Cash")
    if not rebirths or not cash then return end
    local now = os.clock()
    if Runtime.RebirthPending then
        if rebirths.Value ~= Runtime.RebirthPending.Level then
            Runtime.RebirthPending = nil
        elseif now - Runtime.RebirthPending.Time >= 5 then
            Runtime.RebirthPending = nil
            Runtime.RebirthLastAttempt = now + 3
        else return end
    end
    if not State.AutoRebirth or now - Runtime.RebirthLastAttempt < 1 then return end
    local cap = tonumber(RebirthConfig.Cap)
    if cap and rebirths.Value >= cap then return end
    if cash.Value < RebirthConfig.GetCost(rebirths.Value) then return end
    local requirements = GrowthConfig.RebirthRequirements
    if type(requirements) ~= "table" or #requirements == 0 then return end
    local requiredPet = requirements[math.clamp(rebirths.Value + 1, 1, #requirements)]
    if not requiredPet or not owns_rebirth_pet(requiredPet) then return end
    if Runtime.LuckPending or Runtime.ShopPending then return end
    local remote = Game:FindFirstChild("Rebirth")
    if not remote or not remote:IsA("RemoteEvent") then return end
    Runtime.RebirthPending = {Level = rebirths.Value, Time = now}
    Runtime.RebirthLastAttempt = now
    remote:FireServer()
end
local function auto_upgrade_hatch_luck()
    if Runtime.RebirthPending then return end
    local now = os.clock()
    local data = LocalPlayer:FindFirstChild("SavedData")
    local upgrades = data and data:FindFirstChild("HatchUpgrades")
    local cash = data and data:FindFirstChild("Cash")
    if not upgrades or not cash then return end
    if Runtime.LuckPending then
        if upgrades.Value ~= Runtime.LuckPending.Level then
            Runtime.LuckPending = nil
        elseif now - Runtime.LuckPending.Time >= 3 then
            Runtime.LuckPending = nil
            Runtime.LuckLastBuy = now + 2
        else return end
    end
    if Runtime.ShopPending and (cash.Value < Runtime.ShopPending.Cash or now - Runtime.ShopPending.Time >= 3) then
        Runtime.ShopPending = nil
    end
    if not State.AutoUpgradeLuck or Runtime.ShopPending or now - Runtime.LuckLastBuy < 0.5 then return end
    if LocalPlayer:GetAttribute("Setting_LuckMultiplier") == false then return end
    local free = data:FindFirstChild("FreeHatchUpgrades")
    local usedFree = data:FindFirstChild("UsedFreeHatchUpgrades")
    local mode
    if free and free.Value > 0 then
        mode = "MaxFree"
    else
        local paid = HatchLuck.GetPaidUpgrades(upgrades.Value, usedFree and usedFree.Value or 0)
        local count = HatchLuck.GetMaxAffordable(paid, cash.Value)
        if count < 1 then return end
        mode = "Max"
    end
    local plotRemotes = Game:FindFirstChild("Plot")
    local remote = plotRemotes and plotRemotes:FindFirstChild("Upgrades")
    if not remote or not remote:IsA("RemoteEvent") then return end
    Runtime.LuckPending = {Level = upgrades.Value, Time = now}
    Runtime.LuckLastBuy = now
    remote:FireServer(mode)
end
local function auto_buy_shop()
    if Runtime.RebirthPending then return end
    if Runtime.LuckPending then return end
    if not State.AutoBuyFood and not State.AutoBuyGears then return end
    local cash = LocalPlayer:FindFirstChild("SavedData")
    cash = cash and cash:FindFirstChild("Cash")
    if not cash or type(cash.Value) ~= "number" then return end
    local now = os.clock()
    if now - Runtime.ShopLastRefresh >= 15 then
        local requestStock = Game:FindFirstChild("ShopStock")
        if requestStock and requestStock:IsA("RemoteEvent") then
            Runtime.ShopLastRefresh = now
            requestStock:FireServer()
        end
    end
    if Runtime.ShopPending then
        local category = Runtime.ShopStock[Runtime.ShopPending.Category]
        local entry = category and category[Runtime.ShopPending.Name]
        local stockChanged = entry and tonumber(entry.Amount) and tonumber(entry.Amount) < Runtime.ShopPending.Stock
        if cash.Value < Runtime.ShopPending.Cash or stockChanged then
            Runtime.ShopPending = nil
        elseif now - Runtime.ShopPending.Time >= 3 then
            Runtime.ShopPending = nil
            Runtime.ShopLastBuy = now + 2
        else
            return
        end
    end
    if now - Runtime.ShopLastBuy < 0.5 then return end
    local remote = Game:FindFirstChild("BuyWithCash")
    if not remote or not remote:IsA("RemoteEvent") then return end
    for _, category in ipairs({"Food", "Gears"}) do
        if (category == "Food" and State.AutoBuyFood) or (category == "Gears" and State.AutoBuyGears) then
            for _, name in ipairs(shop_item_names(category)) do
                local config = ShopConfig.Categories[category][name]
                local price = tonumber(config.Price)
                local stock = Runtime.ShopStock[category] and Runtime.ShopStock[category][name]
                local amount = stock and tonumber(stock.Amount) or 0
                if State.ShopSelected[category][name] and price and price > 0
                    and cash.Value >= price and amount > 0 then
                    Runtime.ShopPending = {Category = category, Name = name, Cash = cash.Value,
                        Stock = amount, Time = now}
                    Runtime.ShopLastBuy = now
                    remote:FireServer(category, name)
                    return
                end
            end
        end
    end
end
-- table

local raritys_prioritys = {
    Common = 1,Rare = 2,Epic = 3,Legendary = 4,Mythic = 5,Ethereal = 6,Divine = 7
}

local eggs_raritys = get_eggs_rarity()
table.sort(eggs_raritys,function(a,b)
    return (raritys_prioritys[a] or math.huge) < (raritys_prioritys[b] or math.huge)
end)

-- VaderUI

State.SelectedRarities.Ethereal = true
State.SelectedRarities.Divine = true

local VaderUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
-- Match Anime Dice: quiet startup and restored values; user actions still notify.
local initializingUI = true
local originalNotify = VaderUI.Notify
function VaderUI:Notify(config)
    if initializingUI then
        return { Closed = true, Close = function() end }
    end
    return originalNotify(self, config)
end
local Window = VaderUI:CreateWindow({
    Title = "Ride a pet",
    SubTitle = "by vaderhug",
    TabWidth = 180,
    Size = UDim2.fromOffset(600, 460),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

_G.VaderEggFarmUI = VaderUI
local HttpService = game:GetService("HttpService")
local antiAFK = true
local selectedTheme = "Dark"
local selectedMinimizeKey = "RightControl"
local idleConnection
local profileFolder = "Vaderhug/RideAPet"
local profilePath = profileFolder .. "/" .. LocalPlayer.Name .. ".json"
local function notify(message)
    VaderUI:Notify({Title = "Vader Script", Content = message, Duration = 3})
end
local function notifyToggle(title, value)
    if initializingUI then return end
    VaderUI:Notify({
        Title = "Vader Script",
        Content = title .. (value and " enabled." or " disabled."),
        Duration = 2,
    })
end
local savePlayerProfile = function() end
local leavingConnection
local unloaded = false
local destroyVaderUI = VaderUI.Destroy
function VaderUI:Destroy()
    if unloaded then return end
    pcall(savePlayerProfile)
    unloaded = true
    State.AutoFeedPet = false
    Runtime.FeedRevision += 1
    State.AutoSellPet = false
    Runtime.SellRevision += 1
    State.AutoRebirth = false
    State.AutoUpgradeLuck = false
    State.AutoBuyFood = false
    State.AutoBuyGears = false
    if Runtime.ShopConnection then Runtime.ShopConnection:Disconnect() end
    State.AutoFarm = false
    State.AutoPlace = false
    State.AutoHatch = false
    Runtime.PetStopped = true
    State.AutoPlaceBest = false
    Runtime.HatchRevision += 1
    Runtime.PlaceRevision += 1
    release_movement()
    if idleConnection then idleConnection:Disconnect() end
    if leavingConnection then leavingConnection:Disconnect() end
    if _G.VaderEggFarmUI == self then _G.VaderEggFarmUI = nil end
    destroyVaderUI(self)
end

local Tabs = {
    Eggs = Window:AddTab({Title = "Main"}),
    Upgrades = Window:AddTab({Title = "Upgrades"}),
    Shop = Window:AddTab({Title = "Shop"}),
    Pet = Window:AddTab({Title = "Pet"}),
    Settings = Window:AddTab({Title = "Settings"}),
}
local secLuckUpgrade = Tabs.Upgrades:AddSection("Hatch Luck")
secLuckUpgrade:AddToggle("TogAutoUpgradeLuck", {
    Title = "Auto Upgrade Hatch Luck",
    Description = "Use free upgrades first, then buy the maximum affordable upgrades with cash.",
    Default = false,
    Callback = function(value) State.AutoUpgradeLuck = value; notifyToggle("Auto Upgrade Hatch Luck", value) end,
})
local secRebirth = Tabs.Upgrades:AddSection("Rebirth")
secRebirth:AddToggle("TogAutoRebirth", {
    Title = "Auto Rebirth",
    Description = "Rebirth when you have enough cash and the required pet. Cash and Hatch Luck reset on rebirth.",
    Default = false,
    Callback = function(value) State.AutoRebirth = value; notifyToggle("Auto Rebirth", value) end,
})
local secFarm = Tabs.Eggs:AddSection("Egg Farming")
secFarm:AddToggle("TogAutoFarm", {
    Title = "Auto Farm",
    Description = "Collect eggs of the selected rarities and return them to your plot.",
    Default = false,
    Callback = function(value)
        State.AutoFarm = value; notifyToggle("Auto Farm", value)
        if not value then release_movement() end
    end,
})
secFarm:AddDropdown("DropEggRarities", {
    Title = "Select Rarities",
    Values = eggs_raritys,
    Multi = true,
    Default = {"Ethereal", "Divine"},
    Callback = function(value)
        table.clear(State.SelectedRarities)
        if type(value) ~= "table" then return end
        for key, selected in pairs(value) do
            if selected == true and type(key) == "string" then
                State.SelectedRarities[key] = true
            elseif type(key) == "number" and type(selected) == "string" then
                State.SelectedRarities[selected] = true
            end
        end
    end,
})

local secPlace = Tabs.Eggs:AddSection("Egg Placement")
secPlace:AddToggle("TogAutoPlace", {
    Title = "Auto Place Eggs",
    Description = "Equip matching inventory eggs, then place them on your own farm.",
    Default = false,
    Callback = function(value)
        State.AutoPlace = value; notifyToggle("Auto Place Eggs", value)
        Runtime.PlaceRevision += 1
    end,
})
secPlace:AddDropdown("DropPlaceRarities", {
    Title = "Placement Rarities",
    Values = eggs_raritys,
    Multi = true,
    Default = {},
    Callback = function(value)
        Runtime.PlaceRevision += 1
        table.clear(State.PlacementRarities)
        if type(value) ~= "table" then return end
        for key, selected in pairs(value) do
            if selected == true and type(key) == "string" then State.PlacementRarities[key] = true
            elseif type(key) == "number" and type(selected) == "string" then State.PlacementRarities[selected] = true end
        end
    end,
})
local secHatch = Tabs.Eggs:AddSection("Egg Hatching")
secHatch:AddToggle("TogAutoHatch", {
    Title = "Auto Hatch",
    Description = "Check eggs on your own farm and hatch only those that have finished growing.",
    Default = false,
    Callback = function(value)
        State.AutoHatch = value; notifyToggle("Auto Hatch", value)
        Runtime.HatchRevision += 1
    end,
})
local secPet = Tabs.Pet:AddSection("Pet Placement")
secPet:AddToggle("TogAutoPlaceBest", {
    Title = "Auto Place Best",
    Description = "Check every 5 seconds and replace weaker pets with higher-income pets.",
    Default = false,
    Callback = function(value) State.AutoPlaceBest = value; notifyToggle("Auto Place Best", value) end,
})
for _, category in ipairs({"Food", "Gears"}) do
    local section = Tabs.Shop:AddSection(category)
    section:AddDropdown("DropShop" .. category, {
        Title = "Select " .. category,
        Values = shop_item_names(category),
        Multi = true,
        Default = {},
        Callback = function(value)
            table.clear(State.ShopSelected[category])
            if type(value) ~= "table" then return end
            for key, selected in pairs(value) do
                local name = selected == true and key or (type(key) == "number" and selected or nil)
                if type(name) == "string" and ShopConfig.Categories[category][name] then
                    State.ShopSelected[category][name] = true
                end
            end
        end,
    })
    section:AddToggle("TogAutoBuy" .. category, {
        Title = "Auto Buy " .. category,
        Description = "Buy selected items when cash is sufficient and stock is available.",
        Default = false,
        Callback = function(value)
            if category == "Food" then State.AutoBuyFood = value else State.AutoBuyGears = value end
            notifyToggle("Auto Buy " .. category, value)
        end,
    })
end
local restock = Game:FindFirstChild("Restock")
if restock and restock:IsA("RemoteEvent") then
    Runtime.ShopConnection = restock.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        for _, category in ipairs({"Food", "Gears"}) do
            if type(data[category]) == "table" then
                Runtime.ShopStock[category] = {}
                for name, entry in pairs(data[category]) do
                    if type(entry) == "table" then Runtime.ShopStock[category][name] = table.clone(entry) end
                end
            end
        end
    end)
end
local secFeedPet = Tabs.Pet:AddSection("Pet Feeding")
secFeedPet:AddToggle("TogAutoFeedPet", {
    Title = "Auto Feed Pet",
    Description = "Feed pets of selected rarities on your farm using selected inventory food.",
    Default = false,
    Callback = function(value)
        State.AutoFeedPet = value; notifyToggle("Auto Feed Pet", value)
        Runtime.FeedRevision += 1
    end,
})
secFeedPet:AddDropdown("DropFeedPetRarities", {
    Title = "Feed Pet Rarities",
    Values = feed_pet_options(),
    Multi = true,
    Default = {},
    Callback = function(value)
        Runtime.FeedRevision += 1
        table.clear(State.FeedPetRarities)
        if type(value) ~= "table" then return end
        for key, selected in pairs(value) do
            local name = selected == true and key or (type(key) == "number" and selected or nil)
            if type(name) == "string" and table.find(feed_pet_options(), name) then State.FeedPetRarities[name] = true end
        end
    end,
})
secFeedPet:AddDropdown("DropFeedFoods", {
    Title = "Select Foods",
    Values = feed_food_options(),
    Multi = true,
    Default = {},
    Callback = function(value)
        Runtime.FeedRevision += 1
        table.clear(State.FeedFoods)
        if type(value) ~= "table" then return end
        for key, selected in pairs(value) do
            local name = selected == true and key or (type(key) == "number" and selected or nil)
            if type(name) == "string" and Foods[name] then State.FeedFoods[name] = true end
        end
    end,
})
local secSellPet = Tabs.Pet:AddSection("Pet Selling")
secSellPet:AddToggle("TogAutoSellPet", {
    Title = "Auto Sell Pet",
    Description = "Sell matching inventory pets at Richie. Favorited and placed pets are excluded.",
    Default = false,
    Callback = function(value)
        State.AutoSellPet = value; notifyToggle("Auto Sell Pet", value)
        Runtime.SellRevision += 1
    end,
})
secSellPet:AddDropdown("DropSellPetRarities", {
    Title = "Sell Pet Rarities",
    Values = sell_rarity_options(),
    Multi = true,
    Default = {},
    Callback = function(value)
        Runtime.SellRevision += 1
        table.clear(State.SellPetRarities)
        if type(value) ~= "table" then return end
        local allowed = sell_rarity_options()
        for key, selected in pairs(value) do
            local rarity = selected == true and key or (type(key) == "number" and selected or nil)
            if type(rarity) == "string" and table.find(allowed, rarity) then State.SellPetRarities[rarity] = true end
        end
    end,
})
local secTheme = Tabs.Settings:AddSection("Theme Settings")
secTheme:AddDropdown("DropThemeSelect", {
    Title = "Theme",
    Values = VaderUI.Themes,
    Default = "Dark",
    Callback = function(themeName)
        VaderUI:SetTheme(themeName)
        selectedTheme = themeName
    end,
})
local minimizeKey = secTheme:AddKeybind("MinimizeKey", {
    Title = "Show / Hide Key", Default = "RightControl", Mode = "Toggle",
})
VaderUI.MinimizeKeybind = minimizeKey
local setMinimizeKey = minimizeKey.SetValue
function minimizeKey:SetValue(key, mode)
    setMinimizeKey(self, key, mode)
    selectedMinimizeKey = self.Value
end

secTheme:AddButton({
    Title = "Unload UI",
    Description = "Stop farming and close the UI.",
    Callback = function()
        VaderUI:Destroy()
    end,
})
local secAFK = Tabs.Settings:AddSection("Anti-AFK")
secAFK:AddToggle("TogAntiAFK", {
    Title = "Anti-AFK", Default = true,
    Description = "Prevent idle disconnections while Vader is open.",
    Callback = function(value) antiAFK = value; notifyToggle("Anti-AFK", value) end,
})
idleConnection = LocalPlayer.Idled:Connect(function()
    if unloaded or not antiAFK then return end
    pcall(function()
        local virtualUser = game:GetService("VirtualUser")
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end)
end)

local secCommunity = Tabs.Settings:AddSection("Community & Support")
secCommunity:AddParagraph({
    Title = "Vader Script Official Discord",
    Content = "Vader updates, support and community.\nDiscord: https://discord.gg/sghjJ7WyWJ",
})
secCommunity:AddButton({
    Title = "Copy Discord Invite",
    Description = "Copy the Discord invite to your clipboard.",
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

-- Automatic per-player persistence, matching the original Vader behavior.
do
    local canPersist = type(isfile) == "function" and type(readfile) == "function"
        and type(writefile) == "function" and type(makefolder) == "function"
        and type(isfolder) == "function"
    local ready = false
    local lastSaved
    local lastError
    local function settings()
        local rarities = {}
        for _, rarity in ipairs(eggs_raritys) do
            if State.SelectedRarities[rarity] then table.insert(rarities, rarity) end
        end
        local placementRarities = {}
        for _, rarity in ipairs(eggs_raritys) do
            if State.PlacementRarities[rarity] then table.insert(placementRarities, rarity) end
        end
        return {Rarities = rarities, Theme = selectedTheme, MinimizeKey = selectedMinimizeKey, AntiAFK = antiAFK,
            AutoFeedPet = State.AutoFeedPet, FeedPetRarities = table.clone(State.FeedPetRarities), FeedFoods = table.clone(State.FeedFoods),
            AutoSellPet = State.AutoSellPet, SellPetRarities = table.clone(State.SellPetRarities),
            AutoRebirth = State.AutoRebirth, AutoUpgradeLuck = State.AutoUpgradeLuck, AutoBuyFood = State.AutoBuyFood, AutoBuyGears = State.AutoBuyGears,
            ShopFood = table.clone(State.ShopSelected.Food), ShopGears = table.clone(State.ShopSelected.Gears),
            AutoFarm = State.AutoFarm, AutoPlace = State.AutoPlace, AutoHatch = State.AutoHatch, AutoPlaceBest = State.AutoPlaceBest, PlacementRarities = placementRarities}
    end
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
    savePlayerProfile = function()
        if not ready or unloaded or _G.VaderEggFarmUI ~= VaderUI then return end
        local current = settings()
        if lastSaved and sameSettings(current, lastSaved) then return end
        local ok, err = pcall(function()
            writefile(profilePath, HttpService:JSONEncode(current))
        end)
        if ok then
            lastSaved = current
            lastError = nil
        elseif tostring(err) ~= lastError then
            lastError = tostring(err)
            VaderUI:Notify({Title = "Auto Save", Content = lastError, Duration = 5})
        end
    end
    if canPersist then
        local loaded, problem = pcall(function()
            if not isfolder("Vaderhug") then makefolder("Vaderhug") end
            if not isfolder(profileFolder) then makefolder(profileFolder) end
            if isfile(profilePath) then
                local data = HttpService:JSONDecode(readfile(profilePath))
                assert(type(data) == "table", "Invalid Vader profile")
                local options = VaderUI.Options
                if type(data.Rarities) == "table" then
                    local valid = {}
                    for _, rarity in ipairs(data.Rarities) do
                        if table.find(eggs_raritys, rarity) then valid[rarity] = true end
                    end
                    options.DropEggRarities:SetValue(valid)
                end
                if type(data.Theme) == "string" and table.find(VaderUI.Themes, data.Theme) then
                    options.DropThemeSelect:SetValue(data.Theme)
                end
                if type(data.AntiAFK) == "boolean" then options.TogAntiAFK:SetValue(data.AntiAFK) end
                if type(data.MinimizeKey) == "string" and Enum.KeyCode[data.MinimizeKey] then options.MinimizeKey:SetValue(data.MinimizeKey) end
                if type(data.AutoFarm) == "boolean" then options.TogAutoFarm:SetValue(data.AutoFarm) end
                if type(data.PlacementRarities) == "table" then
                    local valid = {}
                    for _, rarity in ipairs(data.PlacementRarities) do
                        if table.find(eggs_raritys, rarity) then valid[rarity] = true end
                    end
                    options.DropPlaceRarities:SetValue(valid)
                end
                if type(data.AutoPlace) == "boolean" then options.TogAutoPlace:SetValue(data.AutoPlace) end
                if type(data.AutoHatch) == "boolean" then options.TogAutoHatch:SetValue(data.AutoHatch) end
                if type(data.AutoPlaceBest) == "boolean" then options.TogAutoPlaceBest:SetValue(data.AutoPlaceBest) end
                for _, category in ipairs({"Food", "Gears"}) do
                    local saved = data["Shop" .. category]
                    if type(saved) == "table" then
                        local valid = {}
                        for name, enabled in pairs(saved) do
                            if enabled == true and ShopConfig.Categories[category][name] then valid[name] = true end
                        end
                        options["DropShop" .. category]:SetValue(valid)
                    end
                    local enabled = data["AutoBuy" .. category]
                    if type(enabled) == "boolean" then options["TogAutoBuy" .. category]:SetValue(enabled) end
                end
                if type(data.AutoUpgradeLuck) == "boolean" then options.TogAutoUpgradeLuck:SetValue(data.AutoUpgradeLuck) end
                if type(data.AutoRebirth) == "boolean" then options.TogAutoRebirth:SetValue(data.AutoRebirth) end
                if type(data.SellPetRarities) == "table" then
                    local valid, allowed = {}, sell_rarity_options()
                    for rarity, enabled in pairs(data.SellPetRarities) do
                        if enabled == true and table.find(allowed, rarity) then valid[rarity] = true end
                    end
                    options.DropSellPetRarities:SetValue(valid)
                end
                if type(data.AutoSellPet) == "boolean" then options.TogAutoSellPet:SetValue(data.AutoSellPet) end
                if type(data.FeedPetRarities) == "table" then
                    local valid = {}
                    for name, enabled in pairs(data.FeedPetRarities) do
                        if enabled == true and table.find(feed_pet_options(), name) then valid[name] = true end
                    end
                    options.DropFeedPetRarities:SetValue(valid)
                end
                if type(data.FeedFoods) == "table" then
                    local valid = {}
                    for name, enabled in pairs(data.FeedFoods) do
                        if enabled == true and Foods[name] then valid[name] = true end
                    end
                    options.DropFeedFoods:SetValue(valid)
                end
                if type(data.AutoFeedPet) == "boolean" then options.TogAutoFeedPet:SetValue(data.AutoFeedPet) end
                lastSaved = settings()
            end
        end)
        ready = loaded
        if not loaded then
            VaderUI:Notify({Title = "Profile Load Failed", Content = tostring(problem)
                .. " Auto-save is paused to preserve the existing file.", Duration = 8})
        else
            savePlayerProfile()
        end
    else
        VaderUI:Notify({Title = "Auto Save Unavailable",
            Content = "This executor does not provide the required file APIs.", Duration = 6})
    end
    leavingConnection = Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then pcall(savePlayerProfile) end
    end)
    task.spawn(function()
        while ready and not unloaded and _G.VaderEggFarmUI == VaderUI do
            task.wait(2)
            if ready and not unloaded and _G.VaderEggFarmUI == VaderUI then
                local ok, problem = pcall(savePlayerProfile)
                if not ok then warn("[VaderUI] Auto-save: " .. tostring(problem)) end
            end
        end
    end)
end

initializingUI = false

-- Shop purchases run independently of movement and egg collection.
task.spawn(function()
    while not unloaded do
        local rebirthOK, rebirthError = pcall(auto_rebirth_when_ready)
        if not rebirthOK then warn("[Vader] Auto Rebirth:", rebirthError) end
        if unloaded then break end
        local upgradeOK, upgradeError = pcall(auto_upgrade_hatch_luck)
        if not upgradeOK then warn("[Vader] Auto Upgrade:", upgradeError) end
        if unloaded then break end
        local ok, err = pcall(auto_buy_shop)
        if not ok then warn("[Vader] Auto Buy:", err) end
        task.wait(0.2)
    end
end)

-- Remote hatching does not move the character and can run during farming.
task.spawn(function()
    while not unloaded do
        local ok, err = pcall(hatch_ready_eggs)
        if not ok then warn("[Vader] Auto Hatch:", err) end
        task.wait(0.2)
    end
end)
-- runtime

task.spawn(function()
    while not unloaded and task.wait() do
        if State.AutoFeedPet then
            local success, err = pcall(auto_feed_placed_pets)
            if not success then warn("[Vader] Auto Feed Pet:", err) end
        end
        if unloaded then break end
        if State.AutoSellPet then
            local success, err = pcall(auto_sell_inventory_pets)
            if not success then warn("[Vader] Auto Sell Pet:", err) end
        end
        if unloaded then break end
        if State.AutoPlaceBest and os.clock() - Runtime.LastPetCheck >= 5 then
            Runtime.LastPetCheck = os.clock()
            local success, err = pcall(place_best_pets, true)
            if not success then warn("[Vader] Place Best:", err) end
        end
        if unloaded then break end

        if State.AutoPlace then
            local success, err = pcall(place_inventory_egg)
            if not success then warn("[Vader] Auto Place:", err) end
        end
        if unloaded then break end
        if State.AutoFarm then
            local success,err = pcall(collect_eggs)
            if not success then
                release_movement()
                warn("[Vader] Auto Farm:",err)
            end
        end
    end
end)