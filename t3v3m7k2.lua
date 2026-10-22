-- VaderUI controls with camera aim and character overlays.
-- Settings restore automatically; first-run defaults show ESP and FOV.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
if env.VaderAimESP then env.VaderAimESP() end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
local config = {aim=false, silent=false, autoHeal=false, healBelow=50, showFov=true, health=true, esp=true, team=true, visible=true, fov=120, speed=12, distance=1000, part="Head", walls=false, names=true, theme="Dark", hitbox=false, hitboxScale=2, hitboxPart="Head", hitboxShow=true}
local HttpService = game:GetService("HttpService")
local settingsPath = "VaderUI_settings_" .. tostring(game.GameId) .. ".json"
local memoryKey = "VaderSettings_" .. tostring(game.GameId)
local initializing, savePending, lastSaveError = true, false, nil
local bounds = {healBelow={1,100}, fov={20,500}, speed={1,30}, distance={50,3000}, hitboxScale={1,5}}
local function restoreSettings(data)
    if type(data) ~= "table" then return end
    for key, default in pairs(config) do
        local value = data[key]
        if type(value) == type(default) then
            if type(value) == "number" then
                if value == value and math.abs(value) < math.huge then
                    config[key] = math.clamp(value, bounds[key][1], bounds[key][2])
                end
            elseif key == "part" or key == "hitboxPart" then
                if value == "Head" or value == "HumanoidRootPart" then config[key] = value end
            elseif key == "theme" then
                if value == "Dark" or value == "Amethyst" or value == "Light" then config[key] = value end
            else
                config[key] = value
            end
        end
    end
end
restoreSettings(env[memoryKey])
if type(readfile) == "function" then
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(settingsPath)) end)
    if ok then restoreSettings(data) end
end
local function saveSettings()
    env[memoryKey] = table.clone(config)
    if type(writefile) ~= "function" then
        lastSaveError = "File saving unavailable; settings kept for this session only."
        return false
    end
    local ok, err = pcall(function() writefile(settingsPath, HttpService:JSONEncode(config)) end)
    lastSaveError = not ok and tostring(err) or nil
    return ok
end
local function updateSetting(key, value)
    config[key] = value
    if initializing then return end
    env[memoryKey] = table.clone(config)
    if savePending then return end
    savePending = true
    task.delay(0.4, function()
        savePending = false
        if not saveSettings() then warn("VaderUI: " .. lastSaveError) end
    end)
end
local connections, overlays = {}, {}
local aimRenderName = "VaderAimESP_" .. tostring(LocalPlayer.UserId)
local stopped = false
local folder = Instance.new("Folder")
folder.Name = "VaderCharacterOverlays"
folder.Parent = workspace

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "VaderFOV"
fovGui.IgnoreGuiInset = true
fovGui.ResetOnSpawn = false
fovGui.DisplayOrder = 10
fovGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
local fovCircle = Instance.new("Frame")
fovCircle.Name = "Radius"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Size = UDim2.fromOffset(config.fov*2, config.fov*2)
fovCircle.Parent = fovGui
local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(0.5, 0)
round.Parent = fovCircle
local outline = Instance.new("UIStroke")
outline.Thickness = 2
outline.Transparency = 0
outline.Color = Color3.fromRGB(190, 150, 255)
outline.Parent = fovCircle
local aimStatus = Instance.new("TextLabel")
aimStatus.Name = "AimStatus"
aimStatus.AnchorPoint = Vector2.new(0.5, 0)
aimStatus.Position = UDim2.new(0.5, 0, 1, 8)
aimStatus.Size = UDim2.fromOffset(300, 22)
aimStatus.BackgroundTransparency = 1
aimStatus.TextColor3 = Color3.new(1, 1, 1)
aimStatus.TextStrokeTransparency = 0.2
aimStatus.TextSize = 14
aimStatus.Parent = fovCircle

local function enemy(player)
    return player ~= LocalPlayer and (not config.team or LocalPlayer.Neutral or player.Neutral or player.Team ~= LocalPlayer.Team)
end

local function teammate(player)
    return player ~= LocalPlayer and not LocalPlayer.Neutral and not player.Neutral and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
end

local function espEligible(player)
    return player ~= LocalPlayer and not teammate(player)
end

local function alive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local hitboxOriginals = {}
local function restoreHitbox(part)
    local original = hitboxOriginals[part]
    if not original then return end
    pcall(function() part.Size = original.size end)
    original.box:Destroy()
    hitboxOriginals[part] = nil
