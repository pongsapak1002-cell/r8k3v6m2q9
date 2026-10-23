-- Place 99610146753435; RightControl minimizes VaderUI.
assert(game.PlaceId == 99610146753435, "This script targets place 99610146753435")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Tags = game:GetService("CollectionService")
local Player = Players.LocalPlayer
local Env = getgenv()
local Ballistics = require(RS.Modules.WeaponBallistics)
assert(type(Ballistics.Directions) == "function", "Ballistics API changed")
local uiSource = Env.__VaderSource46300 or game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua")
local uiChunk, uiError = loadstring(uiSource)
assert(uiChunk, uiError)
if Env.VaderAim46300 then Env.VaderAim46300.Unload() end
local Library = uiChunk()
local State = { Enabled = false, ESP = false, ShowNames = true, HideMyName = true, ShowFOV = true, Radius = 150, Shots = 0 }
local original = Ballistics.Directions
local overlay = Instance.new("ScreenGui")
overlay.Name = "VaderAimOverlay"
overlay.IgnoreGuiInset = true
overlay.ResetOnSpawn = false
overlay.Parent = Player:WaitForChild("PlayerGui")
local circle = Instance.new("Frame")
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Parent = overlay
local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(1, 0)
round.Parent = circle
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(180, 120, 255)
stroke.Thickness = 1.5
stroke.Parent = circle
local visuals = {}
local normalESPColor = Color3.fromRGB(180, 120, 255)
local lockedESPColor = Color3.fromRGB(255, 55, 55)
local connections = {}
local unloaded = false
local maskedNames = setmetatable({}, { __mode = "k" })
local hiddenHumanoids = setmetatable({}, { __mode = "k" })

function State.ApplyHideName(forceOff)
    if forceOff or not State.HideMyName then
        for object, record in pairs(maskedNames) do
            pcall(function() if object.Text == record.hidden then object.Text = record.original end end)
            maskedNames[object] = nil
        end
        for humanoid, record in pairs(hiddenHumanoids) do
            pcall(function() humanoid.DisplayDistanceType = record.mode; humanoid.NameDisplayDistance = record.distance end)
            hiddenHumanoids[humanoid] = nil
        end
        return
    end
    local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if not hiddenHumanoids[humanoid] then hiddenHumanoids[humanoid] = { mode = humanoid.DisplayDistanceType, distance = humanoid.NameDisplayDistance } end
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.NameDisplayDistance = 0
    end
    local roots = { Player.PlayerGui }
    if Player.Character then table.insert(roots, Player.Character) end
    local ok, core = pcall(game.GetService, game, "CoreGui")
    if ok then table.insert(roots, core) end
    for _, root in ipairs(roots) do
        local success, objects = pcall(root.GetDescendants, root)
        if success then for _, object in ipairs(objects) do
            if object:IsA("TextLabel") or object:IsA("TextButton") then pcall(function()
                local original = object.Text
                local hidden = original
                for _, name in ipairs({ Player.Name, Player.DisplayName }) do
                    if #name > 0 then hidden = hidden:gsub(name:gsub("(%W)", "%%%1"), "Player") end
                end
                if hidden ~= original then maskedNames[object] = { original = original, hidden = hidden }; object.Text = hidden end
            end) end
        end end
    end
end

local function allied(model, other)
    local owner = model:GetAttribute("SupportOwnerUserId")
    if owner == Player.UserId then return true end
    local squads = RS:FindFirstChild("Squads")
    if squads then
        for _, squad in ipairs(squads:GetChildren()) do
            if squad:FindFirstChild(Player.Name) then
                if other and squad:FindFirstChild(other.Name) then return true end
                local ownerPlayer = owner and Players:GetPlayerByUserId(owner)
                if ownerPlayer and squad:FindFirstChild(ownerPlayer.Name) then return true end
            end
        end
    end
    return other ~= nil and not Player.Neutral and not other.Neutral and Player.Team == other.Team
end

local function enemy(model)
    if not model:IsA("Model") or model == Player.Character then return false end
    local other = Players:GetPlayerFromCharacter(model)
    if not other and model:GetAttribute("IsBot") ~= true then return false end
    if allied(model, other) or Tags:HasTag(model, "AimAssistIgnore") then return false end
    if other then
        local status = other:GetAttribute("LobbyStatus")
        if status ~= nil and status ~= "Jugando" then return false end
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local down = humanoid and humanoid:FindFirstChild("Down")
    return humanoid ~= nil and humanoid.Health > 0 and not (down and down.Value)
        and model:FindFirstChild("Head") ~= nil
