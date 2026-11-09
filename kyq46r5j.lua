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

-- King Legacy (Vader UI) - Auto Quest logic ported from x2Swiftz's script.
local MAP_NAME = "King Legacy"
local Env = (getgenv and getgenv()) or _G
if Env.VaderMapStarter then pcall(function() Env.VaderMapStarter:Destroy() end) end

local VaderUI = CreateVaderUI()
local State = { Enabled = false }
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

-- ===== King Legacy quest logic =====
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- โครงสร้างเกม ถ้าเกมอัพเดทแล้วพัง เช็คตรงนี้ก่อน
local Game = {}
local gameOk, gameError = pcall(function()
    local chest = ReplicatedStorage:WaitForChild("Chest", 10)
    Game.QuestManager = require(chest.Modules.QuestManager)
    Game.QuestRemote = chest.Remotes.Functions.Quest
    Game.EtcRemote = chest.Remotes.Functions.EtcFunction
    Game.SkillRemote = chest.Remotes.Functions.SkillAction
end)

local function getPlayerLevel()
    local stats = LocalPlayer:FindFirstChild("PlayerStats")
    local lvl = stats and stats:FindFirstChild("lvl")
    return lvl and lvl.Value or 0
end

local function getCurrentQuest()
    local current = LocalPlayer:FindFirstChild("CurrentQuest")
    return current and current.Value or ""
end

-- เลือกเควสเลเวลสูงสุดที่ไม่เกินเลเวลผู้เล่น (ไม่เอาเควสรายวัน/ครั้งเดียว/Find/บอส "Kill 1 ...")
-- seen = ชื่อมอนที่มีในเซิร์ฟนี้ (กันรับเควสของโลกอื่น) ถ้าเป็น nil ไม่กรอง
local function findOptimalQuest(quests, playerLevel, seen)
    local bestName, bestLevel
    for name, data in pairs(quests) do
        if type(data) == "table" and type(data.Level) == "number" and data.Level <= playerLevel
            and not data.DailyQuest and not data.OneTimeQuest and not tostring(name):find("Find ")
            and not tostring(name):find("^Kill 1 ") and (not seen or seen[data.Mob]) then
            if not bestLevel or data.Level > bestLevel then
                bestName, bestLevel = name, data.Level
            end
        end
    end
    return bestName, bestLevel
end
do -- self-check
    local name = findOptimalQuest({
        A = { Level = 1 }, B = { Level = 50 }, C = { Level = 90 },
        D = { Level = 60, DailyQuest = true }, ["Find X"] = { Level = 55 }, E = "skip",
        ["Kill 1 Boss"] = { Level = 58 },
    }, 60)
    assert(name == "B", "findOptimalQuest self-check failed")
    -- C อยู่โลกอื่น (มอนไม่มีในเซิร์ฟ) ต้องได้ B แทน
    name = findOptimalQuest({ B = { Level = 50, Mob = "b" }, C = { Level = 90, Mob = "c" } }, 100, { b = true })
    assert(name == "B", "findOptimalQuest world filter self-check failed")
end

local function acceptQuest(name)
    return pcall(function() return Game.QuestRemote:InvokeServer("take", name) end)
end

local function cancelQuest()
    return pcall(function() return Game.EtcRemote:InvokeServer("CancelQuest", {}) end)
end

-- เควสบอสทั้งหมดชื่อ "Kill 1 <บอส>" -> dropdown โชว์แค่ชื่อบอส เรียงตามเลเวล
local BOSS_NAMES = {}
local function bossQuestName(boss) return "Kill 1 " .. tostring(boss) end
if gameOk then
    for name, data in pairs(Game.QuestManager) do
        local boss = type(data) == "table" and type(data.Level) == "number" and tostring(name):match("^Kill 1 (.+)$")
        if boss then table.insert(BOSS_NAMES, boss) end
    end
    table.sort(BOSS_NAMES, function(a, b)
        return Game.QuestManager[bossQuestName(a)].Level < Game.QuestManager[bossQuestName(b)].Level
    end)
end
local bossBlockedUntil = {} -- เซิร์ฟไม่ให้รับ (เช่นติดคูลดาวน์) ก็พักบอสตัวนั้นไว้ก่อน

local function isMobAlive(mobName)
    local monsters = workspace:FindFirstChild("Monster")
    if not monsters then return false end
    for _, folder in ipairs(monsters:GetChildren()) do
        local mob = folder:FindFirstChild(mobName)
        local hum = mob and mob:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return true end
    end
    return false
end

-- บอสที่เลือกเกิดอยู่ + เลเวลถึง + ไม่ได้โดนพัก -> ทำเควสบอส ไม่งั้นทำเควสเลเวลตามปกติ
-- "Auto" = บอสเลเวลสูงสุดที่ไม่เกินเลเวลเรา ถ้าไม่เกิดลองแค่ตัวที่ต่ำกว่า 1 ขั้น
local function pickBoss(level)
    if not State.AutoBoss or not State.Boss then return nil end
    local candidates = State.Boss == "Auto" and BOSS_NAMES or { State.Boss }
    local tried = 0
    for i = #candidates, 1, -1 do -- BOSS_NAMES เรียงเลเวลน้อยไปมาก ไล่จากท้ายได้ตัวสูงสุดก่อน
        local quest = bossQuestName(candidates[i])
        local data = Game.QuestManager[quest]
        if type(data) == "table" and data.Level <= level then
            tried += 1
            if os.clock() >= (bossBlockedUntil[quest] or 0) and isMobAlive(data.Mob) then
                return quest, data.Level
            end
            if tried >= 2 then return nil end
        end
    end
end

-- เควส Find: ของเกิดใน workspace.SpawnItem ต้องคลิกเก็บ (ทดสอบแล้ว: คลิกตอนไม่มีเควส ของหายแต่ไม่ได้อะไร
-- ทำเควสจบได้จริง: Find 3 Fry Chicken ได้ +5,000 beli)
local FIND_ITEMS = {
    ["Find 3 Fry Chicken"] = "^Fry Chicken$",
    ["Find 3 Diamonds"] = "^Diamond$",
    ["Find 2 Ancient Item"] = "^Ancient",
    ["Find 1 Golden Key"] = "^Golden Key$",
}
-- [ชื่อเควส] = true เมื่อเปิดสวิตช์ Auto Collect ของชิ้นนั้น; ผู้เล่นรับเควสเอง สคริปต์แค่เก็บของ
State.Find = {}
local function findSpawnItems(pattern)
    local list = {}
    local folder = workspace:FindFirstChild("SpawnItem")
    if not folder then return list end
    for _, cd in ipairs(folder:GetDescendants()) do
        if cd:IsA("ClickDetector") and cd.Parent and cd.Parent.Name:find(pattern) then table.insert(list, cd) end
    end
    return list
