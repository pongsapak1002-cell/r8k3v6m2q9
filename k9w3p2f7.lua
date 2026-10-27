repeat task.wait() until game:IsLoaded()
task.wait(1)
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

local MAP_NAME = "Feed A Mosquito"
local Env = (getgenv and getgenv()) or _G
if Env.VaderMapStarter then pcall(function() Env.VaderMapStarter:Destroy() end) end

local VaderUI = CreateVaderUI()
local State = {}
local Connections = {}
local closed = false
local saveProfile = function() return false end
local Window = VaderUI:CreateWindow({
    Title = MAP_NAME,
    SubTitle = "by vaderhug",
    TabWidth = 180,
    Size = UDim2.fromOffset(600, 460),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})
Env.VaderMapStarter = VaderUI

local function notify(message)
    VaderUI:Notify({ Title = MAP_NAME, Content = tostring(message), Duration = 3 })
end

-- Register your own event connections here so closing/reloading disconnects them.
local function track(connection)
    table.insert(Connections, connection)
    return connection
end
local originalDestroy = VaderUI.Destroy
function VaderUI:Destroy()
    if closed then return end
    pcall(saveProfile)
    closed = true
    State.Enabled = false
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Connections)
    if Env.VaderMapStarter == self then Env.VaderMapStarter = nil end
    originalDestroy(self)
end

--------------------------- [[ Game ]] ---------------------------

local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Configs = RS:WaitForChild("Scripts"):WaitForChild("Configs")
local MosquitoConfig = require(Configs.MosquitoConfig)
local AreaConfig = require(Configs.AreaConfig)
local WeaponConfig = require(Configs.WeaponConfig)
local BaseConfig = require(Configs.BaseConfig)
local DamageUpgradeConfig = require(Configs.DamageUpgradeConfig)
local SpeedUpgradeConfig = require(Configs.SpeedUpgradeConfig)
local BloodConfig = require(Configs.BloodTransfusionConfig)
local GameConfig = require(Configs.GameConfig)

-- built from the game's configs so new zones and rarities appear after a game update
local ZONES = {}
for id in pairs(AreaConfig) do table.insert(ZONES, id) end
table.sort(ZONES, function(a, b) return (AreaConfig[a].Step or 0) < (AreaConfig[b].Step or 0) end)

local topPrice = {}
for _, conf in pairs(MosquitoConfig) do
    if conf.Rarity then topPrice[conf.Rarity] = math.max(topPrice[conf.Rarity] or 0, tonumber(conf.Price) or 0) end
end
local RARITIES = {}
for rarity in pairs(topPrice) do table.insert(RARITIES, rarity) end
-- zone rarities in zone order, then event-only rarities by their best mosquito's price
local function zoneStep(rarity)
    local area = AreaConfig[rarity .. "Area"]
    return area and area.Step
end
table.sort(RARITIES, function(a, b)
    local sa, sb = zoneStep(a), zoneStep(b)
    if sa and sb then return sa < sb end
    if sa or sb then return sa ~= nil end
    if topPrice[a] ~= topPrice[b] then return topPrice[a] < topPrice[b] end
    return a < b
end)
local MY_ACTOR = "Player_" .. LocalPlayer.UserId

local allRarities = {}
for _, rarity in ipairs(RARITIES) do allRarities[rarity] = true end
State.Zone = ZONES[1]
State.EggRarities = allRarities
State.SellRarities = {}
State.CollectDelay = 10

-- Never call SpawnEnemy, SkipHatch, SkipFeed, BuyGoods or UpgradeBaseWithRobux: they are Robux purchases.
local function remote(actorId, folder, name)
    local runtime = RS:FindFirstChild("Runtime")
    local actors = runtime and runtime:FindFirstChild("Actors")
    local actor = actors and actors:FindFirstChild(actorId)
    local holder = actor and actor:FindFirstChild(folder)
    return holder and holder:FindFirstChild(name)
end
local function fireAs(actorId, name, ...)
    local event = remote(actorId, "Events", name)
    if event then event:FireServer(...) end
    return event ~= nil
