--// ============================================================
--//  Vader Script  |  Deep Fishing
--//  UI: VaderUI  •  Show / hide: RightControl or the logo button
--//  Settings save to Vaderhug/DeepFishing/<player>.json
--// ============================================================

-- Make sure this is Deep Fishing and the game has finished loading before building the UI
do
    local Boot = getgenv()
    -- a re-run removes the old UI right away and takes over from any run still starting
    local Token = {}
    Boot.VaderFishBoot = Token
    local setIdentity = setthreadidentity or set_thread_identity or setidentity
    if type(Boot.VaderUI_Instance) == "table" and Boot.VaderUI_Instance.Destroy then
        pcall(Boot.VaderUI_Instance.Destroy, Boot.VaderUI_Instance)
    end
    -- also by name: an old copy whose reference was lost (other version, other loader env, or an unload that ran
    -- without the rights to touch CoreGui) still goes away
    if setIdentity then
        pcall(setIdentity, 8)
    end
    local function sweep(parent)
        for _, g in ipairs(parent:GetDescendants()) do
            if g:IsA("ScreenGui") and g.Name == "VaderUI" then
                pcall(g.Destroy, g)
            end
        end
    end
    pcall(function() sweep(game:GetService("CoreGui")) end)
    pcall(function() sweep(game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")) end)
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local waited = 0
    local ok = false
    while not ok and waited < 25 do
        local events = ReplicatedStorage:FindFirstChild("Events")
        local remotes = events and events:FindFirstChild("RemoteEvents")
        ok = ReplicatedStorage:FindFirstChild("Shared") ~= nil and remotes ~= nil and remotes:FindFirstChild("ThrowRod") ~= nil and remotes:FindFirstChild("FishHooked") ~= nil
        if not ok then
            waited += task.wait(0.5) or 0.5
        end
    end
    if not ok then
        warn("[Vader] This is not Deep Fishing, the UI was not started")
        return
    end
    -- The game's client sets ClientLoaded once the save is loaded and every controller started.
    waited = 0
    while workspace:GetAttribute("ClientLoaded") ~= true and waited < 60 do
        waited += task.wait(0.25) or 0.25
    end
    LocalPlayer:WaitForChild("PlayerGui", 20)
    task.wait(0.5)
    if Boot.VaderFishBoot ~= Token then
        return
    end
end

local function CreateVaderUI()


local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Env = (getgenv and getgenv()) or _G

if type(Env.VaderUI_Instance) == "table" and Env.VaderUI_Instance.Destroy then
    pcall(Env.VaderUI_Instance.Destroy, Env.VaderUI_Instance)
end

local DefaultLogo = "https://github.com/DONUT6599/ddgdhdf/blob/main/Asset_1.png?raw=true"
local DefaultMascot = "https://github.com/DONUT6599/ddgdhdf/blob/main/%E0%B9%84%E0%B8%A1%E0%B9%88%E0%B8%A1%E0%B8%B5%E0%B8%8A%E0%B8%B7%E0%B9%88%E0%B8%AD%20114_20260915013214.png?raw=true"

local Palettes = {
    Dark = {
        Window = Color3.fromRGB(14, 12, 20),
        Work = Color3.fromRGB(22, 19, 31),
        Card = Color3.fromRGB(31, 27, 44),
        CardHover = Color3.fromRGB(40, 35, 58),
        Stroke = Color3.fromRGB(54, 46, 78),
        Field = Color3.fromRGB(17, 14, 25),
        Text = Color3.fromRGB(240, 236, 250),
        SubText = Color3.fromRGB(160, 152, 184),
        Accent = Color3.fromRGB(132, 88, 240),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(62, 55, 84),
    },
    Amethyst = {
        Window = Color3.fromRGB(30, 18, 56),
        Work = Color3.fromRGB(40, 25, 72),
        Card = Color3.fromRGB(54, 36, 94),
        CardHover = Color3.fromRGB(66, 45, 112),
        Stroke = Color3.fromRGB(88, 64, 142),
        Field = Color3.fromRGB(28, 17, 52),
        Text = Color3.fromRGB(244, 240, 255),
        SubText = Color3.fromRGB(190, 176, 224),
        Accent = Color3.fromRGB(168, 128, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(82, 62, 128),
    },
    Light = {
        Window = Color3.fromRGB(236, 232, 245),
        Work = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(245, 242, 251),
        CardHover = Color3.fromRGB(236, 231, 247),
        Stroke = Color3.fromRGB(220, 213, 238),
        Field = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(24, 18, 38),
        SubText = Color3.fromRGB(105, 96, 128),
        Accent = Color3.fromRGB(112, 68, 224),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(205, 198, 222),
    },
}

local Library = {
    Version = "1.0.0",
    Options = {},
    Themes = { "Dark", "Amethyst", "Light" },
    Theme = "Dark",
    Unloaded = false,
    UseAcrylic = false,
    MascotTransparency = 0.5,
    MinimizeKey = Enum.KeyCode.RightControl,
    MinimizeKeybind = nil,
    Logo = nil,
    Window = nil,
    GUI = nil,
    Connections = {},
}

local Theme = Palettes.Dark
local Registry = {}   -- { instance, { Property = "ThemeKey" } }
local Refreshers = {} -- repaint functions for state-dependent colours

local function Bind(Inst, Map)
    table.insert(Registry, { Inst, Map })
    for Property, Key in pairs(Map) do
        Inst[Property] = Theme[Key]
    end
end

local function New(Class, Props, Children)
    local Inst = Instance.new(Class)
    if Inst:IsA("GuiObject") then
        Inst.BorderSizePixel = 0
    end
    if Inst:IsA("GuiButton") then
        Inst.AutoButtonColor = false
    end
    if Props then
        for Key, Value in pairs(Props) do
            if Key ~= "Parent" and Key ~= "Theme" then
                Inst[Key] = Value
            end
        end
        if Props.Theme then
            Bind(Inst, Props.Theme)
        end
    end
    if Children then
        for _, Child in ipairs(Children) do
            Child.Parent = Inst
        end
    end
    if Props and Props.Parent then
        Inst.Parent = Props.Parent
    end
    return Inst
end

local function Corner(Radius)
    return New("UICorner", { CornerRadius = UDim.new(0, Radius) })
end

local function Tween(Inst, Time, Props, Style)
    local Info = TweenInfo.new(Time, Style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local Created = TweenService:Create(Inst, Info, Props)
    Created:Play()
    return Created
end

local function Track(Connection)
    table.insert(Library.Connections, Connection)
    return Connection
end

local function IsPress(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
    return Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch
end

local function ResolveImage(Source, CacheName)
    if type(Source) == "number" then
        return "rbxassetid://" .. Source
    end
    if type(Source) ~= "string" or Source == "" then
        return nil
    end
    if Source:match("^rbx") then
        return Source
    end
    if tonumber(Source) then
        return "rbxassetid://" .. Source
    end

    local GetAsset = getcustomasset or getsynasset
    if GetAsset == nil or isfile == nil then
        return nil
    end

    local Path = Source
    if Source:match("^https?://") then
        Path = CacheName
        if not isfile(Path) then
            local ok, Data = pcall(game.HttpGet, game, Source)
            if not ok or writefile == nil then
                return nil
            end
            writefile(Path, Data)
        end
    elseif not isfile(Path) then
        return nil
    end

    local ok, Asset = pcall(GetAsset, Path)
    return ok and Asset or nil
end

local function GetGuiParent()
    if gethui then
        local ok, Hui = pcall(gethui)
        if ok and Hui then
            return Hui
        end
    end
    local ok, CoreGui = pcall(function()
        local Service = game:GetService("CoreGui")
        local _ = Service.Name
        return Service
    end)
    if ok and CoreGui then
        return CoreGui
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function EnsureGui()
    if Library.GUI then
        return Library.GUI
    end
    local Gui = New("ScreenGui", {
        Name = "VaderUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    Gui.Parent = GetGuiParent()
    Library.GUI = Gui

    Library.NotifyHolder = New("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 300, 1, -32),
        ZIndex = 100,
        Parent = Gui,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    return Gui
end

-- A logo image, or a drawn "V" badge when no image can be resolved
local function MakeLogo(Parent, Size, Props)
    local Image = Library.LogoImage
    local Inst
    if Image then
        Inst = New("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(Size, Size),
            Image = Image,
            ScaleType = Enum.ScaleType.Fit,
        })
    else
        Inst = New("TextLabel", {
            Size = UDim2.fromOffset(Size, Size),
            Font = Enum.Font.GothamBold,
            Text = "V",
            TextSize = math.floor(Size * 0.6),
            Theme = { BackgroundColor3 = "Accent", TextColor3 = "AccentText" },
        }, { Corner(math.floor(Size / 4)) })
    end
    for Key, Value in pairs(Props or {}) do
        Inst[Key] = Value
    end
    Inst.Parent = Parent
    return Inst
end

function Library:SafeCallback(Callback, ...)
    if type(Callback) ~= "function" then
        return
    end
    local ok, Problem = pcall(Callback, ...)
    if not ok then
        warn("[VaderUI] callback error: " .. tostring(Problem))
    end
end

function Library:SetTheme(Name)
    if Palettes[Name] == nil then
        Name = "Dark"
    end
    self.Theme = Name
    Theme = Palettes[Name]
    for _, Entry in ipairs(Registry) do
        for Property, Key in pairs(Entry[2]) do
            pcall(function()
                Entry[1][Property] = Theme[Key]
            end)
        end
    end
    for _, Refresh in ipairs(Refreshers) do
        pcall(Refresh)
    end
end

function Library:ToggleAcrylic() end

function Library:ToggleTransparency(Value)
    self.Transparent = Value and true or false
    if self.Window then
        self.Window.Main.BackgroundTransparency = self.Transparent and 0.12 or 0
    end
end

-- 0 is solid, 1 hides her; remembered in VaderUI_mascot_alpha.txt
function Library:SetMascotTransparency(Value)
    Value = math.clamp(tonumber(Value) or 0.5, 0, 1)
    self.MascotTransparency = Value
    if self.Window and self.Window.Mascot then
        self.Window.Mascot.ImageTransparency = Value
    end
    if writefile then
        pcall(writefile, "VaderUI_mascot_alpha.txt", tostring(Value))
    end
end

function Library:Notify(Config)
    Config = Config or {}
    EnsureGui()

    self.NotifyCount = (self.NotifyCount or 0) + 1
    local Card = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        GroupTransparency = 1,
        LayoutOrder = self.NotifyCount,
        Parent = self.NotifyHolder,
    }, {
        Corner(12),
        New("UIStroke", { Color = Theme.Stroke }),
        New("UIPadding", {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        }),
    })
    MakeLogo(Card, 30)

    local Texts = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -40, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Card,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    for Order, Line in ipairs({
        { Config.Title, Enum.Font.GothamBold, 13, Theme.Text },
        { Config.Content, Enum.Font.Gotham, 12, Theme.Text },
        { Config.SubContent, Enum.Font.Gotham, 12, Theme.SubText },
    }) do
        if Line[1] ~= nil and tostring(Line[1]) ~= "" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Line[2],
                Text = tostring(Line[1]),
                TextSize = Line[3],
                TextColor3 = Line[4],
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = Order,
                Parent = Texts,
            })
        end
    end

    Tween(Card, 0.25, { GroupTransparency = 0 })

    local Notification = { Closed = false }
    function Notification:Close()
        if self.Closed then
            return
        end
        self.Closed = true
        Tween(Card, 0.25, { GroupTransparency = 1 })
        task.delay(0.3, function()
            Card:Destroy()
        end)
    end

    task.delay(Config.Duration or 5, function()
        Notification:Close()
    end)
    return Notification
end

function Library:Destroy()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    for _, Connection in ipairs(self.Connections) do
        pcall(Connection.Disconnect, Connection)
    end
    if self.GUI then
        self.GUI:Destroy()
    end
    if Env.VaderUI_Instance == self then
        Env.VaderUI_Instance = nil
    end
end

function Library:CreateWindow(Config)
    Config = Config or {}

    local Gui = EnsureGui()
    self.MinimizeKey = Config.MinimizeKey or self.MinimizeKey
    self.LogoImage = ResolveImage(Config.Logo or self.Logo or Env.VaderUI_Logo or DefaultLogo, "VaderUI_logo.png")
    local MascotImage
    if Config.Mascot ~= false then
        MascotImage = ResolveImage(Config.Mascot or self.Mascot or DefaultMascot, "VaderUI_mascot.png")
    end
    if Palettes[Config.Theme] then
        self.Theme = Config.Theme
        Theme = Palettes[Config.Theme]
    end

    local Requested = Config.Size or UDim2.fromOffset(600, 460)
    local Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local Width = math.clamp(Requested.X.Offset, 520, math.max(520, Viewport.X - 20))
    local Height = math.clamp(Requested.Y.Offset, 380, math.max(380, Viewport.Y - 20))
    local SideWidth = math.max(Config.TabWidth or 180, 180)

    local Window = { Tabs = {}, Minimized = false, Zoomed = false }
    self.Window = Window

    local Holder = New("Frame", {
        Name = "Window",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1.5, Height),
        Size = UDim2.fromOffset(Width, Height),
        Parent = Gui,
    })

    New("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1.2, 1.2),
        Image = "rbxassetid://313486536",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.35,
        Parent = Holder,
    })

    local Main = New("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
        Theme = { BackgroundColor3 = "Window" },
        Parent = Holder,
    }, {
        Corner(14),
        New("UIStroke", { Theme = { Color = "Stroke" } }),
    })
    Window.Main = Main
    Window.Root = Holder

    --------------------------- [[ Dragging ]] ---------------------------

    local ShownPosition = UDim2.fromScale(0.5, 0.5)
    local Drag = { Active = false }

    local function HookDrag(Handle)
        Handle.InputBegan:Connect(function(Input)
            if not IsPress(Input) or Window.Minimized then
                return
            end
            Drag.Active, Drag.Start, Drag.Origin = true, Input.Position, Holder.Position
        end)
    end

    -- ends here rather than on the input object: mouse input objects are reused, so a
    -- listener left on one would later save the minimized, off-screen spot as "shown"
    Track(UserInputService.InputEnded:Connect(function(Input)
        if Drag.Active and IsPress(Input) then
            Drag.Active = false
            if not Window.Minimized then
                ShownPosition = Holder.Position
            end
        end
    end))

    Track(UserInputService.InputChanged:Connect(function(Input)
        if Drag.Active and IsMove(Input) then
            local Delta = Input.Position - Drag.Start
            Holder.Position = UDim2.new(
                Drag.Origin.X.Scale, Drag.Origin.X.Offset + Delta.X,
                Drag.Origin.Y.Scale, Drag.Origin.Y.Offset + Delta.Y
            )
        end
    end))

    --------------------------- [[ Work Area ]] ---------------------------

    local Work = New("Frame", {
        Name = "Work",
        Position = UDim2.fromOffset(SideWidth, 0),
        Size = UDim2.new(1, -SideWidth, 1, 0),
        Theme = { BackgroundColor3 = "Work" },
        Parent = Main,
    }, { Corner(14) })

    -- squares off the work area's left corners where it meets the sidebar
    New("Frame", {
        Size = UDim2.new(0, 14, 1, 0),
        Theme = { BackgroundColor3 = "Work" },
        Parent = Work,
    })

    -- cards go part see-through so the mascot reads behind them
    local CardAlpha = MascotImage and 0.3 or 0
    if MascotImage then
        -- explicit config wins, then the remembered setting, then the default
        local Saved
        if isfile and readfile and isfile("VaderUI_mascot_alpha.txt") then
            local ok, Text = pcall(readfile, "VaderUI_mascot_alpha.txt")
            Saved = ok and tonumber(Text) or nil
        end
        self.MascotTransparency = math.clamp(Config.MascotTransparency or Saved or self.MascotTransparency, 0, 1)

        Window.Mascot = New("ImageLabel", {
            Name = "Mascot",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -4, 1, 0),
            Size = UDim2.new(1, -8, 1, -8),
            Image = MascotImage,
            ImageTransparency = self.MascotTransparency,
            ScaleType = Enum.ScaleType.Fit,
            Parent = Work,
        }, {
            New("UIAspectRatioConstraint", {
                AspectRatio = 1462 / 2000,
                DominantAxis = Enum.DominantAxis.Height,
            }),
        })
    end

    local Header = New("TextLabel", {
        Name = "Header",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 12),
        Size = UDim2.new(1, -36, 0, 26),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
        Theme = { TextColor3 = "Text" },
        Parent = Work,
    })

    local Pages = New("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 48),
        Size = UDim2.new(1, -22, 1, -58),
        ZIndex = 2,
        Parent = Work,
    })

    HookDrag(New("Frame", {
        Name = "DragBar",
        Active = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 3,
        Parent = Main,
    }))

    --------------------------- [[ Sidebar ]] ---------------------------

    local Lights = New("Frame", {
        Name = "Lights",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(60, 12),
        ZIndex = 4,
        Parent = Main,
    }, {
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local function MakeLight(Order, Color)
        return New("TextButton", {
            Text = "",
            BackgroundColor3 = Color,
            Size = UDim2.fromOffset(12, 12),
            LayoutOrder = Order,
            ZIndex = 4,
            Parent = Lights,
        }, { Corner(6) })
    end

    local CloseLight = MakeLight(1, Color3.fromRGB(254, 94, 86))
    local MinimizeLight = MakeLight(2, Color3.fromRGB(255, 189, 46))
    local ZoomLight = MakeLight(3, Color3.fromRGB(39, 200, 63))

    local Brand = New("Frame", {
        Name = "Brand",
        Active = true,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 38),
        Size = UDim2.new(0, SideWidth - 24, 0, 36),
        ZIndex = 3,
        Parent = Main,
    })
    HookDrag(Brand)
    MakeLogo(Brand, 36)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(44, 2),
        Size = UDim2.new(1, -44, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = tostring(Config.Title or "VaderUI"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Theme = { TextColor3 = "Text" },
        Parent = Brand,
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(44, 19),
        Size = UDim2.new(1, -44, 0, 14),
        Font = Enum.Font.Gotham,
        Text = tostring(Config.SubTitle or ""),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Theme = { TextColor3 = "SubText" },
        Parent = Brand,
    })

    local Search = New("Frame", {
        Name = "Search",
        Position = UDim2.fromOffset(12, 84),
        Size = UDim2.new(0, SideWidth - 24, 0, 28),
        Theme = { BackgroundColor3 = "Card" },
        Parent = Main,
    }, { Corner(8) })

    New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 7),
        Size = UDim2.fromOffset(14, 14),
        Image = "rbxassetid://2804603863",
        ScaleType = Enum.ScaleType.Fit,
        Theme = { ImageColor3 = "SubText" },
        Parent = Search,
    })

    local SearchBox = New("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(1, -34, 1, 0),
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Theme = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
        Parent = Search,
    })

    local TabList = New("ScrollingFrame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 122),
        Size = UDim2.new(0, SideWidth - 24, 1, -134),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Theme = { ScrollBarImageColor3 = "Stroke" },
        Parent = Main,
    })
    local TabLayout = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabList,
    })
    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.fromOffset(0, TabLayout.AbsoluteContentSize.Y)
    end)

    --------------------------- [[ Dropdown Popup ]] ---------------------------

    -- one popup shared by every dropdown; its list is rebuilt each time it opens
    local Overlay = New("TextButton", {
        Name = "Overlay",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 50,
        Parent = Gui,
    })

    local Popup = New("Frame", {
        Name = "Popup",
        Active = true,
        Size = UDim2.fromOffset(200, 100),
        ZIndex = 51,
        Theme = { BackgroundColor3 = "Card" },
        Parent = Overlay,
    }, {
        Corner(9),
        New("UIStroke", { Theme = { Color = "Stroke" } }),
    })

    local PopupSearch = New("TextBox", {
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 0, 26),
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
        Theme = { BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "SubText" },
        Parent = Popup,
    }, {
        Corner(6),
        New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
    })

    local PopupList = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 38),
        Size = UDim2.new(1, -12, 1, -44),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 52,
        Theme = { ScrollBarImageColor3 = "Stroke" },
        Parent = Popup,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    local PopupState = { Owner = nil, Anchor = nil }

    local function ClosePopup()
        Overlay.Visible = false
        if PopupState.Owner then
            PopupState.Owner.Opened = false
        end
        PopupState.Owner, PopupState.Anchor = nil, nil
    end

    local function FillPopup()
        for _, Child in ipairs(PopupList:GetChildren()) do
            if Child:IsA("TextButton") then
                Child:Destroy()
            end
        end

        local Dropdown, Anchor = PopupState.Owner, PopupState.Anchor
        if Dropdown == nil or Anchor == nil then
            return
        end

        local Query = PopupSearch.Text:lower()
        local Count = 0
        for Index, Value in ipairs(Dropdown.Values) do
            local Label = tostring(Value)
            if Query == "" or Label:lower():find(Query, 1, true) then
                Count += 1

                local Option = New("TextButton", {
                    BackgroundColor3 = Theme.CardHover,
                    Size = UDim2.new(1, -5, 0, 26),
                    Font = Enum.Font.Gotham,
                    Text = Label,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    LayoutOrder = Index,
                    ZIndex = 53,
                    Parent = PopupList,
                }, {
                    Corner(6),
                    New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 22) }),
                })

                local Dot = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 14, 0.5, 0),
                    Size = UDim2.fromOffset(8, 8),
                    BackgroundColor3 = Theme.Accent,
                    ZIndex = 54,
                    Parent = Option,
                }, { Corner(4) })

                local function Paint()
                    local Selected
                    if Dropdown.Multi then
                        Selected = Dropdown.Value[Value] == true
                    else
                        Selected = Dropdown.Value == Value
                    end
                    Dot.Visible = Selected
                    Option.BackgroundTransparency = Selected and 0 or 1
                    Option.TextColor3 = Selected and Theme.Accent or Theme.Text
                    Option.Font = Selected and Enum.Font.GothamMedium or Enum.Font.Gotham
                end
                Paint()

                Option.MouseEnter:Connect(function()
                    Option.BackgroundTransparency = 0
                end)
                Option.MouseLeave:Connect(Paint)

                Option.MouseButton1Click:Connect(function()
                    if Dropdown.Multi then
                        local Picked = table.clone(Dropdown.Value)
                        Picked[Value] = (not Picked[Value]) or nil
                        Dropdown:SetValue(Picked)
                        Paint()
                    else
                        if Dropdown.Value ~= Value then
                            Dropdown:SetValue(Value)
                        elseif Dropdown.AllowNull then
                            Dropdown:SetValue(nil)
                        end
                        ClosePopup()
                    end
                end)
            end
        end

        local ListHeight = math.clamp(Count * 28 - 2, 26, 196)
        PopupList.CanvasSize = UDim2.fromOffset(0, math.max(Count * 28 - 2, 0))

        local PopupWidth = math.max(Anchor.AbsoluteSize.X, 210)
        local PopupHeight = ListHeight + 44
        local Origin = Anchor.AbsolutePosition - Overlay.AbsolutePosition
        local X = Origin.X + Anchor.AbsoluteSize.X - PopupWidth
        local Y = Origin.Y + Anchor.AbsoluteSize.Y + 4
        if Y + PopupHeight > Overlay.AbsoluteSize.Y - 8 then
            Y = math.max(Origin.Y - PopupHeight - 4, 8)
        end
        Popup.Size = UDim2.fromOffset(PopupWidth, PopupHeight)
        Popup.Position = UDim2.fromOffset(math.max(X, 8), Y)
    end

    local function OpenPopup(Dropdown, Anchor)
        ClosePopup()
        PopupState.Owner, PopupState.Anchor = Dropdown, Anchor
        Dropdown.Opened = true
        PopupSearch.Text = ""
        PopupList.CanvasPosition = Vector2.zero
        FillPopup()
        Overlay.Visible = true
    end

    Overlay.MouseButton1Click:Connect(ClosePopup)
    PopupSearch:GetPropertyChangedSignal("Text"):Connect(FillPopup)

    --------------------------- [[ Dialog ]] ---------------------------

    local Dim = New("TextButton", {
        Name = "Dialog",
        Text = "",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 20,
        Parent = Main,
    }, { Corner(14) })

    local DialogCard = New("Frame", {
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 21,
        Theme = { BackgroundColor3 = "Card" },
        Parent = Dim,
    }, {
        Corner(14),
        New("UIStroke", { Theme = { Color = "Stroke" } }),
        New("UIPadding", {
            PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
        }),
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }),
    })

    MakeLogo(DialogCard, 48, { LayoutOrder = 1, ZIndex = 22 })

    local DialogTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextWrapped = true,
        LayoutOrder = 2,
        ZIndex = 22,
        Theme = { TextColor3 = "Text" },
        Parent = DialogCard,
    })

    local DialogContent = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        LayoutOrder = 3,
        ZIndex = 22,
        Theme = { TextColor3 = "SubText" },
        Parent = DialogCard,
    })

    local DialogButtons = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 4,
        ZIndex = 22,
        Parent = DialogCard,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        New("UIPadding", { PaddingTop = UDim.new(0, 6) }),
    })

    function Window:Dialog(Options)
        Options = Options or {}
        DialogTitle.Text = tostring(Options.Title or "Notice")
        DialogContent.Text = tostring(Options.Content or "")
        for _, Child in ipairs(DialogButtons:GetChildren()) do
            if Child:IsA("TextButton") then
                Child:Destroy()
            end
        end

        for Order, Spec in ipairs(Options.Buttons or { { Title = "OK" } }) do
            local Primary = Order == 1
            local Button = New("TextButton", {
                BackgroundColor3 = Primary and Theme.Accent or Theme.CardHover,
                Size = UDim2.new(1, 0, 0, 32),
                Font = Enum.Font.GothamMedium,
                Text = tostring(Spec.Title or "OK"),
                TextColor3 = Primary and Theme.AccentText or Theme.Text,
                TextSize = 13,
                LayoutOrder = Order,
                ZIndex = 23,
                Parent = DialogButtons,
            }, { Corner(8) })
            Button.MouseButton1Click:Connect(function()
                Dim.Visible = false
                Library:SafeCallback(Spec.Callback)
            end)
        end
        Dim.Visible = true
    end

    --------------------------- [[ Minimize ]] ---------------------------

    local Reopen = New("TextButton", {
        Name = "Reopen",
        Text = "",
        Position = UDim2.new(0, 16, 0.5, -24),
        Size = UDim2.fromOffset(48, 48),
        Visible = false,
        ZIndex = 10,
        Theme = { BackgroundColor3 = "Window" },
        Parent = Gui,
    }, {
        Corner(24),
        New("UIStroke", { Thickness = 2, Theme = { Color = "Accent" } }),
    })
    MakeLogo(Reopen, 36, { Position = UDim2.fromOffset(6, 6), ZIndex = 11 })

    local Motion = 0

    function Window:Minimize()
        self.Minimized = not self.Minimized
        Motion += 1
        local Token = Motion
        ClosePopup()

        if self.Minimized then
            Reopen.Visible = true
            Tween(Holder, 0.4, {
                Position = UDim2.new(ShownPosition.X.Scale, ShownPosition.X.Offset, 1.5, Holder.AbsoluteSize.Y),
            }, Enum.EasingStyle.Quart)
            task.delay(0.4, function()
                if Motion == Token then
                    Holder.Visible = false
                end
            end)
            if not self.MinimizeHintShown then
                self.MinimizeHintShown = true
                local Bind = Library.MinimizeKeybind
                local Key = Bind and type(Bind.Value) == "string" and Bind.Value or Library.MinimizeKey.Name
                Library:Notify({
                    Title = "Interface",
                    Content = ("Press %s or the logo button to bring it back."):format(Key),
                    Duration = 6,
                })
            end
        else
            Reopen.Visible = false
            Holder.Visible = true
            Tween(Holder, 0.4, { Position = ShownPosition })
        end
    end

    Reopen.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)
    MinimizeLight.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)

    ZoomLight.MouseButton1Click:Connect(function()
        Window.Zoomed = not Window.Zoomed
        ClosePopup()
        Tween(Holder, 0.3, {
            Size = Window.Zoomed
                and UDim2.fromOffset(math.min(Width + 160, Viewport.X - 20), math.min(Height + 140, Viewport.Y - 20))
                or UDim2.fromOffset(Width, Height),
        })
    end)

    CloseLight.MouseButton1Click:Connect(function()
        Window:Dialog({
            Title = "Close",
            Content = "Unload the interface? Anything it is running stops.",
            Buttons = {
                { Title = "Unload", Callback = function() Library:Destroy() end },
                { Title = "Cancel" },
            },
        })
    end)

    Track(UserInputService.InputBegan:Connect(function(Input)
        if Library.Picking or UserInputService:GetFocusedTextBox() then
            return
        end
        if Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        local Bind = Library.MinimizeKeybind
        local Hit
        if Bind and type(Bind.Value) == "string" and Bind.Value ~= "None" then
            Hit = Input.KeyCode.Name == Bind.Value
        else
            Hit = Input.KeyCode == Library.MinimizeKey
        end
        if Hit then
            Window:Minimize()
        end
    end))

    --------------------------- [[ Search ]] ---------------------------

    local function ApplySearch()
        local Query = SearchBox.Text:lower()
        for _, Tab in ipairs(Window.Tabs) do
            local TitleHit = Query == "" or Tab.Title:lower():find(Query, 1, true) ~= nil
            local AnyHit = false
            for _, Item in ipairs(Tab.Items) do
                local Hit = TitleHit or Item.Text:find(Query, 1, true) ~= nil
                Item.Row.Visible = Hit
                AnyHit = AnyHit or Hit
            end
            Tab.Button.Visible = TitleHit or AnyHit
        end
    end
    SearchBox:GetPropertyChangedSignal("Text"):Connect(ApplySearch)

    --------------------------- [[ Elements ]] ---------------------------

    local function Fire(Element, ...)
        Library:SafeCallback(Element.Callback, ...)
        Library:SafeCallback(Element.Changed, ...)
    end

    -- A card row: title and description on the left, room for a control on the right
    local function MakeRow(Tab, Title, Description, ControlWidth, Clickable, TitleKey)
        Tab.Order += 1

        local Row = New(Clickable and "TextButton" or "Frame", {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = CardAlpha,
            LayoutOrder = Tab.Order,
            Theme = { BackgroundColor3 = "Card" },
            Parent = Tab.Page,
        }, {
            Corner(9),
            New("UIPadding", {
                PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
                PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
            }),
        })
        if Clickable then
            Row.Text = ""
        end

        local Texts = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, ControlWidth > 0 and -(ControlWidth + 10) or 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = Row,
        }, {
            New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
        })

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.GothamMedium,
            Text = tostring(Title or ""),
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Visible = Title ~= nil and tostring(Title) ~= "",
            Theme = { TextColor3 = TitleKey or "Text" },
            Parent = Texts,
        })

        local DescLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            Text = tostring(Description or ""),
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            Visible = Description ~= nil and tostring(Description) ~= "",
            Theme = { TextColor3 = "SubText" },
            Parent = Texts,
        })

        Row.MouseEnter:Connect(function()
            Tween(Row, 0.15, { BackgroundColor3 = Theme.CardHover })
        end)
        Row.MouseLeave:Connect(function()
            Tween(Row, 0.15, { BackgroundColor3 = Theme.Card })
        end)

        table.insert(Tab.Items, {
            Row = Row,
            Text = (tostring(Title or "") .. " " .. tostring(Description or "")):lower(),
        })

        local Element = { Frame = Row }
        function Element:SetTitle(Text)
            TitleLabel.Text = tostring(Text or "")
            TitleLabel.Visible = TitleLabel.Text ~= ""
        end
        function Element:SetDesc(Text)
            DescLabel.Text = tostring(Text or "")
            DescLabel.Visible = DescLabel.Text ~= ""
        end
        function Element:OnChanged(Callback)
            self.Changed = Callback
            Library:SafeCallback(Callback, self.Value)
        end
        function Element:Destroy()
            Row:Destroy()
        end
        return Row, Element
    end

    local function ControlProps(Width, Height, Extra)
        local Props = {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(Width, Height),
        }
        for Key, Value in pairs(Extra or {}) do
            Props[Key] = Value
        end
        return Props
    end

    local function MakeContainer(Tab)
        local Container = {}

        function Container:AddSection(Title)
            Tab.Order += 1
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -8, 0, 28),
                Font = Enum.Font.GothamBold,
                Text = tostring(Title or ""),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                LayoutOrder = Tab.Order,
                Theme = { TextColor3 = "Text" },
                Parent = Tab.Page,
            }, { New("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4) }) })
            return MakeContainer(Tab)
        end

        function Container:AddParagraph(Options)
            Options = Options or {}
            local _, Element = MakeRow(Tab, Options.Title, Options.Content, 0, false)
            Element.Type = "Paragraph"
            return Element
        end

        function Container:AddButton(Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 0, true, "Accent")
            Element.Type = "Button"
            Element.Callback = Options.Callback
            Row.MouseButton1Click:Connect(function()
                Row.BackgroundColor3 = Theme.Stroke
                Tween(Row, 0.3, { BackgroundColor3 = Theme.CardHover })
                Library:SafeCallback(Element.Callback)
            end)
            return Element
        end

        function Container:AddToggle(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 38, true)
            Element.Type = "Toggle"
            Element.Value = Options.Default and true or false
            Element.Callback = Options.Callback

            local Switch = New("Frame", ControlProps(38, 20, { Parent = Row }), { Corner(10) })
            local Knob = New("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.fromOffset(16, 16),
                Parent = Switch,
            }, { Corner(8) })

            local function Paint(Animate)
                local Color = Element.Value and Theme.Accent or Theme.ToggleOff
                local Position = Element.Value and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)
                if Animate then
                    Tween(Switch, 0.15, { BackgroundColor3 = Color })
                    Tween(Knob, 0.15, { Position = Position })
                else
                    Switch.BackgroundColor3 = Color
                    Knob.Position = Position
                end
            end
            table.insert(Refreshers, Paint)

            function Element:SetValue(Value)
                self.Value = Value and true or false
                Paint(true)
                Fire(self, self.Value)
            end

            Row.MouseButton1Click:Connect(function()
                Element:SetValue(not Element.Value)
            end)

            Paint(false)
            if Id then
                Library.Options[Id] = Element
            end
            Fire(Element, Element.Value)
            return Element
        end

        function Container:AddDropdown(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 150, false)
            Element.Type = "Dropdown"
            Element.Values = Options.Values or {}
            Element.Multi = Options.Multi and true or false
            Element.AllowNull = Options.AllowNull and true or false
            Element.Opened = false
            Element.Callback = Options.Callback
            Element.Value = Element.Multi and {} or nil

            local Button = New("TextButton", ControlProps(150, 28, {
                Font = Enum.Font.Gotham,
                Text = "--",
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Theme = { BackgroundColor3 = "Field", TextColor3 = "Text" },
                Parent = Row,
            }), {
                Corner(7),
                New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Theme = { Color = "Stroke" },
                }),
                New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 24) }),
            })

            New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 18, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                Image = "rbxassetid://10709790948",
                Theme = { ImageColor3 = "SubText" },
                Parent = Button,
            })

            function Element:Display()
                local Text
                if self.Multi then
                    local Names = {}
                    for _, Value in ipairs(self.Values) do
                        if self.Value[Value] then
                            table.insert(Names, tostring(Value))
                        end
                    end
                    Text = table.concat(Names, ", ")
                else
                    Text = self.Value ~= nil and tostring(self.Value) or ""
                end
                Button.Text = Text ~= "" and Text or "--"
            end

            -- Multi takes { Name = true } or { "Name", ... }; names outside Values are dropped
            function Element:SetValue(Value)
                if self.Multi then
                    local Picked = {}
                    if type(Value) == "table" then
                        for Key, Entry in pairs(Value) do
                            local Name
                            if type(Key) == "number" then
                                Name = Entry
                            elseif Entry then
                                Name = Key
                            end
                            if Name ~= nil and table.find(self.Values, Name) then
                                Picked[Name] = true
                            end
                        end
                    end
                    self.Value = Picked
                elseif Value == nil then
                    self.Value = nil
                elseif table.find(self.Values, Value) then
                    self.Value = Value
                end
                self:Display()
                Fire(self, self.Value)
            end

            function Element:SetValues(Values)
                self.Values = Values or {}
                if PopupState.Owner == self then
                    FillPopup()
                end
            end

            Button.MouseButton1Click:Connect(function()
                if PopupState.Owner == Element then
                    ClosePopup()
                else
                    OpenPopup(Element, Button)
                end
            end)

            -- set without firing: a default is not a change
            local Default = Options.Default
            if Element.Multi then
                if type(Default) == "string" then
                    Default = { Default }
                end
                if type(Default) == "table" then
                    for Key, Entry in pairs(Default) do
                        local Name
                        if type(Key) == "number" then
                            Name = Entry
                        elseif Entry then
                            Name = Key
                        end
                        if Name ~= nil and table.find(Element.Values, Name) then
                            Element.Value[Name] = true
                        end
                    end
                end
            elseif type(Default) == "number" and Element.Values[Default] ~= nil then
                Element.Value = Element.Values[Default]
            elseif Default ~= nil and table.find(Element.Values, Default) then
                Element.Value = Default
            end
            Element:Display()

            if Id then
                Library.Options[Id] = Element
            end
            return Element
        end

        function Container:AddInput(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 150, false)
            Element.Type = "Input"
            Element.Callback = Options.Callback
            Element.Value = tostring(Options.Default or "")

            local Box = New("TextBox", ControlProps(150, 28, {
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Font = Enum.Font.Gotham,
                PlaceholderText = tostring(Options.Placeholder or ""),
                Text = Element.Value,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Theme = { BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "SubText" },
                Parent = Row,
            }), {
                Corner(7),
                New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Theme = { Color = "Stroke" },
                }),
                New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }),
            })

            function Element:SetValue(Text)
                Text = tostring(Text or "")
                if Options.MaxLength and #Text > Options.MaxLength then
                    Text = Text:sub(1, Options.MaxLength)
                end
                if Options.Numeric and Text ~= "" and tonumber(Text) == nil then
                    Text = self.Value
                end
                self.Value = Text
                Box.Text = Text
                Fire(self, Text)
            end

            if Options.Finished then
                Box.FocusLost:Connect(function()
                    Element:SetValue(Box.Text)
                end)
            else
                Box:GetPropertyChangedSignal("Text"):Connect(function()
                    if Box.Text ~= Element.Value then
                        Element:SetValue(Box.Text)
                    end
                end)
            end

            if Id then
                Library.Options[Id] = Element
            end
            return Element
        end

        function Container:AddSlider(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 150, false)
            local Min, Max = Options.Min or 0, Options.Max or 100
            Element.Type = "Slider"
            Element.Min, Element.Max, Element.Rounding = Min, Max, Options.Rounding or 0
            Element.Callback = Options.Callback

            local Control = New("Frame", ControlProps(150, 20, { BackgroundTransparency = 1, Parent = Row }))

            local ValueLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 38, 1, 0),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Theme = { TextColor3 = "SubText" },
                Parent = Control,
            })

            local Hit = New("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -46, 1, 0),
                Parent = Control,
            })

            local Bar = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 4),
                Theme = { BackgroundColor3 = "ToggleOff" },
                Parent = Hit,
            }, { Corner(2) })

            local Fill = New("Frame", {
                Size = UDim2.fromScale(0, 1),
                Theme = { BackgroundColor3 = "Accent" },
                Parent = Bar,
            }, { Corner(2) })

            local Knob = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(12, 12),
                Parent = Bar,
            }, { Corner(6) })

            function Element:SetValue(Value)
                Value = math.clamp(tonumber(Value) or Min, Min, Max)
                local Factor = 10 ^ self.Rounding
                Value = math.floor(Value * Factor + 0.5) / Factor
                self.Value = Value

                local Alpha = Max > Min and (Value - Min) / (Max - Min) or 0
                Fill.Size = UDim2.fromScale(Alpha, 1)
                Knob.Position = UDim2.fromScale(Alpha, 0.5)
                ValueLabel.Text = tostring(Value)
                Fire(self, Value)
            end

            local Sliding = false
            local function SlideTo(Input)
                local Alpha = math.clamp((Input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                local Before = Element.Value
                local Factor = 10 ^ Element.Rounding
                local Value = math.floor((Min + (Max - Min) * Alpha) * Factor + 0.5) / Factor
                if Value ~= Before then
                    Element:SetValue(Value)
                end
            end

            Hit.InputBegan:Connect(function(Input)
                if IsPress(Input) then
                    Sliding = true
                    SlideTo(Input)
                end
            end)
            Track(UserInputService.InputChanged:Connect(function(Input)
                if Sliding and IsMove(Input) then
                    SlideTo(Input)
                end
            end))
            Track(UserInputService.InputEnded:Connect(function(Input)
                if IsPress(Input) then
                    Sliding = false
                end
            end))

            if Id then
                Library.Options[Id] = Element
            end
            Element:SetValue(Options.Default or Min)
            return Element
        end

        function Container:AddKeybind(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 96, false)
            Element.Type = "Keybind"
            Element.Value = tostring(Options.Default or "None")
            Element.Mode = Options.Mode or "Toggle"
            Element.Toggled = false
            Element.Callback = Options.Callback

            local Button = New("TextButton", ControlProps(96, 28, {
                Font = Enum.Font.GothamMedium,
                Text = Element.Value,
                TextSize = 12,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Theme = { BackgroundColor3 = "Field", TextColor3 = "Text" },
                Parent = Row,
            }), {
                Corner(7),
                New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Theme = { Color = "Stroke" },
                }),
            })

            function Element:SetValue(Key, Mode)
                self.Value = tostring(Key or self.Value)
                self.Mode = Mode or self.Mode
                Button.Text = self.Value
            end

            function Element:GetState()
                return self.Toggled
            end

            function Element:OnClick(Callback)
                self.Clicked = Callback
            end

            Button.MouseButton1Click:Connect(function()
                if Library.Picking then
                    return
                end
                Library.Picking = true
                Button.Text = "..."

                local Listener
                Listener = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end
                    Listener:Disconnect()
                    if Input.KeyCode ~= Enum.KeyCode.Escape then
                        Element:SetValue(Input.KeyCode.Name)
                        Library:SafeCallback(Options.ChangedCallback, Input.KeyCode)
                        Library:SafeCallback(Element.Changed, Element.Value)
                    else
                        Button.Text = Element.Value
                    end
                    task.defer(function()
                        Library.Picking = false
                    end)
                end)
                Track(Listener)
            end)

            Track(UserInputService.InputBegan:Connect(function(Input)
                if Library.Picking or Library.MinimizeKeybind == Element or UserInputService:GetFocusedTextBox() then
                    return
                end
                if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Element.Value then
                    Element.Toggled = not Element.Toggled
                    Library:SafeCallback(Element.Callback, Element.Toggled)
                    Library:SafeCallback(Element.Clicked, Element.Toggled)
                end
            end))

            if Id then
                Library.Options[Id] = Element
            end
            return Element
        end

        return Container
    end

    --------------------------- [[ Tabs ]] ---------------------------

    local function PaintTabs()
        for _, Tab in ipairs(Window.Tabs) do
            local Selected = Tab == Window.Selected
            Tab.Button.BackgroundTransparency = Selected and 0 or 1
            Tab.Button.BackgroundColor3 = Theme.Accent
            Tab.Button.TextColor3 = Selected and Theme.AccentText or Theme.Text
            Tab.Page.Visible = Selected
            if Tab.Icon then
                Tab.Icon.ImageColor3 = Tab.Button.TextColor3
            end
        end
        if Window.Selected then
            Header.Text = Window.Selected.Title
        end
    end
    table.insert(Refreshers, PaintTabs)

    function Window:SelectTab(Index)
        local Tab = self.Tabs[Index]
        if Tab == nil then
            return
        end
        ClosePopup()
        self.Selected = Tab
        PaintTabs()
    end

    function Window:AddTab(Options)
        Options = Options or {}
        local Index = #self.Tabs + 1
        local HasIcon = type(Options.Icon) == "string" and Options.Icon:match("^rbx") ~= nil

        local Tab = MakeContainer(nil)
        Tab.Title = tostring(Options.Title or ("Tab " .. Index))
        Tab.Items = {}
        Tab.Order = 0

        Tab.Button = New("TextButton", {
            Size = UDim2.new(1, -4, 0, 30),
            Font = Enum.Font.GothamMedium,
            Text = Tab.Title,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = Index,
            Parent = TabList,
        }, {
            Corner(8),
            New("UIPadding", { PaddingLeft = UDim.new(0, HasIcon and 32 or 10), PaddingRight = UDim.new(0, 8) }),
        })

        if HasIcon then
            Tab.Icon = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, -24, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Image = Options.Icon,
                Parent = Tab.Button,
            })
        end

        Tab.Page = New("ScrollingFrame", {
            Name = Tab.Title,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            ZIndex = 2,
            Theme = { ScrollBarImageColor3 = "Stroke" },
            Parent = Pages,
        })
        local Layout = New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Tab.Page,
        })
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Tab.Page.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 8)
        end)

        -- the container was built before the tab table existed; point its methods at it
        local Methods = MakeContainer(Tab)
        for Name, Method in pairs(Methods) do
            Tab[Name] = Method
        end

        Tab.Button.MouseButton1Click:Connect(function()
            Window:SelectTab(Index)
        end)

        table.insert(self.Tabs, Tab)
        if self.Selected == nil then
            self.Selected = Tab
        end
        PaintTabs()
        return Tab
    end

    Tween(Holder, 0.6, { Position = ShownPosition })
    return Window