end

-- เควสรายวันแบบฆ่ามอน (Mob = "ชื่อ [Lv. N]"): เลเวลถึง, มอนไม่เกินเลเวลเรา, มอนเกิดอยู่
-- ทดสอบแล้ว: Quest:InvokeServer("take", "Kill 4 King Snow") รับเควสรายวันได้ตรงๆ
-- ทำครบวันละครั้ง: ถ้าเซิร์ฟไม่ให้รับ (ทำไปแล้ววันนี้) จะพักเควสนั้น 10 นาที (bossBlockedUntil)
local function isDailyKill(quest)
    local data = Game.QuestManager[quest]
    return type(data) == "table" and data.DailyQuest and type(data.Mob) == "string"
        and tonumber(data.Mob:match("%[Lv%. (%d+)%]")) ~= nil
end
local function pickDaily(level)
    if not State.AutoDaily then return nil end
    local best, bestExp
    for quest, data in pairs(Game.QuestManager) do
        if isDailyKill(quest) and data.Level <= level and tonumber(data.Mob:match("%[Lv%. (%d+)%]")) <= level
            and os.clock() >= (bossBlockedUntil[quest] or 0) and isMobAlive(data.Mob) then
            local exp = type(data.Rewards) == "table" and tonumber(data.Rewards.exp) or 0
            if not bestExp or exp > bestExp then best, bestExp = quest, exp end
        end
    end
    return best, best and Game.QuestManager[best].Level
end

-- มอนที่เคยเห็นใน workspace.Monster ของเซิร์ฟนี้ = มอนของโลกที่อยู่ (QuestManager มีเควสทุกโลกรวมกัน)
-- shortcut: นับเฉพาะมอนที่เคยโผล่ ถ้าเกมเปิด StreamingEnabled แล้วมอนไกลๆ ไม่โหลด อาจข้ามเควสที่สูงกว่าไป จนกว่าจะเห็นมอนนั้น
local seenMobs = {}
local function refreshSeenMobs()
    local monsters = workspace:FindFirstChild("Monster")
    if not monsters then return end
    for _, folder in ipairs(monsters:GetChildren()) do
        for _, mob in ipairs(folder:GetChildren()) do seenMobs[mob.Name] = true end
    end
end

local function pickQuest(level)
    local boss, bossLevel = pickBoss(level)
    if boss then return boss, bossLevel end
    local daily, dailyLevel = pickDaily(level)
    if daily then return daily, dailyLevel end
    if State.Enabled then
        refreshSeenMobs()
        return findOptimalQuest(Game.QuestManager, level, next(seenMobs) and seenMobs or nil)
    end
end

-- คืนข้อความสถานะ เอาไว้โชว์ใน UI
local function manageQuests()
    if not gameOk then return "Game structure not found: " .. tostring(gameError) end
    local level = getPlayerLevel()
    local current = getCurrentQuest()
    -- ผู้เล่นรับเควส Find เองแล้วเปิด Auto Collect ไว้ -> ห้ามยกเลิก ปล่อยให้เก็บของจนจบ
    if State.Find[current] then return ("Lv %d | collecting for %s"):format(level, current) end
    -- เควสรายวันที่ทำค้างอยู่ -> ทำต่อแม้มอนยังไม่เกิด (บอสรายวันรอเกิดใหม่) ไม่ยกเลิกทิ้ง
    if State.AutoDaily and isDailyKill(current) and not pickBoss(level) then
        return ("Lv %d | daily: %s"):format(level, current)
    end
    local best, bestLevel = pickQuest(level)
    if not best then
        if not State.Enabled then return ("Lv %d | waiting for %s"):format(level, tostring(State.Boss)) end
        return ("Lv %d | no suitable quest"):format(level)
    end
    if current == best then return ("Lv %d | on %s (Lv %d)"):format(level, best, bestLevel) end
    if current ~= "" then
        local ok, err = cancelQuest()
        if not ok then return "Cancel failed: " .. tostring(err) end
        task.wait(0.5) -- เกมต้องรออย่างน้อย 0.5 วิหลังยกเลิก
    end
    local ok, err = acceptQuest(best)
    if not ok then return "Accept failed: " .. tostring(err) end
    local daily = isDailyKill(best)
    if best:find("^Kill 1 ") or daily then
        task.wait(0.5)
        if getCurrentQuest() ~= best then
            local wait = daily and 600 or 60
            bossBlockedUntil[best] = os.clock() + wait
            return ("Lv %d | %s refused, retry in %ds"):format(level, best, wait)
        end
    end
    return ("Lv %d | accepted %s (Lv %d)"):format(level, best, bestLevel)
end

local Tabs = {
    Main = Window:AddTab({ Title = "Main" }),
    Player = Window:AddTab({ Title = "Player" }),
    Shop = Window:AddTab({ Title = "Shop" }),
    Misc = Window:AddTab({ Title = "Misc" }),
    Teleport = Window:AddTab({ Title = "Teleport" }),
    Dungeon = Window:AddTab({ Title = "Dungeon" }),
    Settings = Window:AddTab({ Title = "Settings" }),
}
local Main = Tabs.Main:AddSection("Auto Farm")
local Status = Main:AddParagraph({
    Title = "Status",
    Content = gameOk and "Idle" or ("Game structure not found: " .. tostring(gameError)),
})
-- Auto Farm = รับเควสตามเลเวลอัตโนมัติ (State.Enabled) + ลอยตีมอนของเควส (State.AutoFarm)
Main:AddToggle("AutoFarm", {
    Title = "Auto Farm", Default = false,
    Callback = function(value)
        State.Enabled = value
        State.AutoFarm = value
    end,
})
State.Boss = "Auto"
local BOSS_OPTIONS = { "Auto", table.unpack(BOSS_NAMES) }
Main:AddToggle("AutoBoss", {
    Title = "Auto Boss Quest", Default = false,
    Description = "Take boss quest when it spawns.",
    Callback = function(value) State.AutoBoss = value end,
})
Main:AddDropdown("Boss", {
    Title = "Boss", Values = BOSS_OPTIONS, Default = "Auto", Multi = false,
    Callback = function(value) State.Boss = value end,
})
Main:AddToggle("AutoDaily", {
    Title = "Auto Daily Quest", Default = false,
    Description = "Kill-type dailies only.",
    Callback = function(value) State.AutoDaily = value end,
})
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        -- เช็คทุก 1 วิ: บอสเกิดเมื่อไหร่รับเควสบอสทับทันที, Auto Farm ตามไปตีมอนของเควสที่ถืออยู่เอง
        if State.Enabled or State.AutoBoss or State.AutoDaily then
            pcall(function() Status:SetDesc(manageQuests()) end)
        end
        task.wait(1)
    end