end

local function aimPoint(model)
    -- The game's hitbox is above the neck, which can differ from Head.Position.
    return Ballistics.CajaCabeza(model, model.Head).Position
end

local function inFOV(point, center, radius)
    return (point - center).Magnitude <= radius
end

local function selectTarget(origin, config)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local center = camera.ViewportSize / 2
    local best, bestModel, distance = nil, nil, State.Radius
    for _, model in ipairs(workspace:GetChildren()) do
        if enemy(model) then
            local position = aimPoint(model)
            local screen, visible = camera:WorldToViewportPoint(position)
            local point = Vector2.new(screen.X, screen.Y)
            if visible and inFOV(point, center, distance) and (position - origin).Magnitude <= (config.Range or 300) then
                local result = Ballistics.Trace(origin, position - origin, config, { Player.Character })
                if result.character == model then
                    best = position
                    bestModel = model
                    distance = (point - center).Magnitude
                end
            end
        end
    end
    return best, bestModel
end

local function redirected(config, frame, spread, random)
    State.Target = nil
    local status = Player:GetAttribute("LobbyStatus")
    if State.Enabled and not config.HealAllies and (status == nil or status == "Jugando" or status == "Tutorial") then
        local ok, target, model = pcall(selectTarget, frame.Position, config)
        if ok and target and (target - frame.Position).Magnitude > 0.001 then
            frame = CFrame.lookAt(frame.Position, target)
            State.Shots = State.Shots + 1
            State.Target = model
        elseif not ok and not State.LastError then
            State.LastError = tostring(target)
            warn("[VaderAim] " .. State.LastError)
        end
    end
    return original(config, frame, spread, random)
end

local function clearVisual(model)
    local visual = visuals[model]
    if visual then
        visual.Highlight:Destroy()
        visual.Label:Destroy()
        visuals[model] = nil
    end
end

local function espColor(model)
    return State.Enabled and State.Target == model and lockedESPColor or normalESPColor
end

local elapsed, nameElapsed = 0, 0
connections[1] = RunService.RenderStepped:Connect(function(dt)
    if Library.Unloaded then State.Unload(); return end
    circle.Size = UDim2.fromOffset(State.Radius * 2, State.Radius * 2)
    circle.Visible = State.ShowFOV
    nameElapsed = nameElapsed + dt
    if nameElapsed >= 0.5 then nameElapsed = 0; State.ApplyHideName() end
    elapsed = elapsed + dt
    if elapsed < 0.2 then return end
    elapsed = 0
    for model in pairs(visuals) do
        if not State.ESP or model.Parent ~= workspace or not enemy(model) then clearVisual(model) end
    end
    if not State.ESP then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    if State.Target then
        local valid = State.Enabled and State.Target.Parent == workspace and enemy(State.Target)
        if valid then
            local screen, visible = camera:WorldToViewportPoint(aimPoint(State.Target))
            valid = visible and inFOV(Vector2.new(screen.X, screen.Y), camera.ViewportSize / 2, State.Radius)
        end
        if not valid then State.Target = nil end
    end
    for _, model in ipairs(workspace:GetChildren()) do
        if enemy(model) then
            local visual = visuals[model]
            if not visual then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = model
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.FillColor = normalESPColor
                highlight.FillTransparency = 0.75
                highlight.OutlineColor = highlight.FillColor
                highlight.Parent = overlay
                local label = Instance.new("BillboardGui")
                label.Adornee = model.Head
                label.Size = UDim2.fromOffset(220, 24)
                label.StudsOffset = Vector3.new(0, 2, 0)
                label.AlwaysOnTop = true
                label.Parent = overlay
                local text = Instance.new("TextLabel")
                text.Size = UDim2.fromScale(1, 1)
                text.BackgroundTransparency = 1
                text.TextColor3 = Color3.new(1, 1, 1)
                text.TextStrokeTransparency = 0.25
                text.TextSize = 14
                text.Font = Enum.Font.Gotham
                text.Parent = label
                visual = { Highlight = highlight, Label = label, Text = text }
                visuals[model] = visual
            end
            local other = Players:GetPlayerFromCharacter(model)
            local distance = (model.Head.Position - camera.CFrame.Position).Magnitude
            visual.Label.Adornee = model.Head
            local color = espColor(model)
            visual.Highlight.FillColor = color
            visual.Highlight.OutlineColor = color
            visual.Text.Text = State.ShowNames and string.format("%s | %d studs", other and other.DisplayName or model.Name, distance) or string.format("%d studs", distance)
        end
    end
end)