end
local function restoreAllHitboxes()
    local parts = {}
    for part in pairs(hitboxOriginals) do table.insert(parts, part) end
    for _, part in ipairs(parts) do restoreHitbox(part) end
end
local function applyHitbox(part)
    local original = hitboxOriginals[part]
    if not original then
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "HitboxBounds"
        box.Adornee = part
        box.Color3 = Color3.fromRGB(255, 100, 100)
        box.Transparency = 0.7
        box.AlwaysOnTop = false
        box.ZIndex = 1
        box.Parent = folder
        original = {size=part.Size, box=box}
        hitboxOriginals[part] = original
    end
    part.Size = original.size * config.hitboxScale
    original.box.Size = part.Size
    original.box.Visible = config.hitboxShow
end
local function refreshHitboxes()
    local active = {}
    local camera = workspace.CurrentCamera
    if config.hitbox and camera then
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local part = character and character:FindFirstChild(config.hitboxPart)
            if enemy(player) and alive(character) and part and part:IsA("BasePart") and (part.Position-camera.CFrame.Position).Magnitude <= config.distance then
                applyHitbox(part)
                active[part] = true
            end
        end
    end
    local expired = {}
    for part in pairs(hitboxOriginals) do
        if not active[part] then table.insert(expired, part) end
    end
    for _, part in ipairs(expired) do restoreHitbox(part) end
end

local function removeOverlay(player)
    local overlay = overlays[player]
    if overlay then
        overlay.highlight:Destroy()
        overlay.label:Destroy()
        overlays[player] = nil
    end
end

local function getOverlay(player, character)
    local overlay = overlays[player]
    if overlay and overlay.character ~= character then removeOverlay(player); overlay = nil end
    if overlay then return overlay end
    local highlight = Instance.new("Highlight")
    highlight.Name = "CharacterHighlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 85, 110)
    highlight.FillTransparency = 0.65
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Enabled = false
    highlight.Parent = folder
    local label = Instance.new("BillboardGui")
    label.Name = "CharacterLabel"
    label.Size = UDim2.fromOffset(220, 60)
    label.StudsOffset = Vector3.new(0, 3, 0)
    label.Enabled = false
    label.Parent = folder
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 0, 22)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0.25
    text.TextSize = 14
    text.Font = Enum.Font.GothamMedium
    text.Parent = label
    local healthText = text:Clone()
    healthText.Name = "Health"
    healthText.Position = UDim2.fromOffset(0, 22)
    healthText.Parent = label
    local healthTrack = Instance.new("Frame")
    healthTrack.Name = "HealthBar"
    healthTrack.Position = UDim2.new(0.1, 0, 0, 48)
    healthTrack.Size = UDim2.new(0.8, 0, 0, 6)
    healthTrack.BorderSizePixel = 0
    healthTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    healthTrack.Parent = label
    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthTrack
    overlay = {character=character, highlight=highlight, label=label, text=text, healthText=healthText, healthTrack=healthTrack, healthFill=healthFill}
    overlays[player] = overlay
    return overlay
end

local function target(camera)
    local center = camera.ViewportSize / 2
    local best, bestDistance = nil, config.fov
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = LocalPlayer.Character and {LocalPlayer.Character, folder} or {folder}
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local part = character and character:FindFirstChild(config.part)
        if enemy(player) and alive(character) and part and part:IsA("BasePart") then
            local delta = part.Position - camera.CFrame.Position
            local screen, onScreen = camera:WorldToViewportPoint(part.Position)
            local screenDistance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
            if onScreen and delta.Magnitude <= config.distance and screenDistance < bestDistance then
                local hit = config.visible and workspace:Raycast(camera.CFrame.Position, delta, ray)
                if not hit or hit.Instance:IsDescendantOf(character) then
                    best, bestDistance = part, screenDistance
                end
            end
        end
    end
    return best
end