end)

-- ===== Auto Farm: วาปไปตีมอนของเควสที่รับอยู่ =====
-- เควสเก็บชื่อมอนไว้ใน QuestManager[ชื่อเควส].Mob เช่น "Soldier [Lv. 1]"
local function getQuestMob()
    if not gameOk then return nil end
    local data = Game.QuestManager[getCurrentQuest()]
    return type(data) == "table" and data.Mob or nil
end

-- หามอนชื่อนี้ที่ยังไม่ตายและอยู่ใกล้ที่สุด (workspace.Monster.Mon / Boss)
local function findMob(mobName, root)
    local monsters = workspace:FindFirstChild("Monster")
    if not monsters then return nil end
    local best, bestDist
    for _, folder in ipairs(monsters:GetChildren()) do
        for _, mob in ipairs(folder:GetChildren()) do
            local hum = mob.Name == mobName and mob:FindFirstChildOfClass("Humanoid")
            local hrp = hum and hum.Health > 0 and mob:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - root.Position).Magnitude
                if not bestDist or dist < bestDist then best, bestDist = hrp, dist end
            end
        end
    end
    return best
end

-- ลอยเหนือหัวมอนกี่ studs: ทดสอบกับ Fighter Fishman แล้ว 5-7 โดนตีสวน, 9 ตีเข้าไม่โดนตี, 10+ ตีไม่ถึง
State.FloatHeight = 9
local farmTarget -- HumanoidRootPart ของมอนที่ล็อคไว้ ตีจนตายค่อยเปลี่ยนตัว

local function isAlive(hrp, mobName)
    local mob = hrp and hrp.Parent
    local hum = mob and mob.Name == mobName and mob:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- ดันเจี้ยน (ทดสอบแล้ว): อยู่เซิร์ฟเดิมแต่โดนวาปไปไกล (~20000) มี PlayerGui.DungeonUI ระหว่างเล่น
-- ศัตรูอยู่ใน workspace.MOB (ไม่ใช่ workspace.Monster)
local function inDungeon() return LocalPlayer.PlayerGui:FindFirstChild("DungeonUI") ~= nil end
-- State.KrakenFight = ช่วงตี Kraken Tentacle ตอนปลดโลก 3 ใช้ระบบตีเดียวกับดันเจี้ยน
local function dungeonActive() return (State.AutoDungeon and inDungeon()) or State.KrakenFight == true end
local function findDungeonMob(root)
    -- shortcut: ยังไม่เคยเห็น Tentacle จริง เลยหาชื่อที่มี "Tentacle" ในทุกโฟลเดอร์มอน ถ้าไม่เจอให้เช็คชื่อโฟลเดอร์ตอนเลเวลถึง
    local folders = State.KrakenFight and { workspace:FindFirstChild("Monster"), workspace:FindFirstChild("SeaMonster"), workspace:FindFirstChild("MOB") }
        or { workspace:FindFirstChild("MOB") }
    local mobs = {}
    for _, f in pairs(folders) do for _, m in ipairs(f:GetDescendants()) do if m:IsA("Model") then table.insert(mobs, m) end end end
    local best, bestDist
    for _, mob in ipairs(mobs) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local hrp = hum and hum.Health > 0 and mob:FindFirstChild("HumanoidRootPart")
        if State.KrakenFight and not mob.Name:find("Tentacle") then hrp = nil end
        if hrp then
            -- Gunner ยิงไกลแรงสุด ฆ่าก่อน (บวกระยะหลอกให้ตัวอื่นอยู่ท้ายคิว)
            local dist = (hrp.Position - root.Position).Magnitude + (mob.Name:find("Gunner") and 0 or 1e6)
            if not bestDist or dist < bestDist then best, bestDist = hrp, dist end
        end
    end
    return best
end

local waitSpot -- ตำแหน่งมอนตัวล่าสุดของเควส ใช้ลอยรอตอนมอนยังไม่เกิด
-- ทุกเฟรม: ล็อคตัวลอยเหนือหัวมอนแล้วหันหน้าลงหามอน (ทำทุกเฟรมตัวจะได้ไม่ตก/ไม่กระตุก)
track(game:GetService("RunService").Heartbeat:Connect(function()
    if dungeonActive() then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end
        -- ไม่ถอยหนีตอนเลือดต่ำ: ทดสอบแล้วลอยสูง 1000 ยังโดน Gunner ยิง 1440/นัด + Shadowbane ดึงตัวลง ถอยไปก็แค่เสียดาเมจ
        local mobHum = farmTarget and farmTarget.Parent and farmTarget.Parent:FindFirstChildOfClass("Humanoid")
        if not (mobHum and mobHum.Health > 0 and farmTarget:IsDescendantOf(workspace))
            or (not State.KrakenFight and not farmTarget.Parent.Name:find("Gunner")) then -- ตีตัวอื่นอยู่แต่ Gunner โผล่ → สลับไป Gunner
            farmTarget = findDungeonMob(root)
        end
        if farmTarget then
            local pos = farmTarget.Position + Vector3.new(0, State.FloatHeight, 0)
            root.CFrame = CFrame.lookAt(pos, farmTarget.Position, farmTarget.CFrame.LookVector)
            root.AssemblyLinearVelocity = Vector3.zero
        end
        return
    end
    if State.Collecting then return end -- Misc กำลังวาปไปเก็บของ อย่าดึงตัวกลับ
    if not State.AutoFarm then farmTarget = nil return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end
    local mobName = getQuestMob()
    if not mobName then farmTarget = nil return end
    if not isAlive(farmTarget, mobName) then farmTarget = findMob(mobName, root) end
    if not farmTarget then
        -- รอมอนเกิดใหม่ (เช่นบอสของเควสรายวัน): ลอยสูงเหนือจุดที่มอนตายล่าสุด กันโดนตี
        if waitSpot and waitSpot.Mob == mobName then
            root.CFrame = CFrame.new(waitSpot.Pos + Vector3.new(0, 60, 0))
            root.AssemblyLinearVelocity = Vector3.zero
        end
        return
    end
    waitSpot = { Mob = mobName, Pos = farmTarget.Position }
    local pos = farmTarget.Position + Vector3.new(0, State.FloatHeight, 0)
    root.CFrame = CFrame.lookAt(pos, farmTarget.Position, farmTarget.CFrame.LookVector)
    root.AssemblyLinearVelocity = Vector3.zero
end))