end
local function fire(name, ...)
    return fireAs(MY_ACTOR, name, ...)
end
local function invoke(name, ...)
    local fn = remote(MY_ACTOR, "Functions", name)
    if fn then return fn:InvokeServer(...) end
end

-- the client keeps a synced copy of player data behind this local BindableFunction
local function getValue(key)
    local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local runtime = scripts and scripts:FindFirstChild("Runtime")
    local actors = runtime and runtime:FindFirstChild("Actors")
    local actor = actors and actors:FindFirstChild(MY_ACTOR)
    local functions = actor and actor:FindFirstChild("Functions")
    local fn = functions and functions:FindFirstChild("GetValue")
    if not fn then return nil end
    local ok, value = pcall(fn.Invoke, fn, key)
    return ok and value or nil
end
local function gold()
    local coins = getValue("Coins")
    return type(coins) == "table" and tonumber(coins.Main) or 0
end
local function rarityOf(itemId)
    local conf = MosquitoConfig[itemId]
    return conf and conf.Rarity
end
local function short(n)
    n = tonumber(n) or 0
    for _, unit in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
        if n >= unit[1] then return ("%.2f%s"):format(n / unit[1], unit[2]) end
    end
    return tostring(math.floor(n))
end

local function character()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then return char, hum, root end
end
local function standUp(hum)
    if hum.SeatPart then hum.Sit = false end
end
local function findTools(match)
    local found, holders = {}, {}
    if LocalPlayer.Character then table.insert(holders, LocalPlayer.Character) end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then table.insert(holders, backpack) end
    for _, holder in ipairs(holders) do
        for _, tool in ipairs(holder:GetChildren()) do
            if tool:IsA("Tool") and match(tool) then table.insert(found, tool) end
        end
    end
    return found
end
local function isWeapon(tool)
    return WeaponConfig[tool.Name] ~= nil
end
local function isEggTool(tool)
    local actor = tool:FindFirstChild("ClientToolActor")
    -- Value is the actor ModuleScript (an ObjectValue); tostring gives its name
    return actor ~= nil and tostring(actor.Value) == "EggToolActor" and tool:FindFirstChild("ItemUid") ~= nil
end

local function myBase()
    local safeZone = workspace:FindFirstChild("SafeZone")
    local bases = safeZone and safeZone:FindFirstChild("Bases")
    if not bases then return end
    for _, base in ipairs(bases:GetChildren()) do
        local owner = base:FindFirstChild("Player")
        if owner and owner:IsA("ObjectValue") and owner.Value == LocalPlayer then return base end
    end
end
local function placePosition(base)
    local part = base:FindFirstChild("BasePart")
    if not part then return end
    local size = part.Size
    local offset = CFrame.new((math.random() - 0.5) * size.X * 0.6, size.Y / 2, (math.random() - 0.5) * size.Z * 0.6)
    return (part.CFrame * offset).Position
end
local function bloodSeat(base)
    local fallback
    for _, item in ipairs(base:GetDescendants()) do
        if item:IsA("Seat") then
            if item.Parent and CollectionService:HasTag(item.Parent, "BloodTransfusion") then return item end
            fallback = fallback or item
        end
    end
    return fallback
end

local function zoneArea(zone)
    local areas = workspace:FindFirstChild("SpawnAreas")
    return areas and zone and areas:FindFirstChild(zone)
end
local function zoneEnemy(zone)
    local area = zoneArea(zone)
    if not area then return end
    for _, model in ipairs(area:GetChildren()) do
        if model:IsA("Model") and not model.Name:match("Egg$") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then return root end
        end
    end
end
local function zoneEgg(zone)
    local area = zoneArea(zone)
    if not area then return end
    for _, model in ipairs(area:GetChildren()) do
        if model:IsA("Model") and model.Name:match("Egg$") then
            local rarity = rarityOf((model.Name:gsub("Egg$", "")))
            local root = model:FindFirstChild("HumanoidRootPart")
            local prompt = root and root:FindFirstChild("CarryPrompt", true)
            if rarity and State.EggRarities[rarity] and prompt and prompt.Enabled then return root, prompt end
        end
    end