function State.Unload()
    if unloaded then return end
    unloaded = true
    State.ApplyHideName(true)
    State.Enabled = false
    State.Target = nil
    if Ballistics.Directions == redirected then Ballistics.Directions = original end
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for model in pairs(visuals) do clearVisual(model) end
    overlay:Destroy()
    Library:Destroy()
    if Env.VaderAim46300 == State then Env.VaderAim46300 = nil end
end

-- Small self-check: FOV boundary, outside rejection, and unchanged spread when disabled.
assert(inFOV(Vector2.new(3, 4), Vector2.zero, 5))
assert(not inFOV(Vector2.new(3, 4), Vector2.zero, 4.99))
assert(not enemy(Player.Character or Instance.new("Folder")))
local colorProbe = {}
State.Enabled = true
State.Target = colorProbe
assert(espColor(colorProbe) == lockedESPColor and espColor({}) == normalESPColor)
State.Enabled = false
assert(espColor(colorProbe) == normalESPColor)
State.Target = nil
local probeConfig = { ShotSize = 3 }
local before = original(probeConfig, CFrame.new(), 2, Random.new(123))
local after = redirected(probeConfig, CFrame.new(), 2, Random.new(123))
assert(#before == #after)
for i, direction in ipairs(before) do assert((direction - after[i]).Magnitude < 1e-6) end

local Window = Library:CreateWindow({ Title = "Vader | Silent Aim + ESP", SubTitle = "Client 46300", Theme = "Dark", MinimizeKey = Enum.KeyCode.RightControl })
local Main = Window:AddTab({ Title = "Combat" })
Main:AddToggle("SilentAim", { Title = "Silent Aim", Default = false, Callback = function(v) State.Enabled = v; if not v then State.Target = nil end end })
Main:AddSlider("FOV", { Title = "FOV radius (pixels)", Min = 25, Max = 500, Default = 150, Rounding = 0, Callback = function(v) State.Radius = v end })
Main:AddToggle("ShowFOV", { Title = "Show FOV", Default = true, Callback = function(v) State.ShowFOV = v end })
Main:AddToggle("ESP", { Title = "Enemy ESP | name + distance", Default = false, Callback = function(v) State.ESP = v end })
Main:AddToggle("ShowNames", { Title = "Show names", Default = true, Callback = function(v) State.ShowNames = v end })
Main:AddParagraph({ Title = "Targeting", Content = "Head | nearest to screen center | visible shot path | skips allies and downed targets. Native weapon spread stays active." })
Main:AddButton({ Title = "Unload", Callback = State.Unload })
local Settings = Window:AddTab({ Title = "Settings" })
Settings:AddToggle("HideMyName", { Title = "Hide my name", Description = "Hides your name on this screen.", Default = true, Callback = function(value) State.HideMyName = value; State.ApplyHideName() end })
Settings:AddParagraph({ Title = "Game ID", Content = "Place: " .. game.PlaceId .. " | Universe: " .. game.GameId })
Settings:AddDropdown("UITheme", { Title = "Theme", Values = { "Dark", "Amethyst", "Light" }, Default = "Dark", Callback = function(value) Library:SetTheme(value) end })
Settings:AddToggle("UITransparent", { Title = "Transparent UI", Default = false, Callback = function(value) Library:ToggleTransparency(value) end })
Settings:AddSlider("UIMascotOpacity", { Title = "Background image opacity", Min = 0, Max = 100, Default = 50, Rounding = 0, Callback = function(value) Library:SetMascotTransparency(1 - value / 100) end })
Library.MinimizeKeybind = Settings:AddKeybind("UIMinimizeKey", { Title = "Show / hide UI key", Default = "RightControl", Mode = "Toggle" })
Settings:AddButton({ Title = "Minimize UI", Callback = function() Window:Minimize() end })
Settings:AddButton({ Title = "Unload", Callback = State.Unload })
State.Library = Library
Window:SelectTab(1)
Ballistics.Directions = redirected
Env.VaderAim46300 = State
Library:Notify({ Title = "Ready", Content = "Silent Aim + ESP loaded. Enable the switches in Combat.", Duration = 5 })
print("[VaderAim] loaded; self-check passed; Silent Aim and ESP are OFF")