-- ทุกท่าส่งผ่าน SkillAction("<FS|SW|DF>_<ชื่อ>_<M1|Z|X|C|V|E>") (ดูจาก ClientSkillHandler ของเกม)
-- ชื่ออาวุธที่ใส่อยู่เก็บใน PlayerStats (FightingStyle / SwordName / DFName)
local WEAPON_KINDS = {
    Melee = { Stat = "FightingStyle", Prefix = "FS_" },        -- "None" = หมัดเปล่า ใช้ได้
    Sword = { Stat = "SwordName", Prefix = "SW_", NoneIsEmpty = true },
    Fruit = { Stat = "DFName", Prefix = "DF_", NoneIsEmpty = true },
}
State.Weapon = "Melee"
State.Skills = { Z = true, X = true, C = true }

local function squash(s) return (s:gsub("%s", "")) end

local function equipWeapon()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local stats = LocalPlayer:FindFirstChild("PlayerStats")
    local kind = WEAPON_KINDS[State.Weapon]
    local value = stats and kind and stats:FindFirstChild(kind.Stat)
    local name = value and tostring(value.Value) or ""
    if not hum or name == "" or (kind.NoneIsEmpty and name == "None") then return nil end
    -- shortcut: tool ผลปีศาจหาจากชื่อ (ตัดช่องว่าง) ยังไม่ได้ทดสอบเพราะยังไม่มีผล
    for _, container in ipairs({ char, LocalPlayer.Backpack }) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and squash(tool.Name) == squash(name) then
                if tool.Parent ~= char then hum:EquipTool(tool) end
                return kind.Prefix .. name
            end
        end
    end
end

local function attack()
    local move = equipWeapon()
    if move then Game.SkillRemote:InvokeServer(move .. "_M1") end
end

-- สกิลส่ง Down (กดปุ่ม) แล้ว Up (ปล่อยปุ่ม) พร้อมตำแหน่งเป้า แทนตำแหน่งเมาส์
local function useSkill(key)
    local move = equipWeapon()
    if not move or not farmTarget then return end
    local name = move .. "_" .. key
    Game.SkillRemote:InvokeServer(name, { Type = "Down", MouseHit = farmTarget.CFrame })
    task.wait(0.2)
    if farmTarget then
        Game.SkillRemote:InvokeServer(name, { Type = "Up", MouseHit = farmTarget.CFrame })
    end
end

Main:AddDropdown("Weapon", {
    Title = "Weapon", Values = { "Melee", "Sword", "Fruit" }, Default = "Melee", Multi = false,
    Callback = function(value) State.Weapon = value end,
})
Main:AddToggle("AutoSkill", {
    Title = "Auto Skill", Default = false,
    Callback = function(value) State.AutoSkill = value end,
})
Main:AddDropdown("Skills", {
    Title = "Skills", Values = { "Z", "X", "C", "V", "E" }, Default = { "Z", "X", "C" }, Multi = true,
    Callback = function(value) State.Skills = value end,
})
Main:AddSlider("FloatHeight", {
    Title = "Float Height", Default = 9, Min = 5, Max = 12, Rounding = 0,
    Description = "Higher = safer, lower = hits more.",
    Callback = function(value) State.FloatHeight = value end,
})
-- แต่ละปุ่มยิงแยก thread; คูลดาวน์จริงให้เซิร์ฟเวอร์ตัดสิน ถ้าค้างเกิน 5 วิก็ยิงใหม่ได้
local skillBusySince = {}
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        if (State.AutoFarm or dungeonActive()) and State.AutoSkill and farmTarget then
            for key, on in pairs(State.Skills) do
                local since = skillBusySince[key]
                if on and (not since or os.clock() - since > 5) then
                    skillBusySince[key] = os.clock()
                    task.spawn(function()
                        pcall(useSkill, key)
                        task.wait(1)
                        skillBusySince[key] = nil
                    end)
                end
            end
        end
        task.wait(0.3)
    end
end)
-- InvokeServer อาจค้างไม่ตอบ (เช่นตอนตาย) เลยยิงแยก thread; ค้างเกิน 2 วิก็ยิงใหม่ได้ ลูปไม่ค้างตาม
local attackBusySince
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        if (State.AutoFarm or dungeonActive()) and farmTarget and (not attackBusySince or os.clock() - attackBusySince > 2) then
            attackBusySince = os.clock()
            task.spawn(function() pcall(attack) attackBusySince = nil end)
        end
        task.wait(0.15)
    end
end)

-- ===== Player: ลงแต้มสถานะ + เปิดฮาคิอัตโนมัติ =====
State.Stat = "Melee"
local function autoStats()
    local stats = LocalPlayer:FindFirstChild("PlayerStats")
    local points = stats and stats:FindFirstChild("Points")
    if not points or points.Value <= 0 then return end
    local remote = LocalPlayer.PlayerGui.MainGui.StarterFrame.StatsFrame.RemoteEvent
    remote:FireServer(State.Stat, 1)
end

-- Haki (เกราะ) เปิดเมื่อ Services.Haki == 0, Ken (สังเกต) เปิดเมื่อ KenOpen == false
local function getHakiValue(name)
    local chars = workspace:FindFirstChild("PlayerCharacters")
    local me = chars and chars:FindFirstChild(LocalPlayer.Name)
    local services = me and me:FindFirstChild("Services")
    return services and services:FindFirstChild(name)
end
local function autoArmament()
    local haki = getHakiValue("Haki")
    if haki and haki.Value == 0 then ReplicatedStorage.Chest.Remotes.Events.Armament:FireServer() end
end
local function autoObservation()
    local ken = getHakiValue("KenOpen")
    if ken and ken.Value == false then ReplicatedStorage.Chest.Remotes.Functions.KenEvent:InvokeServer() end
end

local PlayerSection = Tabs.Player:AddSection("Stats")
PlayerSection:AddToggle("AutoStats", {
    Title = "Auto Stats", Default = false,    Callback = function(value) State.AutoStats = value end,
})
PlayerSection:AddDropdown("Stat", {
    Title = "Stat", Values = { "Melee", "Defense", "Sword", "Fruit" }, Default = "Melee", Multi = false,
    Callback = function(value) State.Stat = value end,
})
local HakiSection = Tabs.Player:AddSection("Haki")
HakiSection:AddToggle("AutoArmament", {
    Title = "Auto Armament Haki", Default = false,
    Description = "Needs Buso bought.",
    Callback = function(value) State.AutoArmament = value end,
})
HakiSection:AddToggle("AutoObservation", {
    Title = "Auto Observation Haki", Default = false,
    Description = "Needs Ken bought.",
    Callback = function(value) State.AutoObservation = value end,
})
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        if State.AutoStats then pcall(autoStats) end
        task.wait(0.2)
    end