end

local lastSwing = 0
local function attack(target, hum, root)
    root.CFrame = CFrame.lookAt((target.CFrame * CFrame.new(0, 0, 4)).Position, target.Position)
    local tool = findTools(isWeapon)[1]
    if not tool then return end
    if tool.Parent ~= LocalPlayer.Character then hum:EquipTool(tool) end
    if os.clock() - lastSwing >= (WeaponConfig[tool.Name].CD or 0.7) + 0.05 then
        lastSwing = os.clock()
        tool:Activate()
    end
end

local function pickEgg(eggRoot, prompt, root)
    -- the prompt sits at the egg's base, far from its centre on big eggs, and the egg body blocks line of sight
    local anchor = prompt.Parent
    local spot = anchor and anchor:IsA("Attachment") and anchor.WorldPosition or eggRoot.Position
    root.CFrame = CFrame.new(spot + Vector3.new(0, 3, 0))
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 30)
    task.wait(0.25)
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.1)
        prompt:InputHoldEnd()
    end
    task.wait(0.3)
end

-- eggs arrive as carried tools or as unplaced entries in the Eggs data
local function placeEggs(hum, root)
    local tools = findTools(isEggTool)
    local loose = {}
    local eggs = getValue("Eggs")
    if type(eggs) == "table" then
        for uid, info in pairs(eggs) do
            if type(info) == "table" and not info.InBase then table.insert(loose, uid) end
        end
    end
    if #tools == 0 and #loose == 0 then return false end

    local base = myBase()
    local landing = base and placePosition(base)
    if not landing then return false end
    root.CFrame = CFrame.new(landing + Vector3.new(0, 4, 0))
    task.wait(0.3)
    local done = {}
    for _, tool in ipairs(tools) do
        local uid = tool.ItemUid.Value
        hum:EquipTool(tool)
        task.wait(0.1)
        fire("PlaceEgg", uid, placePosition(base))
        done[uid] = true
        task.wait(0.3)
    end
    for _, uid in ipairs(loose) do
        if not done[uid] then
            fire("PlaceEgg", uid, placePosition(base))
            task.wait(0.3)
        end
    end
    return true
end

local function hatchReady()
    local infos = getValue("HatchInfos")
    if type(infos) ~= "table" then return end
    local hatched = false
    for uid, info in pairs(infos) do
        if uid ~= "NowTime" and type(info) == "table" and (info.LeftTime or 1) <= 0 then
            hatched = fireAs("Egg_" .. uid, "Hatch") or hatched
        end
    end
    if hatched then
        task.wait(0.5)
        fire("PlaceBest")
    end
end

local lastInput = os.clock()
track(UserInputService.InputBegan:Connect(function()
    lastInput = os.clock()
end))
local function playerIdle(hum)
    return os.clock() - lastInput >= 3 and hum.MoveDirection.Magnitude == 0
end
local function sitForBlood(hum, root)
    local base = myBase()
    local seat = base and bloodSeat(base)
    if not seat or seat.Disabled or seat.Occupant ~= nil then return end
    root.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.15)
    seat:Sit(hum)
end

local lastPlace, lastHatch, lastCollect, lastBest = 0, 0, 0, 0
local function farmStep()
    local _, hum, root = character()
    if not hum then return end
    local now = os.clock()

    if State.AutoHatch and now - lastHatch >= 2 then
        lastHatch = now
        hatchReady()
    end
    if State.AutoCollect and now - lastCollect >= State.CollectDelay then
        lastCollect = now
        fire("CollectIncome")
    end
    if State.AutoPlaceBest and now - lastBest >= 5 then
        lastBest = now
        fire("PlaceBest")
    end
    -- each branch below moves the character, so only one runs per tick
    if State.AutoPlace and now - lastPlace >= 5 then
        standUp(hum)
        if placeEggs(hum, root) then
            lastPlace = now
            return
        end
    end
    if State.AutoKill then
        local target = zoneEnemy(State.Zone)
        if target then
            standUp(hum)
            attack(target, hum, root)
            return
        end
    end
    if State.AutoPickup then
        local eggRoot, prompt = zoneEgg(State.Zone)
        if eggRoot then
            standUp(hum)
            pickEgg(eggRoot, prompt, root)
            return
        end
    end
    if State.AutoBlood and playerIdle(hum) then
        sitForBlood(hum, root)
    end