local bowContexts = setmetatable({}, {__mode="k"})
local function bowDirection(delta, speed, gravity)
    if speed <= 0 or delta.Magnitude < 0.001 then return nil end
    gravity = math.max(0, gravity)
    if gravity < 0.001 then return delta.Unit, delta.Magnitude/speed end
    -- Solve |delta + (0,g*t^2/2,0)|^2 = speed^2*t^2; take the low arc.
    local a = speed*speed-gravity*delta.Y
    local discriminant = a*a-gravity*gravity*delta:Dot(delta)
    if discriminant < 0 or a <= 0 then return nil end
    local timeSquared = 2*delta:Dot(delta)/(a+math.sqrt(discriminant))
    local time = math.sqrt(timeSquared)
    if time <= 0 or time > 5 then return nil end
    return (delta+Vector3.new(0,0.5*gravity*timeSquared,0)).Unit, time
end
local function woodBowContext()
    local shot = bowContexts[coroutine.running()]
    return config.silent and shot and shot.wood and shot or nil
end
local silentModule, silentOriginal, silentWrapper
local silentError
local function makeSilentWrapper(original)
    return function(origin, direction, horizontalOnly, ...)
        -- Bow and Throw also pass true here; it is not a melee flag.
        if not stopped and config.silent and typeof(origin) == "Vector3" and alive(LocalPlayer.Character) and not Input:GetFocusedTextBox() then
            local camera = workspace.CurrentCamera
            local part = camera and target(camera)
            if part then
                local delta = part.Position-origin
                if delta.Magnitude > 0.001 then
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {LocalPlayer.Character, folder}
                    local hit = config.visible and workspace:Raycast(origin, delta, params)
                    if not hit or hit.Instance:IsDescendantOf(part.Parent) then
                        local shot = woodBowContext()
                        if shot then
                            if not shot.speed or delta.Magnitude > shot.range then
                                return original(origin, direction, horizontalOnly, ...)
                            end
                            local compensated = bowDirection(delta, shot.speed, shot.gravity)
                            if compensated then return compensated end
                            return original(origin, direction, horizontalOnly, ...)
                        end
                        return delta.Unit
                    end
                end
            end
        end
        return original(origin, direction, horizontalOnly, ...)
    end
end
local function removeSilent()
    if silentModule and silentModule.AssistDirection == silentWrapper then
        pcall(function() silentModule.AssistDirection = silentOriginal end)
    end
    silentModule, silentOriginal, silentWrapper = nil, nil, nil
end
local function installSilent()
    if silentModule then return true end
    local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local combat = scripts and scripts:FindFirstChild("Combat")
    local module = combat and combat:FindFirstChild("Util")
    if not module then silentError = "Combat.Util not available in this game"; return false end
    local ok, util = pcall(require, module)
    if stopped or not config.silent then return false end
    if not ok or type(util) ~= "table" or type(util.AssistDirection) ~= "function" then
        silentError = "Weapon direction module could not be loaded"
        return false
    end
    local original = util.AssistDirection
    local wrapper = makeSilentWrapper(original)
    local assigned, err = pcall(function() util.AssistDirection = wrapper end)
    if not assigned then silentError = tostring(err); return false end
    silentModule, silentOriginal, silentWrapper = util, original, wrapper
    silentError = nil
    return true
end

local bowModule, bowFireOriginal, bowChargeOriginal, bowFireWrapper, bowChargeWrapper
local function makeBowFireWrapper(original)
    return function(self, ...)
        local thread = coroutine.running()
        local previous = bowContexts[thread]
        local tuning = self.tuning or {}
        bowContexts[thread] = {
            wood=self.ctx and self.ctx.weaponId == "short_bow",
            tuning=tuning, gravity=tuning.gravity or 60, range=tuning.range or 400
        }
        local result = table.pack(pcall(original, self, ...))
        bowContexts[thread] = previous
        if not result[1] then error(result[2], 0) end
        return table.unpack(result, 2, result.n)
    end
end
local function makeBowChargeWrapper(original)
    return function(self, ...)
        local result = table.pack(original(self, ...))
        local shot = bowContexts[coroutine.running()]
        if shot and shot.wood and type(result[1]) == "number" then
            local tuning = shot.tuning
            local minimum = tuning.speedMin or tuning.speed or 100
            local maximum = tuning.speedMax or tuning.speed or minimum
            shot.speed = minimum+(maximum-minimum)*math.clamp(result[1], 0, 1)
        end
        return table.unpack(result, 1, result.n)
    end
end
local function removeBowComp()
    if bowModule then
        if bowModule.Fire == bowFireWrapper then pcall(function() bowModule.Fire=bowFireOriginal end) end
        if bowModule.Charge == bowChargeWrapper then pcall(function() bowModule.Charge=bowChargeOriginal end) end
    end
    bowModule, bowFireOriginal, bowChargeOriginal, bowFireWrapper, bowChargeWrapper = nil,nil,nil,nil,nil