end)
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        -- ในดันเจี้ยนเปิดฮาคิให้เองเสมอ (ชั้น 2 โดน Pirate Gunner ยิงตาย)
        if State.AutoArmament or dungeonActive() then task.spawn(pcall, autoArmament) end
        if State.AutoObservation or dungeonActive() then task.spawn(pcall, autoObservation) end
        task.wait(2)
    end
end)

-- ===== Misc: เก็บผลปีศาจที่ตก + เควส Find =====
-- วาปไปที่ part แล้วทำ action แล้ววาปกลับ (ถ้า Auto Farm เปิด heartbeat จะพาไปหามอนเอง)
local function visit(part, action)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not part.Parent then return end
    State.Collecting = true
    local back = root.CFrame
    root.CFrame = part.CFrame * CFrame.new(0, 3, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)
    pcall(action, root)
    task.wait(0.4)
    if not State.AutoFarm and root.Parent then root.CFrame = back end
    State.Collecting = false
end

-- shortcut: ยังไม่ได้ทดสอบกับผลจริง (ตอนเช็คไม่มีผลตก) สมมติว่าเก็บแบบเดินชนเหมือน Tool ทั่วไป
local function droppedFruitParts()
    local list = {}
    for _, name in ipairs({ "AllDroppedFruit", "AllspawnDF" }) do
        local folder = workspace:FindFirstChild(name)
        for _, fruit in ipairs(folder and folder:GetChildren() or {}) do
            local part = fruit:FindFirstChild("Handle", true) or (fruit:IsA("BasePart") and fruit)
                or fruit:FindFirstChildWhichIsA("BasePart", true)
            if part then table.insert(list, part) end
        end
    end
    return list
end

local Misc = Tabs.Misc:AddSection("Collect")
Misc:AddToggle("AutoFruit", {
    Title = "Auto Collect Fruit", Default = false,
    Callback = function(value) State.AutoFruit = value end,
})
for _, item in ipairs({
    { "Diamond", "Find 3 Diamonds" },
    { "Golden Key", "Find 1 Golden Key" },
    { "Ancient", "Find 2 Ancient Item" },
    { "Fry Chicken", "Find 3 Fry Chicken" },
}) do
    Misc:AddToggle("AutoCollect" .. item[1]:gsub(" ", ""), {
        Title = "Auto Collect " .. item[1], Default = false,
        Callback = function(value) State.Find[item[2]] = value or nil end,
    })
end
-- Battlepass: ปุ่ม "Claim All" ของเกมเรียก ClaimAllBattlepass:InvokeServer() (BuyBattlepass ไม่แตะ)
local Rewards = Tabs.Misc:AddSection("Rewards")
Rewards:AddToggle("AutoBattlepass", {
    Title = "Auto Claim Battlepass", Default = false,
    Callback = function(value) State.AutoBattlepass = value end,
})
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        if State.AutoBattlepass then
            pcall(function() ReplicatedStorage.Chest.Remotes.Functions.ClaimAllBattlepass:InvokeServer() end)
        end
        task.wait(30)
    end
end)

task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        if State.AutoFruit then
            local part = droppedFruitParts()[1]
            if part then
                visit(part, function(root)
                    firetouchinterest(root, part, 0)
                    task.wait(0.1)
                    firetouchinterest(root, part, 1)
                end)
            end
        end
        local quest = getCurrentQuest()
        if State.Find[quest] then
            local pattern = FIND_ITEMS[quest]
            local cd = pattern and findSpawnItems(pattern)[1]
            if cd then
                local part = cd.Parent:IsA("BasePart") and cd.Parent or cd.Parent:FindFirstChildWhichIsA("BasePart", true)
                if part then visit(part, function() fireclickdetector(cd) end) end
            end
        end
        task.wait(0.5)
    end
end)

-- ===== Shop: ซื้อของจาก NPC ให้อัตโนมัติ =====
-- ร้านคือ Part ใน workspace.AllNPC ที่มี Setting.NameWeapon / Setting.Price
-- คลิก NPC ในเกม = CheckQuest:InvokeServer(<Part>) (ดูจาก NPCTalk ของเกม) เราเรียกแบบเดียวกัน
local GameG = (getrenv and getrenv()._G) or _G

local function commas(n)
    local s = tostring(math.floor(n))
    return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
assert(commas(1500000) == "1,500,000" and commas(500) == "500", "commas self-check failed")

local function unstuck()
    pcall(function() LocalPlayer.PlayerGui.MainGui.Dialogue.Visible = false end)
    GameG.NPCTalk = false
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed end
end

-- วิธีที่ทดสอบแล้วว่าซื้อได้ (ซื้อ Soru สำเร็จ): ต้องอยู่ใกล้ NPC -> CheckQuest(npc) -> เซิร์ฟสร้าง
-- ScreenGui ชื่อเดียวกับ NPC ใน PlayerGui -> คลิกเมาส์จริงที่ปุ่ม Accept (ปุ่มนี้ใช้ Script ฝั่งเซิร์ฟ
-- ยิง connection เองไม่ซื้อ) -> DelGui:FireServer() ปิดกล่อง -> วาปกลับที่เดิม
-- ของที่รู้ว่าซื้อแล้ว (เช็คจาก PlayerStats) จะไม่ซื้อซ้ำ; ดาบไม่มีค่าบอกว่ามีแล้ว เลยเช็คไม่ได้
local OWNED = {
    Soru = function(ps) return ps.Soru.Value ~= "None" end,
    BusoHaki = function(ps) return ps.BusoShopValue.Value == "BusoHaki" end,
    KenHaki = function(ps) return ps.KenShopValue.Value == "KenHaki" end,
    -- ซื้อ DarkLeg แล้ว DarkLegBought ยังเป็น False (ทดสอบแล้ว) เลยเช็ค FightingStyle ด้วย
    -- shortcut: ถ้าซื้อแล้วเปลี่ยนไปใช้สไตล์อื่น จะดูเหมือนยังไม่มี -> กดซื้อซ้ำได้
    DarkLeg = function(ps) return ps.FightingStyle.Value == "DarkLeg" or tostring(ps.DarkLegBought.Value):lower() == "true" end,
    Cyborg = function(ps) return ps.FightingStyle.Value == "Cyborg" or tostring(ps.CyborgBought.Value):lower() == "true" end,
    DragonClaw = function(ps) return ps.FightingStyle.Value == "DragonClaw" or tostring(ps.DragonClawBought.Value):lower() == "true" end,
}
local function isOwned(item)
    local check = OWNED[item]
    local ok, owned = pcall(check or function() return false end, LocalPlayer.PlayerStats)
    if ok and owned then return true end
    -- สไตล์หมัดที่ซื้อแล้วอยู่ใน PlayerStats.Bought = {"DarkLeg":true,"WaterStyle":true,...} (รวมของทะเล 2 เช่น Electro)
    local okB, bought = pcall(function()
        return game:GetService("HttpService"):JSONDecode(LocalPlayer.PlayerStats.Bought.Value)
    end)
    return okB and type(bought) == "table" and bought[item] == true