end

local function upgradeStep()
    local money = gold()
    local function try(enabled, config, key, event)
        if not enabled then return end
        local level = tonumber(getValue(key)) or 1
        local row = config[level]
        -- the last row has no next level to buy
        if not row or not row.UpgradePrice or not config[level + 1] then return end
        if money >= row.UpgradePrice then
            fire(event)
            money -= row.UpgradePrice
            task.wait(0.3)
        end
    end
    try(State.UpDamage, DamageUpgradeConfig, "DamageLevel", "UpgradeDamage")
    try(State.UpSpeed, SpeedUpgradeConfig, "SpeedLevel", "UpgradeSpeed")
    try(State.UpBlood, BloodConfig, "BloodTransfusionLevel", "UpgradeBloodTransfusion")
    try(State.UpBase, BaseConfig, "BaseLevel", "UpgradeBase")
end

-- only sells items that are NOT on the base
local function sellStep()
    if next(State.SellRarities) == nil then return 0 end
    local sold = 0
    for _, kind in ipairs({ { "Eggs", "SellEgg" }, { "Mosquitoes", "SellMosquito" } }) do
        local items = getValue(kind[1])
        if type(items) == "table" then
            for uid, info in pairs(items) do
                if type(info) == "table" and not info.InBase and State.SellRarities[rarityOf(info.ItemId)] then
                    invoke(kind[2], uid)
                    sold += 1
                    task.wait(0.2)
                end
            end
        end
    end
    return sold
end

local function bestOwnedWeapon(owned)
    local best
    for id in pairs(owned) do
        local conf = WeaponConfig[id]
        if conf and (not best or conf.Damage > best.Damage) then best = conf end
    end
    return best
end
local function weaponStep(buy)
    local owned = getValue("Weapons")
    if type(owned) ~= "table" then return end
    if buy then
        local money, current = gold(), bestOwnedWeapon(owned)
        local pick
        for id, conf in pairs(WeaponConfig) do
            if conf.CoinId == "Main" and not owned[id] and (conf.CoinCount or math.huge) <= money
                and conf.Damage > (current and current.Damage or 0)
                and (not pick or conf.Damage > pick.Damage) then
                pick = conf
            end
        end
        if pick then
            invoke("BuyWeapon", pick.Id)
            notify("Bought weapon: " .. pick.Name)
            task.wait(0.5)
            owned = getValue("Weapons") or owned
        end
    end
    local best = bestOwnedWeapon(owned)
    if best and type(owned[best.Id]) == "table" and not owned[best.Id].InBackpack then
        invoke("UseWeapon", best.Id)
    end
end

local function infoText()
    local inBase, total = 0, 0
    local mosquitoes = getValue("Mosquitoes")
    if type(mosquitoes) == "table" then
        for _, info in pairs(mosquitoes) do
            total += 1
            if type(info) == "table" and info.InBase then inBase += 1 end
        end
    end
    local hatching = 0
    local infos = getValue("HatchInfos")
    if type(infos) == "table" then
        for uid in pairs(infos) do
            if uid ~= "NowTime" then hatching += 1 end
        end
    end
    local weapon = "-"
    local owned = getValue("Weapons")
    if type(owned) == "table" then
        for id, info in pairs(owned) do
            if type(info) == "table" and info.InBackpack then weapon = WeaponConfig[id] and WeaponConfig[id].Name or id end
        end
    end
    local baseLevel = tonumber(getValue("BaseLevel")) or 1
    local capacity = BaseConfig[baseLevel] and BaseConfig[baseLevel].Capacity or "?"
    return table.concat({
        "Gold: " .. short(gold()),
        "Income: " .. short(getValue("TotalIncome")) .. "/s",
        ("Mosquitoes: %d / %s on base (%d owned)"):format(inBase, tostring(capacity), total),
        "Eggs hatching: " .. hatching,
        "Weapon: " .. weapon,
        ("Base Lv %d | Blood Lv %s | Damage Lv %s | Speed Lv %s"):format(
            baseLevel,
            tostring(getValue("BloodTransfusionLevel") or 1),
            tostring(getValue("DamageLevel") or 1),
            tostring(getValue("SpeedLevel") or 1)
        ),
    }, "\n")