end
local function installBowComp()
    if bowModule or not config.silent then return true end
    local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local combat = scripts and scripts:FindFirstChild("Combat")
    local handlers = combat and combat:FindFirstChild("Handlers")
    local module = handlers and handlers:FindFirstChild("Bow")
    if not module then return false, "Bow handler unavailable" end
    local ok, bow = pcall(require, module)
    if stopped then return false, "Unloaded" end
    if not ok or type(bow) ~= "table" or type(bow.Fire) ~= "function" or type(bow.Charge) ~= "function" then return false, "Bow handler unsupported" end
    local fire, charge = bow.Fire, bow.Charge
    local fireWrapper, chargeWrapper = makeBowFireWrapper(fire), makeBowChargeWrapper(charge)
    local assigned, err = pcall(function() bow.Fire=fireWrapper; bow.Charge=chargeWrapper end)
    if not assigned then
        pcall(function() if bow.Fire==fireWrapper then bow.Fire=fire end end)
        return false, tostring(err)
    end
    bowModule, bowFireOriginal, bowChargeOriginal, bowFireWrapper, bowChargeWrapper = bow,fire,charge,fireWrapper,chargeWrapper
    return true
end

local healController, healCombatState
local healSession, healNextAttempt = nil, 0
local function needsHealing(health, maximum, threshold)
    return maximum > 0 and health > 0 and health/maximum*100 < threshold and health < maximum-0.5
end
local function initializeHealing()
    if healController and healCombatState then return true end
    local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local combat = scripts and scripts:FindFirstChild("Combat")
    local module = combat and combat:FindFirstChild("Controller")
    local getter = debug.getupvalues or getupvalues
    if not module or type(getter) ~= "function" then return false, "Heal controller unavailable" end
    local ok, controller = pcall(require, module)
    if not ok or type(controller) ~= "table" or type(controller.Equip) ~= "function" then return false, "Heal controller unsupported" end
    local read, values = pcall(getter, controller.Equip)
    if read then
        for _, value in pairs(values) do
            if type(value) == "table" and rawget(value,"pressed") and rawget(value,"speed") and rawget(value,"conns") then
                healController, healCombatState = controller, value
                return true
            end
        end
    end
    return false, "Equipped item state unavailable"
end
local function finishHealing(cancel, restore)
    local session = healSession
    healSession = nil
    if not session then return end
    local handler = healCombatState and healCombatState.handler
    if cancel and handler and handler.ctx and handler.ctx.tool == session.tool and handler.using then
        pcall(function() handler:Cancel() end)
    end
    if restore and LocalPlayer.Character == session.character and alive(session.character) and healController.Wanted() == session.tool then
        local previous = session.previous
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if previous and previous.Parent and (previous.Parent == backpack or previous.Parent == session.character) then
            pcall(healController.Equip, previous)
        end
    end