end

local function clickGui(button)
    local inset = game:GetService("GuiService"):GetGuiInset()
    local c = button.AbsolutePosition + button.AbsoluteSize / 2 + inset
    local vim = game:GetService("VirtualInputManager")
    vim:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 1)
    task.wait(0.05)
    vim:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 1)
end

local shopBusy = false
local function buyItem(entry)
    if shopBusy then return notify("Already buying, wait a moment") end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local stats = LocalPlayer:FindFirstChild("PlayerStats")
    if not root or not stats or not entry.Npc.Parent then return notify("Shop NPC not found") end
    if isOwned(entry.Item) then return notify(entry.Item .. ": already owned") end
    if stats.beli.Value < entry.Price then return notify(entry.Item .. ": not enough beli") end
    shopBusy = true
    if State.AutoFarm then
        VaderUI.Options.AutoFarm:SetValue(false) -- ไม่งั้น Auto Farm ดึงตัวกลับไปหามอน
        notify("Auto Farm paused for shopping")
    end
    unstuck()
    local back, beliBefore = root.CFrame, stats.beli.Value
    local npc = entry.Npc
    local pos = (npc.CFrame * CFrame.new(0, 0, -5)).Position
    root.CFrame = CFrame.lookAt(pos, Vector3.new(npc.Position.X, pos.Y, npc.Position.Z))
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)
    GameG.NPCTalk = true
    pcall(function() ReplicatedStorage.Chest.Remotes.Functions.CheckQuest:InvokeServer(npc) end)
    local box, accept
    local t0 = os.clock()
    repeat
        task.wait(0.05)
        box = LocalPlayer.PlayerGui:FindFirstChild(npc.Name)
        accept = box and box:FindFirstChild("Dialogue") and box.Dialogue:FindFirstChild("Accept")
    until (accept and accept.Visible) or os.clock() - t0 > 6
    if accept and accept.Visible then
        task.wait(0.25) -- ปุ่มขยายตัว 0.1 วิ รอให้เต็มก่อนคลิก
        local gui = VaderUI.GUI
        if gui then gui.Enabled = false end -- กันหน้าต่างสคริปต์บังปุ่ม Accept
        clickGui(accept)
        local t1 = os.clock()
        repeat task.wait(0.05) until stats.beli.Value < beliBefore or os.clock() - t1 > 3
        if gui then gui.Enabled = true end
    end
    if box and box:FindFirstChild("DelGui") then pcall(function() box.DelGui:FireServer() end) end
    unstuck()
    if root.Parent then root.CFrame = back end
    shopBusy = false
    local bought = stats.beli.Value < beliBefore
    notify(entry.Item .. (bought and ": bought!" or ": not bought (box did not open or was refused)"))
    return bought
end

local shopItems = {}
for _, npc in ipairs(workspace.AllNPC:GetChildren()) do
    local setting = npc:IsA("BasePart") and npc:FindFirstChild("Setting")
    local item, price = setting and setting:FindFirstChild("NameWeapon"), setting and setting:FindFirstChild("Price")
    if item and price then table.insert(shopItems, { Npc = npc, Item = item.Value, Price = price.Value }) end
end
table.sort(shopItems, function(a, b) return a.Price < b.Price end)

local ShopSection = Tabs.Shop:AddSection("NPC Shops")
ShopSection:AddParagraph({
    Title = "How it works",
    Content = "Click to buy. Don't move the mouse while buying.",
})
for _, entry in ipairs(shopItems) do
    ShopSection:AddButton({
        Title = entry.Item,
        Description = commas(entry.Price) .. " beli",
        Callback = function() task.spawn(buyItem, entry) end,
    })
end
local ShopFix = Tabs.Shop:AddSection("Fix")
ShopFix:AddButton({
    Title = "Unstuck",
    Description = "Fix a frozen shop box.",
    Callback = unstuck,
})

-- ปลดทะเล 2 (ทดสอบแล้ว): มี Material "Map" -> คุย Traveler กด Accept (รับเควส "Second Sea Map")
-- -> คุยอีกรอบกด Accept (ส่ง Map) -> PlayerStats.SecondSeaProgression = "Yes" จากนั้นไปคุย Elite Pirate เพื่อข้ามทะเล
-- คุยซ้ำทันทีหลังปิดกล่อง เซิร์ฟตอบ "Cancel NPCTalk" ต้องรอ ~4 วิ
local function talkAccept(npc)
    for _ = 1, 4 do
        unstuck()
        task.wait(0.2)
        GameG.NPCTalk = true
        local ok, res = pcall(function() return ReplicatedStorage.Chest.Remotes.Functions.CheckQuest:InvokeServer(npc) end)
        if ok and res ~= "Cancel NPCTalk" then break end
        task.wait(4)
    end
    local box, accept, t0 = nil, nil, os.clock()
    repeat
        task.wait(0.05)
        box = LocalPlayer.PlayerGui:FindFirstChild(npc.Name)
        accept = box and box:FindFirstChild("Dialogue") and box.Dialogue:FindFirstChild("Accept")
    until (accept and accept.Visible) or os.clock() - t0 > 6
    if accept and accept.Visible then
        task.wait(0.4) -- รอข้อความ/ปุ่มขึ้นครบก่อนคลิก
        local gui = VaderUI.GUI
        if gui then gui.Enabled = false end
        clickGui(accept)
        task.wait(2)
        if gui then gui.Enabled = true end
    end
    if box and box:FindFirstChild("DelGui") then pcall(function() box.DelGui:FireServer() end) end
    unstuck()
end

local function seaUnlocked()
    local v = LocalPlayer.PlayerStats:FindFirstChild("SecondSeaProgression")
    return not v or v.Value ~= "No"
end
local function hasMap()
    local ok, mats = pcall(function()
        return game:GetService("HttpService"):JSONDecode(LocalPlayer.PlayerStats.Material.Value)
    end)
    return ok and type(mats) == "table" and (tonumber(mats.Map) or 0) > 0
end