end

--------------------------- [[ Tabs ]] ---------------------------

local Tabs = {
    Farm = Window:AddTab({ Title = "Auto Farm" }),
    Upgrade = Window:AddTab({ Title = "Auto Upgrade" }),
    Shop = Window:AddTab({ Title = "Sell & Buy" }),
    Event = Window:AddTab({ Title = "Event" }),
    Info = Window:AddTab({ Title = "Info" }),
    Settings = Window:AddTab({ Title = "Settings" }),
}

local Kill = Tabs.Farm:AddSection("Kill Mosquito")
Kill:AddDropdown("Zone", {
    Title = "Zone", Values = ZONES, Default = State.Zone,
    Callback = function(value) State.Zone = value end,
})
Kill:AddToggle("AutoKill", {
    Title = "Auto Kill", Default = false,
    Callback = function(value) State.AutoKill = value end,
})

local EggSection = Tabs.Farm:AddSection("Eggs")
EggSection:AddDropdown("EggRarities", {
    Title = "Pick Up Rarities", Values = RARITIES, Default = RARITIES, Multi = true,
    Callback = function(value) State.EggRarities = value end,
})
EggSection:AddToggle("AutoPickup", {
    Title = "Auto Pick Up Eggs", Default = false,
    Description = "Selected rarities only.",
    Callback = function(value) State.AutoPickup = value end,
})
EggSection:AddToggle("AutoPlace", {
    Title = "Auto Place Eggs", Default = false,
    Callback = function(value) State.AutoPlace = value end,
})
EggSection:AddToggle("AutoHatch", {
    Title = "Auto Hatch", Default = false,
    Description = "Then runs Place Best.",
    Callback = function(value) State.AutoHatch = value end,
})

local Blood = Tabs.Farm:AddSection("Blood")
Blood:AddToggle("AutoBlood", {
    Title = "Sit For Blood When Idle", Default = false,
    Description = "When idle for 3s.",
    Callback = function(value) State.AutoBlood = value end,
})

local Income = Tabs.Farm:AddSection("Income")
Income:AddToggle("AutoCollect", {
    Title = "Auto Collect Income", Default = false,
    Callback = function(value) State.AutoCollect = value end,
})
Income:AddSlider("CollectDelay", {
    Title = "Collect Every (seconds)", Default = 10, Min = 5, Max = 60, Rounding = 0,
    Callback = function(value) State.CollectDelay = value end,
})
Income:AddToggle("AutoPlaceBest", {
    Title = "Auto Place Best Mosquitoes", Default = false,
    Description = "Every 5s.",
    Callback = function(value) State.AutoPlaceBest = value end,
})

local Upgrades = Tabs.Upgrade:AddSection("Auto Upgrade")
Upgrades:AddToggle("UpDamage", {
    Title = "Damage", Default = false,
    Callback = function(value) State.UpDamage = value end,
})
Upgrades:AddToggle("UpSpeed", {
    Title = "Speed", Default = false,
    Callback = function(value) State.UpSpeed = value end,
})
Upgrades:AddToggle("UpBlood", {
    Title = "Blood Transfusion", Default = false,
    Callback = function(value) State.UpBlood = value end,
})
Upgrades:AddToggle("UpBase", {
    Title = "Base", Default = false,
    Callback = function(value) State.UpBase = value end,
})

local Sell = Tabs.Shop:AddSection("Sell")
Sell:AddDropdown("SellRarities", {
    Title = "Sell Rarities", Values = RARITIES, Default = {}, Multi = true,
    Callback = function(value) State.SellRarities = value end,
})
Sell:AddToggle("AutoSell", {
    Title = "Auto Sell", Default = false,
    Description = "Never sells what is on your base.",
    Callback = function(value) State.AutoSell = value end,
})
Sell:AddButton({
    Title = "Sell Now",
    Callback = function()
        task.spawn(function() notify("Sold " .. sellStep() .. " item(s).") end)
    end,
})