end

Env.VaderUI_Instance = Library
return Library

end

--==================================================
-- VADER GAME ADAPTER
-- Gives the game logic the Groupbox API it was written for
-- (AddToggle / AddSlider / AddDropdown / AddInput / AddButton / AddLabel), built on VaderUI.
--==================================================
local function Vader_MakeLibrary()
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local UIS = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local VUI = CreateVaderUI()
    local VWindow
    local Library = {
        Options = {},
        Toggles = {},
        Unloaded = false,
        Toggled = true,
        ActiveTab = nil,
        IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled,
        VUI = VUI,
    }
    local Signals, UnloadCbs, TabsByV = {}, {}, {}

    local function warnErr(where, e)
        warn("[Vader] " .. where .. ": " .. tostring(e))
    end

    --------------------------------------------------
    -- Saved values: one JSON per player, written a moment after the last change
    --------------------------------------------------
    local StoreDir = "Vaderhug/DeepFishing"
    local StorePath = StoreDir .. "/" .. LocalPlayer.Name .. ".json"
    local Store, CanSave = {}, type(writefile) == "function"
    pcall(function()
        if isfile and readfile and isfile(StorePath) then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(StorePath))
            if ok and type(data) == "table" then
                Store = data
            else
                -- never overwrite a file we could not read
                CanSave = false
                Library.StoreProblem = "Config file is unreadable; auto-save paused to keep it: " .. StorePath
            end
        end
    end)

    local SaveToken = 0
    local function Save(key, value)
        Store[key] = value
        if not CanSave then
            return
        end
        SaveToken += 1
        local token = SaveToken
        task.delay(0.3, function()
            if token ~= SaveToken then
                return
            end
            local ok, e = pcall(function()
                if makefolder and isfolder then
                    if not isfolder("Vaderhug") then
                        makefolder("Vaderhug")
                    end
                    if not isfolder(StoreDir) then
                        makefolder(StoreDir)
                    end
                end
                writefile(StorePath, HttpService:JSONEncode(Store))
            end)
            if not ok then
                warnErr("save", e)
            end
        end)
    end
    local function Persist(key, default)
        local s = Store[key]
        if s ~= nil and type(s) == type(default) then
            return s
        end
        return default
    end
    Library.Save, Library.Persist = Save, Persist

    -- one short line per control, shown instead of the game code's long tooltips
    local ShortTips = {
        PerfectRate = "Share of perfect throws",
        IndexHunt = "Prefer fish missing from your index",
        SmartSell = "Sells when the backpack is full",
        SellAt = "0 = off",
        SellEvery = "0 = off",
        BuyBait = "Buys bait within the budget",
        BaitBudget = "Max bait cost per cast",
        AutoPond = "Collects, fills and feeds the pond",
        AutoRewards = "Daily, free roll, playtime, season, achievements, offline, group, referral",
        AutoBigMouth ="Feeds the Big Mouth every 12h",
        AutoEnchant = "Rolls until a picked enchant",
        AutoMutate = "Mutates your best fish",
        AutoPets = "Hatches eggs at your pond, equips the best pet",
        AutoCargo = "Fills, sends and claims the cargo boat",
        BaitPick = "Empty = any bait in the budget",
        KeepOnTeleport = "Re-runs the script after a server change",
        WebhookCard = "One message, updated every 2 min",
        WebhookReport = "0 = off",
    }

    local function RichText(ui)
        for _, d in ipairs(ui.Frame:GetDescendants()) do
            if d:IsA("TextLabel") then
                d.RichText = true
            end
        end
    end

    --------------------------------------------------
    -- Base element
    --------------------------------------------------
    local function NewElement(kind, id, info)
        local el = { Type = kind, Idx = id, Callback = info.Callback, Changed = {}, Text = info.Text }
        function el:OnChanged(fn)
            table.insert(self.Changed, fn)
            return self
        end
        function el:RunChanged(...)
            if self.Callback then
                local ok, e = pcall(self.Callback, ...)
                if not ok then
                    warnErr(tostring(id), e)
                end
            end
            for _, fn in ipairs(self.Changed) do
                local ok, e = pcall(fn, ...)
                if not ok then
                    warnErr(tostring(id), e)
                end
            end
        end
        return el
    end

    --------------------------------------------------
    -- Groupbox = a VaderUI section. Each group keeps its own slot in the page so
    -- rows added to an earlier group later still land under that group's header.
    --------------------------------------------------
    local function NewGroup(tab, title)
        tab.GroupCount = (tab.GroupCount or 0) + 1
        local V = tab.V
        -- hidden tabs ignore saved values so nothing in them runs from an old config
        local function P(key, default)
            if tab.Hidden then
                return default
            end
            return Persist(key, default)
        end
        V.Order = tab.GroupCount * 1000
        local g = { Tab = tab, Title = title, sec = V:AddSection(title) }
        g.order = V.Order

        local function In(fn)
            V.Order = g.order
            local ok, r = pcall(fn, g.sec)
            g.order = V.Order
            if not ok then
                error(r, 0)
            end
            return r
        end

        function g:AddToggle(id, info)
            info = info or {}
            local el = NewElement("Toggle", id, info)
            el.Default = info.Default == true
            el.Value = P("G_" .. id, el.Default) == true
            local quiet = true
            local function commit(v)
                if el.Value == v then
                    return
                end
                el.Value = v
                Save("G_" .. id, v)
                task.spawn(el.RunChanged, el, v)
            end
            local ui = In(function(sec)
                return sec:AddToggle(nil, {
                    Title = info.Text or id,
                    Description = ShortTips[id],
                    Default = el.Value,
                    Callback = function(v)
                        if not quiet then
                            commit(v)
                        end
                    end,
                })
            end)
            quiet = false
            function el:SetValue(v)
                v = v == true
                if v == self.Value then
                    return
                end
                quiet = true
                ui:SetValue(v)
                quiet = false
                commit(v)
            end
            function el:SetText(t)
                self.Text = t
                ui:SetTitle(t)
            end
            Library.Toggles[id] = el
            if el.Value ~= el.Default and el.Callback then
                task.defer(function()
                    pcall(el.Callback, el.Value)
                end)
            end
            return el
        end

        function g:AddSlider(id, info)
            info = info or {}
            local el = NewElement("Slider", id, info)
            local min, max = tonumber(info.Min) or 0, tonumber(info.Max) or 100
            el.Default = tonumber(info.Default) or min
            el.Value = math.clamp(P("G_" .. id, el.Default), min, max)
            local suffix = info.Suffix and string.match(info.Suffix, "%S+")
            local quiet = true
            local function commit(v)
                if el.Value == v then
                    return
                end
                el.Value = v
                Save("G_" .. id, v)
                task.spawn(el.RunChanged, el, v)
            end
            local ui = In(function(sec)
                return sec:AddSlider(nil, {
                    Title = (info.Text or id) .. (suffix and (" (" .. suffix .. ")") or ""),
                    Description = ShortTips[id],
                    Min = min,
                    Max = max,
                    Rounding = info.Rounding or 0,
                    Default = el.Value,
                    Callback = function(v)
                        if not quiet then
                            commit(v)
                        end
                    end,
                })
            end)
            quiet = false
            function el:SetValue(v)
                v = tonumber(v)
                if v == nil or v == self.Value then
                    return
                end
                quiet = true
                ui:SetValue(v)
                quiet = false
                commit(ui.Value)
            end
            Library.Options[id] = el
            return el
        end

        function g:AddDropdown(id, info)
            info = info or {}
            local multi = info.Multi == true
            local el = NewElement("Dropdown", id, info)
            el.Multi = multi
            el.Values = info.Values or {}
            local default
            if multi then
                default = {}
                if type(info.Default) == "table" then
                    for k, v in pairs(info.Default) do
                        if type(k) == "number" then
                            default[v] = true
                        elseif v then
                            default[k] = true
                        end
                    end
                end
                el.Default = info.Default
            else
                default = info.Default
                if type(default) == "number" then
                    default = el.Values[default]
                end
                if default == nil then
                    default = info.AllowNull and "" or (el.Values[1] or "")
                end
                el.Default = default
            end
            el.Value = P("G_" .. id, default)

            local quiet = false
            local ui
            local function push(v)
                quiet = true
                if multi then
                    ui:SetValue(v)
                else
                    ui:SetValue(v ~= "" and v or nil)
                end
                quiet = false
            end
            ui = In(function(sec)
                return sec:AddDropdown(nil, {
                    Title = info.Text or id,
                    Description = ShortTips[id],
                    Values = el.Values,
                    Multi = multi,
                    AllowNull = info.AllowNull,
                    Default = (multi or el.Value ~= "") and el.Value or nil,
                    Callback = function(v)
                        if quiet then
                            return
                        end
                        if multi and not info.AllowNull and next(v) == nil then
                            push(el.Value) -- the last pick cannot be removed
                            return
                        end
                        el:SetValue(v == nil and "" or v)
                    end,
                })
            end)

            function el:SetValue(v)
                if multi then
                    local nv = {}
                    if type(v) == "table" then
                        for k, x in pairs(v) do
                            if type(k) == "number" then
                                nv[x] = true
                            elseif x then
                                nv[k] = true
                            end
                        end
                    end
                    self.Value = nv
                else
                    if v == self.Value then
                        return
                    end
                    self.Value = v
                end
                push(self.Value)
                Save("G_" .. id, self.Value)
                self:RunChanged(self.Value)
            end
            function el:SetValues(list)
                self.Values = list or {}
                ui:SetValues(self.Values)
                ui:Display()
            end
            Library.Options[id] = el
            return el
        end

        function g:AddInput(id, info)
            info = info or {}
            local el = NewElement("Input", id, info)
            el.Default = info.Default or ""
            el.Value = P("G_" .. id, el.Default)
            local quiet = false
            local function commit(v)
                v = tostring(v or "")
                if v == el.Value then
                    return
                end
                el.Value = v
                Save("G_" .. id, v)
                el:RunChanged(v)
            end
            local ui = In(function(sec)
                return sec:AddInput(nil, {
                    Title = info.Text or id,
                    Description = ShortTips[id],
                    Default = el.Value,
                    Placeholder = info.Placeholder,
                    Finished = true,
                    Callback = function(v)
                        if not quiet then
                            commit(v)
                        end
                    end,
                })
            end)
            function el:SetValue(v)
                v = tostring(v or "")
                quiet = true
                ui:SetValue(v)
                quiet = false
                commit(v)
            end
            Library.Options[id] = el
            return el
        end

        function g:AddButton(a, b)
            local info = type(a) == "table" and a or { Text = a, Func = b }
            local obj = { Text = info.Text }
            local armed = false
            local ui
            ui = In(function(sec)
                return sec:AddButton({
                    Title = info.Text or "",
                    Callback = function()
                        if info.DoubleClick and not armed then
                            armed = true
                            ui:SetTitle("Click again to confirm")
                            task.delay(3, function()
                                armed = false
                                ui:SetTitle(obj.Text or "")
                            end)
                            return
                        end
                        armed = false
                        ui:SetTitle(obj.Text or "")
                        local fn = info.Func or info.Callback
                        if fn then
                            task.spawn(function()
                                local ok, e = pcall(fn)
                                if not ok then
                                    warnErr(tostring(info.Text), e)
                                end
                            end)
                        end
                    end,
                })
            end)
            function obj:SetText(t)
                self.Text = t
                ui:SetTitle(t)
            end
            return obj
        end

        function g:AddLabel(a, b)
            local text
            if type(a) == "table" then
                text = a.Text or ""
            elseif type(b) == "string" then
                text = b
            else
                text = tostring(a or "")
            end
            local obj = { Text = text }
            local ui = In(function(sec)
                return sec:AddParagraph({ Content = text })
            end)
            RichText(ui)
            function obj:SetText(t)
                t = tostring(t)
                if t == self.Text then
                    return
                end
                self.Text = t
                ui:SetDesc(t)
            end
            return obj
        end

        function g:AddDivider()
            return {}
        end

        return g
    end

    --------------------------------------------------
    -- Tab / Window
    --------------------------------------------------
    local Window = {}

    -- built (the game logic reads their values) but never shown
    local HiddenTabs = { Main = true, Stats = true, Webhook = true, Misc = true }

    local function NewTab(name)
        local V = VWindow:AddTab({ Title = name })
        local index = #VWindow.Tabs
        local tab = { Name = name, V = V, Hidden = HiddenTabs[name] == true }
        if tab.Hidden then
            V.Button:Destroy()
            V.Button = Instance.new("TextButton") -- unparented stand-in so tab painting and search keep working
            if VWindow.Selected == V then
                VWindow.Selected = nil -- the next visible tab becomes the opening one
            end
        end
        function tab:AddLeftGroupbox(title)
            return NewGroup(self, title)
        end
        tab.AddRightGroupbox = tab.AddLeftGroupbox
        function tab:Show()
            if not self.Hidden then
                VWindow:SelectTab(index)
            end
        end
        TabsByV[V] = tab
        if Library.ActiveTab == nil and not tab.Hidden then
            Library.ActiveTab = tab
        end
        return tab
    end

    function Window:AddTab(a)
        if type(a) == "table" then
            return NewTab(a.Name)
        end
        return NewTab(a)
    end
    function Window:AddMiscTab()
        return NewTab("Misc")
    end

    --------------------------------------------------
    -- Library API
    --------------------------------------------------
    function Library:CreateWindow(opts)
        opts = opts or {}
        VWindow = VUI:CreateWindow({
            Title = opts.Footer or "Deep Fishing",
            SubTitle = "by vaderhug",
            TabWidth = 180,
            Size = UDim2.fromOffset(620, 480),
            Theme = Persist("VaderTheme", "Dark"),
            MinimizeKey = Enum.KeyCode.RightControl,
        })
        Library.VWindow = VWindow

        local select = VWindow.SelectTab
        function VWindow:SelectTab(index)
            select(self, index)
            Library.ActiveTab = TabsByV[self.Selected] or Library.ActiveTab
        end
        local minimize = VWindow.Minimize
        function VWindow:Minimize()
            minimize(self)
            Library.Toggled = not self.Minimized
        end
        return Window
    end

    function Library:Notify(info)
        VUI:Notify({
            Title = info.Title or "Vader",
            Content = tostring(info.Description or info.Text or ""),
            Duration = info.Time or 3,
        })
    end

    function Library:GiveSignal(conn)
        table.insert(Signals, conn)
        return conn
    end

    function Library:OnUnload(fn)
        table.insert(UnloadCbs, fn)
    end

    local destroyUI = VUI.Destroy
    function Library:Unload()
        if Library.Unloaded then
            return
        end
        Library.Unloaded = true
        -- a thread started from a click or a game signal lacks the rights to touch CoreGui; restore them and remove the
        -- UI first, before the unload callbacks can drop them again
        local setIdentity = setthreadidentity or set_thread_identity or setidentity
        if setIdentity then
            pcall(setIdentity, 8)
        end
        local gui = VUI.GUI
        pcall(destroyUI, VUI)
        if gui then
            pcall(gui.Destroy, gui)
        end
        for _, fn in ipairs(UnloadCbs) do
            pcall(fn)
        end
        for _, c in ipairs(Signals) do
            pcall(function()
                c:Disconnect()
            end)
        end
    end
    -- the close button and a re-execute both go through VUI:Destroy
    function VUI:Destroy()
        Library:Unload()
    end

    function Library:ShowConfirmPrompt(info)
        VWindow:Dialog({
            Title = info.Title or "Confirm",
            Content = tostring(info.Text or "") .. (info.Warning and ("\n\n" .. info.Warning) or ""),
            Buttons = {
                {
                    Title = info.ConfirmText or "OK",
                    Callback = function()
                        if info.OnConfirm then
                            task.spawn(info.OnConfirm)
                        end
                    end,
                },
                {
                    Title = info.CancelText or "Cancel",
                    Callback = function()
                        if info.OnCancel then
                            task.spawn(info.OnCancel)
                        end
                    end,
                },
            },
        })
    end

    -- One dialog per step; on a Multi step each choice button toggles a ✓ and reopens the step.
    function Library:ShowWizard(info)
        local steps, values = info.Steps or {}, {}
        local function show(i, picked)
            local step = steps[i]
            if not step then
                if info.Finish then
                    task.spawn(info.Finish, values)
                end
                return
            end
            picked = picked or {}
            local key = step.Id or tostring(i)
            local buttons = {
                {
                    Title = i == #steps and (info.FinishText or "Start") or "Next",
                    Callback = function()
                        local list = {}
                        for id, yes in pairs(picked) do
                            if yes then
                                list[#list + 1] = id
                            end
                        end
                        table.sort(list)
                        values[key] = list
                        show(i + 1)
                    end,
                },
            }
            for _, c in ipairs(step.Choices or {}) do
                table.insert(buttons, {
                    Title = (picked[c.Id] and "✓  " or "") .. tostring(c.Title or c.Id),
                    Callback = function()
                        if step.Multi then
                            picked[c.Id] = not picked[c.Id] or nil
                            show(i, picked)
                        else
                            values[key] = { c.Id }
                            show(i + 1)
                        end
                    end,
                })
            end
            table.insert(buttons, {
                Title = info.SkipText or "Skip",
                Callback = function()
                    if info.Skipped then
                        task.spawn(info.Skipped)
                    end
                end,
            })
            VWindow:Dialog({ Title = step.Title or "", Content = step.Description or "", Buttons = buttons })
        end
        show(1)
    end

    return Library
end

local function Vader_RunGame(Library)
local Boot = getgenv()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local N = {}
local Options, Toggles, GameName, LoaderScript, INSTANCE, alive, UIQueue, notify, HttpService
local RunService, LogFile, Log, brief, log, logProblem, flushLog, Perf, send, invoke, waitFor
do
	Options = Library.Options
	Toggles = Library.Toggles
	GameName = "Deep Fishing"
	LoaderScript = ""
	local Env = getgenv()
	if Env.DeepFishingInstance then
		pcall(function()
			Env.DeepFishingInstance.stop = true
		end)
	end
	task.wait(0.2)
	INSTANCE = { stop = false }
	Env.DeepFishingInstance = INSTANCE
	function alive()
		return not INSTANCE.stop and Env.DeepFishingInstance == INSTANCE and not Library.Unloaded
	end
	UIQueue = { list = {} }
	function UIQueue.push(fn)
		if #UIQueue.list < 200 then
			table.insert(UIQueue.list, fn)
		end
	end
	function UIQueue.flush()
		local list = UIQueue.list
		if #list == 0 then
			return
		end
		UIQueue.list = {}
		for _, fn in ipairs(list) do
			pcall(fn)
		end
	end
	function notify(Title, Text, Time)
		UIQueue.push(function()
			Library:Notify({ Title = Title, Description = Text, Time = Time or 3 })
		end)
	end
	HttpService = game:GetService("HttpService")
	RunService = game:GetService("RunService")
	LogFile = "Vader_FISH_" .. LocalPlayer.Name .. "_log.txt"
	Log = { lines = {}, start = os.clock(), dirty = false, flushedAt = 0, problems = {}, problemCount = 0, limit = 4000 }
	function brief(value, depth)
		depth = depth or 0
		local kind = typeof(value)
		if kind == "Instance" then
			local ok, name = pcall(function()
				return value.Name
			end)
			return if ok then tostring(name) else "?"
		elseif kind == "Vector3" then
			return string.format("(%.1f, %.1f, %.1f)", value.X, value.Y, value.Z)
		elseif kind == "number" then
			if value ~= value then
				return "nan"
			elseif value % 1 == 0 and math.abs(value) < 1e15 then
				return string.format("%d", value)
			elseif math.abs(value) >= 1e6 then
				return string.format("%.3g", value)
			end
			return string.format("%.2f", value)
		elseif kind == "string" then
			return if #value > 120 then string.sub(value, 1, 120) .. "..." else value
		elseif kind == "table" then
			if depth >= 2 then
				return "{...}"
			end
			local parts, n = {}, 0
			for k, v in pairs(value) do
				n += 1
				if n > 10 then
					table.insert(parts, "...")
					break
				end
				table.insert(parts, tostring(k) .. "=" .. brief(v, depth + 1))
			end
			return "{" .. table.concat(parts, ", ") .. "}"
		end
		return tostring(value)
	end
	function log(...)
		local parts = table.pack(...)
		for i = 1, parts.n do
			parts[i] = if type(parts[i]) == "string" then parts[i] else brief(parts[i])
		end
		local line = string.format("[%7.2f] %s", os.clock() - Log.start, (string.gsub(table.concat(parts, " ", 1, parts.n), "%s+$", "")))
		if #line > 600 then
			line = string.sub(line, 1, 600) .. "..."
		end
		local lines = Log.lines
		lines[#lines + 1] = line
		if #lines > Log.limit + 500 then
			table.move(lines, #lines - Log.limit + 1, #lines, 1)
			for i = #lines, Log.limit + 1, -1 do
				lines[i] = nil
			end
		end
		Log.dirty = true
	end
	Library.LoadLogger = function(line)
		pcall(log, line)
	end
	function logProblem(text)
		text = string.sub(tostring(text or ""), 1, 300)
		log("PROBLEM", text)
		Log.problemCount += 1
		if #Log.problems < 12 and not table.find(Log.problems, text) then
			table.insert(Log.problems, text)
		end
	end
	function flushLog(force)
		if Log.dirty and type(writefile) == "function" and (force or os.clock() - Log.flushedAt > 30) then
			Log.dirty = false
			Log.flushedAt = os.clock()
			local head = ""
			if Log.header then
				local ok, text = pcall(Log.header)
				if ok and type(text) == "string" then
					head = text .. "\n"
				end
			end
			task.spawn(pcall, writefile, LogFile, head .. table.concat(Log.lines, "\n"))
		end
	end
	do
		local executor = "?"
		pcall(function()
			executor = table.concat({ identifyexecutor() }, " ")
		end)
		log("BOOT", GameName, "place", game.PlaceId, "job", string.sub(tostring(game.JobId), 1, 8), "executor", executor)
	end
	Perf = { frames = 0, time = 0, worst = 0, hitches = 0, freezes = 0, work = {}, hitchLogAt = 0, last = nil }
	Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
		Perf.frames += 1
		Perf.time += dt
		if dt > Perf.worst then
			Perf.worst = dt
		end
		if dt > 0.1 then
			Perf.hitches += 1
			if dt > 0.25 and os.clock() - Perf.hitchLogAt > 2 then
				Perf.hitchLogAt = os.clock()
				log("HITCH", math.floor(dt * 1000) .. "ms", "while:", if Log.context then Log.context() else "?")
			end
			if dt > 1 then
				Perf.freezes += 1
			end
		end
	end))
	local function safeRequire(path)
		local result, done = nil, false
		task.spawn(function()
			local ok, value = pcall(function()
				local node = ReplicatedStorage
				for part in path:gmatch("[^%.]+") do
					node = node:WaitForChild(part, 8)
				end
				return require(node)
			end)
			result = ok and value or nil
			done = true
		end)
		local waited = 0
		while not done and waited < 12 do
			waited += task.wait(0.05) or 0.05
		end
		if result == nil then
			log("REQUIRE failed", path)
		end
		return result
	end
	N.safeRequire = safeRequire
	-- The game's own framework (ReplicatedStorage.Shared): configs, content, PlayerData replica, Events (Warp) and the
	-- shared services (GetSellValue). The game's client already required it, so this is the same table it uses.
	N.Sh = safeRequire("Shared") or {}
	function N.sh(path)
		local node = N.Sh
		for part in string.gmatch(path, "[^%.]+") do
			if type(node) ~= "table" then
				return nil
			end
			local ok, child = pcall(function()
				return node[part]
			end)
			if not ok then
				return nil
			end
			node = child
		end
		return node
	end
	-- Player actions the hub may send, all through the game's Warp wrapper Events.Client(name):Fire(true, ...) like the
	-- game's own client. Never: IdleRejoin (kick/rejoin report), CMDR/AdminGift/GiveCash/TesterTool (admin), Shop,
	-- ProductGift, AdReward, StarterPackOffer, CreatorHub (Robux or ads), Gift, Party, Boat (speed validated driving).
	local Allowed = {
		ThrowRod = true,
		FishHooked = true,
		ReelBait = true,
		FishCaught = true,
		CancelThrow = true,
		Upgrades = true,
		RodShop = true,
		BaitShop = true,
		ConsumeBait = true,
		Potion = true,
		EquipTool = true,
		Lock = true,
		Teleport = true,
		Enchant = true,
		MutationReroll = true,
		FishingObject = true,
		JoJoUnbox = true,
		LikeGift = true,
		BossRelic = true,
		BigMouth = true,
		Pond = true,
		Offline = true,
		DailyRewards = true,
		DailyClaimable = true,
		PlaytimeGift = true,
		NextDayReward = true,
		EarlyLeaveReward = true,
		Comeback = true,
		Season = true,
		Achievement = true,
		Codes = true,
		GroupReward = true,
		Referral = true,
		Settings = true,
		Tutorial = true,
		PondGuide = true,
		DoubleSpeed = true,
		OfflineNet = true,
		StreakHold = true,
		HatchEgg = true,
		EquipPet = true,
		Cargo = true,
	}
	local Functions = { Sell = true, SellAll = true }
	-- The fishing loop logs its own CAST/HOOK lines, these stay out of the SEND lines.
	local Quiet = { ThrowRod = true, FishHooked = true, ReelBait = true, FishCaught = true, EquipTool = true, Lock = true }
	-- Only these first arguments (the ad "Watch", party, gift and pond visiting kinds are never sent).
	local Kinds = {
		DailyClaimable = { Claim = true, Sync = true },
		Pond = { Collect = true, AddFish = true, AddFood = true, BuyFood = true, Upgrade = true, EquipBest = true, SellAllDead = true, ReviveHeart = true },
		MutationReroll = { Spin = true, Skip = true },
		Settings = { RareCutscene = true, TeleportCutscene = true, AutoFeed = true },
		OfflineNet = { Buy = true },
		HatchEgg = { Place = true, Hatch = true },
		EquipPet = { Equip = true },
		Cargo = { Sync = true, Give = true, Send = true, Claim = true },
	}
	N.Sent = { count = 0, byName = {}, window = {}, recent = {} }
	function N.remoteExists(name)
		local events = ReplicatedStorage:FindFirstChild("Events")
		local folder = events and events:FindFirstChild(if Functions[name] then "RemoteFunctions" else "RemoteEvents")
		return folder ~= nil and folder:FindFirstChild(name) ~= nil
	end
	-- Warp drops a remote's batch over 200 calls / 2 s, and >= 100 packets / 1 s per player trips its spam signal.
	-- The hub stays far below: 120 per remote per 2 s and 15 calls per second in total.
	local function pace(name)
		local now = os.clock()
		local recent = N.Sent.recent
		while #recent > 0 and now - recent[1] > 1 do
			table.remove(recent, 1)
		end
		local w = N.Sent.window[name]
		if not w or now - w.at > 2 then
			w = { at = now, n = 0 }
			N.Sent.window[name] = w
		end
		if (#recent >= 15 or w.n >= 120) and coroutine.isyieldable() then
			task.wait(if #recent >= 15 then math.max(1 - (now - recent[1]), 0.05) else math.max(2 - (now - w.at), 0.05))
			pace(name)
			return
		end
		w.n += 1
		table.insert(recent, os.clock())
	end
	local function event(name)
		local Ev = N.Sh.Events
		if type(Ev) ~= "table" or type(Ev.Client) ~= "function" or not N.remoteExists(name) then
			return nil
		end
		local ok, obj = pcall(Ev.Client, name)
		return if ok then obj else nil
	end
	N.event = event
	function send(name, ...)
		local first = ...
		if not Allowed[name] or (Kinds[name] and not Kinds[name][first]) then
			log("BLOCKED", name, brief(first))
			return false
		end
		local obj = event(name)
		if not obj then
			log("NO REMOTE", name)
			return false
		end
		pace(name)
		local args = table.pack(...)
		local ok, err = pcall(function()
			obj:Fire(true, table.unpack(args, 1, args.n))
		end)
		N.Sent.count += 1
		N.Sent.byName[name] = (N.Sent.byName[name] or 0) + 1
		if not Quiet[name] or not ok then
			log("SEND", name, brief(table.pack(...)), if ok then "" else "failed: " .. tostring(err))
		end
		return ok
	end
	-- RemoteFunctions (Sell, SellAll): the game's Invoke(timeout, ...). Returns the server's answer or nil.
	function invoke(name, ...)
		if not Functions[name] then
			log("BLOCKED", name)
			return nil
		end
		local obj = event(name)
		if not obj then
			log("NO REMOTE", name)
			return nil
		end
		pace(name)
		local args = table.pack(...)
		local ok, result = pcall(function()
			return obj:Invoke(5, table.unpack(args, 1, args.n))
		end)
		N.Sent.count += 1
		N.Sent.byName[name] = (N.Sent.byName[name] or 0) + 1
		if not ok then
			log("INVOKE failed", name, tostring(result))
			return nil
		end
		return result
	end
	-- One extra callback on a game event (Warp allows several); the hub's handlers never yield.
	N.Listeners = {}
	function N.listen(name, fn)
		task.spawn(function()
			local obj
			local waited = 0
			while not obj and waited < 30 and alive() do
				obj = event(name)
				if not obj then
					waited += task.wait(1) or 1
				end
			end
			if not obj then
				log("NO REMOTE", "listen " .. name)
				return
			end
			local ok, err = pcall(function()
				obj:Connect(function(...)
					if not alive() then
						return
					end
					local fine, problem = pcall(fn, ...)
					if not fine then
						log("ERROR", "event " .. name, tostring(problem))
					end
				end)
			end)
			if ok then
				N.Listeners[name] = true
			else
				log("ERROR", "listen " .. name, tostring(err))
			end
		end)
	end
	function waitFor(check, seconds)
		local waited = 0
		while waited < seconds do
			if check() then
				return true
			end
			waited += task.wait(0.05) or 0.05
		end
		return check() and true or false
	end
end
local formatNumber, allows, selected, on, optionNumber, optionText, Status, setStatus, picked
do
	local Suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
	function formatNumber(n)
		n = tonumber(n) or 0
		if n ~= n or n == math.huge then
			return "?"
		end
		local negative = n < 0
		n = math.abs(n)
		local text
		if n < 1000 then
			text = if n % 1 == 0 or n >= 100 then tostring(math.floor(n)) else (string.format("%.1f", n):gsub("%.0$", ""))
		else
			local i = 1
			while n >= 1000 and i < #Suffixes do
				n /= 1000
				i += 1
			end
			text = string.format("%.2f", n):gsub("%.?0+$", "") .. Suffixes[i]
		end
		return (if negative then "-" else "") .. text
	end
	function N.longTime(seconds)
		seconds = math.max(0, math.floor(tonumber(seconds) or 0))
		if seconds >= 3600 then
			return string.format("%dh %dm", seconds // 3600, (seconds % 3600) // 60)
		elseif seconds >= 60 then
			return string.format("%dm", math.ceil(seconds / 60))
		end
		return string.format("%ds", seconds)
	end
	function allows(option, value)
		local v = option and option.Value
		if v == nil then
			return true
		end
		if type(v) == "table" then
			if next(v) == nil then
				return true
			end
			return v[value] == true
		end
		return v == value
	end
	function selected(option, value)
		local v = option and option.Value
		if type(v) == "table" then
			return v[value] == true
		end
		return v == value
	end
	function picked(option)
		local list = {}
		local v = option and option.Value
		if type(v) == "table" then
			for key, yes in pairs(v) do
				if yes then
					table.insert(list, key)
				end
			end
			table.sort(list)
		elseif type(v) == "string" and v ~= "" then
			table.insert(list, v)
		end
		return list
	end
	-- Every feature is its own toggle (no master toggle). A job runs only when the player switched its toggle on.
	function on(name)
		local t = Toggles[name]
		return t ~= nil and t.Value == true
	end
	function optionNumber(name, default)
		local option = Options[name]
		return tonumber(option and option.Value) or default
	end
	function optionText(name, default)
		local option = Options[name]
		local value = option and option.Value
		return if type(value) == "string" and value ~= "" then value else default
	end
	-- Smart Planner (one toggle, default off) = autopilot: it plays the whole game by itself (fishes, sells, buys by payback,
	-- pond, rewards, codes, Big Mouth, items) even when every other toggle is off, through the same functions the toggles use.
	function N.planner()
		return on("SmartPlanner")
	end
	-- A job runs when its own toggle is on or the planner drives it. Sub-options (mode, thresholds, protect lists) still apply.
	function N.wants(name)
		return on(name) or N.planner()
	end
	-- Cash the planner keeps for the purchase it is saving for (only while that purchase is minutes away).
	function N.reserve()
		local P = N.Plan
		return if P and N.planner() and P.need and (P.eta or 1) <= 0.25 then (tonumber(P.need.price) or 0) else 0
	end
	-- The planner never waits without a reason: when it cannot act, the real reason goes to the log (once a minute per reason)
	-- and to the Status line.
	local IdleAt = {}
	function N.planIdle(reason, status)
		setStatus(status or ("Waiting: " .. reason))
		if N.planner() and os.clock() - (IdleAt[reason] or -1e9) > 60 then
			IdleAt[reason] = os.clock()
			log("PLAN idle", "reason=" .. reason)
		end
	end
	-- Movement: Teleport (default, the game checks no player movement) or Walk.
	function N.safeMove()
		return false -- always teleport
	end
	-- Chore timer: true at most once per `seconds` for a key.
	local DueAt = {}
	function N.due(key, seconds)
		local now = os.clock()
		if now >= (DueAt[key] or 0) then
			DueAt[key] = now + seconds
			return true
		end
		return false
	end
	function N.undue(key)
		DueAt[key] = nil
	end
	Status = "Idle"
	local StatusSeen, StatusSeenCount = {}, 0
	function setStatus(text)
		if Status ~= text then
			local now = os.clock()
			if now - (StatusSeen[text] or -1e9) > 4 then
				log("STATUS", text)
			end
			if not StatusSeen[text] then
				StatusSeenCount += 1
				if StatusSeenCount > 400 then
					table.clear(StatusSeen)
					StatusSeenCount = 0
				end
			end
			StatusSeen[text] = now
			Log.statusAt = now
		end
		Status = text
	end
	Log.context = function()
		return Status
	end
	-- Player data: the game's own replica (Shared.PlayerData.Client.Data), read only.
	function N.data()
		local pd = N.Sh.PlayerData
		local client = type(pd) == "table" and rawget(pd, "Client")
		local data = type(client) == "table" and client.Data
		return if type(data) == "table" then data else {}
	end
	function N.ready()
		return next(N.data()) ~= nil
	end
	function N.cash()
		return tonumber(N.data().Cash) or 0
	end
	function N.level()
		return tonumber(N.data().Level) or 1
	end
	function N.tab(key)
		local v = N.data()[key]
		return if type(v) == "table" then v else {}
	end
	function N.serverTime()
		local ok, now = pcall(function()
			return workspace:GetServerTimeNow()
		end)
		return if ok and type(now) == "number" then now else os.time()
	end
	-- World key ("World 1", "World 2", "Pond", ...) from PlayerData.World (the game stores the key or the UI name).
	function N.worldKey()
		local raw = N.data().World or "World 1"
		local cfg = N.sh("Config.WorldsConfig")
		if type(cfg) == "table" and type(cfg.KeyFromUIName) == "function" then
			local ok, key = pcall(cfg.KeyFromUIName, raw)
			if ok and type(key) == "string" then
				return key
			end
		end
		return raw
	end
	function N.worldCfg(key)
		local cfg = N.sh("Config.WorldsConfig")
		local worlds = type(cfg) == "table" and cfg.Worlds
		return type(worlds) == "table" and worlds[key or N.worldKey()] or nil
	end
	function N.worldNumber(key)
		local w = N.worldCfg(key)
		return w and tonumber(w.WorldNumber) or 0
	end
	function N.unlocked(key)
		return N.tab("UnlockedWorlds")[key] == true
	end
	-- Fishing worlds unlocked, best (highest number) first.
	function N.bestFishingWorld()
		local best, bestNumber = "World 1", 1
		for key, yes in pairs(N.tab("UnlockedWorlds")) do
			local n = N.worldNumber(key)
			local w = N.worldCfg(key)
			if yes and w and not w.NoFishing and n > bestNumber then
				best, bestNumber = key, n
			end
		end
		return best, bestNumber
	end
	-- Inventory (guid -> item {Type, Name, Data}).
	function N.inv()
		return N.tab("Inventory")
	end
	function N.isLocked(item)
		local lockMod = N.sh("Modules.Lock")
		if type(lockMod) == "table" and type(lockMod.IsLocked) == "function" then
			local ok, yes = pcall(lockMod.IsLocked, item)
			if ok then
				return yes == true
			end
		end
		return type(item.Data) == "table" and item.Data.Locked == true
	end
	function N.fishDef(name)
		local fish = N.sh("Content.Item.Fish")
		if type(fish) ~= "table" or type(fish.Get) ~= "function" then
			return nil
		end
		local ok, def = pcall(fish.Get, fish, name, true)
		return if ok and type(def) == "table" then def else nil
	end
	-- Sell value with every multiplier the game applies (size, mutation, gamepasses, index, enchants, CashBoost, potion).
	function N.value(item)
		local svc = N.sh("Services.Item")
		if type(svc) ~= "table" or type(svc.GetSellValue) ~= "function" then
			local def = item and N.fishDef(item.Name)
			return def and tonumber(def.SellPrice) or 0
		end
		local ok, v = pcall(svc.GetSellValue, svc, LocalPlayer, item)
		return if ok and type(v) == "number" then v else 0
	end
	function N.fishValue(name, size, mutation)
		return N.value({ Type = "Fish", Name = name, Data = { Size = size or 1, Mutation = mutation } })
	end
	-- Relic fish (boss relics): Services.Backpack:RelicKey(item) names the relic, Data.Used once consumed.
	function N.relicOf(item)
		local bp = N.sh("Services.Backpack")
		if type(bp) ~= "table" or type(bp.RelicKey) ~= "function" then
			return nil
		end
		local ok, key = pcall(bp.RelicKey, bp, item)
		if ok and key ~= nil and not (type(item.Data) == "table" and item.Data.Used) then
			return key
		end
		return nil
	end
	-- Fish the Keep lists protect (rarities, species, mutated): Smart Sell locks them right before every sale, so they are
	-- never part of the sellable value the planner counts on (a kept 361K Secret fish once made a "fund" sale come up
	-- short of the rod price and the buy never followed).
	function N.keeps(item, def)
		def = def or N.fishDef(item.Name)
		local rarity = def and def.Rarity or "Common"
		if selected(Options.KeepRarities, rarity) or selected(Options.KeepFish, tostring(item.Name)) then
			return true
		end
		return on("KeepMutated") and type(item.Data) == "table" and item.Data.Mutation ~= nil
	end
	-- Fish in the backpack: count, sellable count and sellable value (not locked, not kept, not an unused relic) and the
	-- value of every fish (the income tracker's worth). Values are cached per item for a minute and the whole scan for
	-- 2 s (a full backpack holds 2500 fish).
	local ValueCache, Stats = {}, { at = -1e9 }
	function N.cachedValue(guid, item)
		local now = os.clock()
		local c = ValueCache[guid]
		if not c or now - c.at > 60 or c.item ~= item then
			c = { v = N.value(item), at = now, item = item }
			ValueCache[guid] = c
		end
		return c.v
	end
	function N.fishStats(fresh)
		local now = os.clock()
		if not fresh and now - Stats.at < 2 then
			return Stats.count, Stats.sellable, Stats.value, Stats.total
		end
		local count, sellable, value, total = 0, 0, 0, 0
		local inv = N.inv()
		for guid, item in pairs(inv) do
			if type(item) == "table" and item.Type == "Fish" then
				count += 1
				if not N.relicOf(item) then
					local def = N.fishDef(item.Name)
					if not def or def.SellPrice then
						local v = N.cachedValue(guid, item)
						total += v
						if not N.isLocked(item) and not N.keeps(item, def) then
							sellable += 1
							value += v
						end
					end
				end
			end
		end
		if now - (Stats.trimAt or 0) > 300 then
			Stats.trimAt = now
			for guid in pairs(ValueCache) do
				if inv[guid] == nil then
					ValueCache[guid] = nil
				end
			end
		end
		Stats.at, Stats.count, Stats.sellable, Stats.value, Stats.total = now, count, sellable, value, total
		return count, sellable, value, total
	end
	function N.backpack()
		local bp = N.sh("Services.Backpack")
		if type(bp) == "table" and type(bp.GetCap) == "function" then
			local ok, res = pcall(bp.GetCap, bp)
			if ok and type(res) == "table" and tonumber(res.Cap) then
				return tonumber(res.Count) or 0, tonumber(res.Cap)
			end
		end
		local n = 0
		for _ in pairs(N.inv()) do
			n += 1
		end
		return n, 2500
	end
	function N.itemsOf(kind)
		local out = {}
		for guid, item in pairs(N.inv()) do
			if type(item) == "table" and item.Type == kind then
				table.insert(out, { guid = guid, item = item })
			end
		end
		table.sort(out, function(a, b)
			return tostring(a.guid) < tostring(b.guid)
		end)
		return out
	end
	-- Character
	function N.char()
		return LocalPlayer.Character
	end
	function N.root()
		local char = LocalPlayer.Character
		return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	end
	function N.humanoid()
		local char = LocalPlayer.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end
	function N.alive()
		local hum = N.humanoid()
		return hum ~= nil and hum.Health > 0 and N.root() ~= nil
	end
	function N.myPos()
		local root = N.root()
		return root and root.Position
	end
	function N.tp(pos)
		local char = LocalPlayer.Character
		local root = N.root()
		if not (char and root) then
			return false
		end
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
		end)
		return (pcall(function()
			char:PivotTo(CFrame.new(pos))
		end))
	end
	-- Goes to a spot: Teleport (default, the game has no movement check) pivots there; Walk uses Humanoid:MoveTo with a
	-- jump when stuck and gives up after the timeout.
	function N.goTo(pos, near, timeout)
		near = near or 6
		local root = N.root()
		if not root then
			return false
		end
		local function flat()
			local p = N.myPos() or pos
			return Vector3.new(p.X - pos.X, 0, p.Z - pos.Z).Magnitude
		end
		if flat() <= near then
			return true
		end
		if not N.safeMove() then
			-- Right after a spawn or a world change the game still moves the character (cutscene, streaming), so the first
			-- pivots can be undone: retry for about 3 s before calling it a problem.
			for try = 1, 6 do
				N.tp(pos + Vector3.new(0, 3, 0))
				task.wait(0.3 + 0.1 * try)
				if flat() <= near then
					return true
				end
			end
			logProblem(string.format("Teleport did not land on the spot (%.0f studs off)", flat()))
			return false
		end
		local hum = N.humanoid()
		if not hum then
			return false
		end
		local started, sentAt, lastDist, lastAt = os.clock(), -1e9, flat(), os.clock()
		timeout = timeout or 30
		while os.clock() - started < timeout and alive() do
			if os.clock() - sentAt >= 2 then
				sentAt = os.clock()
				pcall(function()
					hum:MoveTo(pos)
				end)
			end
			local d = flat()
			if d <= near then
				return true
			end
			if lastDist - d > 1 then
				lastDist, lastAt = d, os.clock()
			elseif os.clock() - lastAt > 1.5 then
				lastAt = os.clock()
				pcall(function()
					hum.Jump = true
				end)
			end
			task.wait(0.1)
		end
		logProblem(string.format("Walk did not reach the spot (%.0f studs left). Movement Teleport skips walking", flat()))
		return false
	end
	-- The current world's folder (workspace.World.<world>) and a named spot in it (NPC_Sell, Throw, BigMouthFish, ...).
	function N.worldFolder()
		local root = workspace:FindFirstChild("World")
		return root and (root:FindFirstChild(N.worldKey()) or root:FindFirstChild(N.data().World or ""))
	end
	function N.spot(name)
		local folder = N.worldFolder()
		local inter = folder and folder:FindFirstChild("Interactable")
		local inst = (inter and inter:FindFirstChild(name)) or (folder and folder:FindFirstChild(name, true))
		if not inst then
			return nil
		end
		local ok, pos = pcall(function()
			if inst:IsA("BasePart") then
				return inst.Position
			end
			return inst:GetPivot().Position
		end)
		return if ok then pos else nil
	end
	-- Equips a backpack tool (rod by name) the way the game's AutoFishing:EquipRod does.
	function N.holdTool(name)
		local char = N.char()
		if not char then
			return false
		end
		local held = char:FindFirstChildOfClass("Tool")
		if held and held.Name == name then
			return true
		end
		local bp = LocalPlayer:FindFirstChild("Backpack")
		local tool = bp and bp:FindFirstChild(name)
		local hum = N.humanoid()
		if not (hum and tool and tool:IsA("Tool")) then
			return false
		end
		pcall(function()
			hum:EquipTool(tool)
		end)
		return true
	end
	-- Items (fish, chests, stones) are equipped through the game's EquipTool remote, like a hotbar click.
	function N.holdItem(guid)
		send("EquipTool", guid, "Equip")
		task.wait(0.35)
	end
end
local Session = {
	started = os.clock(),
	casts = 0,
	perfect = 0,
	hooked = 0,
	caught = 0,
	castValue = 0,
	specials = 0,
	fights = 0,
	refused = 0,
	sold = 0,
	soldValue = 0,
	upgrades = 0,
	rods = 0,
	baits = 0,
	worlds = 0,
	claims = 0,
	codes = 0,
	opened = 0,
	potions = 0,
	relics = 0,
	pondTrips = 0,
	bigMouth = 0,
	enchants = 0,
	mutations = 0,
	best = 0,
	bestName = "-",
	cashStart = nil,
	levelStart = nil,
}
N.Events = {}
N.Fish = {
	cast = nil,
	last = "",
	engine = "-",
	canThrow = nil,
	refusals = {},
	fails = 0,
	fallbackUntil = 0,
	fallbackReason = "",
	cycle = 0,
	evCast = 0,
	af = nil,
	afTried = false,
	patched = nil,
	orig = {},
	paused = false,
	mode = "safe",
}
do
	local F = N.Fish
	-- Cast cadence (player report: "fast, then slow, then fast again"): casts per minute in 1-minute windows, the pauses
	-- (trips) that cost time in the window, and a SLOW line with the dominant cause when a minute is under 60% of the best.
	N.Rate = { start = os.clock(), casts = 0, tSum = 0, best = 0, causes = {}, minutes = 0 }
	function N.rateCause(why)
		local R = N.Rate
		R.causes[why] = (R.causes[why] or 0) + 1
	end
	function N.rateCast(took)
		local R = N.Rate
		R.casts += 1
		R.tSum += tonumber(took) or 0
	end
	function N.rateTick()
		local R = N.Rate
		if os.clock() - R.start < 60 then
			return
		end
		local span = (os.clock() - R.start) / 60
		local perMin = R.casts / span
		local avgT = if R.casts > 0 then R.tSum / R.casts else 0
		log("RATE", "casts/min=" .. string.format("%.1f", perMin), "avg cast t=" .. string.format("%.1f", avgT), "best minute=" .. string.format("%.1f", R.best))
		if R.minutes >= 2 and R.best > 0 and perMin < 0.6 * R.best and (N.wants("AutoFish") or N.planner()) then
			local cause, count = "longer fights (avg cast " .. string.format("%.1f", avgT) .. " s)", 0
			for why, n in pairs(R.causes) do
				if n > count then
					cause, count = "pause: " .. why .. " x" .. n, n
				end
			end
			log("SLOW", "cause=" .. cause, "casts/min=" .. string.format("%.1f", perMin), "best=" .. string.format("%.1f", R.best))
		end
		R.minutes += 1
		R.best = math.max(R.best, perMin)
		R.start, R.casts, R.tSum, R.causes = os.clock(), 0, 0, {}
	end
	-- Auto Fish mode (default "Fast (default)"): always the fastest way that works. Any danger signal while fast (refused
	-- casts, casts without an answer or catch window, a client error/kick message) = the game's own auto fishing for 30
	-- minutes, and 3 such fallbacks in a day switch the fast way off for the day. "Legit" pins the game's auto fishing.
	F.ladder = { phase = "measureSafe", mode = "safe", t0 = nil, w0 = 0, safe = nil, blat = nil, keep = "safe", falls = {}, dayOffUntil = 0, ratio = nil }
	local L = F.ladder
	local function modeChoice()
		return "Fast" -- forced; the danger fallback below still switches to the game's auto fishing
	end
	function N.fishMode()
		return "blatant" -- Fast only, no fallback to the game's auto fishing
	end
	-- No ladder (owner 2026-10-06): the planner always fishes in the fastest mode that works; Safe only after a danger signal.
	function N.ladderTick() end
	function N.modeText()
		local c = modeChoice()
		if os.clock() < F.fallbackUntil then
			return "Fishing with the game's auto fishing (fast way paused " .. tostring(F.pauseText or "30 min") .. ": " .. F.fallbackReason .. ")"
		end
		if os.clock() < L.dayOffUntil then
			return "Fishing with the game's auto fishing (fast way off for the day)"
		end
		if c == "Legi" then
			return "Fishing with the game's auto fishing (your choice)"
		end
		return "Fishing at full speed"
	end
	function N.fallback(reason)
		-- Fast only: a danger signal is logged, fishing stays on Fast
		if N.due("fallbackLog", 60) then
			log("MODE danger signal ignored (Fast only)", "reason=" .. tostring(reason))
		end
		do
			return
		end
		local now = os.clock()
		-- First fallback of the day: 5 minutes (the first throws right after joining often get no answer while the character settles at the pier); later ones 30 minutes.
		local pause = if #L.falls == 0 then 300 else 1800
		F.fallbackUntil = now + pause
		F.fallbackReason = reason
		F.pauseText = if pause >= 1800 then "30 min" else "5 min"
		L.phase, L.mode, L.keep = "cooldown", "safe", "safe"
		table.insert(L.falls, now)
		while #L.falls > 0 and now - L.falls[1] > 86400 do
			table.remove(L.falls, 1)
		end
		log("MODE fallback blatant -> safe", "reason=" .. tostring(reason), "retry in " .. F.pauseText, "falls today=" .. #L.falls)
		if #L.falls >= 3 then
			L.dayOffUntil = now + 86400
			log("MODE blatant off for the day", "falls=" .. #L.falls)
		end
		notify("Auto Fish", "Fast fishing paused for " .. F.pauseText .. " (" .. tostring(reason) .. "), using the game's auto fishing meanwhile", 6)
	end
	pcall(function()
		game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
			if alive() and N.fishMode() == "blatant" and tostring(msg) ~= "" then
				N.fallback("client message: " .. string.sub(tostring(msg), 1, 60))
			end
		end)
	end)
	-- Hooks per cast exactly like the game's client (ThrowCinematic:GetBaitCapacity): Capacity upgrade of this world +
	-- HookSlots enchants, never more than the free backpack slots.
	function N.hookCapRaw()
		local d = N.data()
		local U = N.sh("Config.UpgradesConfig")
		local cap = 3
		pcall(function()
			local key = U.KeyForData(d)
			local level = U.LevelOf(d, "Capacity", key)
			local W = N.sh("Config.WorldsConfig")
			local effect = (W.ForPlayerData(d).UpgradeEffect or 1)
			cap = U.CapacityValue(level, effect, key)
		end)
		pcall(function()
			cap += N.sh("Modules.Enchant").Add(d, "HookSlots") or 0
		end)
		return math.max(cap, 1)
	end
	function N.hookCap()
		local d = N.data()
		local U = N.sh("Config.UpgradesConfig")
		local cap = 3
		pcall(function()
			local key = U.KeyForData(d)
			local level = U.LevelOf(d, "Capacity", key)
			local W = N.sh("Config.WorldsConfig")
			local effect = (W.ForPlayerData(d).UpgradeEffect or 1)
			cap = U.CapacityValue(level, effect, key)
		end)
		pcall(function()
			cap += N.sh("Modules.Enchant").Add(d, "HookSlots") or 0
		end)
		local count, max = N.backpack()
		return math.max(math.min(cap, max - count), 0)
	end
	function N.fightRequired(name, boss)
		local CF = N.sh("Modules.CatchFight")
		if type(CF) ~= "table" or type(CF.Required) ~= "function" then
			return nil
		end
		local def = if boss then CF.Boss else N.fishDef(name)
		local ok, req = pcall(CF.Required, def)
		return if ok and type(req) == "number" and req > 0 then req else nil
	end
	-- Seconds one hook keeps the cast open: the spacing between hooks plus, for fish with a fight, the sequential fight
	-- (required clicks at 10 per second in Blatant, 7 at the legit pace; castOnce waits exactly this). Cast time is money:
	-- the planner's income per second prices every one of these seconds.
	function N.hookSeconds(name, boss)
		local req = N.fightRequired(name, boss)
		if N.fishMode() == "blatant" then
			return 0.11 + (if req then req / 10 + 0.15 else 0)
		end
		return 0.6 + (if req then req / 7 + 0.4 else 0)
	end
	-- The pier (the world's Interactable.Throw area). The server takes a cast only inside it or on a stopped boat.
	function N.throwArea()
		local folder = N.worldFolder()
		local inter = folder and folder:FindFirstChild("Interactable")
		return inter and inter:FindFirstChild("Throw")
	end
	function N.pierPos()
		local area = N.throwArea()
		local part = area and (area:FindFirstChild("Part") or area:FindFirstChildWhichIsA("BasePart", true))
		if not part then
			return nil
		end
		local att = part:FindFirstChild("PierTutorialAttachment")
		if att then
			local ok, pos = pcall(function()
				return att.WorldPosition
			end)
			if ok and pos then
				return pos
			end
		end
		return part.Position
	end
	function N.atPier()
		if F.canThrow == true then
			return true
		end
		local pos = N.myPos()
		local area = N.throwArea()
		if not (pos and area) then
			return false
		end
		local ThrowArea = N.sh("Modules.ThrowArea")
		if type(ThrowArea) == "table" and type(ThrowArea.IsInside) == "function" then
			local ok, inside = pcall(ThrowArea.IsInside, area, pos)
			if ok then
				return inside == true
			end
		end
		local part = area:FindFirstChild("Part")
		if part then
			local d, s = pos - part.Position, part.Size
			return math.abs(d.X) <= s.X / 2 + 2 and math.abs(d.Z) <= s.Z / 2 + 2 and math.abs(d.Y) <= s.Y / 2 + 6
		end
		return false
	end
	function N.goPier()
		if N.atPier() then
			return true
		end
		local pos = N.pierPos()
		if not pos then
			setStatus("Waiting for the pier to load")
			return false
		end
		setStatus("Going to the pier")
		N.goTo(pos, 3)
		return waitFor(N.atPier, 2)
	end
	function N.rodHeld()
		local char = N.char()
		local tool = char and char:FindFirstChildOfClass("Tool")
		return tool ~= nil and tool.Name == (N.data().RodEquipped or "Wooden Rod")
	end
	function N.equipRod()
		if N.rodHeld() then
			return true
		end
		N.holdTool(N.data().RodEquipped or "Wooden Rod")
		return waitFor(N.rodHeld, 1.5)
	end
	-- Server events of the cast (the game's own ThrowRod channel): Started / Catch / Landed / Refused.
	N.listen("ThrowRod", function(kind, a, b)
		local cast = F.cast
		if kind == "Started" and type(a) == "table" then
			F.lastSchool = a
			if not cast then
				-- A cast of the game's own auto fishing (Safe mode).
				Session.casts += 1
			end
			if cast and not cast.payload then
				cast.payload = a
				cast.startedAt = os.clock()
			end
		elseif kind == "Catch" then
			if cast and cast.payload then
				if a then
					cast.windowOpen = true
					cast.openedAt = os.clock()
				else
					cast.windowOpen = false
					cast.closed = true
				end
			end
		elseif kind == "Landed" then
			if cast and cast.payload then
				cast.landed = true
			end
		elseif kind == "Refused" then
			Session.refused += 1
			if cast then
				cast.refused = tostring(a)
			end
			log("THROW refused", tostring(a))
			local now = os.clock()
			table.insert(F.refusals, now)
			while #F.refusals > 0 and now - F.refusals[1] > 60 do
				table.remove(F.refusals, 1)
			end
			if N.fishMode() == "blatant" then
				local code = string.lower(tostring(a))
				if string.find(code, "flag", 1, true) or string.find(code, "suspect", 1, true) or string.find(code, "cheat", 1, true) then
					N.fallback("server answer " .. tostring(a))
				elseif #F.refusals >= 3 then
					N.fallback("server refused 3 casts in a minute")
				end
			end
		end
	end)
	N.listen("Fishing", function(kind)
		if kind == "Entered" then
			F.canThrow = true
		elseif kind == "Left" then
			F.canThrow = false
		end
	end)
	-- Power of a throw: Perfect (0.40-0.55, quality 2) with the Perfect Rate chance, else Good (quality 1.5), with the
	-- same tiny jitter as the game's StopHook.
	local function throwPower(rate)
		local perfect = math.random() < rate
		local p
		if perfect then
			p = 0.41 + math.random() * 0.12
		elseif math.random() < 0.5 then
			p = 0.15 + math.random() * 0.22
		else
			p = 0.58 + math.random() * 0.3
		end
		return p + (1 + math.random() * 8) * 1e-7, perfect
	end
	N.throwPower = throwPower
	-- Ranks the school: every special (scrolls, keys, chests) first, then the fish by sell value. Returns the plan list.
	function N.rankSchool(payload, cap)
		local school = type(payload.school) == "table" and payload.school or {}
		local sizes = type(payload.sizes) == "table" and payload.sizes or {}
		local muts = type(payload.mutations) == "table" and payload.mutations or {}
		local fish = {}
		for i, name in ipairs(school) do
			local boss = payload.boss == i
			local value = N.fishValue(name, sizes[i], muts[i]) * (if boss then 2 else 1)
			-- Index Hunt: a species missing from the index counts 50% more (every 10/25/50/75/100 species = +10% on all sales).
			local index = N.tab("Index").Fish
			if on("IndexHunt") and type(index) == "table" and not index[name] then
				value = value * 1.5 + 1
			end
			table.insert(fish, { index = i, name = name, value = value, fight = N.fightRequired(name, boss), boss = boss })
		end
		-- Value per second (planner): a hook is worth its sell value minus what its seconds cost at the current income rate
		-- (spacing + fight). Fish are ranked by that net, the ones below zero stay in the water (the cast simply ends sooner),
		-- bosses and the index hunt are never skipped. Without the planner: plain best value first, like the game's client.
		local rate = if N.planner() then N.incomeRate() else 0
		if rate > 1 then
			for _, f in ipairs(fish) do
				f.net = f.value - rate * N.hookSeconds(f.name, f.boss)
			end
		end
		table.sort(fish, function(x, y)
			local a, b = x.net or x.value, y.net or y.value
			if a ~= b then
				return a > b
			end
			return x.index < y.index
		end)
		local picks = {}
		for k, special in ipairs(type(payload.specials) == "table" and payload.specials or {}) do
			table.insert(picks, { index = #school + k, special = true, name = if type(special) == "table" then tostring(special.Name or special.name or "special") else tostring(special) })
		end
		for i = 1, math.min(cap, #fish) do
			local f = fish[i]
			if f.net and f.net <= 0 and not f.boss and #picks > 0 then
				break
			end
			table.insert(picks, f)
		end
		return picks, fish
	end
	-- One cast through the remotes, by the server's rules (ThrowRod handler): hooks only while the catch window is open,
	-- one fight at a time for at least required/12 s, ReelBait only in the window, FishCaught once after Landed with
	-- only the hooked indices. Blatant: the best fish of the school at 0.1 s spacing, fights at required/10 s, reel
	-- right after the last hook. Legit pace: 0.35-0.7 s between hooks, fights at required/7 s, reel only when full.
	function N.castOnce(blatant)
		local cast = { sentAt = os.clock(), blatant = blatant, hooked = {}, value = 0 }
		F.cast = cast
		local power, perfect = throwPower(math.clamp(optionNumber("PerfectRate", 60) / 100, 0, if blatant then 0.6 else 0.95))
		send("ThrowRod", power)
		Session.casts += 1
		if perfect then
			Session.perfect += 1
		end
		if not waitFor(function()
			return cast.payload ~= nil or cast.refused ~= nil
		end, 4) then
			F.fails += 1
			log("THROW no answer", "power=" .. string.format("%.2f", power), "fails=" .. F.fails)
			send("CancelThrow")
			F.cast = nil
			if F.fails >= 3 and blatant then
				N.fallback("3 casts without an answer")
			end
			task.wait(1)
			return false
		end
		if cast.refused then
			F.cast = nil
			task.wait(1.5)
			return false
		end
		F.fails = 0
		local p = cast.payload
		local cap = N.hookCap()
		local picks, fish = N.rankSchool(p, cap)
		local waitOpen = (tonumber(p.arcDuration) or 2) + (tonumber(p.diveDuration) or 1) + (tonumber(p.holdDuration) or 0) + 12
		for _, b in ipairs(type(p.bounces) == "table" and p.bounces or {}) do
			waitOpen += tonumber(type(b) == "table" and b.Duration) or 0.5
		end
		if not waitFor(function()
			return cast.windowOpen or cast.closed
		end, waitOpen) then
			log("CAST no catch window", "throw=" .. tostring(p.throwId))
			F.noWindow = (F.noWindow or 0) + 1
			if blatant and F.noWindow >= 2 then
				N.fallback("2 casts without a catch window")
			end
		else
			F.noWindow = 0
		end
		local hookedList = {}
		local function hook(pick)
			if not cast.windowOpen or not alive() then
				return false
			end
			if pick.special then
				send("FishHooked", pick.index)
				Session.specials += 1
				log("SPECIAL", "k=" .. (pick.index - #(p.school or {})), "item=" .. tostring(pick.name))
			elseif pick.fight then
				send("FishHooked", pick.index, "fight", nil, true)
				Session.fights += 1
				task.wait(pick.fight / (if blatant then 10 else 7) + 0.15)
				send("FishHooked", pick.index, "won", pick.fight + math.random(0, 2))
			else
				send("FishHooked", pick.index)
			end
			cast.hooked[pick.index] = true
			table.insert(hookedList, pick.index)
			if not pick.special then
				cast.value += pick.value or 0
			end
			return true
		end
		if cast.windowOpen then
			task.wait(if blatant then 0.05 + math.random() * 0.1 else 0.6 + math.random() * 0.5)
			local fights = {}
			for _, pick in ipairs(picks) do
				if pick.fight then
					table.insert(fights, pick)
				elseif hook(pick) then
					task.wait(if blatant then 0.08 + math.random() * 0.05 else 0.35 + math.random() * 0.35)
				end
			end
			for _, pick in ipairs(fights) do
				if hook(pick) then
					task.wait(if blatant then 0.1 else 0.4 + math.random() * 0.3)
				end
			end
			local fishHooked = 0
			for _, pick in ipairs(picks) do
				if not pick.special and cast.hooked[pick.index] then
					fishHooked += 1
				end
			end
			-- The game's client reels by itself once the hook is full; Blatant reels right after the last hook. `true` is the
			-- client's early reel (RequestReel(true)): the server returns the line 22% faster (reelEarly, dump 187974).
			if cast.windowOpen and (blatant or (cap > 0 and fishHooked >= cap)) then
				send("ReelBait", true)
			end
		end
		local landWait = (tonumber(p.pullUpDuration) or 10) + (tonumber(p.returnDuration) or 2) + 20
		if not waitFor(function()
			return cast.landed == true
		end, landWait) then
			log("CAST no landing", "throw=" .. tostring(p.throwId))
			F.cast = nil
			return false
		end
		-- The server takes the claim only after Landed and minDuration - 0.5 s after the cast.
		task.wait(if blatant then 0.05 else 0.2 + math.random() * 0.3)
		local fishCount = 0
		for _, idx in ipairs(hookedList) do
			if idx <= #(p.school or {}) then
				fishCount += 1
			end
		end
		if #hookedList > 0 then
			send("FishCaught", p.throwId, hookedList, false)
		end
		local took = os.clock() - cast.sentAt
		Session.hooked += #hookedList
		Session.caught += fishCount
		Session.castValue += cast.value
		if cast.value > Session.best and fish[1] then
			Session.best = cast.value
		end
		if fish[1] and fish[1].value > 0 and cast.hooked[fish[1].index] and (tonumber(fish[1].value) or 0) >= (Session.bestFish or 0) then
			Session.bestFish = fish[1].value
			Session.bestName = fish[1].name
		end
		F.cycle = if F.cycle > 0 then F.cycle * 0.8 + took * 0.2 else took
		F.evCast = if F.evCast > 0 then F.evCast * 0.8 + cast.value * 0.2 else cast.value
		F.last = string.format("%d fish + %d finds, %s coins, %.1f s", fishCount, #hookedList - fishCount, formatNumber(cast.value), took)
		log(
			"CAST",
			"id=" .. tostring(p.throwId),
			"mode=" .. (if blatant then "blatant" else "safe-direct"),
			"perfect=" .. tostring(perfect),
			"school=" .. #(p.school or {}),
			"cap=" .. cap,
			"best=" .. formatNumber(fish[1] and fish[1].value or 0),
			"took=" .. formatNumber(cast.value),
			"hooks=" .. #hookedList,
			"t=" .. string.format("%.1f", took)
		)
		if N.Events.cast then
			pcall(N.Events.cast, fish[1], cast.hooked)
		end
		N.rateCast(took)
		F.cast = nil
		return true
	end
	-- Safe with the game's own Auto Fishing (Controllers.Fishing.AutoFishing): its own casts, steering, fights and
	-- pauses. Vader only points its target picker at the most valuable fish and sets the Perfect rate the game's
	-- AutoBoost enchant uses. Restored when Auto Fish goes off.
	local function findAutoFishing()
		if F.af or F.afTried then
			return F.af
		end
		F.afTried = true
		local node = LocalPlayer:FindFirstChild("PlayerScripts")
		for _, part in ipairs({ "Client", "Controllers", "Fishing", "AutoFishing" }) do
			node = node and node:FindFirstChild(part)
		end
		if not (node and node:IsA("ModuleScript")) then
			log("FISH engine", "game auto fishing not found, Safe uses the legit remote pace")
			return nil
		end
		local result, done = nil, false
		task.spawn(function()
			local ok, mod = pcall(require, node)
			result = ok and type(mod) == "table" and mod or nil
			done = true
		end)
		waitFor(function()
			return done
		end, 5)
		if result and type(rawget(result, "SetOn")) == "function" and type(rawget(result, "PickTarget")) == "function" then
			F.af = result
			log("FISH engine", "game auto fishing found")
		else
			log("FISH engine", "game auto fishing unusable, Safe uses the legit remote pace")
		end
		return F.af
	end
	N.findAutoFishing = findAutoFishing
	local function patch(AF)
		if F.patched == AF then
			return
		end
		F.orig = { PickTarget = rawget(AF, "PickTarget"), Boost = rawget(AF, "Boost") }
		F.patched = AF
		AF.PickTarget = function(self, list, hangY)
			if not (alive() and N.wants("AutoFish")) then
				return F.orig.PickTarget(self, list, hangY)
			end
			local best, bestScore
			for _, f in ipairs(list) do
				local okValid, valid = pcall(self.TargetValid, self, f, hangY)
				if okValid and valid then
					local score = if f.special then math.huge else N.fishValue(f.name, f.size, f.mutation or f.pendingMutation)
					if not best or score > bestScore then
						best, bestScore = f, score
					end
				end
			end
			return best
		end
		AF.Boost = function(self)
			if alive() and N.wants("AutoFish") then
				return math.clamp(optionNumber("PerfectRate", 60) / 100, 0, 0.95)
			end
			return F.orig.Boost(self)
		end
		log("FISH patched", "target=best value", "perfect=" .. math.floor(optionNumber("PerfectRate", 60)) .. "%")
	end
	function N.unpatch()
		local AF = F.patched
		if AF then
			pcall(function()
				if AF.On then
					AF:SetOn(false)
				end
			end)
			AF.PickTarget = F.orig.PickTarget
			AF.Boost = F.orig.Boost
			F.patched = nil
			log("FISH unpatched")
		end
	end
	-- Stops casting for a trip (sell, shop, pond): the game's auto fishing off and any cast finished first.
	function N.pauseFishing(why)
		F.paused = true
		N.rateCause(tostring(why))
		local AF = F.patched
		if AF and AF.On then
			pcall(AF.SetOn, AF, false)
		end
		waitFor(function()
			if F.cast then
				return false
			end
			local tc = AF and AF.Controllers and AF.Controllers.ThrowCinematic
			return not (tc and tc.Active)
		end, 40)
		if why then
			log("FISH pause", why)
		end
	end
	function N.resumeFishing()
		F.paused = false
	end
	-- Tutorial (Events.Tutorial): the server takes increasing step numbers 1..8 (8 = done, Beginner potion + baits).
	-- Vader sends each step after the matching real action (pier, cast, catch, sale, Strength, three catches, rod),
	-- with a 90 s fallback so it never stalls. Step 5 tops the cash up to the first Strength, step 7 to the cheapest rod.
	-- Tutorial hold (option, off): the tutorial stops at step 6 and stays there. The server doubles the luck of every cast
	-- at step 6 (x2 luck, x1.3 distance, 2 free bounces; dump 188368-188506); the price is no playtime gifts, quests or
	-- guaranteed scrolls while the tutorial is open. The game's own window would send step 7 after three catches, so the
	-- Tutorial channel is guarded: numbers above 6 are dropped while the hold is on.
	N.Tut = { at = -1e9, sentStep = nil, guarded = nil, dropped = 0, droppedAt = -1e9, released = false }
	local tutorialOnce
	-- The hold is for accounts still inside the tutorial (new farm accounts): at step 7 or later the x2 step is gone for good.
	function N.tutorialHold()
		local cur = tonumber(N.data().Tutorial) or -1
		return on("TutorialHold") and not N.Tut.released and cur < 100 and cur <= 6
	end
	-- Smart Planner decision for the hold (blatant.md NEW 1). Holding = x2 luck and x1.3 distance on every cast (estimate:
	-- +50% income, the low end of the doc's x1.6-x2.5). Finishing = the playtime gift (PlaytimeGiftConfig: 88 casts of
	-- coins at the expected cast value of the moment of the claim + Bumble Bait + a Luck potion, 40 minutes after the
	-- tutorial ends: deferred by the hold, not lost), plus quests and guaranteed scrolls (estimate 10% of income while the
	-- tutorial is open). The planner finishes only when the gift can still be collected before the 24 h window ends and
	-- finishing is worth more; otherwise it holds. Logs `TUTORIAL hold|finish reason=`.
	function N.tutorialDecide()
		local cur = tonumber(N.data().Tutorial) or -1
		if not on("TutorialHold") then
			N.Tut.released = false
			return
		end
		if cur >= 100 or cur > 6 then
			if N.due("tutNa", 3600) then
				log("TUTORIAL hold", "n/a", "reason=" .. (if cur >= 100 then "the account finished the tutorial, step 6 cannot be reached again" else "step " .. cur .. " is past the x2 luck step"))
			end
			return
		end
		if cur ~= 6 or N.Tut.released or not N.planner() or not N.due("tutDecide", 300) then
			return
		end
		local perHour = N.Econ.rate * 3600
		local ev = N.Fish.evCast
		if perHour <= 0 or ev <= 0 then
			return
		end
		local P = N.sh("Config.PlaytimeGiftConfig")
		local giftSeconds, giftCasts = 0, 0
		pcall(function()
			for _, stage in ipairs(P.Stages) do
				giftSeconds += tonumber(stage.Duration) or 0
				for _, reward in ipairs(stage.Rewards or {}) do
					giftCasts += tonumber(reward.Casts) or 0
				end
			end
		end)
		if giftSeconds <= 0 then
			giftSeconds, giftCasts = 2400, 88
		end
		local left = 24 - ((os.clock() - Session.started) / 3600) % 24
		local holdValue = 0.5 * perHour * left
		local finishValue = giftCasts * ev + 0.1 * perHour * left
		local canFinish = left * 3600 > giftSeconds + 600
		local text = string.format("x2 luck +50%% = %s over %.1f h vs gift %d casts + quests/scrolls = %s%s", formatNumber(holdValue), left, giftCasts, formatNumber(finishValue), if canFinish then "" else " (the gift no longer fits the window)")
		if canFinish and finishValue > holdValue then
			N.Tut.released = true
			log("TUTORIAL finish", "reason=" .. text)
		elseif N.due("tutHoldLog", 1800) then
			log("TUTORIAL hold", "reason=" .. text)
		end
	end
	function N.tutorialGuard()
		if N.Tut.guarded then
			return true
		end
		local obj = N.event("Tutorial")
		if not obj then
			return false
		end
		local ok = pcall(function()
			local fire = obj.Fire
			obj.Fire = function(self, reliable, n, ...)
				if type(n) == "number" and n > 6 and N.tutorialHold() then
					N.Tut.dropped += 1
					if os.clock() - N.Tut.droppedAt > 60 then
						N.Tut.droppedAt = os.clock()
						log("TUTORIAL hold", "dropped step " .. tostring(n), "(x2 luck stays)")
					end
					return
				end
				return fire(self, reliable, n, ...)
			end
		end)
		N.Tut.guarded = ok or nil
		if ok then
			log("TUTORIAL guard on", "steps above 6 are held back while Tutorial hold is on")
		end
		return ok
	end
	function N.tutorialStep()
		if N.tutorialHold() then
			N.tutorialGuard()
			if N.due("tutHoldPlan", 1800) then
				log("PLAN tutorial", "hold=on", "step=" .. tostring(N.data().Tutorial), "value=x2 luck, x1.3 distance per cast", "cost=no playtime gifts, quests or guaranteed scrolls")
			end
		end
		for _ = 1, 3 do
			if not tutorialOnce() then
				return
			end
			task.wait(2.5)
		end
	end
	function tutorialOnce()
		local cur = tonumber(N.data().Tutorial) or -1
		if cur >= 100 or cur >= 8 then
			return false
		end
		if cur >= 6 and N.tutorialHold() then
			return false
		end
		local nextStep = math.max(cur + 1, 1)
		local caught = math.max(Session.caught, tonumber(N.tab("Stats").FishCaught) or 0)
		local waited = os.clock() - N.Tut.at
		local ready = ({
			[1] = true,
			[2] = N.atPier(),
			[3] = Session.casts >= 1,
			[4] = caught >= 1,
			[5] = Session.sold >= 1 or waited > 90,
			[6] = (tonumber(N.tab("Upgrades").Strength) or 0) >= 1 or waited > 90,
			[7] = caught >= 3 or waited > 90,
			[8] = waited > 20,
		})[nextStep]
		if nextStep == 6 and (tonumber(N.tab("Upgrades").Strength) or 0) < 1 then
			local U = N.sh("Config.UpgradesConfig")
			local price = U and U.GetPrice and U.GetPrice("Strength", 0) or math.huge
			if N.cash() >= price then
				send("Upgrades", "Buy", "Strength")
				log("TUTORIAL buy Strength", formatNumber(price))
				task.wait(1)
				ready = true
			end
		end
		if nextStep == 8 and not N.tab("Rods")["Iron Rod"] and N.cash() >= 5000 then
			send("RodShop", "Buy", "Iron Rod")
			task.wait(0.5)
			send("RodShop", "Equip", "Iron Rod")
			log("TUTORIAL buy Iron Rod")
		end
		if ready and waited > 2 then
			N.Tut.at = os.clock()
			send("Tutorial", nextStep)
			log("TUTORIAL step", nextStep)
			return true
		end
		return false
	end
	-- Main fishing step (called by the main loop when Auto Fish or the Smart Planner is on and nothing else needs the
	-- character).
	function N.fishStep()
		N.ladderTick()
		F.mode = N.fishMode()
		if F.paused then
			task.wait(0.3)
			return
		end
		-- Sell before the cast when the backpack cannot take a whole school: the server drops every fish over the cap
		-- (FishCaught 189470), so a near-full backpack sells first (Smart Sell rules and protect lists) instead of wasting casts.
		local count, max = N.backpack()
		if max - count < N.hookCapRaw() then
			-- Before every cast that would not fit (a sale at a distant NPC is throttled to once per 20 s, a remote sale to 6 s).
			if N.wants("SmartSell") and N.due("sellFull", if N.Sell.needNpc then 20 else 6) then
				local _, sellable = N.fishStats(true)
				if sellable > 0 then
					N.sellNow(string.format("backpack %d/%d before the cast", count, max))
					count, max = N.backpack()
				end
			end
			if count >= max then
				N.pauseFishing("backpack full")
				F.paused = false
				if N.wants("SmartSell") then
					N.planIdle("backpack full of protected fish", "Backpack full of kept fish: unlock some or shorten the Keep lists")
				else
					setStatus("Backpack full: Smart Sell or Sell Now makes room")
				end
				task.wait(2)
				return
			end
		end
		if (N.data().World and N.worldCfg() and N.worldCfg().NoFishing) then
			if N.World.manual == N.worldKey() then
				setStatus("Staying in " .. N.worldKey() .. " (you teleported here)")
				task.wait(2)
				return
			end
			setStatus("In a world without fishing, going back")
			N.travel(N.bestFishingWorld())
			return
		end
		if not N.goPier() then
			if not N.pierPos() then
				N.planIdle("pier not loaded in " .. N.worldKey(), "Waiting for the pier to load")
			else
				N.planIdle("could not reach the pier", "Going to the pier")
			end
			task.wait(1)
			return
		end
		if not N.equipRod() then
			N.planIdle("rod " .. tostring(N.data().RodEquipped) .. " not in the backpack", "Equipping the rod")
			task.wait(1)
			return
		end
		N.tutorialDecide()
		if (tonumber(N.data().Tutorial) or -1) < 100 then
			N.tutorialStep()
		end
		-- A rare catch (Secret 4.2 s, Exotic 5.7 s, Exclusive 6.9 s) holds the next cast on the server while the player's own
		-- Rare Cutscene setting would show it (RareShowcaseConfig, showcaseHold 187673-187709). "None" is one of the game's
		-- own choices: sent once per session, from anywhere (Settings checks only the value, 186849).
		if not F.rareCutscene and N.ready() then
			F.rareCutscene = true
			if N.tab("Settings").RareCutscene ~= "None" then
				send("Settings", "RareCutscene", "None")
				log("SETTING", "RareCutscene=None", "(a rare catch no longer holds the next cast for 4-7 s)")
			end
		end
		-- Group members get the game's Double Speed (x1.5 cast speed); the server checks IsInGroup.
		if N.data().IsInGroup and not F.doubleSpeed then
			F.doubleSpeed = true
			send("DoubleSpeed", true)
			log("FISH double speed on (group member)")
		end
		if F.mode == "safe" then
			local AF = findAutoFishing()
			if AF then
				F.engine = "game"
				patch(AF)
				if not AF.On then
					local ok, err = pcall(AF.SetOn, AF, true)
					log("FISH safe", "game auto fishing on", if ok then "" else tostring(err))
				end
				setStatus("Fishing: the game's auto fishing, aimed at the best fish")
				if N.due("safeStats", 300) then
					local caught = tonumber(N.tab("Stats").FishCaught) or 0
					F.caughtBase = F.caughtBase or caught
					log("FISH safe stats", "casts=" .. Session.casts, "caught=" .. (caught - F.caughtBase), "income/h=" .. formatNumber(N.Econ.rate * 3600), "perfect=" .. math.floor(optionNumber("PerfectRate", 60)) .. "%")
				end
				task.wait(1)
				return
			end
			F.engine = "remote-legit"
			setStatus("Fishing at the game's own pace")
			N.castOnce(false)
			task.wait(1.5 + math.random())
			return
		end
		-- Blatant: the game's auto fishing must be off (one cast at a time).
		if F.patched and F.patched.On then
			N.pauseFishing("switching to Blatant")
			F.paused = false
		end
		-- The game's own auto fishing (saved ON in the profile, or left on by an earlier Legit/fallback phase) casts with the
		-- full catch animation next to ours: switch it off once, found even when the hub never patched it.
		-- checked before every cast: the game turns its saved Auto back on after a respawn, a world change or a trip
		do
			local AF = findAutoFishing()
			if AF and AF.On then
				pcall(AF.SetOn, AF, false)
				log("FISH game auto fishing was on, switched off (Blatant casts by itself, no catch animation)")
			end
		end
		F.engine = "remote-blatant"
		setStatus("Fishing: best fish of every school, instant reel")
		N.castOnce(true)
		task.wait(0.3 + math.random() * 0.3)
	end
	-- Auto Fish and the planner both off: the game's auto fishing is restored; a cast in flight finishes by itself (its
	-- hooks and claim still belong to the server's active throw).
	function N.fishOff()
		if F.patched then
			N.unpatch()
		end
	end
end
N.Reward = { log = {}, last = "" }
do
	local R = N.Reward
	local function claimed(what)
		Session.claims += 1
		table.insert(R.log, 1, os.date("%H:%M") .. "  " .. what)
		while #R.log > 6 do
			table.remove(R.log)
		end
		R.last = what
		log("REWARD", what)
	end
	N.claimed = claimed
	local function cfg(name)
		local c = N.sh("Config." .. name)
		return if type(c) == "table" then c else nil
	end
	-- Remote-only claims (no movement, no held item): each one only when the game's own config says it is ready.
	function N.rewardStep()
		if not N.wants("AutoRewards") then
			return
		end
		local d = N.data()
		local now = N.serverTime()
		-- Daily login ladder (DailyRewardsConfig.CanClaim, claims every unlocked day).
		local dr = d.DailyRewards
		if type(dr) ~= "table" then
			if N.due("dailySync", 120) then
				send("DailyRewards", "Sync")
			end
		elseif N.due("daily", 30) then
			local c = cfg("DailyRewardsConfig")
			local ok, can = pcall(function()
				return c.CanClaim(dr, now)
			end)
			if ok and can then
				-- One call with the highest unlocked day: the server claims every day from Claimed+1 up to it (183443).
				local from, to = (tonumber(dr.Claimed) or 0) + 1, math.max(tonumber(dr.Unlocked) or 1, (tonumber(dr.Claimed) or 0) + 1)
				send("DailyRewards", "Claim", to)
				claimed(if to > from then string.format("Daily rewards days %d-%d (catch-up)", from, to) else "Daily reward day " .. from)
			end
		end
		-- Free daily roll (DailyClaimableConfig.State == "Free"; the ad "Watch" claim is never used).
		if N.due("claimable", 60) then
			local c = cfg("DailyClaimableConfig")
			local ok, state = pcall(function()
				return c.State(d.DailyClaimable, now)
			end)
			if ok and state == "Free" then
				send("DailyClaimable", "Claim")
				claimed("Free daily roll")
			elseif not ok and N.due("claimableSync", 600) then
				send("DailyClaimable", "Sync")
			end
		end
		-- Playtime gift stages (server: Stats.SecondsPlayed >= PlaytimeGiftReadyAt).
		local stage = tonumber(d.PlaytimeGiftStage) or 0
		local readyAt = tonumber(d.PlaytimeGiftReadyAt) or 0
		-- Seconds played: the saved Stats value, or its value at start plus this session when the replica lags.
		local statsPlayed = tonumber(N.tab("Stats").SecondsPlayed) or 0
		R.playBase = R.playBase or statsPlayed
		R.playBaseAt = R.playBaseAt or os.clock()
		local played = math.max(statsPlayed, R.playBase + (os.clock() - R.playBaseAt))
		if readyAt > 0 and played >= readyAt and N.due("playtime", if R.playtimeStage == stage then 300 else 90) then
			send("PlaytimeGift", "Claim")
			R.playtimeStage = stage
		end
		if R.playtimeStage and stage > R.playtimeStage then
			claimed("Playtime gift " .. stage)
			R.playtimeStage = nil
		end
		-- Next day reward (12 h after the first join).
		if not d.IsNextDayRewardClaimed and (tonumber(d.NextDayRewardAt) or 0) > 0 and now >= (tonumber(d.NextDayRewardAt) or 0) and N.due("nextDay", 300) then
			send("NextDayReward")
			claimed("Next day reward")
		end
		-- Season pass, free track only (SeasonConfig.TierFromXP).
		if N.due("season", 60) then
			local c = cfg("SeasonConfig")
			local s = d.Season
			if c and type(s) == "table" and s.Id == c.Id then
				local okTier, tier = pcall(c.TierFromXP, tonumber(s.XP) or 0)
				local free = type(s.Free) == "table" and s.Free or {}
				for t = 1, (okTier and tonumber(tier) or 0) do
					if not free["T" .. t] then
						send("Season", "Claim", "Free", t)
						claimed("Season tier " .. t)
						break
					end
				end
			end
		end
		-- Achievements (AchievementConfig.CanClaim).
		if N.due("achievements", 45) then
			local c = cfg("AchievementConfig")
			if c and type(c.Order) == "table" then
				for _, item in ipairs(c.Order) do
					local ok, can = pcall(c.CanClaim, item, d)
					if ok and can then
						send("Achievement", "Claim", item.Key)
						claimed("Achievement " .. tostring(item.Key))
						break
					end
				end
			end
		end
		-- Group reward (only when the account is in the group), referral, comeback, early leave, offline catch.
		if d.IsInGroup and not d.IsGroupRewardClaimed and N.due("group", 300) then
			send("GroupReward")
			claimed("Group reward")
		end
		local ref = type(d.Referral) == "table" and d.Referral or {}
		if (tonumber(ref.LinkedWithUserId) or 0) ~= 0 and not ref.IsClaimed and N.due("referral", 600) then
			send("Referral", "Claim")
			claimed("Referral reward")
		end
		if (tonumber(d.ComebackStage) or 0) > 0 and (tonumber(d.ComebackClaimDay) or 0) < (tonumber(d.ComebackStage) or 0) and N.due("comeback", 900) then
			send("Comeback", "Claim")
			claimed("Comeback reward")
		end
		if not d.IsEarlyLeaveRewardClaimed and (tonumber(N.tab("Stats").SecondsPlayed) or 0) <= 900 and N.due("early", 3600) then
			send("EarlyLeaveReward", "Claim")
		end
		if (tonumber(d.OfflineReward) or 0) > 0 and N.due("offline", 120) then
			send("Offline")
			claimed("Offline catch " .. formatNumber(d.OfflineReward))
		end
	end
	-- Codes: the game's Codes remote (server CodeList, per-code stock, a short cooldown) and the per-player secret code
	-- painted on the four signs (PlayerData.SecretCode). Redeemed codes are kept in PlayerData.Codes.
	N.Codes = {
		known = { "update9", "volcano", "boats", "sunkencrown", "update8", "keys", "kraken", "update7", "pond", "update4", "skins" },
		tried = {},
		results = {},
		last = "-",
		queue = {},
	}
	local C = N.Codes
	local CodeFile = "Vader/FISH_codes_" .. tostring(LocalPlayer.UserId) .. ".txt"
	pcall(function()
		if isfile(CodeFile) then
			for code in string.gmatch(readfile(CodeFile), "[^\n]+") do
				C.tried[code] = true
			end
		end
	end)
	local function saveTried()
		pcall(function()
			if makefolder and isfolder and not isfolder("Vader") then
				makefolder("Vader")
			end
			local list = {}
			for code in pairs(C.tried) do
				table.insert(list, code)
			end
			table.sort(list)
			writefile(CodeFile, table.concat(list, "\n"))
		end)
	end
	local function norm(code)
		return string.lower((string.gsub(tostring(code or ""), "[^%w]", "")))
	end
	N.listen("Codes", function(status, a, b)
		local text = tostring(status)
		C.last = text .. (if a ~= nil then " " .. tostring(a) else "")
		C.results[C.pending or "?"] = text
		log("CODE result", tostring(C.pending), text, brief(a), brief(b))
		if N.Events.code and C.pending then
			pcall(N.Events.code, C.pending, text)
		end
	end)
	function N.redeemCode(code)
		code = norm(code)
		if code == "" then
			return
		end
		C.pending = code
		C.tried[code] = true
		saveTried()
		send("Codes", code)
		Session.codes += 1
	end
	function N.redeemAllCodes()
		for _, code in ipairs(C.known) do
			table.insert(C.queue, code)
		end
	end
	function N.codeCounts()
		local redeemed, tried = 0, 0
		local have = N.tab("Codes")
		for _ in pairs(C.tried) do
			tried += 1
		end
		for _ in pairs(have) do
			redeemed += 1
		end
		return redeemed, tried
	end
	function N.codeStep()
		local d = N.data()
		if N.wants("AutoCodes") and N.due("codeScan", 30) then
			local have = N.tab("Codes")
			for _, code in ipairs(C.known) do
				if not have[code] and not C.tried[code] and not table.find(C.queue, code) then
					table.insert(C.queue, code)
				end
			end
			if type(d.SecretCode) == "string" and d.SecretCode ~= "" and not d.SecretCodeRedeemed and not C.tried["secret:" .. d.SecretCode] then
				C.tried["secret:" .. d.SecretCode] = true
				table.insert(C.queue, d.SecretCode)
				log("CODE secret code from the signs queued")
			end
		end
		-- One code every 6 s (the server has a redeem cooldown).
		if #C.queue > 0 and N.due("codeSend", 6) then
			N.redeemCode(table.remove(C.queue, 1))
		end
	end
	-- Item chores (need the item held, so the main loop runs them between casts): chests, cages, like gifts, potions and
	-- boss relics, all through the game's own tool activation remotes.
	N.Items = { last = "-", openedNames = {} }
	local I = N.Items
	local function potionActive(name)
		local p = N.tab("Potions")[name]
		if p == nil then
			return false
		end
		if type(p) == "table" then
			local left = tonumber(p.Remaining or p.TimeLeft or p.Duration)
			local ends = tonumber(p.EndsAt or p.Expires)
			if ends then
				return ends > N.serverTime()
			end
			return left == nil or left > 0
		end
		return (tonumber(p) or 0) > 0
	end
	N.potionActive = potionActive
	function N.itemChores()
		if not N.ready() then
			return false
		end
		local did = false
		if N.wants("AutoOpen") and N.due("open", 5) then
			for _, kind in ipairs({ "Chest", "Cage", "Exclusive" }) do
				local list = N.itemsOf(kind)
				if #list > 0 then
					local entry = list[1]
					do
						N.pauseFishing()
						N.holdItem(entry.guid)
						send(if kind == "Exclusive" then "LikeGift" else "FishingObject", "Open", entry.guid)
						Session.opened += 1
						I.last = "Opened " .. tostring(entry.item.Name)
						log("OPEN", kind, tostring(entry.item.Name))
						task.wait(1)
						did = true
						break
					end
				end
			end
		end
		if N.wants("AutoPotions") and N.worldKey() ~= "Pond" and N.due("potions", 10) then
			for _, entry in ipairs(N.itemsOf("Potion")) do
				local name = tostring(entry.item.Name)
				if selected(Options.PotionKinds, name) and not potionActive(name) then
					N.pauseFishing()
					N.holdItem(entry.guid)
					send("Potion", "Drink", entry.guid)
					Session.potions += 1
					I.last = "Drank " .. name
					log("POTION", name)
					task.wait(1)
					did = true
					break
				end
			end
		end
		-- Boss relics: luck relics (SunkenKing, SunkenQueen) right away; the sell relic (Kraken x10) only right before a
		-- big sale (Smart Sell calls N.useSellRelics).
		if N.wants("AutoRelics") and N.due("relics", 15) then
			local BR = N.sh("Config.BossRelicConfig")
			for guid, item in pairs(N.inv()) do
				if type(item) == "table" and item.Type == "Fish" then
					local key = N.relicOf(item)
					local def = key and BR and type(BR.Get) == "function" and select(2, pcall(BR.Get, key))
					if key and type(def) == "table" and not def.SellAll then
						N.pauseFishing()
						N.holdItem(guid)
						send("BossRelic", "Consume", guid)
						Session.relics += 1
						I.last = "Used relic " .. tostring(key)
						log("RELIC", tostring(key))
						task.wait(1)
						did = true
						break
					end
				end
			end
		end
		return did
	end
	function N.useSellRelics()
		local BR = N.sh("Config.BossRelicConfig")
		local used = 0
		for guid, item in pairs(N.inv()) do
			if type(item) == "table" and item.Type == "Fish" then
				local key = N.relicOf(item)
				local ok, def = false, nil
				if key and BR and type(BR.Get) == "function" then
					ok, def = pcall(BR.Get, key)
				end
				if key and ok and type(def) == "table" and def.SellAll then
					N.holdItem(guid)
					send("BossRelic", "Consume", guid)
					used += 1
					Session.relics += 1
					log("RELIC sell boost", tostring(key))
					task.wait(0.8)
				end
			end
		end
		return used
	end
	-- Big Mouth (World 1): feed it the cheapest fish until it is full, every 12 h. Each round raises luck for good
	-- (+10% for the first five, then +5%, up to +200%) and rolls a reward.
	function N.bigMouthStep()
		if not N.wants("AutoBigMouth") or not N.unlocked("World 1") then
			return false
		end
		local bm = N.tab("BigMouth")
		if (tonumber(bm.ReadyAt) or 0) > N.serverTime() or os.clock() < (N.bmBackoff or 0) or not N.due("bigMouth", 60) then
			return false
		end
		local _, sellable = N.fishStats()
		if sellable == 0 then
			return false
		end
		-- Priced like every purchase (cast model): the cheapest fish fed (about `Goal`, 10 when unknown) against the +5% luck
		-- (the smaller of its two steps) it buys over the planner's horizon; a backpack of only expensive fish is not fed.
		if N.planner() and N.castModel and N.due("bigMouthPrice", 120) then
			local base = N.castModel()
			local up = N.castModel({ extraLuck = 0.05 })
			if base and up then
				local values = {}
				for _, item in pairs(N.inv()) do
					if type(item) == "table" and item.Type == "Fish" and not N.isLocked(item) and not N.relicOf(item) then
						table.insert(values, N.value(item))
					end
				end
				table.sort(values)
				local cost = 0
				for i = 1, math.min(#values, math.max(tonumber(bm.Goal) or 0, 10)) do
					cost += values[i]
				end
				local worth = (up / base - 1) * N.incomeRate() * 3600 * math.max(N.Plan.horizon or 12, 1)
				if cost > worth then
					log("BIGMOUTH skipped", "cost=" .. formatNumber(cost), "luck gain over the horizon=" .. formatNumber(worth))
					return false
				end
			end
		end
		N.pauseFishing("Big Mouth")
		local back = N.worldKey()
		if back ~= "World 1" and not N.travel("World 1") then
			N.resumeFishing()
			return false
		end
		local pos = N.spot("BigMouthFish")
		if not pos or not N.goTo(pos, 8) then
			-- every failed trip cost two world changes and a lost cast, repeated each minute (live log: 4 trips in 5 minutes)
			N.BMFail = math.min((N.BMFail or 0) + 1, 6)
			N.bmBackoff = os.clock() + 300 * 2 ^ (N.BMFail - 1)
			log("BIGMOUTH not reached", "retry in " .. math.floor(300 * 2 ^ (N.BMFail - 1) / 60) .. " min")
			N.resumeFishing()
			return false
		end
		setStatus("Feeding the Big Mouth")
		if (tonumber(bm.Goal) or 0) <= 0 then
			send("BigMouth", "Open")
			task.wait(1)
		end
		local fed = 0
		while fed < 40 and alive() and N.wants("AutoBigMouth") and (tonumber(N.tab("BigMouth").ReadyAt) or 0) <= N.serverTime() do
			local cheapest, cheapValue
			for guid, item in pairs(N.inv()) do
				if type(item) == "table" and item.Type == "Fish" and not N.isLocked(item) and not N.relicOf(item) then
					local v = N.value(item)
					if not cheapest or v < cheapValue then
						cheapest, cheapValue = guid, v
					end
				end
			end
			if not cheapest then
				break
			end
			N.holdItem(cheapest)
			send("BigMouth", "Feed")
			fed += 1
			task.wait(0.8)
		end
		Session.bigMouth += 1
		log("BIGMOUTH fed", fed, "luck", tostring(N.tab("BigMouth").Luck))
		claimed("Big Mouth fed " .. fed .. " fish")
		if back ~= "World 1" then
			N.travel(back)
		end
		N.resumeFishing()
		return true
	end
	-- Enchant (Stone Mage): hold an Enchant Stone (slot 1) or Ultra Enchant Stone (slot 2) and roll until the rod carries
	-- one of the picked enchants. Only where the Stone Mage stands in the current world.
	local function stoneOf(slot)
		for _, entry in ipairs(N.itemsOf("Scroll")) do
			local n = tostring(entry.item.Name)
			if (slot == 1 and n == "Enchant Stone") or (slot == 2 and n == "Ultra Enchant Stone") then
				return entry.guid
			end
		end
		return nil
	end
	function N.enchantNames()
		local E = N.sh("Modules.Enchant")
		if type(E) == "table" and type(E.Names) == "function" then
			local ok, a, b = pcall(E.Names, N.data())
			if ok then
				return a, b
			end
		end
		return nil, nil
	end
	function N.enchantStep()
		if not N.wants("AutoEnchant") or not N.due("enchant", 20) then
			return false
		end
		local s1, s2 = N.enchantNames()
		local want1 = stoneOf(1) and not selected(Options.EnchantTargets, tostring(s1))
		local want2 = stoneOf(2) and not selected(Options.EnchantTargets, tostring(s2))
		if not (want1 or want2) then
			return false
		end
		local pos = N.spot("NPC_StoneMage")
		if not pos then
			if N.due("enchantNoMage", 600) then
				log("ENCHANT no Stone Mage in " .. N.worldKey())
			end
			return false
		end
		N.pauseFishing("enchant")
		if not N.goTo(pos, 8) then
			N.resumeFishing()
			return false
		end
		local slot = if want1 then 1 else 2
		local guid = stoneOf(slot)
		if guid then
			N.holdItem(guid)
			send("Enchant", "Roll")
			Session.enchants += 1
			task.wait(2)
			local n1, n2 = N.enchantNames()
			log("ENCHANT roll", "slot=" .. slot, "now=" .. tostring(if slot == 1 then n1 else n2))
		end
		N.resumeFishing()
		return true
	end
	-- Mutation Dealer: spend free Mutation Scrolls (the game counts them in MutationRerolls) on the most valuable
	-- unmutated fish; the mutation multiplies its sell value (x2..x15).
	function N.mutationStep()
		if not N.wants("AutoMutate") or not N.due("mutate", 30) then
			return false
		end
		local scrolls = 0
		for _, entry in ipairs(N.itemsOf("Scroll")) do
			local n = tostring(entry.item.Name)
			if n == "Mutation Scroll" or n == "Ultra Mutation Scroll" then
				scrolls += tonumber(type(entry.item.Data) == "table" and entry.item.Data.Amount) or 1
			end
		end
		if scrolls <= 0 then
			return false
		end
		local pos = N.spot("MutationDealer")
		if not pos then
			return false
		end
		local best, bestValue
		for guid, item in pairs(N.inv()) do
			if type(item) == "table" and item.Type == "Fish" and not (type(item.Data) == "table" and item.Data.Mutation) and not N.relicOf(item) then
				local v = N.value(item)
				if not best or v > bestValue then
					best, bestValue = guid, v
				end
			end
		end
		if not best then
			return false
		end
		N.pauseFishing("mutation")
		if N.goTo(pos, 8) then
			N.holdItem(best)
			send("MutationReroll", "Spin", false)
			Session.mutations += 1
			log("MUTATE spin", formatNumber(bestValue))
			task.wait(2.5)
		end
		N.resumeFishing()
		return true
	end
end
-- Profit engine: measured income, purchases by payback, worlds, Smart Sell, bait and the pond.
N.Econ = { samples = {}, rate = 0, spent = 0 }
N.Plan = { text = "", say = "", best = nil, need = nil, lastKey = "", lastAt = -1e9, list = {} }
N.Sell = { needNpc = nil, last = "-", locked = {}, at = os.clock() }
N.Shop = { near = {}, last = "-", stockOut = {} }
N.Pond = { last = "-", at = -1e9 }
N.World = { last = "-" }
do
	local E, P = N.Econ, N.Plan
	local function cfg(name)
		local c = N.sh("Config." .. name)
		return if type(c) == "table" then c else nil
	end
	-- Worth = cash + sell value of the backpack (without a server CashBoost, which would fake a jump) + the pond's fish +
	-- what Vader spent; its slope is the real income per second. A drop (fish fed to the Big Mouth, a sale under the
	-- estimate, a boost that ended) is an accounting event, not negative income: it is carried in E.adjust so the measured
	-- rate never falls to 0 while the casts keep earning.
	function N.backpackValue()
		return (select(4, N.fishStats())) or 0
	end
	local function pondValue()
		local total = 0
		pcall(function()
			for _, f in pairs(N.tab("Pond").Fish or {}) do
				if type(f) == "table" and f.Name and not f.Dead then
					total += N.value(f)
				end
			end
		end)
		return total
	end
	E.adjust = 0
	function N.econTick()
		local boost = math.max(tonumber(workspace:GetAttribute("ServerCash")) or 1, 1)
		local worth = N.cash() + N.backpackValue() / boost + pondValue() + E.spent + E.adjust
		local prev = E.samples[#E.samples]
		if prev and worth < prev.w then
			E.adjust += prev.w - worth
			worth = prev.w
		end
		local now = os.clock()
		table.insert(E.samples, { t = now, w = worth, c = Session.casts, v = Session.castValue })
		while #E.samples > 2 and now - E.samples[1].t > 900 do
			table.remove(E.samples, 1)
		end
		local first, last = E.samples[1], E.samples[#E.samples]
		if last.t - first.t >= 60 then
			E.rate = math.max((last.w - first.w) / (last.t - first.t), 0)
			E.cps = math.max((last.c - first.c) / (last.t - first.t), 0)
			if E.cps > 0 and N.castModel then
				local _, info = N.castModel()
				if info then
					local seen = math.clamp(1 / E.cps - info.cycle, 0.3, 30)
					E.overhead = if E.overhead then E.overhead * 0.7 + seen * 0.3 else seen
				end
			end
		end
		-- Realised cast value / what the cast model says the current setup is worth (size, mutation and event luck of the
		-- real catches): an exponential average over the last casts, so a purchase changes the model side at once.
		local prevS = E.samples[#E.samples - 1]
		if prevS and N.castScale then
			local dc, dv = last.c - prevS.c, last.v - prevS.v
			local scale, model = N.castScale()
			if dc > 0 and model and model > 0 and scale > 0 then
				E.rhoNum = (E.rhoNum or 0) * 0.9 + dv
				E.rhoDen = (E.rhoDen or 0) * 0.9 + scale * model * dc
			end
		end
	end
	function N.spent(amount)
		E.spent += tonumber(amount) or 0
	end
	-- Expected income per second = realised/modelled value ratio x modelled cast value x measured casts per second. The
	-- measured worth slope still rules before the model or the cast pace exist, and it stays a cross-check: a one-off x10
	-- relic sale or a lull never again decides a payback (a measured 15K/s from one relic sale kept the planner from buying
	-- for 20 minutes, then fell to 2.6K/s). Without a cast pace the live cast value / cycle stands in.
	function N.expectedRate()
		if os.clock() - (E.expAt or -1e9) < 3 then
			return E.exp
		end
		E.expAt, E.exp = os.clock(), nil
		local scale, model = N.castScale()
		if model and model > 0 and (E.cps or 0) > 0 and (E.rhoDen or 0) > 0 then
			local rho = math.clamp(E.rhoNum / E.rhoDen, 0.3, 5)
			E.exp = rho * scale * model * E.cps
		end
		return E.exp
	end
	function N.incomeRate()
		local r = N.expectedRate() or E.rate
		if r <= 0 and N.Fish.cycle > 0 and N.Fish.evCast > 0 then
			r = N.Fish.evCast / N.Fish.cycle
		end
		return math.max(r, 1)
	end
	-- Rod stats on the current world (older world rods keep RodStep^(worlds behind), WorldsConfig.RodFactor).
	local function rodPower(name)
		local rods = N.sh("Content.Item.Rod")
		local def = rods and type(rods.Items) == "table" and rods.Items[name]
		if not def then
			return 0, 0
		end
		local W = cfg("WorldsConfig")
		local factor = 1
		pcall(function()
			factor = W.RodFactor(N.worldNumber(def.RequiredWorld or "World 1"), select(2, N.bestFishingWorld()))
		end)
		return (tonumber(def.Luck) or 0) * factor, (tonumber(def.Strength) or 0) * factor
	end
	N.rodPower = rodPower
	-- Share of income one purchase adds (documented model, notes.md Profit model):
	-- Capacity: more hooks per cast on the best fish (x0.7, the extra fish are the cheaper ones of the top list);
	-- Strength/Weight: distance/depth multiplier -> deeper, bigger schools and rarer fish (x0.6 of the multiplier step);
	-- Bounce: extra distance chance; rods: luck and strength vs the equipped rod.
	local function statGain(U, stat, level, key)
		local step = 1
		pcall(function()
			step = U.StepFor(stat, key)
		end)
		if stat == "Capacity" then
			local cap = math.max(N.hookCap(), 1)
			return step / cap * 0.7
		elseif stat == "Strength" then
			local ok, a, b = pcall(function()
				return U.StrengthMultiplier(level), U.StrengthMultiplier(level + step)
			end)
			return if ok and a and a > 0 then (b / a - 1) * 0.6 else 0.05
		elseif stat == "Weight" then
			local ok, a, b = pcall(function()
				return U.WeightMultiplier(level), U.WeightMultiplier(level + step)
			end)
			return if ok and a and a > 0 then (b / a - 1) * 0.6 else 0.03
		end
		return if level <= 0 then 0.05 else 0.02
	end
	-- CAST MODEL (valuation core, 2026-10-06): one function that replays the server's own throw maths (dump 188350-188730)
	-- for a hypothetical state and returns the expected value of one cast in base-price units:
	--   luck   = ((1 + rodLuck x rodFactor + bait + level + referral + big mouth + enchant) x skin x gamepass + potion) x ServerLuck
	--   dist   = quality x 25 x StrengthMult x (1 + rod strength) x (1 + enchant), capped 11700, plus the Bounce skip
	--            (chance x gain, capped at 11700)
	--   depth  = log2(dist x WeightMult x (1 + bait weight) / 60 + 1) x 30 + 26 + enchant
	--   school = clamp(floor(max(hooks x 1.5, (depth - 26) / 5.5) + 0.5), 3, 56), hooks = Capacity + HookSlots + potion
	--   fish odds = Fish:SpawnWeights(luck, world, depth, depthScale) (the game's own rarity x depth x luck weights);
	--   the hub keeps the best `hooks` of the school, so a cast = min(hooks, school) x mean of the top hooks/school share.
	-- Every purchase is valued by its effect on this number: Capacity (hooks), Strength/Weight/Bounce (depth, so rarity),
	-- rods and bait (luck, distance, depth), the next world (its fish table with the upgrades it would start with). The
	-- model is a RATIO tool (cast after / cast before); N.castScale turns it into coins. Missing pieces fall back to 0/1 and
	-- a missing Fish module returns nil (the planner then uses the older flat shares).
	local function try(f, default, ...)
		local ok, v = pcall(f, ...)
		if ok and v ~= nil then
			return v
		end
		return default
	end
	-- Species by sell price, best first (rebuilt per call: a few dozen species, cheaper than a stale cache).
	local function fishOrder(Fish)
		local list = {}
		for name, def in pairs(Fish.Items) do
			if type(def) == "table" and tonumber(def.SellPrice) and def.SellPrice > 0 then
				table.insert(list, { name = name, price = def.SellPrice })
			end
		end
		table.sort(list, function(a, b)
			return a.price > b.price
		end)
		return list
	end
	local function baseBait()
		local baits = N.sh("Content.Item.Bait")
		local defs = baits and baits.Items
		local best
		if type(defs) == "table" then
			for name, n in pairs(N.tab("ActiveBaits")) do
				local def = defs[name]
				if (tonumber(n) or 0) > 0 and def and (not best or (tonumber(def.Luck) or 0) > (tonumber(best.Luck) or 0)) then
					best = def
				end
			end
		end
		return best or false
	end
	-- Landing flight of a cast (the server's mapping of the logical distance, dump 188431-188440) and the time its arc takes
	-- (Arc module, dump 190624-190677). A cast lasts about arc + dive + return + the hub's own overhead, so a deeper or
	-- farther setup is worth its richer fish divided by the longer cycle.
	local function flightOf(dist)
		local d = math.max(dist, 0)
		return math.min(if d < 110 then d ^ 2 * 0.03540353338991906 else d ^ 0.975 * 4.38, 40546.68244059479)
	end
	local function arcTime(mag)
		local function timeFor(apex)
			local v = math.max(apex, 0) * 2 / (36.4 * (1 + math.max(apex, 0) / 1000))
			return math.max(math.sqrt(v) * 2, 0.45)
		end
		local function solved(m)
			local apex = 0.045 * math.max(m, 0)
			return timeFor(math.max(apex / (1 + (apex / 420) ^ 3) ^ (1 / 3), 8))
		end
		if mag > 6000 then
			return math.min(solved(6000) * (mag / 6000) ^ 0.11, 8)
		end
		return solved(mag)
	end
	-- over = { world = key, rod = name, bait = def | false, levels = { Stat = level }, extraLuck = n, quality = n }
	function N.castModel(over)
		over = over or {}
		local d = N.data()
		local U, Wc = cfg("UpgradesConfig"), cfg("WorldsConfig")
		local Fish, Rods = N.sh("Content.Item.Fish"), N.sh("Content.Item.Rod")
		if not (U and Wc and type(Fish) == "table" and type(Fish.Items) == "table" and type(Fish.SpawnWeights) == "function") then
			return nil
		end
		local key = over.world or (N.bestFishingWorld())
		local wdef = type(Wc.Worlds) == "table" and Wc.Worlds[key]
		if not wdef then
			return nil
		end
		local effect = tonumber(wdef.UpgradeEffect) or 1
		local levels = try(U.LevelsFor, {}, d, key)
		local function lv(stat)
			if over.levels and over.levels[stat] then
				return over.levels[stat]
			end
			return tonumber(levels[stat]) or 0
		end
		local rodName = over.rod or d.RodEquipped or "Wooden Rod"
		local rdef = type(Rods) == "table" and type(Rods.Items) == "table" and Rods.Items[rodName] or {}
		local home = math.max(N.worldNumber(rdef.RequiredWorld or "World 1"), if rdef.FullPowerThrough then N.worldNumber(rdef.FullPowerThrough) else 0)
		local factor = try(Wc.RodFactor, 1, home, tonumber(wdef.WorldNumber) or 1)
		local bait = over.bait
		if bait == nil then
			bait = baseBait()
		end
		local baitLuck = if bait then tonumber(bait.Luck) or 0 else 0
		local baitWeight = if bait then tonumber(bait.Weight) or 0 else 0
		local Enchant = N.sh("Modules.Enchant")
		local function ench(effect2)
			return tonumber(try(function()
				return Enchant.Add(d, effect2)
			end, 0)) or 0
		end
		local luckSum = (tonumber(rdef.Luck) or 0) * factor / 100 + baitLuck / 100
			+ try(function()
				return cfg("LevelConfig").LuckForLevel(N.level()) / 100
			end, 0)
			+ try(function()
				return cfg("ReferralConfig").LuckFor(d)
			end, 0)
			+ try(function()
				return cfg("BigMouthConfig").LuckFor(d)
			end, 0)
			+ ench("Luck") + (over.extraLuck or 0)
		local skin = try(function()
			return cfg("SkinBoostConfig").WornMultiplier(d, "Luck")
		end, 1)
		local gamepass = try(function()
			return cfg("LuckConfig").MultiplierFor(type(d.Gamepasses) == "table" and d.Gamepasses or {})
		end, 1)
		local potion = try(function()
			return cfg("PotionConfig").LuckBonus(d)
		end, 0)
		local luck = ((1 + luckSum) * skin * gamepass + potion) * (tonumber(workspace:GetAttribute("ServerLuck")) or 1)
		local quality = over.quality or (if N.fishMode() == "blatant" then 2 else 1.8)
		local dist = math.min(quality * 25 * U.StrengthMultiplier(lv("Strength"), effect) * (1 + (tonumber(rdef.Strength) or 0) * factor / 100) * (1 + ench("Distance")), 11700)
		local bounceLevel = lv("Bounce")
		local pBounce = try(function()
			return U.BounceChance(bounceLevel, effect)
		end, 0) * (if quality >= 2 then 1 elseif quality >= 1.5 then 0.5 else 0)
		local gBounce = try(function()
			return U.BounceGain(bounceLevel, effect)
		end, 0)
		dist += pBounce * math.min(dist * gBounce, math.max(11700 - dist, 0))
		local depth = math.log(dist * U.WeightMultiplier(lv("Weight"), effect) * (baitWeight / 100 + 1) / 60 + 1, 2) * 30 + 26 + ench("Depth")
		local hooks = U.CapacityValue(lv("Capacity"), effect, key) + ench("HookSlots") + math.floor(try(function()
			return cfg("PotionConfig").Bonus(d, "Capacity")
		end, 0))
		local school = math.clamp(math.floor(math.max(hooks * 1.5, (depth - 26) / 5.5) + 0.5), 3, 56)
		local ok, weights, total = pcall(Fish.SpawnWeights, Fish, luck, tonumber(wdef.WorldNumber) or 1, depth, tonumber(wdef.DepthScale) or 1)
		if not (ok and type(weights) == "table" and tonumber(total) and total > 0) then
			return nil
		end
		-- Exact expected value of the best k fish of `school` independent draws (the hub keeps the best `hooks`): with the
		-- species sorted by price, species j fills min(N<=j, k) - min(N<j, k) of the k slots, N ~ Binomial(school, F_j), and
		-- E[min(N, k)] = sum over m = 1..k of P(N >= m). A plain "mean of the top share" would ignore the luck of the draw.
		local n, k = school, math.min(hooks, school)
		local function slots(F)
			if F <= 0 then
				return 0
			elseif F >= 1 then
				return k
			end
			local q = 1 - F
			local pmf, ratio = q ^ n, F / q
			local cdf, acc = 0, 0
			for m = 1, k do
				cdf += pmf
				acc += 1 - cdf
				pmf = pmf * (n - (m - 1)) / m * ratio
			end
			return acc
		end
		local sum, cumulative, before, hookTime = 0, 0, 0, 0
		for _, e in ipairs(fishOrder(Fish)) do
			local w = weights[e.name]
			if w and w > 0 then
				cumulative += w / total
				local now = slots(cumulative)
				sum += e.price * (now - before)
				hookTime += (now - before) * N.hookSeconds(e.name, false)
				before = now
			end
		end
		if sum <= 0 then
			return nil
		end
		local mag = flightOf(dist)
		local cycle = arcTime(mag) + math.clamp(depth / 70, 0.15, 1) + math.clamp(mag / 3810, 1, 3) + hookTime
		return sum, { luck = luck, dist = dist, depth = depth, hooks = hooks, school = school, cycle = cycle }
	end
	-- Coins per model unit: the game's own sell multiplier (gamepass, index, enchant) on the cheapest fish, without a
	-- server CashBoost; plus the base model value.
	function N.castScale()
		local base = N.castModel()
		local scale = 1
		pcall(function()
			local Fish = N.sh("Content.Item.Fish")
			local list = fishOrder(Fish)
			local e = list[#list]
			local v = N.value({ Type = "Fish", Name = e.name, Data = { Size = 1 } })
			local boost = math.max(tonumber(workspace:GetAttribute("ServerCash")) or 1, 1)
			if v > 0 and e.price > 0 then
				scale = v / boost / e.price
			end
		end)
		return scale, base
	end
	-- Upgrade levels a world would start with after its cheap first steps (the unlock then buys 10% of its price in
	-- upgrades at once: W2 Strength 500K/1M, Weight 1M ...): greedy cheapest next step within the budget.
	local function catchUp(key, budget)
		local U = cfg("UpgradesConfig")
		local cur = try(U.LevelsFor, {}, N.data(), key)
		local lvls = {}
		for _, stat in ipairs(U.Order) do
			lvls[stat] = tonumber(cur[stat]) or 0
		end
		local spent = 0
		while true do
			local pickStat, pickPrice
			for _, stat in ipairs(U.Order) do
				local ok, price = pcall(function()
					if lvls[stat] < U.MaxLevelFor(stat, key) then
						return U.GetPrice(stat, lvls[stat], key)
					end
					return nil
				end)
				if ok and price and price > 0 and spent + price <= budget and (not pickPrice or price < pickPrice) then
					pickStat, pickPrice = stat, price
				end
			end
			if not pickStat then
				break
			end
			lvls[pickStat] += U.StepFor(pickStat, key)
			spent += pickPrice
		end
		return lvls, spent
	end
	-- Planning horizon in hours: what is left of the current 24 h window (with a 10% margin), never under 6 h (the account
	-- keeps playing after the mark, the window just rolls over).
	function N.horizon()
		return math.max((24 - ((os.clock() - Session.started) / 3600) % 24) * 0.9, 6)
	end
	-- Every purchase Vader could make now: {kind, name, price, g, frac, payback (h), paybackNow (h)}.
	--   g       = share of income it adds right now: the cast model's rate ratio after / before, rate = cast value / cycle
	--             (arc + dive + return + hook and fight seconds + the hub's measured overhead);
	--   frac    = its share averaged over the planning horizon H. The upgrades are PER WORLD (the next world starts from its own
	--             levels), so while a world move is planned (unlocked in tW hours) an upgrade only works for min(tW, H);
	--             a rod keeps working in the new world at that world's rod factor and the new world pays m = 1 + fracWorld
	--             times the income, so its gain after the move counts m times: frac = (g x min(tW,H) + gPost x m x (H - tW)) / H;
	--   payback = price / (rate x frac), the number the "best payback" ordering and the horizon test use; it is the real
	--             payback only when nothing is planned (frac = g); paybackNow = price / (rate x g) is the plain payback today.
	function N.candidates()
		local d = N.data()
		local out = {}
		local rate = N.incomeRate()
		local U = cfg("UpgradesConfig")
		local base, baseInfo = N.castModel()
		local _, bestNumber = N.bestFishingWorld()
		local overhead = E.overhead or 1.5
		local H = N.horizon()
		-- Income ratio after / before: cast value per cycle (arc + dive + return + hook/fight seconds + the hub's overhead).
		local function perCycle(c, info)
			return c / (info.cycle + overhead)
		end
		local function gain(over)
			if not (base and base > 0) then
				return nil
			end
			local c, info = N.castModel(over)
			return if c then math.max(perCycle(c, info) / perCycle(base, baseInfo) - 1, 0) else nil
		end
		local worldCand, worldRate, worldLvls
		if N.planner() or on("AutoWorlds") then
			local W = cfg("WorldsConfig")
			for key, w in pairs(W and type(W.Worlds) == "table" and W.Worlds or {}) do
				if not w.NoFishing and tonumber(w.WorldNumber) == bestNumber + 1 and not N.unlocked(key) and N.level() >= (tonumber(w.RequiredLevel) or 1) then
					local price = tonumber(w.UnlockPrice) or 0
					local frac, extra = 5, 0
					if base then
						-- The new world's fish table with the upgrades it starts with and the best owned rod there.
						local lvls, spent = catchUp(key, price * 0.1)
						local bestRate
						for name in pairs(N.tab("Rods")) do
							local c, info = N.castModel({ world = key, rod = name, levels = lvls })
							if c and (not bestRate or perCycle(c, info) > bestRate) then
								bestRate = perCycle(c, info)
							end
						end
						if not bestRate then
							local c, info = N.castModel({ world = key, levels = lvls })
							bestRate = if c then perCycle(c, info) else nil
						end
						if bestRate then
							frac, extra = math.clamp(bestRate / perCycle(base, baseInfo) - 1, 0.2, 1000), spent
							worldRate, worldLvls = bestRate, lvls
						end
					end
					worldCand = { kind = "world", name = key, price = price, cost = price + extra, g = frac, frac = frac, persist = true, key = key }
					table.insert(out, worldCand)
				end
			end
		end
		-- Hours until the planned world is paid for (cash plus the backpack it can sell at once).
		local tW, mW
		if worldCand then
			local funds = N.cash() + N.backpackValue() * 0.95
			tW = math.max(worldCand.price - funds, 0) / rate / 3600 + 0.02
			mW = 1 + worldCand.g
			worldCand.eta = tW
		end
		local function averaged(g, gPost)
			if not tW then
				return g
			end
			return (g * math.min(tW, H) + gPost * mW * math.max(H - tW, 0)) / H
		end
		if U and type(U.Order) == "table" and (N.planner() or on("AutoUpgrades")) then
			local key = "World 1"
			pcall(function()
				key = U.KeyForData(d)
			end)
			for _, stat in ipairs(U.Order) do
				if N.planner() or selected(Options.UpgradeStats, stat) then
					local ok, level, max, price = pcall(function()
						local lv = U.LevelOf(d, stat, key)
						return lv, U.MaxLevelFor(stat, key), U.GetPrice(stat, lv, key)
					end)
					if ok and level < max and price and price > 0 then
						local step = 1
						pcall(function()
							step = U.StepFor(stat, key)
						end)
						local g = gain({ world = key, levels = { [stat] = level + step } }) or statGain(U, stat, level, key)
						table.insert(out, { kind = "upgrade", name = stat, price = price, g = g, frac = averaged(g, 0), persist = false })
					end
				end
			end
		end
		local rods = N.sh("Content.Item.Rod")
		if rods and type(rods.Items) == "table" and (N.planner() or on("AutoRods")) then
			local curL, curS = rodPower(d.RodEquipped or "Wooden Rod")
			local owned = N.tab("Rods")
			for name, def in pairs(rods.Items) do
				local price = tonumber(def.Price) or 0
				local need = N.worldNumber(def.RequiredWorld or "World 1")
				if not owned[name] and price > 0 and not def.MazeOnly and not def.CaveOnly and need <= bestNumber then
					local g = gain({ rod = name })
					if not g then
						local l, s = rodPower(name)
						g = (l - curL) / (100 + curL) * 0.8 + (s - curS) / (100 + curS) * 0.4
					end
					if g > 0.005 then
						-- After the move: the rod's rate in the new world against the best rod already owned there.
						local gPost = 0
						if worldRate then
							local c, info = N.castModel({ world = worldCand.key, rod = name, levels = worldLvls })
							if c then
								gPost = math.max(perCycle(c, info) / worldRate - 1, 0)
							end
						end
						table.insert(out, { kind = "rod", name = name, price = price, g = g, frac = averaged(g, gPost), persist = gPost > 0.01 })
					end
				end
			end
		end
		if N.wants("AutoPond") and not N.unlocked("Pond") and N.level() >= 5 then
			table.insert(out, { kind = "world", name = "Pond", price = 25000, g = 0.15, frac = 0.15, persist = true })
		end
		for _, c in ipairs(out) do
			c.payback = (c.cost or c.price) / math.max(rate * c.frac, 1e-6) / 3600
			c.paybackNow = (c.cost or c.price) / math.max(rate * c.g, 1e-6) / 3600
		end
		table.sort(out, function(a, b)
			return a.payback < b.payback
		end)
		return out
	end
	-- While the planner saves for the next world (cost C, in tW hours): another purchase X goes first only when it gets the
	-- world bought SOONER. Time to buy world after X now: (need + pX) / (r (1 + gX)); without X: need / r, plus, for a rod that
	-- keeps working after the move, the time to buy it after the world: pX / (r m). Both then run at the same rate, so the
	-- earlier finish wins. For a per-world upgrade this is exactly "pays back before the world arrives"; for a rod it also
	-- credits the gain it keeps in the new world.
	function N.beatsWorld(c, world, funds, rate)
		local need = math.max(world.price - funds, 0)
		local without = need / rate
		if c.persist then
			without += c.price / (rate * (1 + world.g))
		end
		local with = (need + c.price) / (rate * (1 + c.g))
		return with < without
	end
	-- Offline net (OfflineNet "Buy": cash is the only server check, no NPC needed, 186038): one World 1 fish every
	-- SecondsPerFish (quality 1.5), up to MaxFish, claimed by Auto Rewards (Offline) every 2 minutes. Whether the net also
	-- fills while the account is online is not verified, so it is a spare-cash perk, never an investment that competes with
	-- the payback list: bought only when it costs at most 0.2% of the cash on hand (see spendStep) and its modelled payback
	-- fits the window. A net fish is modelled as a quarter of the average fish a cast hooks (a random fish of the cheapest
	-- world: base prices jump about x100 per world).
	function N.netCandidate()
		local OC = cfg("OfflineConfig")
		if not (OC and OC.Enabled and N.Fish.evCast > 0) then
			return nil
		end
		local ok, price, spf, nextSpf = pcall(function()
			local lv = OC.LevelFor(N.data())
			return OC.PriceFor(lv), OC.SecondsPerFishFor(lv), OC.SecondsPerFishFor(lv + 1)
		end)
		if not (ok and price and price > 0 and spf and nextSpf and nextSpf < spf) then
			return nil
		end
		local perFish = N.Fish.evCast / math.max(N.hookCapRaw(), 1) * 0.25 / 100 ^ math.max(select(2, N.bestFishingWorld()) - 1, 0)
		local extraPerSecond = (1 / nextSpf - 1 / spf) * perFish
		return { kind = "net", name = "Offline Net", price = price, frac = extraPerSecond / N.incomeRate(), payback = price / math.max(extraPerSecond, 1e-9) / 3600 }
	end
	local function owned(c)
		local d = N.data()
		if c.kind == "rod" then
			return N.tab("Rods")[c.name] ~= nil
		elseif c.kind == "world" then
			return N.unlocked(c.name)
		elseif c.kind == "upgrade" then
			return (c.levelBefore or -1) < (tonumber(N.tab("Upgrades")[c.name]) or 0) or N.cash() < (c.cashBefore or 0) - c.price * 0.5 or d == nil
		elseif c.kind == "net" then
			return (c.levelBefore or -1) < (tonumber(d.OfflineNetLevel) or 1) or N.cash() < (c.cashBefore or 0) - c.price * 0.5
		end
		return false
	end
	-- Rejoin through the game's own IdleRejoin channel: the server saves the profile and moves the character to a server
	-- (same one when it has room) with resume data; the hub starts again there (Misc > Keep after teleport). Used only
	-- to recover a stuck state (a world change that fails twice, 10 minutes on one status), never as anti idle.
	function N.rejoin(reason)
		local keep = Toggles.KeepOnTeleport
		if not (keep and keep.Value) then
			log("REJOIN skipped", "Keep after teleport is off", "reason=" .. tostring(reason))
			return false
		end
		if os.clock() - (N.World.rejoinAt or -1e9) < 600 then
			return false
		end
		N.World.rejoinAt = os.clock()
		local obj = N.event("IdleRejoin")
		if not obj then
			log("NO REMOTE", "IdleRejoin")
			return false
		end
		log("REJOIN", "reason=" .. tostring(reason), "(IdleRejoin: the server saves and moves us, the hub restarts after the teleport)")
		flushLog(true)
		N.Sent.count += 1
		N.Sent.byName.IdleRejoin = (N.Sent.byName.IdleRejoin or 0) + 1
		return (pcall(function()
			obj:Fire(true, { AutoFishing = false, DoubleSpeed = N.data().IsInGroup == true })
		end))
	end
	-- Travels to a world (Teleport remote; the first visit unlocks it with the price and level). Two failed travels in a
	-- row within 10 minutes = a stuck client (cutscene, missing folder): the rejoin above resets it.
	function N.travel(key)
		if not key or N.worldKey() == key then
			return true
		end
		-- the player teleported here from the Teleport tab: automatic trips stay put until the player teleports again
		if N.World.manual and N.World.manual == N.worldKey() and not N.World.tpBusy then
			if N.due("manualStay", 60) then
				log("WORLD stay", "in " .. tostring(N.World.manual), "skipped a trip to " .. tostring(key))
			end
			return false
		end
		if N.due("cutsceneOff", 3600) then
			send("Settings", "TeleportCutscene", false)
		end
		N.pauseFishing("travel to " .. tostring(key))
		setStatus("Travelling to " .. tostring(key))
		-- like the game's Teleport window: its Cutscene controller loads the new map and moves the character; the remote
		-- alone only changes the saved world
		if N.Cutscene == nil then
			N.Cutscene = false
			pcall(function()
				local mod = LocalPlayer.PlayerScripts.Client.Controllers.Cutscene
				local c = require(mod)
				if type(c) == "table" and type(c.Play) == "function" then
					N.Cutscene = c
				end
			end)
		end
		if N.Cutscene then
			-- run it at the game's own identity: at the executor's, the world-ready callbacks cannot require the game's
			-- modules, the travel never ends and the iris stays black
			local setId = setthreadidentity or set_thread_identity or setidentity
			local getId = getthreadidentity or get_thread_identity or getidentity
			local before = getId and getId() or 8
			if setId then
				pcall(setId, 2)
			end
			local ok, err = pcall(N.Cutscene.Play, N.Cutscene, key)
			if setId then
				pcall(setId, before)
			end
			if not ok then
				log("WORLD cutscene failed", tostring(err))
			end
			-- never leave the screen black: lift the game's iris if its travel is still running after 15 s
			local cut = N.Cutscene
			task.delay(15, function()
				if cut.Token ~= nil and cut.World == key then
					pcall(function()
						cut.Modules.UI.Iris:Out()
						cut:ShowPrompts()
					end)
					log("WORLD iris lifted", tostring(key))
				end
			end)
		end
		send("Teleport", key)
		local ok = waitFor(function()
			return N.worldKey() == key
		end, 30)
		task.wait(2)
		N.World.last = (if ok then "Arrived in " else "Could not reach ") .. tostring(key)
		log("WORLD", if ok then "arrived" else "failed", tostring(key))
		if ok then
			N.World.fails = 0
		else
			N.World.fails = (if os.clock() - (N.World.failAt or -1e9) < 600 then (N.World.fails or 0) else 0) + 1
			N.World.failAt = os.clock()
			if N.World.fails >= 2 then
				N.World.fails = 0
				N.rejoin("world change to " .. tostring(key) .. " failed twice")
			end
		end
		N.resumeFishing()
		return ok
	end
	-- One purchase through the game's remote. Upgrades are server-checked by cash and level only (190509): bought from the
	-- pier, never a walk. Rods and bait: when the server ignores the buy from the pier, the shop spot is tried once
	-- (Rods/Baits counters) and remembered.
	local ShopSpot = { rod = "Rods", bait = "Baits" }
	function N.buy(c, why)
		local before = N.cash()
		c.cashBefore = before
		c.levelBefore = if c.kind == "net" then (tonumber(N.data().OfflineNetLevel) or 1) else (tonumber(N.tab("Upgrades")[c.name]) or 0)
		local function fire()
			if c.kind == "upgrade" then
				send("Upgrades", "Buy", c.name)
			elseif c.kind == "net" then
				send("OfflineNet", "Buy")
			elseif c.kind == "rod" then
				send("RodShop", "Buy", c.name)
			elseif c.kind == "world" then
				N.travel(c.name)
			end
		end
		local spotName = ShopSpot[c.kind]
		local back
		if spotName and N.Shop.near[c.kind] then
			back = N.myPos()
			N.pauseFishing("shop")
			local pos = N.spot(spotName)
			if pos then
				N.goTo(pos, 10)
			end
		end
		fire()
		local ok = waitFor(function()
			return owned(c) or N.cash() <= before - c.price * 0.5
		end, 3)
		if not ok and spotName and not N.Shop.near[c.kind] then
			local pos = N.spot(spotName)
			if pos then
				N.pauseFishing("shop probe")
				back = N.myPos()
				N.goTo(pos, 10)
				fire()
				ok = waitFor(function()
					return owned(c) or N.cash() <= before - c.price * 0.5
				end, 3)
				N.Shop.near[c.kind] = ok or nil
				log("SHOP probe", c.kind, "far=fail", "near=" .. (if ok then "ok" else "fail"))
			end
		end
		if back then
			N.resumeFishing()
		end
		if ok then
			N.spent(c.price)
			if c.kind == "rod" then
				Session.rods += 1
				send("RodShop", "Equip", c.name)
			elseif c.kind == "upgrade" or c.kind == "net" then
				Session.upgrades += 1
			elseif c.kind == "world" then
				Session.worlds += 1
			end
			N.Shop.last = string.format("%s %s for %s", c.kind, c.name, formatNumber(c.price))
			log("BUY", c.kind, c.name, "price=" .. formatNumber(c.price), "payback=" .. (if c.payback then string.format("%.1fh", c.payback) else "-"), why or "")
			if N.Events.bought then
				pcall(N.Events.bought, c.name, c.price)
			end
		else
			log("BUY failed", c.kind, c.name, "price=" .. formatNumber(c.price))
		end
		return ok
	end
	-- Equips the strongest owned rod (luck + strength on this world).
	function N.equipBestRod()
		local d = N.data()
		local best, bestScore = d.RodEquipped, nil
		for name in pairs(N.tab("Rods")) do
			local l, s = rodPower(name)
			local score = l * 2 + s
			if not bestScore or score > bestScore then
				best, bestScore = name, score
			end
		end
		local curL, curS = rodPower(d.RodEquipped or "Wooden Rod")
		if best and best ~= d.RodEquipped and bestScore > curL * 2 + curS then
			send("RodShop", "Equip", best)
			log("ROD equip", best)
			return true
		end
		return false
	end
	-- Smart Planner (and the plain buy toggles): one purchase per call.
	function N.spendStep()
		local list = N.candidates()
		P.list = list
		-- A purchase must pay back before the current 24 h window ends (with a 10% margin), so late buys never cost
		-- more than they return.
		local horizon = N.horizon()
		P.horizon = horizon
		if N.planner() then
			-- Spare-cash perk: an offline net level that costs at most 0.2% of the cash on hand (never the reserve).
			local net = N.netCandidate()
			if net and N.cash() - N.reserve() >= net.price * 500 and net.payback <= horizon and N.buy(net, "planner spare cash") then
				return true
			end
			-- Autopilot rule: the best payback that fits the horizon is bought NOW: from cash, or after selling the
			-- backpack (Smart Sell rules, protect lists: kept fish never count) when that covers it. Only when even the
			-- backpack is not enough does Vader save, and saving = fishing on. While it saves, another purchase goes first
			-- only when its payback is shorter than the saving eta: by the time the best could be afforded it has paid
			-- for itself, so the best is never delayed (a 300K rod with a 0.9 h payback waits when the 600K rod is 5
			-- minutes away; a 400K Capacity with 1.1 h goes first when World 2 is 12 hours away).
			local best = list[1]
			local pick, fund
			P.need, P.eta = nil, nil
			local cash = N.cash()
			local _, sellable, value = N.fishStats(true)
			local funds = cash + value * 0.95
			if best and best.payback <= horizon then
				if cash >= best.price then
					pick = best
				elseif sellable > 0 and funds >= best.price then
					fund = best
				else
					P.need = best
					P.eta = math.max(best.price - funds, 0) / N.incomeRate() / 3600
					-- Saving for a world: another purchase goes first only when it gets the world bought sooner (beatsWorld).
					-- Saving for anything else: only when it pays back before the best could be afforded.
					local limit = math.min(P.eta, horizon)
					local rate = N.incomeRate()
					for _, c in ipairs(list) do
						local goesFirst
						if best.kind == "world" and best.cost then
							goesFirst = c.price < best.price and N.beatsWorld(c, best, funds, rate)
						else
							goesFirst = c.paybackNow <= limit
						end
						if c ~= best and goesFirst then
							if cash >= c.price then
								pick = c
								break
							elseif sellable > 0 and funds >= c.price then
								fund = c
								break
							end
						end
					end
				end
			end
			local action = if pick
				then pick.name
				elseif fund then fund.name .. " (sell first)"
				elseif P.need then string.format("- (fishing, saving for %s, eta %s)", P.need.name, N.longTime(P.eta * 3600))
				else "-"
			local key = (best and best.name or "-") .. "/" .. (if not pick and not fund and P.need then "saving " .. P.need.name else action)
			if key ~= P.lastKey or os.clock() - P.lastAt > 60 then
				P.lastKey, P.lastAt = key, os.clock()
				local parts = {}
				for i = 1, math.min(5, #list) do
					table.insert(parts, string.format("%s %s %s payback %.1fh (today %.1fh, +%d%%)", list[i].kind, list[i].name, formatNumber(list[i].price), list[i].payback, list[i].paybackNow or list[i].payback, math.floor((list[i].g or 0) * 100)))
				end
				log("PLAN", "rate=" .. formatNumber(N.incomeRate()) .. "/s", "horizon=" .. string.format("%.1fh", horizon), "best: " .. (if #parts > 0 then table.concat(parts, " | ") else "-"), "buy=" .. action)
			end
			local fishing = N.modeText()
			P.say = if pick
				then string.format("Buying %s (%s, payback %.1f h), then %s", pick.name, formatNumber(pick.price), pick.payback, string.lower(fishing))
				elseif fund then string.format("Selling the backpack to buy %s (%s, payback %.1f h)", fund.name, formatNumber(fund.price), fund.payback)
				elseif P.need then string.format("%s, saving for %s: %s (payback %.1f h, about %s)", fishing, P.need.name, formatNumber(P.need.price), P.need.payback, N.longTime(P.eta * 3600))
				else string.format("%s. Nothing pays back within %.0f h yet", fishing, horizon)
			if fund then
				N.sellNow("fund " .. fund.name)
				if N.cash() >= fund.price then
					pick = fund
				else
					-- The sale came up short (server value under the estimate): keep saving for it, the reserve holds the
					-- cash back from bait, the next casts close the gap.
					P.need = fund
					P.eta = math.max(fund.price - N.cash(), 0) / N.incomeRate() / 3600
					P.say = string.format("%s, saving for %s: %s (payback %.1f h, about %s)", fishing, fund.name, formatNumber(fund.price), fund.payback, N.longTime(P.eta * 3600))
					log("PLAN fund short", fund.name, "cash=" .. formatNumber(N.cash()), "price=" .. formatNumber(fund.price), "eta=" .. N.longTime(P.eta * 3600))
				end
			end
			if pick then
				if N.buy(pick, "planner") then
					P.need, P.eta = nil, nil
					N.equipBestRod()
					return true
				end
			end
			return false
		end
		-- Plain toggles: cheapest affordable upgrade, the strongest affordable rod, the next world when open. Buys back to
		-- back while the cash lasts (up to 15 in one go) instead of one purchase per cast.
		P.need = nil
		local function plainOnce(cands)
			local cheapest
			for _, c in ipairs(cands) do
				if N.cash() >= c.price and (c.kind ~= "rod" or on("AutoRods")) then
					if c.kind == "world" and (on("AutoWorlds") or (c.name == "Pond" and on("AutoPond"))) then
						return N.buy(c, "plain"), true
					end
					if c.kind == "upgrade" and on("AutoUpgrades") and (not cheapest or c.price < cheapest.price) then
						cheapest = c
					end
				end
			end
			if on("AutoRods") then
				local bestRod
				for _, c in ipairs(cands) do
					if c.kind == "rod" and N.cash() >= c.price and (not bestRod or c.frac > bestRod.frac) then
						bestRod = c
					end
				end
				if bestRod and N.buy(bestRod, "plain") then
					N.equipBestRod()
					return true
				end
			end
			if cheapest then
				return N.buy(cheapest, "plain")
			end
			return false
		end
		local bought = 0
		for i = 1, 15 do
			local ok, world = plainOnce(if i == 1 then list else N.candidates())
			if not ok then
				break
			end
			bought += 1
			if world then
				break
			end
			task.wait(0.25)
		end
		return bought > 0
	end
	-- Go fishing in the best unlocked world (Auto Worlds / planner).
	function N.worldStep()
		if not (on("AutoWorlds") or N.planner()) then
			return false
		end
		local best = N.bestFishingWorld()
		local cur = N.worldKey()
		if N.World.manual == cur then
			return false
		end
		if best ~= cur and not (N.worldCfg(cur) and N.worldCfg(cur).NoFishing and N.Pond.busy) then
			return N.travel(best)
		end
		return false
	end
	-- Smart Sell: SellAll (the NPC's own "Sell All Fish") when the backpack passes the threshold, during CashBoost, to
	-- fund the planner's next buy, or on a timer. Protected fish are locked first (the server skips locked fish), the
	-- Kraken relic (x10 on the next sale) is used right before.
	function N.protectStep()
		local n = 0
		for guid, item in pairs(N.inv()) do
			if n >= 25 then
				break
			end
			if type(item) == "table" and item.Type == "Fish" and not N.isLocked(item) and not N.relicOf(item) and not N.Sell.locked[guid] then
				if N.keeps(item) then
					send("Lock", "Toggle", guid)
					N.Sell.locked[guid] = true
					n += 1
					task.wait(0.1)
				end
			end
		end
		if n > 0 then
			log("SELL protect locked", n)
		end
		return n
	end
	function N.sellNow(reason)
		local _, sellable, value = N.fishStats(true)
		if sellable == 0 then
			return false
		end
		N.protectStep()
		if N.wants("AutoRelics") then
			N.useSellRelics()
		end
		local cashBefore = N.cash()
		local function sell()
			local res = invoke("SellAll", "Fish", nil)
			local amount = type(res) == "table" and tonumber(res.Amount) or 0
			return amount > 0, res
		end
		local ok, res, back = false, nil, nil
		if not N.Sell.needNpc then
			ok, res = sell()
		end
		if not ok then
			local pos = N.spot("NPC_Sell")
			if pos then
				N.pauseFishing("sell trip")
				back = true
				N.goTo(pos, 8)
				ok, res = sell()
				if N.Sell.needNpc == nil then
					N.Sell.needNpc = ok
					log("SELL probe", "far=fail", "npc=" .. (if ok then "ok" else "fail"))
				end
			end
		end
		if back then
			N.resumeFishing()
		end
		if ok then
			local got = tonumber(res.Value) or math.max(N.cash() - cashBefore, 0)
			Session.sold += tonumber(res.Amount) or 0
			Session.soldValue += got
			N.Sell.at = os.clock()
			N.Sell.last = string.format("%d fish for %s%s (%s)", tonumber(res.Amount) or 0, formatNumber(got), if res.Boost then " x" .. tostring(res.Boost) .. " " .. tostring(res.BoostName or "") else "", reason)
			log("SELL", "amount=" .. tostring(res.Amount), "value=" .. formatNumber(got), "boost=" .. tostring(res.Boost or 1), "reason=" .. reason, "near=" .. tostring(back == true))
			if N.Events.sold then
				pcall(N.Events.sold, tonumber(res.Amount) or 0, got)
			end
		else
			log("SELL failed", "fish=" .. sellable, "value=" .. formatNumber(value))
		end
		return ok
	end
	function N.sellStep()
		if not N.wants("SmartSell") or not N.due("sellCheck", 5) then
			return false
		end
		local count, max = N.backpack()
		local _, sellable, value = N.fishStats()
		if sellable == 0 then
			return false
		end
		local fill = count / math.max(max, 1)
		local boost = tonumber(workspace:GetAttribute("ServerCash")) or 1
		local reason
		if fill >= optionNumber("SellAt", 80) / 100 then
			reason = string.format("backpack %d%%", math.floor(fill * 100))
		elseif boost > 1 and sellable >= 5 then
			reason = "CashBoost x" .. boost
		elseif N.planner() and P.need and N.cash() < P.need.price and N.cash() + value * 0.95 >= P.need.price then
			reason = "fund " .. P.need.name
		elseif optionNumber("SellEvery", 0) > 0 and os.clock() - N.Sell.at >= optionNumber("SellEvery", 0) * 60 then
			reason = "timer"
		elseif (tonumber(N.data().Tutorial) or 100) == 4 then
			reason = "tutorial first sale"
		end
		if not reason then
			return false
		end
		return N.sellNow(reason)
	end
	-- Bait: one item = 5 casts (ConsumeBait arms up to 10 items = 50 casts in one call, 182807). Keeps a bait active; buys
	-- the strongest bait whose cost per cast stays under the budget share of the measured value of a cast, 10 at a time
	-- when the stack is cheap against the cash, never from the planner's reserve.
	function N.baitStep()
		if not N.wants("AutoBait") or not N.due("bait", 10) then
			return false
		end
		local active = 0
		for _, n in pairs(N.tab("ActiveBaits")) do
			active += tonumber(n) or 0
		end
		if active > 0 then
			return false
		end
		local baits = N.sh("Content.Item.Bait")
		local defs = baits and type(baits.Items) == "table" and baits.Items or {}
		local bestGuid, bestLuck, bestAmount
		for _, entry in ipairs(N.itemsOf("Bait")) do
			local def = defs[entry.item.Name]
			local luck = def and tonumber(def.Luck) or 0
			if not bestGuid or luck > bestLuck then
				bestGuid, bestLuck = entry.guid, luck
				bestAmount = tonumber(type(entry.item.Data) == "table" and entry.item.Data.Amount) or 1
			end
		end
		if bestGuid then
			local n = math.clamp(bestAmount, 1, 10)
			send("ConsumeBait", bestGuid, n)
			Session.baits += n
			log("BAIT use", "luck=" .. tostring(bestLuck), "x" .. n, "=" .. (n * 5) .. " casts")
			return true
		end
		if not N.wants("BuyBait") then
			return false
		end
		local perCast = math.max(N.Fish.evCast, N.incomeRate() * math.max(N.Fish.cycle, 15))
		local budget = perCast * optionNumber("BaitBudget", 10) / 100
		local free = N.cash() - N.reserve()
		local pick, pickLuck
		-- Marginal value (cast model): extra coins per cast of this bait (luck and depth) minus its cost per cast
		-- (price / 5); the best net gain wins. Without the model: the strongest bait inside the budget share.
		local chosen = Options.BaitPick and type(Options.BaitPick.Value) == "table" and Options.BaitPick.Value or {}
		local K, base = N.castScale()
		local none = if base then N.castModel({ bait = false }) else nil
		if next(chosen) then
			-- the player's list: the strongest picked bait that is affordable and in stock
			for name in pairs(chosen) do
				local def = defs[name]
				local price = def and tonumber(def.Price) or math.huge
				if def and price * 2 <= free and (N.Shop.stockOut[name] or 0) < os.clock() and (not pick or (tonumber(def.Luck) or 0) > pickLuck) then
					pick, pickLuck = name, tonumber(def.Luck) or 0
				end
			end
		elseif base and none then
			local pickNet
			for name, def in pairs(defs) do
				local price = tonumber(def.Price) or math.huge
				if price * 2 <= free and (N.Shop.stockOut[name] or 0) < os.clock() then
					local c = N.castModel({ bait = def })
					local net = if c then (c - none) * K - price / 5 else -1
					if net > 0 and (not pickNet or net > pickNet) then
						pick, pickNet, pickLuck = name, net, tonumber(def.Luck) or 0
					end
				end
			end
		else
			for name, def in pairs(defs) do
				local price = tonumber(def.Price) or math.huge
				if price / 5 <= budget and price * 2 <= free and (N.Shop.stockOut[name] or 0) < os.clock() and (not pick or (tonumber(def.Luck) or 0) > pickLuck) then
					pick, pickLuck = name, tonumber(def.Luck) or 0
				end
			end
		end
		if not pick then
			return false
		end
		local price = tonumber(defs[pick].Price) or 0
		local count = if price * 10 <= free * 0.05 then 10 else 2
		local before = #N.itemsOf("Bait")
		send("BaitShop", "Buy", pick, count)
		if not waitFor(function()
			return #N.itemsOf("Bait") > before
		end, 3) then
			N.Shop.stockOut[pick] = os.clock() + 300
			log("BAIT buy failed", pick, "(out of stock or too far), retry in 5m")
			return false
		end
		log("BAIT buy", pick, "x" .. count, "cost/cast=" .. formatNumber(price / 5), "cast value=" .. formatNumber(perCast))
		return true
	end
	-- Pond (idle income): a trip every Pond Every minutes: collect, the game's EquipBest roster, revive or clear dead
	-- fish, food stock, capacity upgrades. Potions pause in the pond world, so trips stay short.
	function N.pondStep()
		if not N.wants("AutoPond") then
			return false
		end
		if not N.unlocked("Pond") then
			return false
		end
		if not N.due("pond", optionNumber("PondEvery", 60) * 60) then
			return false
		end
		local back = N.worldKey()
		N.Pond.busy = true
		if not N.travel("Pond") then
			N.Pond.busy = false
			return false
		end
		setStatus("Pond: collecting and feeding")
		local before = N.cash()
		send("Pond", "Collect")
		task.wait(1)
		send("Pond", "EquipBest")
		task.wait(1)
		local pond = N.tab("Pond")
		local dead = 0
		for _, f in pairs(type(pond.Fish) == "table" and pond.Fish or {}) do
			if type(f) == "table" and f.Dead then
				dead += 1
			end
		end
		if dead > 0 then
			send("Pond", "ReviveHeart")
			task.wait(1)
			send("Pond", "SellAllDead")
			task.wait(0.5)
		end
		-- Food: the strongest food whose price stays under half an hour of pond income.
		local PondMod = N.sh("Modules.Pond")
		local foods = N.sh("Content.Item.Food")
		local hourly = 0
		pcall(function()
			hourly = PondMod:BaseRate(pond) * 3600
		end)
		local stock, maxStock = tonumber(pond.Stock) or 0, 0
		pcall(function()
			maxStock = PondMod:MaxStock(pond)
		end)
		if foods and type(foods.Items) == "table" and maxStock > 0 and stock < maxStock * 0.5 then
			local pick, pickMult
			for name, def in pairs(foods.Items) do
				local price = tonumber(def.Price) or math.huge
				if price <= math.max(hourly * 0.5, 300) and price * 3 <= N.cash() and (not pick or (tonumber(def.Multiplier) or 0) > pickMult) then
					pick, pickMult = name, tonumber(def.Multiplier) or 0
				end
			end
			if pick then
				send("Pond", "BuyFood", pick)
				task.wait(1)
				for _, entry in ipairs(N.itemsOf("Food")) do
					send("Pond", "AddFood", entry.guid)
					task.wait(0.3)
				end
					log("POND food", pick)
			end
		end
		if N.due("pondAutoFeed", 3600) then
			send("Settings", "AutoFeed", true)
		end
		-- Capacity 10/15/20 slots: always worth it once the pond earns (each fish pays back its value within hours).
		local cfgPond = N.sh("Config.PondConfig")
		pcall(function()
			local levels = cfgPond.UpgradePrices or cfgPond.CapacityPrices
			local price = levels and levels[(tonumber(pond.Level) or 1)]
			if price and N.cash() >= price * 2 and hourly > 0 then
				send("Pond", "Upgrade")
				N.spent(price)
				log("POND upgrade", formatNumber(price))
			end
		end)
		Session.pondTrips += 1
		local got = N.cash() - before
		N.Pond.last = string.format("Collected %s, %d fish, %s/h", formatNumber(math.max(got, 0)), (function()
			local n = 0
			for _ in pairs(type(N.tab("Pond").Fish) == "table" and N.tab("Pond").Fish or {}) do
				n += 1
			end
			return n
		end)(), formatNumber(hourly))
		log("POND trip", N.Pond.last)
		N.Pond.busy = false
		N.travel(if back ~= "Pond" or N.World.manual == "Pond" then back else N.bestFishingWorld())
		return true
	end
	-- Pets: equip the strongest pet (rarity, then shiny, then level) from anywhere; eggs need the own pond world, the egg
	-- held as a tool and the character at the hatchery (World.Pond.Interactable.EggHatchPart.Slot1..5), like the game's
	-- prompts: HatchEgg("Place", slot) / HatchEgg("Hatch", slot). The game's own client answers "Hatched" with "Done".
	local PetRank = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Exclusive = 7, Secret = 8 }
	local function petScore(item)
		local defs = N.sh("Content.Item.Pet")
		local def = defs and type(defs.Items) == "table" and defs.Items[item.Name]
		local d = type(item.Data) == "table" and item.Data or {}
		return (PetRank[def and def.Rarity] or 0) * 1000 + (if d.Shiny then 500 else 0) + (tonumber(d.Level) or 1)
	end
	function N.petStep()
		if not N.wants("AutoPets") or not N.due("pets", 30) then
			return false
		end
		local d = N.data()
		local equipped = type(d.EquippedPets) == "table" and d.EquippedPets or {}
		local inPond = type(d.PondPets) == "table" and d.PondPets or {}
		local best, bestScore
		for guid, item in pairs(N.inv()) do
			if type(item) == "table" and item.Type == "Pet" and inPond[guid] == nil then
				local s = petScore(item)
				if not best or s > bestScore then
					best, bestScore = guid, s
				end
			end
		end
		if best and equipped[best] == nil then
			send("EquipPet", "Equip", best)
			log("PET equip", tostring(N.inv()[best] and N.inv()[best].Name), "score=" .. bestScore)
		end
		local slots = tonumber(N.sh("Config.PetConfig.Hatchery.Slots")) or 5
		local placed = type(d.PlacedEggs) == "table" and d.PlacedEggs or {}
		local now = N.serverTime()
		local ready, free = {}, {}
		for i = 1, slots do
			local egg = placed[tostring(i)] or placed[i]
			if type(egg) == "table" then
				if (tonumber(egg.ReadyAt) or math.huge) <= now then
					table.insert(ready, i)
				end
			else
				table.insert(free, i)
			end
		end
		local eggs = N.itemsOf("Egg")
		if #ready == 0 and (#free == 0 or #eggs == 0) then
			return false
		end
		if not N.unlocked("Pond") then
			return false
		end
		local back = N.worldKey()
		if not N.travel("Pond") then
			return false
		end
		setStatus("Pets: hatching eggs")
		local function slotPart(i)
			local w = workspace:FindFirstChild("World")
			local bed = w and w:FindFirstChild("Pond")
			bed = bed and bed:FindFirstChild("Interactable")
			bed = bed and bed:FindFirstChild(tostring(N.sh("Config.PetConfig.Hatchery.Anchor") or "EggHatchPart"))
			local part = bed and bed:FindFirstChild("Slot" .. i)
			return if part and part:IsA("BasePart") then part else nil
		end
		local hatched, placedNow = 0, 0
		for _, i in ipairs(ready) do
			local part = slotPart(i)
			if part then
				N.goTo(part.Position, 5)
				send("HatchEgg", "Hatch", tostring(i))
				hatched += 1
				task.wait(2)
				table.insert(free, i)
			end
		end
		-- the best eggs first (rarer eggs give rarer pets)
		local eggDefs = N.sh("Content.Item.Egg")
		table.sort(eggs, function(a, b)
			local da = eggDefs and type(eggDefs.Items) == "table" and eggDefs.Items[a.item.Name]
			local db = eggDefs and type(eggDefs.Items) == "table" and eggDefs.Items[b.item.Name]
			return (PetRank[da and da.Rarity] or 0) > (PetRank[db and db.Rarity] or 0)
		end)
		for _, i in ipairs(free) do
			local entry = eggs[1]
			while entry and N.inv()[entry.guid] == nil do
				table.remove(eggs, 1)
				entry = eggs[1]
			end
			local part = slotPart(i)
			if not entry or not part then
				break
			end
			N.goTo(part.Position, 5)
			N.holdItem(entry.guid)
			send("HatchEgg", "Place", tostring(i))
			placedNow += 1
			task.wait(1)
		end
		log("PET hatchery", "hatched=" .. hatched, "placed=" .. placedNow)
		N.travel(if back ~= "Pond" or N.World.manual == "Pond" then back else N.bestFishingWorld())
		return hatched + placedNow > 0
	end
	-- Cargo (task board): give each order slot from the inventory (the server picks the cheapest unlocked match, Keep
	-- lists stay safe), send the boat once full, claim it when it returns. Remote only, no movement.
	function N.cargoStep()
		if not N.wants("AutoCargo") or not N.due("cargo", 20) then
			return false
		end
		local CC = N.sh("Config.CargoConfig")
		if type(CC) ~= "table" or type(CC.Cycle) ~= "function" then
			return false
		end
		local now = N.serverTime()
		local cargo = N.tab("Cargo")
		if type(cargo.Voyage) == "table" then
			if (tonumber(cargo.Voyage.ReturnAt) or math.huge) <= now then
				send("Cargo", "Claim")
				log("CARGO claim")
				return true
			end
			return false
		end
		local cycle = CC.Cycle(now)
		local order = cargo.Order
		if type(order) ~= "table" or order.Cycle ~= cycle then
			send("Cargo", "Sync")
			return false
		end
		if order.Sent then
			return false
		end
		local d, gave = N.data(), 0
		for i, slot in ipairs(type(order.Slots) == "table" and order.Slots or {}) do
			local left = (tonumber(slot.Need) or 0) - (tonumber(slot.Given) or 0)
			local ok, have = pcall(CC.Have, N.Sh, LocalPlayer, d, slot)
			for _ = 1, math.min(left, if ok then tonumber(have) or 0 else 0) do
				send("Cargo", "Give", i, cycle)
				gave += 1
				task.wait(0.4)
			end
		end
		if gave > 0 then
			log("CARGO give", gave)
			task.wait(1)
		end
		local okFull, full = pcall(CC.Full, N.tab("Cargo").Order)
		if okFull and full then
			send("Cargo", "Send", cycle)
			log("CARGO send", "tier=" .. tostring(order.Tier))
			return true
		end
		return gave > 0
	end
	-- Probes (Fishing > Probes, all OFF, blatant.md NEW 8): one-shot experiments on hidden server handlers. Each runs once
	-- per PlaceVersion on this account (the result is remembered in Vader/FISH_probes_<UserId>.txt, a game update runs it
	-- again), logs `PROBE <name> result=...`, then switches its own toggle off. They never feed the planner: a result only
	-- tells the owner whether a shortcut exists.
	N.Probe = { last = "-", names = { "ProbeSell2", "ProbeTpLocked", "ProbeStreakHold" } }
	do
		local ProbeFile = "Vader/FISH_probes_" .. tostring(LocalPlayer.UserId) .. ".txt"
		local memory = {}
		pcall(function()
			if isfile(ProbeFile) then
				for line in string.gmatch(readfile(ProbeFile), "[^\n]+") do
					local key, result = string.match(line, "^(%S+)%s+(.+)$")
					if key then
						memory[key] = result
					end
				end
			end
		end)
		local function saveMemory()
			pcall(function()
				if makefolder and isfolder and not isfolder("Vader") then
					makefolder("Vader")
				end
				local lines = {}
				for key, result in pairs(memory) do
					table.insert(lines, key .. " " .. result)
				end
				table.sort(lines)
				writefile(ProbeFile, table.concat(lines, "\n"))
			end)
		end
		local function placeVersion()
			local ok, v = pcall(function()
				return game.PlaceVersion
			end)
			return tostring(if ok and v ~= nil then v else 0)
		end
		local function switchOff(name)
			local toggle = Toggles[name]
			if toggle and toggle.Value then
				local quiet = N.quiet
				N.quiet = true
				pcall(toggle.SetValue, toggle, false)
				N.quiet = quiet
			end
		end
		-- Double Sell (Sell = Invoke(5, guid) of the held fish, handler hidden, no visible lock): the same fish sold twice at
		-- the same moment. Expected: one sale, one refusal. Needs one cheap unlocked, unprotected fish.
		local function probeSell2()
			local guid, cheapest
			for g, item in pairs(N.inv()) do
				if type(item) == "table" and item.Type == "Fish" and not N.isLocked(item) and not N.relicOf(item) and not N.keeps(item) then
					local v = N.value(item)
					if not cheapest or v < cheapest then
						guid, cheapest = g, v
					end
				end
			end
			if not guid then
				return nil, "needs one cheap unprotected fish in the backpack"
			end
			N.pauseFishing("probe sell2")
			local pos = N.spot("NPC_Sell")
			if pos then
				N.goTo(pos, 8)
			end
			N.holdItem(guid)
			local a, b, done = nil, nil, 0
			task.spawn(function()
				a = invoke("Sell", guid)
				done += 1
			end)
			task.spawn(function()
				b = invoke("Sell", guid)
				done += 1
			end)
			waitFor(function()
				return done >= 2
			end, 12)
			N.resumeFishing()
			local x, y = tonumber(a) or 0, tonumber(b) or 0
			if done < 2 then
				return nil, "the sale did not answer in 12 s, trying again"
			elseif x > 0 and y > 0 then
				return string.format("DUPLICATE both paid %s + %s for one fish", formatNumber(x), formatNumber(y))
			elseif x > 0 or y > 0 then
				return string.format("refused the second sale (%s, %s)", formatNumber(x), formatNumber(y))
			end
			return "neither sale paid (not at the merchant or the fish is not for sale)"
		end
		-- Teleport to a locked world (the client gates by level and unlock, the server's Islands:Teleport is hidden): the
		-- lowest fishing world above the level. Expected: refused. A world change = the server did not stop it.
		local function probeTpLocked()
			local W = cfg("WorldsConfig")
			local key, def
			for k, w in pairs(W and type(W.Worlds) == "table" and W.Worlds or {}) do
				if not w.NoFishing and not N.unlocked(k) and N.level() < (tonumber(w.RequiredLevel) or 1) and (not def or (tonumber(w.WorldNumber) or 0) < (tonumber(def.WorldNumber) or 0)) then
					key, def = k, w
				end
			end
			if not key then
				return "n/a (no locked fishing world above this level)"
			end
			local back = N.worldKey()
			N.pauseFishing("probe tp_locked")
			send("Teleport", key)
			local moved = waitFor(function()
				return N.worldKey() == key
			end, 15)
			local context = string.format("%s level=%d needs=%s cash=%s price=%s", key, N.level(), tostring(def.RequiredLevel), formatNumber(N.cash()), formatNumber(tonumber(def.UnlockPrice) or 0))
			N.resumeFishing()
			if moved then
				N.travel(back)
				return "TRAVELLED, the server did not stop it: " .. context
			end
			return "refused: " .. context
		end
		-- Streak hold (StreakHold(true) is what the client sends while a cutscene plays; HoldForCutscene is hidden): does
		-- the server set StreakHeldUntil? Released again at once (false) like the game's own watcher does.
		local function probeStreakHold()
			local function heldUntil()
				return tonumber(LocalPlayer:GetAttribute("StreakHeldUntil")) or 0
			end
			local before = heldUntil()
			send("StreakHold", true)
			local held = waitFor(function()
				return heldUntil() > math.max(before, N.serverTime())
			end, 4)
			local seconds = heldUntil() - N.serverTime()
			task.wait(0.5)
			send("StreakHold", false)
			return if held then string.format("held %.0f s ahead (StreakHeldUntil set)", seconds) else "no hold (StreakHeldUntil unchanged)"
		end
		local Probes = {
			{ toggle = "ProbeSell2", name = "sell2", run = probeSell2 },
			{ toggle = "ProbeTpLocked", name = "tp_locked", run = probeTpLocked },
			{ toggle = "ProbeStreakHold", name = "streakhold", run = probeStreakHold },
		}
		-- One probe per call from the main loop (it owns the character); returns true when it did something.
		function N.probeStep()
			for _, p in ipairs(Probes) do
				if on(p.toggle) and N.due("probe_" .. p.name, 20) then
					local key = p.name .. "@" .. placeVersion()
					if memory[key] then
						N.Probe.last = p.name .. ": " .. memory[key] .. " (remembered)"
						log("PROBE", p.name, "result=" .. memory[key], "(remembered for PlaceVersion " .. placeVersion() .. ")")
						switchOff(p.toggle)
						return false
					end
					local result, why = p.run()
					if result then
						memory[key] = result
						saveMemory()
						N.Probe.last = p.name .. ": " .. result
						log("PROBE", p.name, "result=" .. result)
						switchOff(p.toggle)
						return true
					end
					setStatus("Probe " .. p.name .. " waits: " .. tostring(why))
					if N.due("probeWait_" .. p.name, 300) then
						log("PROBE", p.name, "waiting", tostring(why))
					end
				end
			end
			return false
		end
	end
end
local Window, Tabs, Labels
do
	do
		local setIdentity = setthreadidentity or set_thread_identity or setidentity or (syn and syn.set_thread_identity)
		-- The UI thread loses its rights after a while ('lacking capability Plugin' every ~30 s in the live log): set again before every UI group.
		function N.fixIdentity()
			if setIdentity then
				pcall(setIdentity, 8)
			end
		end
		N.fixIdentity()
	end
	Window = Library:CreateWindow({
		Title = "Vader UI",
		Footer = GameName,
	})
	function N.addTab(name, icon, description)
		return Window:AddTab({ Name = name, Icon = icon, Description = description })
	end
	Tabs = {}
	Tabs.Main = N.addTab("Main", "house", "What Vader does next")
	Tabs.Fishing = N.addTab("Fishing", "fish", "Auto Fish, Smart Sell, bait, pond and the Smart Planner")
	Tabs.Upgrades = N.addTab("Upgrades", "trending-up", "Upgrades, rods and worlds")
	Tabs.Rewards = N.addTab("Rewards", "gift", "Daily, playtime, season, achievements, codes and the Big Mouth")
	Tabs.Items = N.addTab("Items", "backpack", "Chests, potions, relics, enchants and mutations")
	Tabs.Teleport = N.addTab("Teleport", "map", "Islands")
	Tabs.Stats = N.addTab("Stats", "chart-column", "Session progress and rates")
	Tabs.Webhook = N.addTab("Webhook", "webhook", "Discord posts")
	Tabs.Misc = Window:AddMiscTab({ Description = "Performance, AFK and connection" })
	Labels = {}
	-- Every automation toggle (Stop Everything, Status, the stuck check). No master toggle (owner decision 2026-10-05).
	N.FarmToggles = {
		{ "AutoFish", "Fish" },
		{ "SmartSell", "Sell" },
		{ "SmartPlanner", "Smart Planner" },
		{ "AutoBait", "Bait" },
		{ "AutoPond", "Pond" },
		{ "AutoUpgrades", "Upgrades" },
		{ "AutoRods", "Rods" },
		{ "AutoWorlds", "Worlds" },
		{ "AutoRewards", "Rewards" },
		{ "AutoCodes", "Codes" },
		{ "AutoBigMouth", "Big Mouth" },
		{ "AutoOpen", "Open chests" },
		{ "AutoPotions", "Potions" },
		{ "AutoRelics", "Relics" },
		{ "AutoEnchant", "Enchant" },
		{ "AutoMutate", "Mutations" },
		{ "AutoPets", "Pets" },
		{ "AutoCargo", "Cargo" },
	}
	function N.resetOptions()
		local ignore = {}
		local function skip(name)
			return ignore[name] == true or name == "MenuKeybind" or string.find(name, "^SaveManager") ~= nil or string.find(name, "^Vader") ~= nil or string.find(name, "^ThemeManager") ~= nil
		end
		N.quiet = true
		local changed = 0
		for name, toggle in pairs(Toggles) do
			local default = toggle.Default
			if not skip(name) and type(default) == "boolean" and toggle.Value ~= default then
				pcall(toggle.SetValue, toggle, default)
				changed += 1
			end
		end
		for name, option in pairs(Options) do
			local kind = option.Type
			local default = option.Default
			if not skip(name) and default ~= nil and kind ~= "KeyPicker" and kind ~= "ColorPicker" then
				local value = default
				if type(default) == "table" and option.Multi then
					value = {}
					for k, v in pairs(default) do
						if type(k) == "number" then
							value[v] = true
						elseif v then
							value[k] = true
						end
					end
				elseif type(default) == "table" then
					value = default[1]
				end
				pcall(option.SetValue, option, value)
				changed += 1
			end
		end
		N.quiet = false
		log("RESET options to defaults", "controls", changed)
		notify("Vader", "All hub options are back to their defaults. Saved configs are untouched", 5)
	end
	function N.askReset()
		Library:ShowConfirmPrompt({
			Title = "Reset Hub Options",
			Text = "Reset all options to defaults?",
			Warning = "Saved configs are not deleted",
			ConfirmText = "Reset",
			CancelText = "Cancel",
			OnConfirm = function()
				N.resetOptions()
			end,
		})
	end
	local function listKeys(path, filter)
		local t = N.sh(path)
		local items = type(t) == "table" and (t.Items or t) or {}
		local out = {}
		if type(items) == "table" then
			for name, def in pairs(items) do
				if type(name) == "string" and type(def) == "table" and (not filter or filter(def)) then
					table.insert(out, name)
				end
			end
		end
		table.sort(out)
		return out
	end
	do
		local FishBox = Tabs.Fishing:AddLeftGroupbox("Auto Fish", "fish")
		FishBox:AddToggle("AutoFish", {
			Text = "Auto Fish",
			Default = false,
			Tooltip = "Goes to the pier, holds your rod, finishes the tutorial and fishes. Mode picks how. It also sets the game's Rare Cutscene setting to None once, so a rare catch no longer holds the next cast for 4-7 s",
			Callback = function(v)
				if not v and not N.planner() then
					N.fishOff()
				end
			end,
		})
		FishBox:AddSlider("PerfectRate", {
			Text = "Perfect Rate",
			Default = 60,
			Min = 0,
			Max = 95,
			Rounding = 0,
			Suffix = "%",
			Tooltip = "Share of Perfect throws (+33% distance, deeper water, more fish). 60% is what the game's AutoBoost enchant gives",
		})
		FishBox:AddToggle("IndexHunt", { Text = "Index Hunt", Default = false, Tooltip = "Counts species missing from your index 50% higher when picking fish (every 10/25/50/75/100 species = +10% on all sales)" })
		Labels.Fish = { SetText = function() end }
		local SellBox = Tabs.Fishing:AddRightGroupbox("Auto Sell", "coins")
		SellBox:AddToggle("SmartSell", {
			Text = "Auto Sell",
			Default = false,
			Tooltip = "Sells all unlocked fish (the merchant's Sell All) when the backpack fills, during a server CashBoost, when the Smart Planner needs the cash, or on the timer. Kept fish are locked first",
		})
		SellBox:AddSlider("SellAt", { Text = "Sell at backpack", Default = 80, Min = 10, Max = 100, Rounding = 0, Suffix = "%" })
		SellBox:AddSlider("SellEvery", { Text = "Also sell every", Default = 0, Min = 0, Max = 60, Rounding = 0, Suffix = " min", HideMax = true, Tooltip = "0 = only by the rules above" })
		local rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Exotic" }
		SellBox:AddDropdown("KeepRarities", { Text = "Keep rarities", Values = rarities, Default = { "Secret", "Exotic" }, Multi = true, AllowNull = true, Tooltip = "Fish of these rarities are locked (favorited) and never sold" })
		SellBox:AddToggle("KeepMutated", { Text = "Keep mutated fish", Default = false })
		SellBox:AddDropdown("KeepFish", { Text = "Keep fish", Values = listKeys("Content.Item.Fish"), Default = {}, Multi = true, AllowNull = true, Searchable = true, Tooltip = "These species are locked and never sold" })
		SellBox:AddButton({
			Text = "Sell Now",
			Func = function()
				task.spawn(N.runManual, function()
					N.sellNow("button")
				end)
			end,
		})
		Labels.Sell = { SetText = function() end }
		local BaitBox = Tabs.Fishing:AddLeftGroupbox("Bait", "worm")
		BaitBox:AddToggle("AutoBait", { Text = "Auto Bait", Default = false, Tooltip = "Keeps your strongest bait active (one bait = 5 casts)" })
		BaitBox:AddToggle("BuyBait", { Text = "Buy bait", Default = true, Tooltip = "With Auto Bait: buys the strongest bait in stock whose cost per cast stays under the budget" })
		local baitNames = listKeys("Content.Item.Bait")
		local baitDefs = N.sh("Content.Item.Bait")
		baitDefs = baitDefs and type(baitDefs.Items) == "table" and baitDefs.Items or {}
		table.sort(baitNames, function(a, b)
			return (tonumber(baitDefs[a] and baitDefs[a].Price) or 0) < (tonumber(baitDefs[b] and baitDefs[b].Price) or 0)
		end)
		BaitBox:AddDropdown("BaitPick", { Text = "Baits to buy", Values = baitNames, Default = {}, Multi = true, AllowNull = true })
		BaitBox:AddSlider("BaitBudget", { Text = "Bait budget", Default = 10, Min = 1, Max = 50, Rounding = 0, Suffix = "% of a cast", Tooltip = "Most a bait may cost per cast, as a share of what one cast earns" })
		Labels.Bait = { SetText = function() end }
		local PondBox = Tabs.Fishing:AddRightGroupbox("Pond", "droplets")
		PondBox:AddToggle("AutoPond", {
			Text = "Auto Pond",
			Default = false,
			Tooltip = "Unlocks the pond (level 5), then visits it: collects the income, fills it with your best fish (the game's Equip Best), revives or clears dead fish, buys food and capacity",
		})
		PondBox:AddSlider("PondEvery", { Text = "Visit every", Default = 60, Min = 20, Max = 240, Rounding = 0, Suffix = " min", Tooltip = "The pond keeps up to 8 hours of income" })
		Labels.Pond = { SetText = function() end }
		Labels.Planner = { SetText = function() end }
		Labels.Probes = { SetText = function() end }
		-- Main: Status.
		local StatusBox = Tabs.Main:AddRightGroupbox("Status", "activity")
		Labels.Status = StatusBox:AddLabel({ Text = "Idle", DoesWrap = true })
		Labels.Info = StatusBox:AddLabel({ Text = "-", DoesWrap = true })
		Labels.Plan = StatusBox:AddLabel({ Text = "-", DoesWrap = true })
		Labels.Lines = StatusBox:AddLabel({ Text = "-", DoesWrap = true })
	end
	do
		local UpBox = Tabs.Upgrades:AddLeftGroupbox("Upgrades", "arrow-up")
		UpBox:AddToggle("AutoUpgrades", { Text = "Auto Upgrades", Default = false, Tooltip = "Buys the cheapest picked upgrade you can afford (Capacity = hooks per cast, Strength = distance, Weight = depth, Bounce). Smart Planner buys by payback instead" })
		UpBox:AddDropdown("UpgradeStats", { Text = "Upgrades", Values = { "Capacity", "Strength", "Weight", "Bounce" }, Default = { "Capacity", "Strength", "Weight", "Bounce" }, Multi = true, AllowNull = true })
		Labels.Upgrades = { SetText = function() end }
		local RodBox = Tabs.Upgrades:AddRightGroupbox("Rods", "anchor")
		RodBox:AddToggle("AutoRods", { Text = "Auto Buy Rods", Default = false, Tooltip = "Buys the strongest rod you can afford and equips your best rod. Smart Planner buys by payback instead" })
		Labels.Rods = { SetText = function() end }
		local WorldBox = Tabs.Upgrades:AddRightGroupbox("Worlds", "globe")
		WorldBox:AddToggle("AutoWorlds", { Text = "Auto Worlds", Default = false, Tooltip = "Unlocks the next world once your level and cash allow (World 2: level 15, 30M; World 3: 40, 7.5B; World 4: 65, 400B) and fishes in the best one" })
		Labels.World = { SetText = function() end }
	end
	do
		local RewardBox = Tabs.Rewards:AddLeftGroupbox("Rewards", "gift")
		RewardBox:AddToggle("AutoRewards", {
			Text = "Auto Rewards",
			Default = false,
			Tooltip = "Daily ladder, free daily roll, playtime gifts, next day reward, season free tiers, achievements, offline catch, and the group, referral and comeback rewards when you have them",
		})
		Labels.Rewards = { SetText = function() end }
		local CodeBox = Tabs.Rewards:AddRightGroupbox("Codes", "ticket")
		CodeBox:AddToggle("AutoCodes", { Text = "Auto Redeem Codes", Default = false, Tooltip = "Redeems every known code once on this account, plus your secret code from the four signs" })
		local MouthBox = Tabs.Rewards:AddLeftGroupbox("Big Mouth", "smile")
		MouthBox:AddToggle("AutoBigMouth", { Text = "Auto Big Mouth", Default = false, Tooltip = "Every 12 h feeds the Big Mouth (World 1) your cheapest fish until it is full: permanent luck (+10% for the first five, then +5%, up to +200%) and a reward roll" })
		Labels.BigMouth = { SetText = function() end }
	end
	do
		local OpenBox = Tabs.Items:AddLeftGroupbox("Chests & Gifts", "package-open")
		OpenBox:AddToggle("AutoOpen", { Text = "Auto Open", Default = false, Tooltip = "Opens chests, cages and like gifts from your catches" })
		Labels.Open = { SetText = function() end }
		local PotionBox = Tabs.Items:AddRightGroupbox("Potions", "flask-conical")
		PotionBox:AddToggle("AutoPotions", { Text = "Auto Potions", Default = false, Tooltip = "Drinks a picked potion when none of its kind runs (not in the pond, where potions pause)" })
		PotionBox:AddDropdown("PotionKinds", { Text = "Potions", Values = { "Luck", "Coins", "XP", "Mutation", "Capacity" }, Default = { "Luck", "Coins", "XP", "Mutation", "Capacity" }, Multi = true, AllowNull = true })
		local RelicBox = Tabs.Items:AddLeftGroupbox("Boss Relics", "crown")
		RelicBox:AddToggle("AutoRelics", { Text = "Auto Relics", Default = false, Tooltip = "Uses boss relics: luck relics right away, the Kraken relic (x10 on the next sale) right before Smart Sell sells" })
		local EnchantBox = Tabs.Items:AddRightGroupbox("Enchant", "sparkles")
		EnchantBox:AddToggle("AutoEnchant", { Text = "Auto Enchant", Default = false, Tooltip = "At the Stone Mage: rolls Enchant Stones (slot 1) and Ultra Enchant Stones (slot 2) until the rod has a picked enchant" })
		EnchantBox:AddDropdown("EnchantTargets", { Text = "Stop at", Values = listKeys("Config.EnchantConfig"), Default = { "Trawler", "Fishmonger", "Deepnet", "Midas" }, Multi = true, AllowNull = true, Searchable = true })
		local MutateBox = Tabs.Items:AddLeftGroupbox("Mutation Dealer", "dna")
		MutateBox:AddToggle("AutoMutate", { Text = "Auto Mutate", Default = false, Tooltip = "Spends Mutation Scrolls at the Mutation Dealer on your most valuable fish without a mutation (x2 to x15 sell value)" })
		local PetBox = Tabs.Items:AddRightGroupbox("Pets", "paw-print")
		PetBox:AddToggle("AutoPets", { Text = "Auto Pets", Default = false })
		local CargoBox = Tabs.Items:AddLeftGroupbox("Cargo", "ship")
		CargoBox:AddToggle("AutoCargo", { Text = "Auto Cargo", Default = false })
		Labels.Items = { SetText = function() end }
	end
	-- Teleport: the game's own Teleport remote (N.travel), the same as its Teleport window. A locked island the level
	-- allows is bought with its unlock price on the first visit, exactly like the window's price button.
	do
		local TpBox = Tabs.Teleport:AddLeftGroupbox("Islands", "map")
		for _, w in ipairs({ { "Pond", "Pond" }, { "World 1", "Fernshore" }, { "World 2", "Dunehaven" }, { "World 3", "Frostmere" }, { "World 4", "Emberdeep" } }) do
			local key, name = w[1], w[2]
			local cfg = N.worldCfg(key) or {}
			local req = tonumber(cfg.RequiredLevel) or 1
			local price = tonumber(cfg.UnlockPrice) or 0
			TpBox:AddButton({
				Text = string.format("%s (Lv %d%s)", name, req, if price > 0 then ", " .. formatNumber(price) else ""),
				Func = function()
					if N.World.tpBusy then
						notify("Teleport", "Already teleporting, wait a moment", 2)
					elseif N.worldKey() == key then
						N.World.manual = key
						notify("Teleport", "You are already in " .. name, 3)
					elseif N.level() < req then
						notify("Teleport", string.format("%s needs level %d (you are %d)", name, req, N.level()), 4)
					elseif not N.unlocked(key) and N.cash() < price then
						notify("Teleport", string.format("%s costs %s to unlock (you have %s)", name, formatNumber(price), formatNumber(N.cash())), 4)
					else
						N.World.tpBusy = true
						-- the hub stays where the player sent it: Auto Worlds and the no-fishing check stop pulling back
						N.World.manual = key
						notify("Teleport", "Teleporting to " .. name .. "...", 3)
						local ok = N.travel(key)
						N.World.tpBusy = false
						notify("Teleport", (if ok then "Arrived in " else "Could not reach ") .. name, 3)
					end
				end,
			})
		end
	end
end
N.StatRows = {}
do
	local function statRow(box, icon, text, size, color)
		if box.AddStat then
			local ok, stat = pcall(box.AddStat, box, { Icon = icon, Text = text, Value = "-", Size = size or 22, ValueColor = color })
			if ok and stat then
				return {
					set = function(value)
						stat:SetValue(value)
					end,
				}
			end
		end
		local label = box:AddLabel({ Text = text .. ": -", DoesWrap = true })
		return {
			set = function(value)
				label:SetText(text .. ": " .. tostring(value))
			end,
		}
	end
	local ProgressBox = Tabs.Stats:AddLeftGroupbox("Progress", "trending-up")
	N.StatRows.Cash = statRow(ProgressBox, "coins", "Coins", 28)
	N.StatRows.Earned = statRow(ProgressBox, "trending-up", "Earned this session", 22, "FontColor")
	N.StatRows.Rate = statRow(ProgressBox, "activity", "Coins per hour", 22, "FontColor")
	N.StatRows.Level = statRow(ProgressBox, "chevrons-up", "Level", 22)
	N.StatRows.World = statRow(ProgressBox, "globe", "World", 22)
	N.StatRows.Time = statRow(ProgressBox, "clock", "Session", 22, "FontColor")
	local FishStats = Tabs.Stats:AddRightGroupbox("Fishing", "fish")
	N.StatRows.Casts = statRow(FishStats, "target", "Casts / Perfect", 28)
	N.StatRows.Caught = statRow(FishStats, "fish", "Fish caught / finds", 22)
	N.StatRows.Best = statRow(FishStats, "award", "Best fish", 22)
	N.StatRows.Cycle = statRow(FishStats, "timer", "Cast time / value", 22)
	N.StatRows.Sold = statRow(FishStats, "coins", "Sold fish / coins", 22)
	N.StatRows.Backpack = statRow(FishStats, "backpack", "Backpack", 22)
	local BuyStats = Tabs.Stats:AddLeftGroupbox("Purchases", "shopping-cart")
	N.StatRows.Buys = statRow(BuyStats, "arrow-up", "Upgrades / rods / worlds", 22)
	N.StatRows.Bait = statRow(BuyStats, "worm", "Baits used", 22)
	N.StatRows.Pond = statRow(BuyStats, "droplets", "Pond trips", 22)
	local RewardStats = Tabs.Stats:AddRightGroupbox("Rewards & Items", "gift")
	N.StatRows.Claims = statRow(RewardStats, "gift", "Rewards claimed", 22)
	N.StatRows.Codes = statRow(RewardStats, "ticket", "Codes redeemed / tried", 22)
	N.StatRows.Items = statRow(RewardStats, "package-open", "Opened / potions / relics", 22)
	function N.drawStats()
		local elapsed = math.max(os.clock() - Session.started, 1)
		local count, max = N.backpack()
		local earned = N.cash() + N.Econ.spent - (Session.cashStart or N.cash())
		local redeemed, tried = N.codeCounts()
		N.StatRows.Cash.set(formatNumber(N.cash()))
		N.StatRows.Earned.set("+" .. formatNumber(math.max(earned, 0)))
		N.StatRows.Rate.set(formatNumber(N.Econ.rate * 3600))
		N.StatRows.Level.set(string.format("%d (+%d)", N.level(), N.level() - (Session.levelStart or N.level())))
		N.StatRows.World.set(N.worldKey())
		N.StatRows.Time.set(string.format("%dh %02dm", elapsed // 3600, (elapsed % 3600) // 60))
		N.StatRows.Casts.set(formatNumber(Session.casts) .. " / " .. formatNumber(Session.perfect))
		N.StatRows.Caught.set(formatNumber(Session.caught) .. " / " .. formatNumber(Session.specials))
		N.StatRows.Best.set(tostring(Session.bestName) .. " " .. formatNumber(Session.bestFish or 0))
		N.StatRows.Cycle.set(string.format("%.1f s / %s", N.Fish.cycle, formatNumber(N.Fish.evCast)))
		N.StatRows.Sold.set(formatNumber(Session.sold) .. " / " .. formatNumber(Session.soldValue))
		N.StatRows.Backpack.set(count .. " / " .. max)
		N.StatRows.Buys.set(Session.upgrades .. " / " .. Session.rods .. " / " .. Session.worlds)
		N.StatRows.Bait.set(tostring(Session.baits))
		N.StatRows.Pond.set(tostring(Session.pondTrips))
		N.StatRows.Claims.set(tostring(Session.claims))
		N.StatRows.Codes.set(redeemed .. " / " .. tried)
		N.StatRows.Items.set(Session.opened .. " / " .. Session.potions .. " / " .. Session.relics)
	end
end
local Debug = {}
do
	function Debug.perfText()
		local last = Perf.last
		if not last then
			return "first reading in 30 s"
		end
		return string.format(
			"fps %d, worst frame %dms, hitches %d, freezes %d, Vader used %dms in %ds (%.2f%%), ping %sms, memory %sMB",
			math.floor(last.fps + 0.5),
			math.floor(last.worst * 1000),
			last.hitches,
			last.freezes,
			math.floor(last.hub * 1000),
			math.floor(last.span),
			last.hub / math.max(last.span, 1) * 100,
			tostring(last.ping),
			tostring(last.memory)
		)
	end
	function Debug.running()
		local running = {}
		for _, row in ipairs(N.FarmToggles) do
			if on(row[1]) then
				table.insert(running, row[1])
			end
		end
		return running
	end
	function Debug.header()
		local elapsed = math.floor(os.clock() - Session.started)
		local executor = "?"
		pcall(function()
			executor = table.concat({ identifyexecutor() }, " ")
		end)
		local d = N.data()
		local count, max = N.backpack()
		local lines = {
			"Vader debug log  |  " .. GameName,
			string.format("Player %s (@%s)  |  executor %s  |  place %s  |  %s", LocalPlayer.DisplayName, LocalPlayer.Name, executor, tostring(game.PlaceId), os.date("%Y-%m-%d %H:%M:%S")),
			string.format(
				"Session %dh %02dm  |  casts %d (perfect %d, refused %d)  |  caught %d, finds %d, fights %d  |  sold %d for %s  |  upgrades %d, rods %d, worlds %d, baits %d  |  pond %d  |  claims %d, codes %d",
				elapsed // 3600,
				(elapsed % 3600) // 60,
				Session.casts,
				Session.perfect,
				Session.refused,
				Session.caught,
				Session.specials,
				Session.fights,
				Session.sold,
				formatNumber(Session.soldValue),
				Session.upgrades,
				Session.rods,
				Session.worlds,
				Session.baits,
				Session.pondTrips,
				Session.claims,
				Session.codes
			),
			"Status: " .. tostring(Status) .. "  |  mode " .. N.fishMode() .. " (" .. tostring(N.Fish.engine) .. ")" .. (if N.Fish.fallbackReason ~= "" then ", last fallback: " .. N.Fish.fallbackReason else "") .. "  |  planner " .. (if N.planner() then "on" else "off"),
			"Running: " .. table.concat(Debug.running(), ", "),
			string.format(
				"Game: world %s, cash %s, level %s, rod %s, hooks %d, backpack %d/%d, tutorial %s, rate %s/h, events %s",
				N.worldKey(),
				formatNumber(N.cash()),
				tostring(d.Level),
				tostring(d.RodEquipped),
				N.hookCap(),
				count,
				max,
				tostring(d.Tutorial),
				formatNumber(N.Econ.rate * 3600),
				(function()
					local n = 0
					for _ in pairs(N.Listeners) do
						n += 1
					end
					return tostring(n)
				end)()
			),
			"Perf: " .. Debug.perfText(),
			"Plan: " .. (if N.Plan.say ~= "" then N.Plan.say else "-"),
			"Problems (" .. Log.problemCount .. "): " .. (if #Log.problems > 0 then table.concat(Log.problems, " | ") else "none"),
			string.rep("-", 70),
		}
		return table.concat(lines, "\n")
	end
	Log.header = Debug.header
end
N.AllAutoToggles = {}
for _, row in ipairs(N.FarmToggles) do
	table.insert(N.AllAutoToggles, row[1])
end
N.Manual = { running = false }
do
	function N.runManual(fn, ...)
		if N.Manual.running then
			notify("Vader", "Still busy with the last action", 3)
			return
		end
		N.Manual.running = true
		local ok, err = pcall(fn, ...)
		N.Manual.running = false
		if not ok then
			log("ERROR", "manual action", tostring(err))
		end
	end
	function N.stopAll()
		N.quiet = true
		for _, name in ipairs(N.AllAutoToggles) do
			local toggle = Toggles[name]
			if toggle and toggle.Value then
				toggle:SetValue(false)
			end
		end
		for _, name in ipairs(N.Probe.names) do
			local toggle = Toggles[name]
			if toggle and toggle.Value then
				toggle:SetValue(false)
			end
		end
		N.quiet = false
		N.fishOff()
		log("STOP everything")
		notify("Vader", "Everything is off", 3)
	end
end
do
	local KeepOnTeleport = true
	local function queueSelf()
		local queue = queue_on_teleport or (typeof(syn) == "table" and syn.queue_on_teleport) or queueonteleport
		if type(queue) ~= "function" or INSTANCE.queued or LoaderScript == "" then
			return INSTANCE.queued == true
		end
		INSTANCE.queued = pcall(
			queue,
			table.concat({
				"if not game:IsLoaded() then game.Loaded:Wait() end",
				"if game.GameId ~= " .. tostring(game.GameId) .. " then return end",
				LoaderScript,
			}, "\n")
		)
		return INSTANCE.queued
	end
	if Tabs.Misc then
		pcall(function()
			local ExecBox = Tabs.Misc:AddRightGroupbox("Auto Execute", "zap")
			ExecBox:AddToggle("KeepOnTeleport", {
				Text = "Keep after teleport",
				Default = true,
				Tooltip = "When the game moves you to another server the script is started again there. Needs your own loader line below (the loadstring you use to run this script)",
				Callback = function(value)
					KeepOnTeleport = value
				end,
			})
			ExecBox:AddInput("LoaderLine", {
				Text = "Loader line",
				Placeholder = 'loadstring(game:HttpGet("https://..."))()',
				Finished = true,
				Default = "",
				Callback = function(value)
					LoaderScript = tostring(value or "")
				end,
			})
			LoaderScript = tostring(Options.LoaderLine and Options.LoaderLine.Value or "")
			Library:GiveSignal(LocalPlayer.OnTeleport:Connect(function(state)
				if state == Enum.TeleportState.Started and KeepOnTeleport then
					queueSelf()
				end
			end))
		end)
	end
end
do
	local Hook = { queue = {}, sent = 0, feedbackAt = -1e9, feedbackCount = 0 }
	local function httpRequest(options)
		local fn = (typeof(syn) == "table" and syn.request) or (typeof(http) == "table" and http.request) or http_request or request
		if type(fn) ~= "function" then
			return nil
		end
		local ok, response = pcall(fn, options)
		return if ok then response else nil
	end
	local function validWebhook(url)
		return type(url) == "string"
			and (
					url:find("^https://discord%.com/api/webhooks/")
					or url:find("^https://discordapp%.com/api/webhooks/")
					or url:find("^https://canary%.discord%.com/api/webhooks/")
					or url:find("^https://ptb%.discord%.com/api/webhooks/")
				)
				~= nil
	end
	local function postWebhook(url, payload)
		if not validWebhook(url) then
			return false, 0
		end
		local response = httpRequest({
			Url = url,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload),
		})
		local code = response and tonumber(response.StatusCode) or 0
		return code >= 200 and code < 300, code
	end
	local GameLink = "https://www.roblox.com/games/" .. tostring(game.PlaceId)
	local function gameField()
		return { name = "Game", value = "[" .. GameName .. "](" .. GameLink .. ")", inline = true }
	end
	local function playerField()
		if Toggles.WebhookHideName and Toggles.WebhookHideName.Value then
			return "Hidden"
		end
		return "||" .. LocalPlayer.Name .. "||"
	end
	local function queueEmbed(embed)
		if #Hook.queue < 30 then
			embed.footer = embed.footer or { text = "Vader  \u{00B7}  " .. GameName }
			embed.timestamp = embed.timestamp or DateTime.now():ToIsoDate()
			table.insert(Hook.queue, embed)
		end
	end
	local function hookOn()
		return Toggles.WebhookOn and Toggles.WebhookOn.Value
	end
	local function reportEmbed(title)
		local elapsed = math.max(os.clock() - Session.started, 60)
		local count, max = N.backpack()
		return {
			title = title,
			color = 6344854,
			fields = {
				{ name = "Coins", value = formatNumber(N.cash()), inline = true },
				{ name = "Per hour", value = formatNumber(N.Econ.rate * 3600), inline = true },
				{ name = "Level", value = tostring(N.level()), inline = true },
				{ name = "World", value = N.worldKey(), inline = true },
				{ name = "Casts", value = formatNumber(Session.casts), inline = true },
				{ name = "Backpack", value = count .. " / " .. max, inline = true },
				{ name = "Best fish", value = tostring(Session.bestName) .. " " .. formatNumber(Session.bestFish or 0), inline = true },
				{ name = "Sold", value = formatNumber(Session.soldValue), inline = true },
				{ name = "Session", value = string.format("%dh %02dm", elapsed // 3600, (elapsed % 3600) // 60), inline = true },
				{ name = "Player", value = playerField(), inline = true },
			},
		}
	end
	-- Rare catch: the best fish of a cast, when its rarity is picked.
	N.Events.cast = function(best, hooked)
		if not (hookOn() and on("WebhookRare") and best and hooked[best.index]) then
			return
		end
		local def = N.fishDef(best.name)
		local rarity = def and def.Rarity or "Common"
		if selected(Options.WebhookRarities, rarity) then
			queueEmbed({
				title = "\u{2726}  Caught " .. tostring(best.name),
				description = "**" .. rarity .. "**, worth **" .. formatNumber(best.value) .. "** coins.",
				color = 11027200,
				fields = { { name = "Player", value = playerField(), inline = true } },
			})
		end
	end
	N.Events.sold = function(amount, value)
		if hookOn() and on("WebhookSales") then
			queueEmbed({
				title = "\u{2726}  Sold " .. tostring(amount) .. " fish",
				description = "For **" .. formatNumber(value) .. "** coins.",
				color = 6283215,
				fields = { { name = "Player", value = playerField(), inline = true } },
			})
		end
	end
	N.Events.code = function(code, message)
		if hookOn() and on("WebhookCodes") then
			queueEmbed({
				title = "\u{2726}  Code " .. tostring(code),
				description = tostring(message or ""),
				color = 6283215,
				fields = { { name = "Player", value = playerField(), inline = true } },
			})
		end
	end
	N.Events.bought = function(name, price)
		if hookOn() and on("WebhookBuys") then
			queueEmbed({
				title = "\u{2726}  Bought " .. tostring(name),
				description = "Paid **" .. formatNumber(price) .. "** coins.",
				color = 8454016,
				fields = { { name = "Player", value = playerField(), inline = true } },
			})
		end
	end
	task.spawn(function()
		local lastReport = os.clock()
		while alive() do
			task.wait(2.5)
			pcall(function()
				local url = Options.WebhookUrl and Options.WebhookUrl.Value
				local enabled = hookOn() and validWebhook(url)
				local every = (Options.WebhookReport and Options.WebhookReport.Value or 0) * 60
				if enabled and every > 0 and os.clock() - lastReport >= every then
					lastReport = os.clock()
					queueEmbed(reportEmbed("\u{2726}  Farm report"))
				end
				if not enabled then
					table.clear(Hook.queue)
					return
				end
				if N.cardTick then
					N.cardTick()
				end
				local embed = table.remove(Hook.queue, 1)
				if embed then
					embed.author = { name = GameName }
					if postWebhook(url, { username = "Vader", allowed_mentions = { parse = {} }, embeds = { embed } }) then
						Hook.sent += 1
					end
				end
			end)
		end
	end)
	pcall(function()
		local holder = Tabs.Misc or Tabs.Main
		local PerfBox = holder:AddLeftGroupbox("Performance", "gauge")
		Labels.Perf = PerfBox:AddLabel({ Text = "Measuring...", DoesWrap = true })
	end)
	-- Live stats card: one Discord message (POST ?wait=true gives its id) edited in place every 2 minutes.
	local Card = { id = nil, at = -1e9, url = nil }
	function N.cardTick()
		local url = Options.WebhookUrl and Options.WebhookUrl.Value
		if not (hookOn() and on("WebhookCard") and validWebhook(url)) then
			return false
		end
		if os.clock() - Card.at < 120 then
			return false
		end
		Card.at = os.clock()
		if Card.url ~= url then
			Card.url, Card.id = url, nil
		end
		local embed = reportEmbed("\u{2726}  Live stats")
		embed.author = { name = GameName }
		embed.footer = { text = "Vader  \u{00B7}  " .. GameName .. "  \u{00B7}  updates every 2 min" }
		embed.timestamp = DateTime.now():ToIsoDate()
		local body = HttpService:JSONEncode({ username = "Vader", allowed_mentions = { parse = {} }, embeds = { embed } })
		if Card.id then
			local response = httpRequest({ Url = url .. "/messages/" .. Card.id, Method = "PATCH", Headers = { ["Content-Type"] = "application/json" }, Body = body })
			local code = response and tonumber(response.StatusCode) or 0
			if code >= 200 and code < 300 then
				return true
			end
			Card.id = nil
		end
		local response = httpRequest({ Url = url .. "?wait=true", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
		local ok, data = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		if ok and type(data) == "table" and data.id then
			Card.id = tostring(data.id)
			log("WEBHOOK card", Card.id)
		end
		return true
	end
	if Tabs.Webhook then
		pcall(function()
			local HookBox = Tabs.Webhook:AddLeftGroupbox("Discord Webhook", "webhook")
			HookBox:AddToggle("WebhookOn", { Text = "Post to Discord", Default = false, Tooltip = "Posts to your own Discord webhook: the events on the right, a timed report and a live stats card" })
			HookBox:AddInput("WebhookUrl", { Text = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...", Finished = true, Default = "" })
			HookBox:AddToggle("WebhookCard", { Text = "Live stats card", Default = true, Tooltip = "One message with your coins, income, level and session, edited every 2 minutes instead of new posts" })
			HookBox:AddSlider("WebhookReport", { Text = "Report every", Default = 30, Min = 0, Max = 180, Rounding = 0, Suffix = " min", HideMax = true, Tooltip = "0 turns the timed report off" })
			HookBox:AddToggle("WebhookHideName", { Text = "Hide my username", Default = false })
			HookBox:AddButton({
				Text = "Send test",
				Func = function()
					local url = Options.WebhookUrl and Options.WebhookUrl.Value
					if not validWebhook(url) then
						notify("Webhook", "Paste a Discord webhook URL first", 4)
						return
					end
					task.spawn(function()
						local embed = reportEmbed("\u{2726}  Test from Vader")
						embed.author = { name = GameName }
						embed.footer = { text = "Vader  \u{00B7}  " .. GameName }
						local ok, code = postWebhook(url, { username = "Vader", allowed_mentions = { parse = {} }, embeds = { embed } })
						notify("Webhook", if ok then "Test sent" else "Discord answered " .. tostring(code), 4)
					end)
				end,
			})
			local PostBox = Tabs.Webhook:AddRightGroupbox("Posts", "bell")
			PostBox:AddToggle("WebhookRare", { Text = "Rare catches", Default = true })
			PostBox:AddDropdown("WebhookRarities", { Text = "Rare means", Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Exotic" }, Default = { "Mythic", "Secret", "Exotic" }, Multi = true, AllowNull = true })
			PostBox:AddToggle("WebhookSales", { Text = "Sales", Default = false })
			PostBox:AddToggle("WebhookBuys", { Text = "Purchases", Default = true })
			PostBox:AddToggle("WebhookCodes", { Text = "Codes redeemed", Default = true })
			PostBox:AddLabel({ Text = '<font transparency="0.35">Each post goes out once, at most one every 2.5 s. Pick what is worth a ping.</font>', DoesWrap = true })
		end)
	end
end
do
	local function setToggles(names, args)
		local word = args and args[1] and string.lower(tostring(args[1])) or ""
		local first = Toggles[names[1]]
		local state
		if word == "on" or word == "1" or word == "true" then
			state = true
		elseif word == "off" or word == "0" or word == "false" then
			state = false
		else
			state = not (first and first.Value)
		end
		for _, name in ipairs(names) do
			local toggle = Toggles[name]
			if toggle then
				toggle:SetValue(state)
			end
		end
		return state
	end
	N.setToggles = setToggles
	local function toggleCommand(name, aliases, names, text)
		Library:AddCommand({
			Name = name,
			Aliases = aliases,
			Args = "[on/off]",
			Description = "Turns " .. text .. " on or off",
			Source = GameName,
			Callback = function(args)
				return text .. (if setToggles(names, args) then " on" else " off")
			end,
		})
	end
	if Library.AddCommand then
		pcall(function()
			toggleCommand("planner", { "smart" }, { "SmartPlanner" }, "Smart Planner")
			toggleCommand("fish", {}, { "AutoFish" }, "Auto Fish")
			toggleCommand("sell", {}, { "SmartSell" }, "Smart Sell")
			toggleCommand("pond", {}, { "AutoPond" }, "Auto Pond")
			toggleCommand("rewards", { "claim" }, { "AutoRewards" }, "Auto Rewards")
			Library:AddCommand({
				Name = "stop",
				Aliases = { "alloff" },
				Description = "Turns every automation off",
				Source = GameName,
				Callback = function()
					N.stopAll()
					return "Everything off"
				end,
			})
			Library:AddCommand({
				Name = "status",
				Description = "Shows what Vader is doing",
				Source = GameName,
				Callback = function()
					return string.format("%s  |  coins %s  |  level %d  |  %s  |  %d casts", Status, formatNumber(N.cash()), N.level(), N.worldKey(), Session.casts)
				end,
			})
			Library:AddCommand({
				Name = "perf",
				Aliases = { "fps", "lag" },
				Description = "Shows how smooth the game runs and how much time Vader takes",
				Source = GameName,
				Callback = Debug.perfText,
			})
		end)
	end
	if Library.OnUnload then
		Library:OnUnload(function()
			pcall(N.fishOff)
			INSTANCE.stop = true
			log("UNLOAD")
			flushLog(true)
		end)
	end
	if Window.AddCommandsTab then
		pcall(function()
			Tabs.Commands = Window:AddCommandsTab()
		end)
	end
	if Library.SetQuickBar then
		pcall(function()
			Library:SetQuickBar({
				{ Toggle = "AutoFish", Icon = "fish", Label = "Fish" },
				{ Toggle = "SmartSell", Icon = "coins", Label = "Sell" },
				{ Toggle = "SmartPlanner", Icon = "brain", Label = "Planner" },
				{ Toggle = "AutoPond", Icon = "droplets", Label = "Pond" },
				{ Toggle = "AutoRewards", Icon = "gift", Label = "Rewards" },
			})
		end)
	end
	local SetupFlag = "Vader/FISH_setup_done.txt"
	function N.markSetupDone()
		pcall(function()
			if makefolder and isfolder and not isfolder("Vader") then
				makefolder("Vader")
			end
			writefile(SetupFlag, "1")
		end)
	end
	function N.setupDone()
		local ok, done = pcall(function()
			return isfile(SetupFlag)
		end)
		return not ok or done == true
	end
	function N.openWizard()
		if not Library.ShowWizard then
			return
		end
		return Library:ShowWizard({
			SkipText = "Skip",
			FinishText = "Start",
			Steps = {
				{
					Id = "tasks",
					Title = "What should Vader do for you?",
					Description = "Nothing is picked for you: tap what you want running, tap again to unpick.",
					Multi = true,
					Required = false,
					Default = {},
					Choices = {
						{ Id = "fish", Title = "Fish", Description = "Auto Fish on the best fish of every cast", Icon = "fish", Color = "#5fb8ff" },
						{ Id = "sell", Title = "Sell", Description = "Smart Sell when the backpack fills, keeps Secret and Exotic fish", Icon = "coins", Color = "#fab428" },
						{ Id = "planner", Title = "Smart Planner", Description = "Autopilot: fishes, sells, buys by payback, pond, rewards, the whole game", Icon = "brain", Color = "#3ccf91" },
						{ Id = "pond", Title = "Pond", Description = "Unlock, fill, feed and collect the pond", Icon = "droplets", Color = "#4fd1c5" },
						{ Id = "rewards", Title = "Claim rewards", Description = "Daily, playtime, season, achievements, offline and the Big Mouth", Icon = "gift", Color = "#ff5d8f" },
						{ Id = "codes", Title = "Redeem codes", Description = "Every known code and your secret code", Icon = "ticket", Color = "#b18cff" },
						{ Id = "items", Title = "Items", Description = "Open chests, drink potions, use relics, keep a bait active", Icon = "package-open", Color = "#f0b90b" },
					},
				},
			},
			Finish = function(values)
				local chosen = type(values.tasks) == "table" and values.tasks or {}
				local groups = {
					fish = { "AutoFish" },
					sell = { "SmartSell" },
					planner = { "SmartPlanner" },
					pond = { "AutoPond" },
					rewards = { "AutoRewards", "AutoBigMouth" },
					codes = { "AutoCodes" },
					items = { "AutoOpen", "AutoPotions", "AutoRelics", "AutoBait" },
				}
				-- Only what the player picked is switched on; nothing is switched off and nothing else changes.
				local want = {}
				for _, id in ipairs(chosen) do
					want[id] = true
				end
				for id, yes in pairs(chosen) do
					if yes == true then
						want[id] = true
					end
				end
				for id, names in pairs(groups) do
					if want[id] then
						setToggles(names, { "on" })
					end
				end
				N.markSetupDone()
				notify("Quick setup done", "Change anything in the tabs any time", 5)
			end,
			Skipped = function()
				N.markSetupDone()
				notify("Quick setup", "Skipped. Open it again from Main > Controls.", 4)
			end,
		})
	end
end
pcall(function()
	Library.RenderOverlayInfo = function()
		return string.format("coins %s  \u{00B7}  level %d", formatNumber(N.cash()), N.level())
	end
end)
-- this hub logs AUTOLOAD and CLICK itself (below), so the library's standard lines are off
Library.OnAutoload = false
Library.OnUserToggle = nil
-- Autoload report and click log. The library applies the autoload config a moment after the Settings tab is built, so the
-- report and the CLICK hooks wait for it; changes made by the hub itself (Stop Everything, Reset Hub Options) stay quiet.
task.delay(3, function()
	local function show(value)
		if type(value) == "table" then
			local keys = {}
			for k, v in pairs(value) do
				table.insert(keys, tostring(if type(k) == "number" then v else k))
			end
			table.sort(keys)
			return "{" .. table.concat(keys, ",") .. "}"
		end
		return tostring(value)
	end
	local restored = {}
	for name, toggle in pairs(Toggles) do
		if toggle.Value == true and not toggle.Default and string.sub(name, 1, 2) ~= "QS" then
			table.insert(restored, name)
		end
	end
	table.sort(restored)
	log("AUTOLOAD toggles=" .. (if #restored > 0 then table.concat(restored, ",") else "-"))
	local function hook(name, element)
		local run = element.RunChanged
		if type(run) ~= "function" or element.Type == "KeyPicker" or element.Type == "ColorPicker" then
			return
		end
		element.RunChanged = function(self, ...)
			if not N.quiet then
				log("CLICK", name .. "=" .. show(element.Value))
			end
			return run(self, ...)
		end
	end
	for name, toggle in pairs(Toggles) do
		hook(name, toggle)
	end
	for name, option in pairs(Options) do
		hook(name, option)
	end
end)
do
	local ErrorLogAt = {}
	local function reportError(where, err)
		local text = tostring(err)
		local first = string.match(text, "^[^\n]*") or text
		if os.clock() - (ErrorLogAt[first] or -1e9) > 30 then
			ErrorLogAt[first] = os.clock()
			log("ERROR", where, text)
			logProblem(where .. ": " .. first)
		end
		return first
	end
	local function anyAutoOn()
		for _, name in ipairs(N.AllAutoToggles) do
			if on(name) then
				return true
			end
		end
		return false
	end
	N.anyAutoOn = anyAutoOn
	local function loop(name, body)
		task.spawn(function()
			while alive() do
				local ok, err = xpcall(body, debug.traceback)
				if not ok then
					setStatus("Error: " .. reportError(name, err))
					task.wait(1)
				end
				task.wait()
			end
		end)
	end
	local function spending()
		return N.planner() or on("AutoUpgrades") or on("AutoRods") or on("AutoWorlds") or on("AutoPond")
	end
	-- The main loop owns the character: sales, purchases, trips (worlds, pond, Big Mouth, Stone Mage, Mutation Dealer),
	-- held items and fishing never overlap.
	loop("main loop", function()
		if N.Manual.running then
			task.wait(0.3)
			return
		end
		if not N.ready() then
			setStatus("Waiting for the game data")
			task.wait(1)
			return
		end
		Session.cashStart = Session.cashStart or N.cash()
		Session.levelStart = Session.levelStart or N.level()
		if not N.alive() then
			setStatus("Waiting for the character")
			task.wait(0.5)
			return
		end
		if N.sellStep() then
			return
		end
		if N.probeStep() then
			return
		end
		if spending() and N.due("spend", 4) and N.spendStep() then
			return
		end
		if N.worldStep() then
			return
		end
		if N.pondStep() or N.petStep() then
			return
		end
		if N.bigMouthStep() or N.enchantStep() or N.mutationStep() then
			return
		end
		if N.itemChores() then
			return
		end
		N.baitStep()
		-- Auto Fish or the Smart Planner (the autopilot owns the main loop) fish; the planner never waits for Auto Fish.
		if N.wants("AutoFish") then
			N.resumeFishing()
			N.fishStep()
			return
		end
		if not anyAutoOn() then
			setStatus("Idle")
		else
			setStatus("Waiting (Auto Fish is off: turn it or the Smart Planner on to fish)")
		end
		task.wait(0.5)
	end)
	-- Remote-only chores: they never move the character or change the held item.
	loop("chores", function()
		if N.ready() then
			N.rewardStep()
			N.codeStep()
			N.cargoStep()
			if N.due("econ", 15) then
				N.econTick()
			end
		end
		task.wait(1)
	end)
	-- Every label text is built here; the draw thread below only copies strings.
	N.InfoText = {}
	function N.upNext()
		local out = {}
		local who = if N.planner() then "Smart Planner: " else ""
		if N.planner() then
			table.insert(out, if N.Plan.say ~= "" then "Smart Planner: " .. N.Plan.say else "Smart Planner: fishing, the first purchases come after about a minute of income data")
		end
		if N.wants("AutoFish") and not N.planner() then
			table.insert(out, N.modeText() .. string.format(", %d%% Perfect", math.floor(optionNumber("PerfectRate", 60))))
		end
		if N.wants("SmartSell") then
			table.insert(out, who .. string.format("selling at %d%% backpack, before a cast that would not fit%s", math.floor(optionNumber("SellAt", 80)), if N.planner() then " and to fund the next buy" else ""))
		end
		if N.wants("AutoPond") then
			table.insert(out, who .. (if N.unlocked("Pond") then "pond trip every " .. math.floor(optionNumber("PondEvery", 60)) .. " min" else "pond unlock at level 5 when it pays back"))
		end
		if N.wants("AutoRewards") then
			table.insert(out, who .. "claiming rewards" .. (if N.wants("AutoCodes") then " and codes" else "") .. " when ready")
		end
		if N.tutorialHold() then
			table.insert(out, "Tutorial held at step 6: x2 luck on every cast (no playtime gifts or quests meanwhile)")
		end
		return out
	end
	task.spawn(function()
		while alive() do
			local started = os.clock()
			local ok, err = pcall(function()
				local I = N.InfoText
				local d = N.data()
				local count, max = N.backpack()
				I.info = string.format(
					"Coins <b>%s</b>  \u{00B7}  level <b>%d</b>  \u{00B7}  %s\nIncome <b>%s</b>/h  \u{00B7}  backpack %d/%d  \u{00B7}  hooks %d\nCasts <b>%d</b>  \u{00B7}  sold %s  \u{00B7}  Smart Planner %s",
					formatNumber(N.cash()),
					N.level(),
					N.worldKey(),
					formatNumber(N.Econ.rate * 3600),
					count,
					max,
					N.hookCap(),
					Session.casts,
					formatNumber(Session.soldValue),
					if N.planner() then "on" else "off"
				)
				local upNext = N.upNext()
				I.plan = if #upNext > 0 then "<b>Up next</b>\n" .. '<font transparency="0.2">\u{2022} ' .. table.concat(upNext, "\n\u{2022} ") .. "</font>" else "Up next: nothing running"
				local F = N.Fish
				I.fish = string.format(
					"<b>%s</b> (%s)%s\nLast cast: %s\nCasts %d, Perfect %d, caught %d, finds %d, fights %d\nCast %.1f s, %s coins per cast",
					N.modeText(),
					tostring(F.engine),
					if os.clock() < F.fallbackUntil then "\nBlatant paused " .. N.longTime(F.fallbackUntil - os.clock()) .. ": " .. F.fallbackReason else "",
					if F.last ~= "" then F.last else "-",
					Session.casts,
					Session.perfect,
					Session.caught,
					Session.specials,
					Session.fights,
					F.cycle,
					formatNumber(F.evCast)
				)
				local _, sellable, value = N.fishStats()
				I.sell = string.format("Backpack <b>%d/%d</b>, %d sellable worth %s\nLast: %s\nSold %s fish for %s", count, max, sellable, formatNumber(value), N.Sell.last, formatNumber(Session.sold), formatNumber(Session.soldValue))
				local active = 0
				for name, n in pairs(N.tab("ActiveBaits")) do
					active += tonumber(n) or 0
				end
				I.bait = string.format("Active bait casts <b>%d</b>  \u{00B7}  %d baits in the backpack\nUsed %d this session", active, #N.itemsOf("Bait"), Session.baits)
				local pond = N.tab("Pond")
				I.pond = if not N.unlocked("Pond")
					then "Pond locked (level 5, 25K). Auto Pond unlocks it"
					else string.format("Level %s, pending %s\n%s\nTrips %d", tostring(pond.Level or 1), formatNumber(pond.PendingIncome or 0), N.Pond.last, Session.pondTrips)
				I.probes = if N.Probe.last ~= "-" then "Last probe: " .. N.Probe.last else "Off. Each probe runs once per game version and logs PROBE <name> result="
				I.planner = if N.planner()
					then string.format("<b>On</b>  \u{00B7}  income %s/h\n%s\nLast buy: %s", formatNumber(N.Econ.rate * 3600), if N.Plan.say ~= "" then N.Plan.say else "Fishing; the first purchases come after about a minute of income data", N.Shop.last)
					else "Off. Turn it on and Vader plays the whole game: fishing, selling, buying by payback, pond, rewards. Your other toggles stay as they are"
				local up = N.tab("Upgrades")
				I.upgrades = string.format("Capacity %s  \u{00B7}  Strength %s  \u{00B7}  Weight %s  \u{00B7}  Bounce %s\nHooks per cast %d\nBought %d this session", tostring(up.Capacity or 0), tostring(up.Strength or 0), tostring(up.Weight or 0), tostring(up.Bounce or 0), N.hookCap(), Session.upgrades)
				local luck, strength = N.rodPower(d.RodEquipped or "Wooden Rod")
				I.rods = string.format("Equipped <b>%s</b> (luck %s, strength %s)\nBought %d this session", tostring(d.RodEquipped or "-"), formatNumber(luck), formatNumber(strength), Session.rods)
				I.world = string.format("In <b>%s</b>, best unlocked %s\n%s", N.worldKey(), (N.bestFishingWorld()), N.World.last)
				I.rewards = string.format("Claimed <b>%d</b> this session%s", Session.claims, if #N.Reward.log > 0 then "\n" .. table.concat(N.Reward.log, "\n") else "")
				local redeemed, tried = N.codeCounts()
				I.codes = string.format("Redeemed <b>%d</b>, tried %d\nLast: %s", redeemed, tried, N.Codes.last)
				local bm = N.tab("BigMouth")
				local wait = (tonumber(bm.ReadyAt) or 0) - N.serverTime()
				I.bigMouth = string.format("Luck +%s%%  \u{00B7}  feeds %s\n%s", tostring(bm.Luck or 0), tostring(bm.Feeds or 0), if wait > 0 then "Hungry again in " .. N.longTime(wait) else "Hungry now")
				I.open = string.format("Opened %d  \u{00B7}  potions %d  \u{00B7}  relics %d\nLast: %s", Session.opened, Session.potions, Session.relics, N.Items.last)
				local s1, s2 = N.enchantNames()
				I.items = string.format("Rod enchants: %s / %s\nEnchant rolls %d  \u{00B7}  mutation spins %d", tostring(s1 or "-"), tostring(s2 or "-"), Session.enchants, Session.mutations)
				I.lines = string.format("Rewards %d  \u{00B7}  codes %d  \u{00B7}  pond trips %d\nLast reward: %s", Session.claims, redeemed, Session.pondTrips, if N.Reward.last ~= "" then N.Reward.last else "-")
			end)
			if not ok then
				reportError("info", err)
			end
			pcall(N.rateTick)
			Perf.work.info = (Perf.work.info or 0) + (os.clock() - started)
			task.wait(1)
		end
	end)
	local function shown(tab)
		if tab == nil or Library.Toggled == false then
			return false
		end
		return Library.ActiveTab == nil or Library.ActiveTab == tab
	end
	-- The thread of the UI loop loses its rights ('lacking capability Plugin' every ~30 s on the live log): a group that fails for that
	-- reason is queued and run on the Heartbeat (frame) thread, which always has them (same fix as Blue Lock Farm).
	local UiLater, uiMoved = {}, false
	pcall(function()
		Library:GiveSignal(RunService.Heartbeat:Connect(function()
			if #UiLater == 0 then
				return
			end
			local queue = UiLater
			UiLater = {}
			for _, fn in ipairs(queue) do
				pcall(fn)
			end
		end))
	end)
	task.spawn(function()
		local uiErrorAt = -1e9
		local function group(fn)
			N.fixIdentity()
			local ok, err = xpcall(fn, debug.traceback)
			if ok then
				return
			end
			if string.find(tostring(err), "lacking capability", 1, true) then
				if #UiLater < 20 then
					table.insert(UiLater, fn)
				end
				if not uiMoved then
					uiMoved = true
					log("UI thread lost its rights, UI updates now run on the frame thread")
				end
				return
			end
			if os.clock() - uiErrorAt > 30 then
				uiErrorAt = os.clock()
				log("ERROR", "ui", string.sub(tostring(err), 1, 300))
			end
		end
		local frame = 0
		while alive() do
			frame += 1
			local started = os.clock()
			group(UIQueue.flush)
			if frame % 3 == 0 then
				local I = N.InfoText
				if shown(Tabs.Main) then
					group(function()
						Labels.Status:SetText(Status)
						Labels.Info:SetText(I.info or "-")
						Labels.Lines:SetText(I.lines or "-")
						Labels.Plan:SetText(I.plan or "-")
					end)
				end
				if shown(Tabs.Fishing) then
					group(function()
						Labels.Fish:SetText(I.fish or "-")
						Labels.Sell:SetText(I.sell or "-")
						Labels.Bait:SetText(I.bait or "-")
						Labels.Pond:SetText(I.pond or "-")
						Labels.Planner:SetText(I.planner or "-")
						Labels.Probes:SetText(I.probes or "-")
					end)
				end
				if frame % 6 == 0 and N.syncMirrors then
					group(N.syncMirrors)
				end
				if shown(Tabs.Upgrades) then
					group(function()
						Labels.Upgrades:SetText(I.upgrades or "-")
						Labels.Rods:SetText(I.rods or "-")
						Labels.World:SetText(I.world or "-")
					end)
				end
				if shown(Tabs.Rewards) then
					group(function()
						Labels.Rewards:SetText(I.rewards or "-")
						Labels.BigMouth:SetText(I.bigMouth or "-")
					end)
				end
				if shown(Tabs.Items) then
					group(function()
						Labels.Open:SetText(I.open or "-")
						Labels.Items:SetText(I.items or "-")
					end)
				end
				if shown(Tabs.Stats) or frame % 30 == 0 then
					group(N.drawStats)
				end
				if Labels.Perf and shown(Tabs.Misc) then
					group(function()
						Labels.Perf:SetText(Debug.perfText())
					end)
				end
			end
			Perf.work.ui = (Perf.work.ui or 0) + (os.clock() - started)
			task.wait(0.1)
		end
	end)
	task.spawn(function()
		local windowStart = os.clock()
		while alive() do
			task.wait(5)
			pcall(function()
				if os.clock() - windowStart >= 30 then
					local span = os.clock() - windowStart
					windowStart = os.clock()
					local hub, parts = 0, {}
					for key, seconds in pairs(Perf.work) do
						hub += seconds
						table.insert(parts, key .. " " .. math.floor(seconds * 1000) .. "ms")
					end
					table.sort(parts)
					local ping, memory = "?", "?"
					pcall(function()
						ping = tostring(math.floor(LocalPlayer:GetNetworkPing() * 1000))
					end)
					pcall(function()
						memory = tostring(math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb()))
					end)
					Perf.last = { fps = if Perf.time > 0 then Perf.frames / Perf.time else 0, worst = Perf.worst, hitches = Perf.hitches, freezes = Perf.freezes, hub = hub, span = span, ping = ping, memory = memory }
					log("PERF", Debug.perfText(), "|", table.concat(parts, ", "))
					Perf.frames, Perf.time, Perf.worst, Perf.hitches, Perf.freezes = 0, 0, 0, 0, 0
					table.clear(Perf.work)
					flushLog(false)
				end
				if Log.statusAt and os.clock() - Log.statusAt > 600 and Log.stuckAt ~= Log.statusAt and anyAutoOn() and not string.find(Status, "Fishing", 1, true) and string.sub(Status, 1, 7) ~= "Waiting" then
					Log.stuckAt = Log.statusAt
					logProblem("Stuck for 10 minutes on: " .. tostring(Status))
					-- The autopilot never stays stuck: a rejoin through the game's own channel resets the client state.
					if N.planner() then
						N.rejoin("stuck 10 minutes on: " .. tostring(Status))
					end
				end
			end)
		end
	end)
	pcall(function()
		Tabs.Main:Show()
	end)
	notify("Vader", if Library.IsMobile then "Loaded and ready. The logo button opens and closes the menu." else "Loaded. Press RightControl or the logo button to hide or show the menu.", 5)
	-- The Quick Setup wizard never opens by itself and has no button.
end

end


--==================================================
-- START
--==================================================

do
    local lib = Vader_MakeLibrary()
    local ok, err = xpcall(Vader_RunGame, debug.traceback, lib)
    if not ok then
        local report = "[Vader] Deep Fishing failed to start:\n" .. tostring(err)
        warn(report)
        pcall(setclipboard, report)
        lib.VUI:Notify({ Title = "Vader Script", Content = "Deep Fishing failed to start. See F9 (error copied to clipboard).", Duration = 8 })
    end
    if lib.StoreProblem then
        lib.VUI:Notify({ Title = "Vader Script", Content = lib.StoreProblem, Duration = 8 })
    end

    local Window = lib.VWindow
    if Window and not lib.Unloaded then
        local VaderUI = lib.VUI
        local Settings = Window:AddTab({ Title = "Settings" })

        local Theme = Settings:AddSection("Theme Settings")
        Theme:AddDropdown("VaderTheme", {
            Title = "Theme", Values = VaderUI.Themes, Default = VaderUI.Theme,
            Callback = function(value)
                VaderUI:SetTheme(value)
                lib.Save("VaderTheme", value)
            end,
        })
        local minimizeKey = Theme:AddKeybind("MenuKeybind", {
            Title = "Show / Hide Key", Default = lib.Persist("VaderMenuKey", "RightControl"), Mode = "Toggle",
        })
        minimizeKey:OnChanged(function(value)
            lib.Save("VaderMenuKey", value)
        end)
        VaderUI.MinimizeKeybind = minimizeKey
        Theme:AddButton({ Title = "Unload UI", Callback = function() VaderUI:Destroy() end })

        local Community = Settings:AddSection("Community & Support")
        Community:AddParagraph({
            Title = "Vader Script Official Discord",
            Content = "Vader updates, support and community.\nDiscord: https://discord.gg/sghjJ7WyWJ",
        })
        Community:AddButton({
            Title = "Copy Discord Invite",
            Description = "Copy the Discord invite to your clipboard.",
            Callback = function()
                local copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
                local copied = type(copy) == "function" and pcall(copy, "https://discord.gg/sghjJ7WyWJ")
                VaderUI:Notify({
                    Title = "Vader Script",
                    Content = copied and "Discord invite copied to the clipboard." or "Discord: discord.gg/sghjJ7WyWJ",
                    Duration = 4,
                })
            end,
        })
    end
end

print("[Vader] Deep Fishing loaded")