end
local function updateAutoHeal(now)
    if stopped or not config.autoHeal then return end
    if not healController or not healCombatState then return end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then finishHealing(true, false); return end
    if healSession then
        local session = healSession
        if session.character ~= character or not session.tool.Parent then finishHealing(true, false); return end
        -- Respect a manual weapon switch instead of forcing the healing item back.
        if healController.Wanted() ~= session.tool then finishHealing(false, false); return end
        local handler = healCombatState.handler
        if session.phase == "repeat" then
            local charges = session.tool:GetAttribute("Charges")
            if not needsHealing(humanoid.Health, humanoid.MaxHealth, config.healBelow) or type(charges) ~= "number" or charges < 1 then
                finishHealing(false, true)
                return
            end
            if now < healNextAttempt then return end
            session.phase = "equip"
            session.deadline = now+1
        end
        if session.phase == "equip" then
            if now > session.deadline then finishHealing(true, true); return end
            local state = healController.State()
            if state.equipPending or not handler or not handler.ctx or handler.ctx.tool ~= session.tool then return end
            if not needsHealing(humanoid.Health, humanoid.MaxHealth, config.healBelow) then finishHealing(false, true); return end
            if handler.kind ~= "Herbs" or type(handler.Activate) ~= "function" then finishHealing(false, true); return end
            local charges = session.tool:GetAttribute("Charges")
            if type(charges) ~= "number" or charges < 1 then finishHealing(false, true); return end
            local ok = pcall(function() handler:Activate() end)
            if not ok or not handler.using then finishHealing(false, true); return end
            session.phase = "use"
            session.deadline = now+(handler.tuning.useTime or 0.7)+1
            session.doneAfter = now+(handler.tuning.useTime or 0.7)+0.05
            healNextAttempt = now+(handler.tuning.useTime or 0.7)+(handler.tuning.healTime or 0)+0.15
        elseif not handler or not handler.ctx or handler.ctx.tool ~= session.tool then
            finishHealing(false, false)
        elseif now > session.deadline then
            finishHealing(true, true)
        elseif not handler.using and now >= session.doneAfter then
            local charges = session.tool:GetAttribute("Charges")
            if needsHealing(humanoid.Health, humanoid.MaxHealth, config.healBelow) and type(charges) == "number" and charges > 0 then
                session.phase = "repeat"
            else
                finishHealing(false, true)
            end
        end
        return
    end
    if now < healNextAttempt or Input:GetFocusedTextBox() then return end
    if not needsHealing(humanoid.Health, humanoid.MaxHealth, config.healBelow) then return end
    if healCombatState.char ~= character or healController.State().equipPending then return end
    local mode = LocalPlayer:GetAttribute("CombatMode")
    if mode == false or (mode == nil and LocalPlayer:GetAttribute("State") ~= "Match") then return end
    local tool
    local containers = {character}
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then table.insert(containers, backpack) end
    for _, parent in ipairs(containers) do
        for _, item in ipairs(parent:GetChildren()) do
            local charges = item:GetAttribute("Charges")
            if item:IsA("Tool") and item:GetAttribute("WeaponId") == "bandage" and type(charges) == "number" and charges > 0 then
                tool = item
                break
            end
        end
        if tool then break end
    end
    if not tool then return end
    healNextAttempt = now+2
    healSession = {character=character,tool=tool,previous=healController.Wanted(),phase="equip",deadline=now+4}
    local ok, equipped = pcall(healController.Equip, tool)
    if not ok or not equipped then finishHealing(false, false) end
end

local function cleanup()
    if stopped then return end
    saveSettings()
    stopped = true
    finishHealing(true, true)
    removeSilent()
    removeBowComp()
    RunService:UnbindFromRenderStep(aimRenderName)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    restoreAllHitboxes()
    folder:Destroy()
    fovGui:Destroy()
    table.clear(overlays)
    Library:Destroy()
    if env.VaderAimESP == cleanup then env.VaderAimESP = nil end
end
env.VaderAimESP = cleanup