local Weapons = Tabs.Shop:AddSection("Weapon")
Weapons:AddToggle("AutoBuyWeapon", {
    Title = "Auto Buy Best Weapon", Default = false,
    Description = "Gold only, then equips it.",
    Callback = function(value) State.AutoBuyWeapon = value end,
})
Weapons:AddButton({
    Title = "Equip Best Owned Weapon",
    Callback = function() task.spawn(weaponStep, false) end,
})

-- free spins come from play time; buying more spins is a Robux product, never called here
local function freeSpins()
    local data = getValue("EventData")
    local event = type(data) == "table" and GameConfig.Event and data[GameConfig.Event]
    return type(event) == "table" and tonumber(event.SpinCount) or 0
end
local EventSection = Tabs.Event:AddSection("Halloween")
EventSection:AddToggle("AutoSpin", {
    Title = "Auto Spin", Default = false,
    Callback = function(value) State.AutoSpin = value end,
})

local InfoBox = Tabs.Info:AddSection("Player"):AddParagraph({ Title = "Stats", Content = "Loading..." })

local function loop(interval, step)
    task.spawn(function()
        while not closed do
            local ok, problem = pcall(step)
            if not ok then warn("[" .. MAP_NAME .. "] " .. tostring(problem)) end
            task.wait(interval)
        end
    end)
end
loop(0.15, farmStep)
loop(1, upgradeStep)
loop(5, function()
    if State.AutoSpin and freeSpins() > 0 then invoke("Spin") end
end)
loop(3, function()
    if State.AutoSell then sellStep() end
    if State.AutoBuyWeapon then weaponStep(true) end
end)
loop(2, function() InfoBox:SetDesc(infoText()) end)

local Settings = Tabs.Settings:AddSection("Theme Settings")
Settings:AddDropdown("Theme", {
    Title = "Theme", Values = VaderUI.Themes, Default = "Dark",
    Callback = function(value) VaderUI:SetTheme(value) end,
})
local minimizeKey = Settings:AddKeybind("MinimizeKey", {
    Title = "Show / Hide Key", Default = "RightControl", Mode = "Toggle",
})
VaderUI.MinimizeKeybind = minimizeKey
Settings:AddButton({ Title = "Unload UI", Callback = function() VaderUI:Destroy() end })

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local antiAFK = true
local autoSave = true
local profileReady = false
local restoring = false
local lastSaved
local lastError
-- Separate configs by map name and player username, matching Anime Dice.
local CONFIG_NAME = MAP_NAME:gsub("[^%w_%-]", "")
if CONFIG_NAME == "" then CONFIG_NAME = "YourMap" end
local profileFolder = "Vaderhug/" .. CONFIG_NAME
local profilePath = profileFolder .. "/" .. Players.LocalPlayer.Name .. ".json"
local canPersist = type(isfile) == "function" and type(readfile) == "function"
    and type(writefile) == "function" and type(makefolder) == "function"
    and type(isfolder) == "function"

local function snapshot()
    local data = { Version = 1, Options = {} }
    for id, option in pairs(VaderUI.Options) do
        if option.SetValue and option.Type ~= "Button" and option.Type ~= "Paragraph" then
            data.Options[id] = { Type = option.Type, Value = option.Value, Mode = option.Mode }
        end
    end
    -- JSON round-trip detaches tables from live dropdown values.
    return HttpService:JSONDecode(HttpService:JSONEncode(data))
end
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
saveProfile = function(force)
    if closed or restoring or not profileReady then return false, "Config storage is unavailable or paused." end
    if not force and not autoSave then return true end
    local ok, result = pcall(function()
        local data = snapshot()
        if not force and lastSaved and equal(data, lastSaved) then return end
        writefile(profilePath, HttpService:JSONEncode(data))
        lastSaved = data
    end)
    if not ok then
        if tostring(result) ~= lastError then notify("Config save failed: " .. tostring(result)) end
        lastError = tostring(result)
        return false, tostring(result)
    end
    lastError = nil
    return true