local function unlockSecondSea()
    local traveler = workspace.AllNPC:FindFirstChild("Traveler")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not traveler or not root or shopBusy then return end
    shopBusy = true
    -- พักทุกอย่างที่ดึงตัว/เปลี่ยนเควส ไม่งั้นเควสบอสทับเควส Second Sea Map ระหว่างคุย
    local farm, boss, daily = State.AutoFarm, State.AutoBoss, State.AutoDaily
    if farm then VaderUI.Options.AutoFarm:SetValue(false) end
    State.AutoBoss, State.AutoDaily, State.Collecting = false, false, true
    local back = root.CFrame
    pcall(function()
        for _ = 1, 3 do
            if seaUnlocked() then break end
            local pos = (traveler.CFrame * CFrame.new(0, 0, -5)).Position
            root.CFrame = CFrame.lookAt(pos, Vector3.new(traveler.Position.X, pos.Y, traveler.Position.Z))
            root.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.3)
            talkAccept(traveler)
        end
    end)
    State.AutoBoss, State.AutoDaily, State.Collecting = boss, daily, false
    if root.Parent then root.CFrame = back end
    if farm then VaderUI.Options.AutoFarm:SetValue(true) end
    shopBusy = false
    notify(seaUnlocked() and "Second Sea unlocked! Talk to Elite Pirate to travel" or "Second Sea unlock failed")
end

-- โลก 3 (ทดสอบแล้วแค่บทพูด): The Squid ตอบ "You are not ready." ตอน Lv 3658 (ไกด์บอก Lv 4000)
-- Summon Tentacle (Mystery Altar) ตอบ "You needed Heart of Sea in order to start this quests."
-- Heart of Sea คราฟที่ Jack Stones: Log 50, Fresh Fish 50, Pile of Bones 10, Sea King's Blood 1, Angellic's Feather 15, Undead's Ooze 10
-- ขั้นตอน: ใช้ Heart of Sea ที่ Summon Tentacle -> ฆ่า Kraken Tentacle 6 ตัว -> คุย The Squid -> ไปโลก 3
local THIRD_SEA_LEVEL = 4000
local HEART_RECIPE = { Log = 50, ["Fresh Fish"] = 50, ["Pile of Bones"] = 10, ["Sea King's Blood"] = 1, ["Angellic's Feather"] = 15, ["Undead's Ooze"] = 10 }
local function materials()
    local ok, mats = pcall(function()
        return game:GetService("HttpService"):JSONDecode(LocalPlayer.PlayerStats.Material.Value)
    end)
    return ok and type(mats) == "table" and mats or {}
end
local function thirdSeaMissing()
    local miss = {}
    local lvl = LocalPlayer.PlayerStats.lvl.Value
    if lvl < THIRD_SEA_LEVEL then table.insert(miss, ("Level %d/%d"):format(lvl, THIRD_SEA_LEVEL)) end
    local mats = materials()
    if (tonumber(mats["Heart of Sea"]) or 0) < 1 then
        for name, need in pairs(HEART_RECIPE) do
            local have = tonumber(mats[name]) or 0
            if have < need then table.insert(miss, ("%s %d/%d"):format(name, have, need)) end
        end
        table.sort(miss)
        table.insert(miss, "Heart of Sea (craft at Jack Stones)")
    end
    return miss
end

local function goTalk(npcName)
    local npc = workspace.AllNPC:FindFirstChild(npcName)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not npc or not root then return false end
    local pos = (npc.CFrame * CFrame.new(0, 0, -5)).Position
    root.CFrame = CFrame.lookAt(pos, Vector3.new(npc.Position.X, pos.Y, npc.Position.Z))
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)
    talkAccept(npc)
    return true
end

local function unlockThirdSea()
    if shopBusy or game.PlaceId ~= 6381829480 then return end -- ต้องอยู่โลก 2
    shopBusy = true
    local farm, boss, daily = State.AutoFarm, State.AutoBoss, State.AutoDaily
    if farm then VaderUI.Options.AutoFarm:SetValue(false) end
    State.AutoBoss, State.AutoDaily, State.Collecting = false, false, true
    pcall(function()
        goTalk("Summon Tentacle")
        -- ตี Tentacle จนหมด (รอเกิดสูงสุด 30 วิ ตีสูงสุด 10 นาที)
        State.Collecting, State.KrakenFight = false, true
        local root = LocalPlayer.Character.HumanoidRootPart
        local t0, seen = os.clock(), false
        while os.clock() - t0 < 600 do
            local alive = findDungeonMob(root) ~= nil
            seen = seen or alive
            if (seen and not alive) or (not seen and os.clock() - t0 > 30) then break end
            task.wait(1)
        end
        State.KrakenFight, State.Collecting = false, true
        farmTarget = nil
        if seen then task.wait(2) goTalk("The Squid") end
    end)
    State.KrakenFight = false
    State.AutoBoss, State.AutoDaily, State.Collecting = boss, daily, false
    if farm then VaderUI.Options.AutoFarm:SetValue(true) end
    shopBusy = false
end

local SeaSection = Tabs.Misc:AddSection("Sea")
SeaSection:AddToggle("AutoUnlockSea", {
    Title = "Auto Unlock Second Sea",
    Default = false,
    Callback = function(value) State.AutoUnlockSea = value end,
})
local unlockRetryAt = 0
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        if State.AutoUnlockSea and os.clock() >= unlockRetryAt and not seaUnlocked() and hasMap() then
            unlockSecondSea()
            if not seaUnlocked() then unlockRetryAt = os.clock() + 600 end -- เลเวลไม่ถึง/โดนปฏิเสธ พัก 10 นาที
        end
        task.wait(10)
    end
end)