local Window = Library:CreateWindow({Title="VaderUI", SubTitle="Aim & ESP", Size=UDim2.fromOffset(600, 460), TabWidth=180, Theme=config.theme, MinimizeKey=Enum.KeyCode.RightControl})
local Aim = Window:AddTab({Title="Aimbot"})
local ESP = Window:AddTab({Title="ESP"})
local Hitbox = Window:AddTab({Title="Hitbox"})
local Healing = Window:AddTab({Title="Auto Heal"})
local Settings = Window:AddTab({Title="Settings"})
Aim:AddParagraph({Title="Quick Start", Content="Enable Silent Aim. Wood Bow drop compensation is automatic; draw and release with a target in FOV."})
Aim:AddToggle("AimEnabled", {Title="Aimbot", Description="Hold right mouse to move the camera toward a target.", Default=config.aim, Callback=function(v) updateSetting("aim", v) end})
Aim:AddToggle("SilentAim", {Title="Silent Aim", Description="Redirect shots within FOV. Automatically compensates Wood Bow drop using draw charge.", Default=config.silent, Callback=function(v)
    updateSetting("silent", v)
    if initializing then return end
    if not v then removeSilent(); removeBowComp(); return end
    if not installSilent() and silentError then
        Library:Notify({Title="Silent aim unavailable", Content=silentError, Duration=6})
    end
    local ok, err = installBowComp()
    if not ok then Library:Notify({Title="Wood Bow compensation unavailable", Content=err, Duration=6}) end
end})
Aim:AddToggle("ShowFOV", {Title="Show FOV", Description="Display the target selection circle.", Default=config.showFov, Callback=function(v) updateSetting("showFov", v) end})
Aim:AddToggle("VisibleOnly", {Title="Visibility Check", Description="Skip targets blocked by walls.", Default=config.visible, Callback=function(v) updateSetting("visible", v) end})
Aim:AddDropdown("AimPart", {Title="Target Part", Description="Choose Head or HumanoidRootPart.", Values={"Head", "HumanoidRootPart"}, Default=config.part, Callback=function(v) updateSetting("part", v) end})
Aim:AddSlider("AimFOV", {Title="FOV Radius", Description="Target selection radius in pixels.", Min=20, Max=500, Default=config.fov, Rounding=0, Callback=function(v) updateSetting("fov", v) end})
Aim:AddSlider("AimSpeed", {Title="Aim Response", Description="Higher values move the camera faster.", Min=1, Max=30, Default=config.speed, Rounding=0, Callback=function(v) updateSetting("speed", v) end})
ESP:AddToggle("ESPEnabled", {Title="Enemy ESP", Description="Highlight opponents only.", Default=config.esp, Callback=function(v) updateSetting("esp", v) end})
ESP:AddToggle("ESPHealth", {Title="Enemy Health", Description="Show current health and a health bar.", Default=config.health, Callback=function(v) updateSetting("health", v) end})
ESP:AddToggle("ESPNames", {Title="Names and Distance", Description="Show player names and distance in studs.", Default=config.names, Callback=function(v) updateSetting("names", v) end})
ESP:AddToggle("ESPThroughWalls", {Title="ESP Through Walls", Description="Keep enemy overlays visible behind walls.", Default=config.walls, Callback=function(v) updateSetting("walls", v) end})
Hitbox:AddParagraph({Title="Local Hitbox", Content="Client-side size changes may not match server hit detection."})
Hitbox:AddToggle("HitboxEnabled", {Title="Hitbox", Description="Enlarge the selected part locally.", Default=config.hitbox, Callback=function(v)
    updateSetting("hitbox", v)
    if not v then restoreAllHitboxes() end
end})
Hitbox:AddDropdown("HitboxPart", {Title="Hitbox Part", Description="Choose which body part to enlarge.", Values={"Head", "HumanoidRootPart"}, Default=config.hitboxPart, Callback=function(v)
    restoreAllHitboxes()
    updateSetting("hitboxPart", v)
end})
Hitbox:AddSlider("HitboxScale", {Title="Hitbox Scale", Description="Multiply the original part size by 1–5.", Min=1, Max=5, Default=config.hitboxScale, Rounding=1, Callback=function(v) updateSetting("hitboxScale", v) end})
Hitbox:AddToggle("HitboxShow", {Title="Show Hitbox", Description="Display the enlarged hitbox bounds.", Default=config.hitboxShow, Callback=function(v) updateSetting("hitboxShow", v) end})
Settings:AddToggle("TeamCheck", {Title="Aim Team Check", Description="Exclude teammates from aim and hitbox targeting.", Default=config.team, Callback=function(v) updateSetting("team", v) end})
Healing:AddToggle("AutoHeal", {Title="Auto Heal", Description="Chain Bandages while health is low, then restore your weapon. Uses normal healing time.", Default=config.autoHeal, Callback=function(v)
    updateSetting("autoHeal", v)
    if initializing then return end
    if not v then finishHealing(true, true); return end
    local ok, err = initializeHealing()
    if not ok then Library:Notify({Title="Auto heal unavailable", Content=err, Duration=6}) end
end})
Healing:AddSlider("HealBelow", {Title="Heal Below (%)", Description="Heal when your health is below this percentage. Uses Bandage charges.", Min=1, Max=100, Default=config.healBelow, Rounding=0, Callback=function(v) updateSetting("healBelow", v) end})
Settings:AddSlider("MaxDistance", {Title="Maximum Distance", Description="Limit targeting and overlays by distance in studs.", Min=50, Max=3000, Default=config.distance, Rounding=0, Callback=function(v) updateSetting("distance", v) end})
Settings:AddDropdown("Theme", {Title="Theme", Description="Change the interface colors.", Values={"Dark", "Amethyst", "Light"}, Default=config.theme, Callback=function(v) Library:SetTheme(v); updateSetting("theme", v) end})
Settings:AddButton({Title="Unload", Description="Restore changes and close the interface.", Callback=cleanup})
Settings:AddButton({Title="Save settings now", Description="Save all current settings.", Callback=function()
    local ok = saveSettings()
    Library:Notify({Title="Settings", Content=ok and "Settings saved" or lastSaveError, Duration=4})
end})