end
local function loadProfile()
    if not canPersist then return false, "Required file APIs are unavailable." end
    restoring = true
    local ok, problem = pcall(function()
        if not isfolder("Vaderhug") then makefolder("Vaderhug") end
        if not isfolder(profileFolder) then makefolder(profileFolder) end
        if not isfile(profilePath) then return end
        local data = HttpService:JSONDecode(readfile(profilePath))
        assert(type(data) == "table" and data.Version == 1 and type(data.Options) == "table", "Invalid config format")
        local pending = {}
        -- Validate every known value before applying any callbacks.
        for id, saved in pairs(data.Options) do
            local option = VaderUI.Options[id]
            if option then
                assert(type(saved) == "table" and saved.Type == option.Type, "Invalid control: " .. id)
                local value = saved.Value
                if option.Type == "Toggle" then
                    assert(type(value) == "boolean", "Invalid toggle: " .. id)
                elseif option.Type == "Slider" then
                    assert(type(value) == "number" and value == value and math.abs(value) ~= math.huge, "Invalid slider: " .. id)
                    value = math.clamp(value, option.Min, option.Max)
                elseif option.Type == "Input" then
                    assert(type(value) == "string", "Invalid input: " .. id)
                elseif option.Type == "Keybind" then
                    assert(type(value) == "string" and (value == "None" or Enum.KeyCode[value] ~= nil), "Invalid keybind: " .. id)
                    assert(saved.Mode == nil or saved.Mode == "Toggle" or saved.Mode == "Hold" or saved.Mode == "Always", "Invalid keybind mode")
                elseif option.Type == "Dropdown" then
                    if option.Multi then
                        assert(type(value) == "table", "Invalid dropdown: " .. id)
                    elseif value ~= nil and not table.find(option.Values, value) then
                        value = option.Value
                    end
                else
                    error("Unsupported config control: " .. id)
                end
                table.insert(pending, { Option = option, Value = value, Mode = saved.Mode })
            end
        end
        -- Restore enabling toggles last so callbacks see restored parameters.
        for _, item in ipairs(pending) do
            if item.Option.Type ~= "Toggle" then item.Option:SetValue(item.Value, item.Mode) end
        end
        for _, item in ipairs(pending) do
            if item.Option.Type == "Toggle" then item.Option:SetValue(item.Value) end
        end
    end)
    restoring = false
    profileReady = ok
    if ok then lastSaved = nil end
    return ok, problem
end

local AFK = Tabs.Settings:AddSection("Anti-AFK")
AFK:AddToggle("AntiAFK", {
    Title = "Anti-AFK", Default = true,
    Description = "Prevents idle kick.",
    Callback = function(value) antiAFK = value end,
})
track(Players.LocalPlayer.Idled:Connect(function()
    if closed or not antiAFK then return end
    pcall(function()
        local virtualUser = game:GetService("VirtualUser")
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end)
end))


local secCommunity = Tabs.Settings:AddSection("Community & Support")
secCommunity:AddParagraph({
    Title = "Vader Script Official Discord",
    Content = "Vader updates, support and community.\nDiscord: https://discord.gg/sghjJ7WyWJ",
})
secCommunity:AddButton({
    Title = "Copy Discord Invite",
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


if canPersist then
    local ok, problem = loadProfile()
    if ok then saveProfile() else notify("Config load failed; auto-save paused to preserve the file: " .. tostring(problem)) end
else
    notify("Auto-save unavailable: this environment does not provide file APIs.")
end
track(Players.PlayerRemoving:Connect(function(player)
    if player == Players.LocalPlayer then saveProfile() end
end))
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        task.wait(2)
        if not closed and Env.VaderMapStarter == VaderUI then saveProfile() end
    end
end)
Window:SelectTab(1)

return { UI = VaderUI, Window = Window, Tabs = Tabs, State = State, Track = track }