SeaSection:AddToggle("AutoUnlockThirdSea", {
    Title = "Auto Unlock Third Sea",
    Default = false,
    Callback = function(value) State.AutoUnlockThirdSea = value end,
})
local thirdSeaInfo = SeaSection:AddParagraph({ Title = "Third Sea", Content = "" })
local thirdRetryAt = 0
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        local miss = thirdSeaMissing()
        pcall(function() thirdSeaInfo:SetDesc(#miss == 0 and "Ready" or "Need: " .. table.concat(miss, ", ")) end)
        if State.AutoUnlockThirdSea and #miss == 0 and os.clock() >= thirdRetryAt then
            unlockThirdSea()
            thirdRetryAt = os.clock() + 600 -- สำเร็จจะโดนวาปไปโลก 3 อยู่แล้ว ถ้ายังอยู่แปลว่าพลาด พัก 10 นาที
        end
        task.wait(5)
    end
end)

-- เกาะ = Model ใน workspace.Island (ชื่อแบบ "A - Starter Island") ตัดของที่ไม่ใช่เกาะออก
local NOT_ISLANDS = { EnchantCutscene = true, ["Gacha Background"] = true, Board = true, AwakeFruitCount = true, ["Mirror Room"] = true }
local function islandName(model) return (model.Name:gsub("^%S %- ", ""):gsub("^%+ ", "")) end
local islands = {}
for _, m in ipairs(workspace:FindFirstChild("Island") and workspace.Island:GetChildren() or {}) do
    if m:IsA("Model") and not NOT_ISLANDS[m.Name] then table.insert(islands, m) end
end
table.sort(islands, function(a, b) return a.Name < b.Name end)
assert(islandName({ Name = "A - Starter Island" }) == "Starter Island" and islandName({ Name = "+ Stone Rain Sea" }) == "Stone Rain Sea", "islandName self-check failed")

local function pauseFarm()
    if State.AutoFarm then
        VaderUI.Options.AutoFarm:SetValue(false) -- ไม่งั้น Auto Farm ดึงตัวกลับไปหามอน
        notify("Auto Farm paused for teleport")
    end
end

local function teleportIsland(model)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not model.Parent then return end
    pauseFarm()
    local p = model:GetPivot().Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { model }
    -- ตรงกลางบางเกาะเป็นช่องว่าง (Skull Island) ยิงรอบๆ ห่างออกไปจนเจอพื้น
    local hit
    for _, r in ipairs({ 0, 40, 80, 150 }) do
        for _, d in ipairs({ Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis }) do
            hit = workspace:Raycast(p + d * r + Vector3.new(0, 1500, 0), Vector3.new(0, -3000, 0), params)
            if hit then break end
        end
        if hit then break end
    end
    root.CFrame = CFrame.new((hit and hit.Position or p) + Vector3.new(0, 5, 0))
    root.AssemblyLinearVelocity = Vector3.zero
end

-- ข้ามทะเล: คุย Elite Pirate แล้วกด Accept (ทดสอบแล้ว ทั้งสองทะเลใช้ NPC ชื่อเดียวกัน
-- ทะเล 1 ถาม "go Second Sea?" ทะเล 2 ถาม "go FirstSea?")
local SEA_PLACE = { [1] = 4520749081, [2] = 6381829480 }
local function travelSea(sea)
    if game.PlaceId == SEA_PLACE[sea] then return notify("Already in this sea") end
    local npc = workspace.AllNPC:FindFirstChild("Elite Pirate")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not npc then return notify("Elite Pirate not found") end
    if not root or shopBusy then return end
    if sea == 2 and not seaUnlocked() then return notify("Second Sea is locked") end
    pauseFarm()
    shopBusy = true
    local pos = (npc.CFrame * CFrame.new(0, 0, -5)).Position
    root.CFrame = CFrame.lookAt(pos, Vector3.new(npc.Position.X, pos.Y, npc.Position.Z))
    root.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)
    pcall(talkAccept, npc)
    shopBusy = false
end

local SeaTravel = Tabs.Teleport:AddSection("Sea")
SeaTravel:AddButton({ Title = "Teleport to First Sea", Callback = function() task.spawn(travelSea, 1) end })
SeaTravel:AddButton({ Title = "Teleport to Second Sea", Callback = function() task.spawn(travelSea, 2) end })
-- shortcut: ไปโลก 3 = คุย The Squid ในโลก 2 (ยังไม่ได้ทดสอบหลังปลด) ขากลับจากโลก 3 ยังไม่รู้ว่าคุย NPC ไหน
SeaTravel:AddButton({ Title = "Teleport to Third Sea", Callback = function()
    if game.PlaceId ~= 6381829480 then return notify("Go to Second Sea first") end
    if shopBusy then return end
    pauseFarm()
    shopBusy = true
    task.spawn(function() pcall(goTalk, "The Squid") shopBusy = false end)
end })
local IslandSection = Tabs.Teleport:AddSection("Islands")
for _, m in ipairs(islands) do
    IslandSection:AddButton({ Title = islandName(m), Callback = function() teleportIsland(m) end })
end

-- เข้าดันเจี้ยน (ทดสอบแล้ว): ยืนบนแท่น workspace.Dungeon -> ป้ายขึ้น "1/6 (ชื่อเรา)" นับ 20 วิ
-- -> หน้าโหวต ChooseMap (ไม่โหวตเกมเลือก Easy ให้) -> วาปเข้าดันเจี้ยน
-- มีคนเล่นอยู่ ป้ายขึ้น "Dungeon in progress. Access temporarily restricted." ต้องรอ
local function padText(pad)
    local t = {}
    for _, v in ipairs(pad:GetDescendants()) do if v:IsA("TextLabel") then table.insert(t, v.Text) end end
    return table.concat(t, " ")
end
local function joinDungeon()
    local pad = workspace:FindFirstChild("Dungeon")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not pad or not pad:IsA("BasePart") or not root or shopBusy then return end
    if padText(pad):find("in progress") then return end
    State.Collecting = true -- กัน Auto Farm ดึงตัวออกจากแท่นระหว่างนับถอยหลัง
    local t0 = os.clock()
    -- นับถอยหลังเริ่มใหม่ทุกครั้งที่มีคนเข้า/ออกแท่น เลยรอนานหน่อย
    while State.AutoDungeon and not inDungeon() and os.clock() - t0 < 120 do
        root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dist = root and (root.Position - pad.Position).Magnitude
        -- ยังอยู่แมพหลัก (ไม่ใช่โดนเกมวาปไปดันเจี้ยนแล้ว ที่ y ~15900) ก็ดึงกลับขึ้นแท่น
        if dist and dist > 10 and root.Position.Y < 10000 then
            root.CFrame = pad.CFrame + Vector3.new(0, 3, 0)
            root.AssemblyLinearVelocity = Vector3.zero
        end
        task.wait(0.5)
    end
    State.Collecting = false
end

local DungeonSection = Tabs.Dungeon:AddSection("Dungeon")
DungeonSection:AddToggle("AutoDungeon", {
    Title = "Auto Dungeon", Default = false,
    Callback = function(value) State.AutoDungeon = value end,
})
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        if State.AutoDungeon and not inDungeon() then pcall(joinDungeon) end
        task.wait(3)
    end
end)

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
    Title = "Anti-AFK", Default = true,    Callback = function(value) antiAFK = value end,
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
    Content = "discord.gg/sghjJ7WyWJ",
})
secCommunity:AddButton({
    Title = "Copy Discord Invite",    Callback = function()
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

-- Updating controls from code (SetValue invokes the control callback):
-- VaderUI.Options.Enabled:SetValue(false)
-- VaderUI.Options.Target:SetValues({ "New Option" })
-- VaderUI.Options.Target:SetValue("New Option")
-- VaderUI.Options.Selected:SetValue({ ["Option 1"] = true })
-- Window:SelectTab(1)
-- track(yourEvent:Connect(function() ... end))

-- No farming workers, remote calls, webhook, or map modules are included.
return { UI = VaderUI, Window = Window, Tabs = Tabs, State = State, Track = track }