table.insert(connections, Players.PlayerRemoving:Connect(removeOverlay))
local hitboxElapsed = 0
local healElapsed = 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
    if stopped then return end
    healElapsed = healElapsed+dt
    if healElapsed >= 0.05 then
        healElapsed = 0
        updateAutoHeal(os.clock())
    end
    hitboxElapsed = hitboxElapsed + dt
    if hitboxElapsed < 0.1 then return end
    hitboxElapsed = 0
    refreshHitboxes()
end))
table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    if stopped then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    fovCircle.Position = UDim2.fromOffset(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    fovCircle.Size = UDim2.fromOffset(config.fov*2, config.fov*2)
    fovCircle.Visible = config.showFov
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local distance = root and (root.Position - camera.CFrame.Position).Magnitude or math.huge
        local show = config.esp and espEligible(player) and alive(character) and distance <= config.distance
        if show then
            local overlay = getOverlay(player, character)
            local teamColor = Color3.fromRGB(255, 85, 110)
            overlay.highlight.FillColor = teamColor
            overlay.text.TextColor3 = teamColor
            overlay.highlight.Enabled = true
            overlay.highlight.DepthMode = config.walls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            overlay.label.Adornee = character:FindFirstChild("Head") or root
            overlay.label.AlwaysOnTop = config.walls
            overlay.label.MaxDistance = config.distance
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local health = math.max(0, humanoid.Health)
            local maximum = math.max(0, humanoid.MaxHealth)
            local ratio = maximum > 0 and math.clamp(health/maximum, 0, 1) or 0
            local color = Color3.fromRGB(255, 65, 65):Lerp(Color3.fromRGB(65, 235, 100), ratio)
            -- Health remains enemy-only even if teammate filtering is disabled.
            local showHealth = config.health
            overlay.label.Enabled = config.names or showHealth
            overlay.text.Visible = config.names
            overlay.text.Text = string.format("%s | %d studs", player.DisplayName, distance)
            overlay.healthText.Visible = showHealth
            overlay.healthText.Text = string.format("HP %.0f / %.0f", health, maximum)
            overlay.healthText.TextColor3 = color
            overlay.healthTrack.Visible = showHealth
            overlay.healthFill.Size = UDim2.fromScale(ratio, 1)
            overlay.healthFill.BackgroundColor3 = color
        elseif overlays[player] then
            overlays[player].highlight.Enabled = false
            overlays[player].label.Enabled = false
        end
    end
end))

local function updateAim(dt)
    if stopped then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    if not config.aim then
        if config.silent then
            if not silentModule then aimStatus.Text = "Silent aim unavailable: see notification"
            else aimStatus.Text = target(camera) and "Silent aim: target in FOV" or "Silent aim: no eligible target in FOV" end
        else aimStatus.Text = "Aim disabled" end
        return
    end
    if not alive(LocalPlayer.Character) then aimStatus.Text = "Waiting for character"; return end
    if Input:GetFocusedTextBox() then aimStatus.Text = "Paused while typing"; return end
    if not Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then aimStatus.Text = "Hold right mouse to aim"; return end
    local response = config.speed
    local part = target(camera)
    if not part then aimStatus.Text = "No eligible target: check FOV / team / visibility"; return end
    if (part.Position-camera.CFrame.Position).Magnitude <= 0.001 then return end
    camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, part.Position), 1-math.exp(-response*dt))
    aimStatus.Text = "Aimbot active"
end
-- Apply after camera and character updates so the usual camera step cannot overwrite it.
RunService:BindToRenderStep(aimRenderName, Enum.RenderPriority.Last.Value + 1, updateAim)
initializing = false
if config.autoHeal then
    local ok, err = initializeHealing()
    if not ok then Library:Notify({Title="Auto heal unavailable", Content=err, Duration=6}) end
end
if config.silent and not installSilent() and silentError then
    Library:Notify({Title="Silent aim unavailable", Content=silentError, Duration=6})
end
do
    local ok, err = installBowComp()
    if not ok then Library:Notify({Title="Wood Bow compensation unavailable", Content=err, Duration=6}) end
end
Window:SelectTab(1)
Library:Notify({Title="VaderUI", Content="Settings loaded; changes save automatically", SubContent=type(writefile) == "function" and "Settings saved per game on this device." or "File saving unavailable; session memory only.", Duration=5})