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

-- Break And Steal An Egg on the Vader UI.
local MAP_NAME = "Break And Steal An Egg"
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Env = (getgenv and getgenv()) or _G
if Env.VaderMapStarter then pcall(function() Env.VaderMapStarter:Destroy() end) end

local VaderUI = CreateVaderUI()
local Connections = {}
local cleanupTasks = {}
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

local function Notify(message)
    VaderUI:Notify({ Title = MAP_NAME, Content = tostring(message), Duration = 3 })
end
local notify = Notify

local function track(connection)
    table.insert(Connections, connection)
    return connection
end
local function addCleanup(fn)
    table.insert(cleanupTasks, fn)
end
local originalDestroy = VaderUI.Destroy
function VaderUI:Destroy()
    if closed then return end
    pcall(saveProfile)
    closed = true
    for _, fn in ipairs(cleanupTasks) do
        pcall(fn)
    end
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Connections)
    if Env.VaderMapStarter == self then Env.VaderMapStarter = nil end
    originalDestroy(self)
end

-- Short widget helpers the farm logic below calls, mapped onto Vader controls.
local L10n = { Hooks = {}, Tp = function(text) return text end }
local ConfigRuntime = {} -- the farm code still fills this in; the Vader profile is what actually saves
local sectionName = ""
local quiet = false

local function CreatePage(name)
    return Window:AddTab({ Title = name })
end
local function CreateTab() end
local function Section(page, title)
    sectionName = title
    page:AddSection(title)
end
local function StatusCard(page, initial)
    return function() end -- status rows removed from the UI; the farm code still reports to this
end

-- Vader fires the callback on creation and on every SetValue; the farm logic expects neither when silent.
local function control(page, kind, title, options, onChange)
    quiet = true
    options.Title = title
    options.Callback = function(value)
        if not quiet then
            task.spawn(onChange, value)
        end
    end
    -- titles repeat across sections ("TP Speed"), so the section name is part of the profile key
    local element = page["Add" .. kind](page, ((sectionName .. title):gsub("%W", "")), options)
    quiet = false

    local api = {}
    function api.Get()
        return element.Value
    end
    function api.Set(value, silent)
        local before = quiet
        quiet = quiet or silent == true
        element:SetValue(value)
        quiet = before
    end
    return api, element
end

-- Measured in game: the speed the server tolerates rises with the walk speed your SpeedPower gives.
-- Non-stop 2200-stud runs: 1.7x and 1.8x clean at walk speed 42.6, 1.9x pulled back (also at 35.4). 1.7x keeps a margin.
local okSpeedConfig, SpeedConfig = pcall(function()
    return require(game:GetService("ReplicatedStorage").Shared.SpeedConfig)
end)
local MAX_MULT, MIN_MULT = 1.6, 1
local speedMult, lastPull, lastWalk = MAX_MULT, os.clock(), 0
local function safeSpeed()
    lastWalk = os.clock()
    local ok, walk = pcall(function()
        return SpeedConfig.SpeedPowerToWalkSpeed(LocalPlayer:GetAttribute("SpeedPower"))
    end)
    return (okSpeedConfig and ok and type(walk) == "number" and walk or 26) * speedMult
end

-- Pulled back by the server: drop the multiplier 0.1. A minute without a pull-back: climb 0.1 back up.
do
    local lastPos, lastChar
    track(RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            lastPos = nil
            return
        end
        local now = os.clock()
        -- the walk loops never move more than ~8 studs a frame, so a 25-stud jump mid-walk is the server
        if char == lastChar and lastPos and now - lastWalk < 0.3 and (hrp.Position - lastPos).Magnitude > 25 then
            speedMult = math.max(speedMult - 0.1, MIN_MULT)
            lastPull = now
        elseif speedMult < MAX_MULT and now - lastPull > 60 then
            speedMult = math.min(speedMult + 0.1, MAX_MULT)
            lastPull = now
        end
        lastPos, lastChar = hrp.Position, char
    end))
end

local function Toggle(page, title, enabled, callback, _, desc)
    return nil, (control(page, "Toggle", title, { Description = desc, Default = enabled == true }, callback))
end
local function Slider(page, title, min, max, default, decimals, onChange, _, desc)
    return (control(page, "Slider", title, {
        Description = desc, Min = min, Max = max, Default = default, Rounding = decimals,
    }, onChange))
end
local function TextInput(page, title, default, placeholder, callback, desc)
    return nil, (control(page, "Input", title, {
        Description = desc, Default = default, Placeholder = placeholder, Finished = true,
    }, callback))
end
local function Dropdown(page, title, opts)
    -- Vader keeps a multi selection as { Name = true }; the farm code expects a list of names
    local function chosen(value)
        if not opts.Multi then
            return value
        end
        local list = {}
        for name, on in pairs(value) do
            if on then
                table.insert(list, name)
            end
        end
        table.sort(list)
        return list
    end
    local api, element = control(page, "Dropdown", title, {
        Description = opts.Desc, Values = opts.Options, Multi = opts.Multi, Default = opts.Default,
    }, function(value)
        opts.OnChange(chosen(value))
    end)
    function api.Get()
        return chosen(element.Value)
    end
    return nil, api
end

-- Shared between Event / Auto Break / Auto Steal. Event has the highest priority.
local EventGate = {
	Active = false,    -- the Hell Event is running (Break / Steal must stay out of the way)
	Abort = false,     -- Steal must stop its current walk now
	StealBusy = false, -- Auto Steal is in the middle of a target
	InArena = nil,     -- set by the Event tab: true while the player is inside the Hell arena
	Safe = nil,        -- Auto Steal's Safe Zone position (single source of truth)
	InZone = nil,      -- Auto Steal's inAnyZone(pos)
	Running = false,   -- Auto Hell Event toggle is ON: the Event tab owns the game's AutoSwing switch
}

local function BuildAutoFarm()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ContextActionService = game:GetService("ContextActionService")
	local Workspace = game:GetService("Workspace")

	local Page = CreatePage("Farm")
	CreateTab("Farm", "124620632231839")

	-- same request as the game's own "Equip Best" button in the pets inventory
	local equipBest = false
	Section(Page, "Pets")
	Toggle(Page, "Auto Equip Best", false, function(on)
		equipBest = on
	end)
	task.spawn(function()
		while not closed do
			local remote = equipBest and ReplicatedStorage:FindFirstChild("PetsInventoryRemote")
			if remote then
				remote:FireServer("EquipBest")
			end
			task.wait(5)
		end
	end)

	local BREAK_RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Cosmic", "Secret", "Celestial" }
	local STEAL_RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Cosmic", "Secret", "Celestial", "Inferno", "Void", "Omega" }
	local RANK = {}
	for i, r in ipairs(STEAL_RARITIES) do
		RANK[r] = i
	end
	-- measured in game: 55 studs/s runs clean, 60 is pulled back by the server every ~3 s
	local MIN_SPEED, MAX_SPEED = 20, 55
	-- Auto Treadmill installs TMX.Exit: jump off the treadmill (the game only lets go on a jump) before another function moves
	local TMX = { Exit = function() end }

	local function getHRP()
		local c = LocalPlayer.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local function getHumanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	local function toSet(list)
		local t = {}
		for _, v in ipairs(list or {}) do
			t[v] = true
		end
		return t
	end

	local SW, ST, TT
	SW = {
		Running = false, Job = 0, Speed = 55, Priority = "Largest Size",
		Rarity = { Legendary = true },
		Yielded = false, Assumed = false, OnSig = nil, OffSig = nil, MonitorOff = false, ManualOff = false, EvtState = nil,
		Working = false, -- Auto Break is walking to / breaking an egg (used by Auto Treadmill)
	}
	ST = {
		Running = false, Busy = false, Working = false, Noclip = true, SafeWait = true, AntiRagdoll = true,
		Speed = 55, Rarity = {}, Mutation = {}, Collected = 0, MinIncome = 0, Unread = 0,
	}
	TT = { Running = false, Job = 0, Speed = 55, Working = false, Paused = false, EnabledSwing = false, Zone = {} }
	for z = 1, 11 do
		TT.Zone[z] = true
	end

	-- Auto Break / Auto Steal stay paused while the Event runs, or while the player is still inside the arena
	local function evBlock()
		if EventGate.Active then return true end
		if EventGate.InArena then
			local ok, v = pcall(EventGate.InArena)
			return ok and v == true
		end
		return false
	end

	-- Priority: Hell Event > Auto Steal > Auto Titanic Egg > Auto Break
	local function breakBlocked()
		return ST.Working or TT.Working or evBlock()
	end

	local swToggle, stToggle
	local swPriorityDrop, swRarityDrop, stRarityDrop, stMutDrop, swSpeedCtl, stSpeedCtl, stIncomeInput
	local setSwStatus, setStStatus

	local SW_STOP = 6

	local function swAlive(id)
		return SW.Running and SW.Job == id
	end

	local function findSwingBtn()
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		local mg = pg and pg:FindFirstChild("MainGUI")
		local btn = mg and mg:FindFirstChild("AutoSwing")
		if not btn and pg then
			btn = pg:FindFirstChild("AutoSwing", true)
		end
		return btn
	end

	local function pressBtn(btn)
		if firesignal and btn and btn:IsA("GuiButton") then
			pcall(firesignal, btn.MouseButton1Click)
			pcall(firesignal, btn.Activated)
			return true
		end
		return false
	end

	local function sigOf(btn)
		local parts = {}
		local nodes = btn:GetDescendants()
		table.insert(nodes, 1, btn)
		for _, d in ipairs(nodes) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				table.insert(parts, d.Text .. tostring(d.TextColor3))
			end
			if d:IsA("GuiObject") then
				table.insert(parts, tostring(d.BackgroundColor3) .. d.BackgroundTransparency .. tostring(d.Visible))
			end
			if d:IsA("ImageLabel") or d:IsA("ImageButton") then
				table.insert(parts, tostring(d.ImageColor3) .. d.Image)
			end
			if d:IsA("UIStroke") then
				table.insert(parts, tostring(d.Color))
			end
			if d:IsA("BoolValue") then
				table.insert(parts, tostring(d.Value))
			end
		end
		return table.concat(parts, "|")
	end

	local function wordState(t)
		t = t:lower()
		if t:find("%f[%a]off%f[%A]") then
			return false
		end
		if t:find("%f[%a]on%f[%A]") then
			return true
		end
		return nil
	end

	local swingHooked = {}
	local function setSwingEventState(want)
		if type(getnilinstances) ~= "function" then
			return false
		end
		local ok, list = pcall(getnilinstances)
		if not ok or type(list) ~= "table" then
			return false
		end
		for _, obj in ipairs(list) do
			local matches = false
			pcall(function()
				matches = obj.Name == "Event"
					and obj:IsA("BindableEvent")
					and obj:GetDebugId() == "0_132375"
			end)
			if matches then
				local fired = pcall(function()
					obj:Fire(want)
				end)
				if fired then
					SW.EvtState = want
					return true
				end
			end
		end
		return false
	end
	local function hookSwingEvents()
		if type(getnilinstances) ~= "function" then
			return
		end
		local ok, list = pcall(getnilinstances)
		if not ok or type(list) ~= "table" then
			return
		end
		for _, o in ipairs(list) do
			local isEvt = false
			pcall(function()
				isEvt = o.Name == "Event" and o:IsA("BindableEvent")
			end)
			if isEvt and not swingHooked[o] then
				swingHooked[o] = true
				pcall(function()
					track(o.Event:Connect(function(v)
						if type(v) == "boolean" then
							SW.EvtState = v
						end
					end))
				end)
			end
		end
	end

	local function readSwingState(btn)
		for _, inst in ipairs({ btn, btn.Parent }) do
			if inst then
				for k, v in pairs(inst:GetAttributes()) do
					if type(v) == "boolean" then
						local n = k:lower()
						if n:find("auto") or n:find("enabled") or n:find("active") or n == "on" or n:find("toggle") or n:find("state") then
							return v
						end
					end
				end
			end
		end
		for _, d in ipairs(btn:GetChildren()) do
			if d:IsA("BoolValue") then
				return d.Value
			end
		end
		local nodes = btn:GetDescendants()
		table.insert(nodes, 1, btn)
		for _, d in ipairs(nodes) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local r = wordState(d.Text)
				if r ~= nil then
					return r
				end
			end
		end
		if SW.EvtState ~= nil then
			return SW.EvtState
		end
		if SW.OnSig and SW.OffSig then
			local s = sigOf(btn)
			if s == SW.OnSig then
				return true
			elseif s == SW.OffSig then
				return false
			end
		end
		return nil
	end

	local function setGameSwing(want)
		local btn = findSwingBtn()
		if not btn then
			return false
		end
		local cur = readSwingState(btn)
		if cur == nil then
			cur = SW.Assumed
		end
		if cur ~= want then
			if pressBtn(btn) then
				SW.Assumed = want
			end
		end
		return true
	end

	local function btnShown(btn)
		if not btn then
			return false
		end
		local g = btn
		while g and not g:IsA("LayerCollector") do
			if g:IsA("GuiObject") and not g.Visible then
				return false
			end
			g = g.Parent
		end
		return true
	end

	local ensureSwingRemote

	-- true while a pickaxe is in the character's hands (not just in the backpack)
	local function holdingPick()
		local c = LocalPlayer.Character
		if c then
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") and t.Name:lower():find("pick") then
					return true
				end
			end
		end
		return false
	end

	local function enableGameSwing()
		hookSwingEvents()
		local btn = ensureSwingRemote and ensureSwingRemote() or findSwingBtn()
		if not btn then
			-- Still request the game's event state, but report that the UI button was not found.
			setSwingEventState(true)
			Notify("Game AutoSwing button not found (walking only)", false)
			return
		end

		-- Read the button BEFORE firing the event. setSwingEventState() updates SW.EvtState
		-- optimistically, which otherwise makes readSwingState() falsely report ON.
		SW.EvtState = nil
		SW.Assumed = nil
		local current = readSwingState(btn)
		local before = sigOf(btn)

		if current ~= true then
			if not pressBtn(btn) then
				Notify("firesignal not available - cannot press AutoSwing", false)
				setSwingEventState(true)
				return
			end
			task.wait(0.35)
		end

		-- Fire true only after checking/activating the actual game button.
		setSwingEventState(true)
		SW.Assumed = true

		-- If the button exposes an OFF state after activation, retry once.
		for _ = 1, 2 do
			local st = readSwingState(btn)
			if st ~= false then
				break
			end
			pressBtn(btn)
			task.wait(0.35)
		end

		local after = sigOf(btn)
		if before ~= after and readSwingState(btn) ~= false then
			SW.OffSig, SW.OnSig = before, after
		end
	end

	local function monitorSwing(id)
		local lastPress = 0
		local lastHook = 0
		local wasHolding = nil
		while swAlive(id) do
			task.wait(0.15)
			if os.clock() - lastHook > 5 then
				lastHook = os.clock()
				hookSwingEvents()
			end
			if swAlive(id) and not SW.Yielded and not SW.Resuming and not EventGate.Active then
				-- The pickaxe came back into the hands (e.g. it was put away after AutoSwing was
				-- turned OFF by hand): the cached swing state is stale, so re-read the real button and turn it ON.
				local holding = holdingPick()
				if wasHolding == false and holding then
					enableGameSwing()
					setSwStatus("Pickaxe back in hand -> AutoSwing turned ON again")
				end
				wasHolding = holding
				if SW.EvtState == false then
					setSwingEventState(true)
				end
				local btn = findSwingBtn()
				if not btnShown(btn) and ensureSwingRemote then
					btn = ensureSwingRemote()
				end
				-- keep AutoSwing ON: the moment the game reports OFF, press the game's own button
				if btn and readSwingState(btn) == false and os.clock() - lastPress > 0.6 then
					lastPress = os.clock()
					pressBtn(btn)
					SW.Assumed = true
					setSwStatus("AutoSwing was OFF -> turned ON again")
				end
			else
				wasHolding = nil -- paused / resuming: those flows equip and press by themselves
			end
		end
	end

	local function isPickaxe(t)
		return t:IsA("Tool") and t.Name:lower():find("pick") ~= nil
	end

	local function equipPickaxe()
		local char = LocalPlayer.Character
		local hum = getHumanoid()
		if not (char and hum) then
			return false
		end
		for _, t in ipairs(char:GetChildren()) do
			if isPickaxe(t) then
				return true
			end
		end
		local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		if not bp then
			return false
		end
		for _, t in ipairs(bp:GetChildren()) do
			if isPickaxe(t) then
				pcall(function()
					hum:EquipTool(t)
				end)
				return true
			end
		end
		return false
	end

	local function reequipPickaxe()
		local hum = getHumanoid()
		if hum then
			pcall(function()
				hum:UnequipTools()
			end)
		end
		task.wait(0.3)
		equipPickaxe()
	end

	ensureSwingRemote = function()
		local btn = findSwingBtn()
		for _ = 1, 3 do
			if btnShown(btn) then
				return btn
			end
			if setSwStatus then
				setSwStatus("Swing button not showing -> re-equipping pickaxe")
			end
			reequipPickaxe()
			task.wait(0.6)
			btn = findSwingBtn()
		end
		return btn
	end

	local function eggRarity(model)
		local g = model:FindFirstChild("RarityGradient", true)
		return g and g:GetAttribute("Rarity")
	end

	-- Halloween event targets (Event tab). Haunted houses and candy piles take the same pickaxe hits as eggs.
	local CollectionService = game:GetService("CollectionService")
	local EVT = { House = false, Candy = false, Collect = false }
	local pickups = {}
	track(Workspace.DescendantAdded:Connect(function(d)
		if d.Name == "CandyCornPickup" and d:IsA("BasePart") then
			pickups[d] = true
		end
	end))
	-- shortcut: bag attribute name and 500 capacity are read from HalloweenEventConfig, not yet seen live
	local function bagFull()
		return (tonumber(LocalPlayer:GetAttribute("CandyHeistBag")) or 0) >= 500
	end
	local bankPart -- the Safe Zone hitbox: walking into it banks the candy bag

	local function eggAlive(part)
		if part and part == bankPart then
			return bagFull()
		end
		return part and part.Parent and part:GetAttribute("Broken") ~= true and (part:GetAttribute("Health") or 1) > 0
	end

	local function eggSize(model, part)
		local ok, s = pcall(function()
			return model:GetExtentsSize()
		end)
		if not ok or not s then
			s = part.Size
		end
		return math.floor(s.X * s.Y * s.Z * 100 + 0.5)
	end

	local function pickaxeDamage()
		local ok, dmg = pcall(function()
			return require(ReplicatedStorage.Shared.PickaxeConfig).GetDamage(LocalPlayer:GetAttribute("PickaxeTier"))
		end)
		return ok and tonumber(dmg) or 1
	end

	local function eventTargets()
		local out, hrp = {}, getHRP()
		local function add(part)
			out[#out + 1] = { part = part, size = 0, rank = 0, dist = hrp and (part.Position - hrp.Position).Magnitude or 0 }
		end
		if EVT.Candy and bagFull() then
			local hitboxes = Workspace:FindFirstChild("ZoneHitboxes", true)
			bankPart = hitboxes and hitboxes:FindFirstChild("SafeZone")
			if bankPart then
				add(bankPart)
				return out
			end
		end
		if EVT.Collect then
			for p in pairs(pickups) do
				if not p.Parent then
					pickups[p] = nil
				elseif hrp and (p.Position - hrp.Position).Magnitude < 150 then
					add(p)
				end
			end
		end
		-- only what the pickaxe finishes in about a minute, so it never parks on a house it cannot break
		local maxHealth = pickaxeDamage() * 120
		for tag, on in pairs({ BreakableHalloweenDoor = EVT.House, BreakableCandyPile = EVT.Candy }) do
			if on then
				for _, part in ipairs(CollectionService:GetTagged(tag)) do
					if part:IsA("BasePart") and eggAlive(part) and (tonumber(part:GetAttribute("Health")) or 0) <= maxHealth then
						add(part)
					end
				end
			end
		end
		table.sort(out, function(a, b) return a.dist < b.dist end)
		return out
	end

	local function scanEggs()
		local ev = eventTargets()
		if #ev > 0 then
			return ev
		end
		local out = {}
		local build = Workspace:FindFirstChild("Build")
		local zb = build and build:FindFirstChild("ZoneBuilds")
		if not zb then
			return out
		end
		local hrp = getHRP()
		for _, zone in ipairs(zb:GetChildren()) do
			local eggs = zone:FindFirstChild("Eggs")
			if eggs then
				for _, m in ipairs(eggs:GetChildren()) do
					local part = m:FindFirstChild("Egg")
					if part and part:IsA("BasePart") and eggAlive(part) then
						local r = eggRarity(m)
						if r and SW.Rarity[r] then
							table.insert(out, {
								part = part,
								size = eggSize(m, part),
								rank = RANK[r] or 0,
								dist = hrp and (part.Position - hrp.Position).Magnitude or 0,
							})
						end
					end
				end
			end
		end
		table.sort(out, function(a, b)
			if SW.Priority == "Highest Rarity" then
				if a.rank ~= b.rank then
					return a.rank > b.rank
				end
				if a.size ~= b.size then
					return a.size > b.size
				end
			else
				if a.size ~= b.size then
					return a.size > b.size
				end
				if a.rank ~= b.rank then
					return a.rank > b.rank
				end
			end
			return a.dist < b.dist
		end)
		return out
	end

	local function swWalkTo(part, id)
		while swAlive(id) and not breakBlocked() and eggAlive(part) do
			local r = getHRP()
			if not r then
				return false
			end
			local dir = Vector3.new(part.Position.X - r.Position.X, 0, part.Position.Z - r.Position.Z)
			local dist = dir.Magnitude
			-- the step below stops exactly at SW_STOP, so allow for float error or this never returns
			if dist <= SW_STOP + 0.1 then
				return true
			end
			local dt = math.min(RunService.Heartbeat:Wait(), 0.05)
			if not swAlive(id) or breakBlocked() then
				return false
			end
			local step = math.min(safeSpeed() * dt, dist - SW_STOP)
			local np = r.Position + dir.Unit * step
			np = Vector3.new(np.X, 3.693, np.Z) -- stay at ground height, never float up
			r.CFrame = CFrame.new(np, Vector3.new(part.Position.X, np.Y, part.Position.Z))
			r.AssemblyLinearVelocity = Vector3.zero
		end
		return false
	end

	local function breakLoop(id)
		local lastEquip = 0
		reequipPickaxe()
		enableGameSwing()
		task.spawn(monitorSwing, id)
		while swAlive(id) do
			if breakBlocked() then
				SW.Working = false
				if not SW.Yielded then
					SW.Yielded = true
					setSwStatus(evBlock() and "Paused - Hell Event has priority" or (TT.Working and "Paused - Auto Titanic Egg is working (AutoSwing kept ON)" or "Paused - Auto Steal is working (AutoSwing kept ON)"))
				end
				task.wait(0.15)
			else
				if SW.Yielded then
					SW.Resuming = true
					SW.Yielded = false
					setSwStatus("Auto Steal finished -> equipping Pickaxe")

					-- Do not resume Auto Swing unless a Pickaxe is actually equipped.
					local equipped = false
					for _ = 1, 5 do
						if not swAlive(id) then break end
						equipPickaxe()
						task.wait(0.25)
						local char = LocalPlayer.Character
						if char then
							for _, tool in ipairs(char:GetChildren()) do
								if isPickaxe(tool) then
									equipped = true
									break
								end
							end
						end
						if equipped then break end
					end

					if equipped and not SW.ManualOff then
						hookSwingEvents()
						local btn = ensureSwingRemote and ensureSwingRemote() or findSwingBtn()
						if btn then
							-- Clear optimistic/cached state so the actual button is checked first.
							SW.EvtState = nil
							SW.Assumed = nil
							if readSwingState(btn) ~= true then
								-- One activation after Auto Steal completes, while Pickaxe is equipped.
								pressBtn(btn)
								task.wait(0.35)
							end
						end
						setSwingEventState(true)
						SW.Assumed = true
						setSwStatus("Resumed - Pickaxe equipped, AutoSwing enabled")
					elseif not equipped then
						setSwStatus("Cannot resume - Pickaxe not found/equipped")
					end
					SW.Resuming = false
				elseif os.clock() - lastEquip > 1 then
					lastEquip = os.clock()
					equipPickaxe()
				end
				local e = scanEggs()[1]
				if not e then
					SW.Working = false
					setSwStatus("No matching egg found, scanning...")
					task.wait(0.5)
				else
					SW.Working = true
					TMX.Exit()
					setSwStatus("Walking to egg (size " .. e.size .. ")")
					if swWalkTo(e.part, id) then
						setSwStatus("Breaking egg")
						while swAlive(id) and not breakBlocked() and eggAlive(e.part) do
							local r = getHRP()
							if r and Vector3.new(e.part.Position.X - r.Position.X, 0, e.part.Position.Z - r.Position.Z).Magnitude > SW_STOP * 4 then
								break
							end
							task.wait(0.3)
						end
					end
				end
				task.wait()
			end
		end
	end

	local function swStop(msg)
		local was = SW.Running
		SW.Running = false
		SW.Working = false
		SW.Job += 1
		SW.Yielded = false
		if was then
			setGameSwing(false)
		end
		setSwingEventState(false)
		local hrp = getHRP()
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		if setSwStatus then
			setSwStatus(msg or "Stopped")
		end
	end

	local function swStart()
		local any = false
		for _, v in pairs(SW.Rarity) do
			if v then
				any = true
				break
			end
		end
		if not any then
			Notify("Select a rarity first", false)
			return false
		end
		SW.Running = true
		SW.Yielded = false
		SW.MonitorOff = false
		SW.ManualOff = false
		SW.Job += 1
		local id = SW.Job
		task.spawn(function()
			local ok, err = pcall(breakLoop, id)
			if not ok then
				warn("[Vader] AutoBreak error: " .. tostring(err))
				if SW.Job == id then
					swStop("Error - see console")
					pcall(function()
						swToggle.Set(false, true)
					end)
				end
			end
		end)
		return true
	end

	local setTtStatus
	local ttToggle, ttSpeedCtl, ttZoneDrop
	local TT_GAP = 3.2

	local function ttAlive(id)
		return TT.Running and TT.Job == id
	end

	local function titanicBlocked()
		return ST.Working or evBlock()
	end

	local function fmtClock(sec)
		sec = math.max(0, math.floor(sec))
		return ("%d:%02d"):format(math.floor(sec / 60), sec % 60)
	end

	-- A real Titanic Egg: the Egg part carries Titanic = true (plus DespawnAt). Its model keeps a normal
	-- name like "3: Candy Egg", so the name cannot be used. WeightBracket = "TITANIC" alone is only a SIZE
	-- class (big normal eggs have it too, without the Titanic flag), so it is NOT used.
	-- Fallback: Workspace announces the live Titanic (TitanicZoneIndex / TitanicEggName / TitanicEndsAt).
	local function isTitanicEgg(model, part)
		if part:GetAttribute("Titanic") == true then
			return true
		end
		local zi = tonumber(Workspace:GetAttribute("TitanicZoneIndex"))
		local nm = Workspace:GetAttribute("TitanicEggName")
		local ends = tonumber(Workspace:GetAttribute("TitanicEndsAt"))
		local despawn = tonumber(part:GetAttribute("DespawnAt"))
		if zi and nm and ends and despawn
			and tonumber(part:GetAttribute("ZoneIndex")) == zi
			and part:GetAttribute("EggType") == nm
			and math.abs(despawn - ends) < 2 then
			return true
		end
		return false
	end

	local function findTitanic()
		local build = Workspace:FindFirstChild("Build")
		local zb = build and build:FindFirstChild("ZoneBuilds")
		if not zb then
			return nil
		end
		local r = getHRP()
		local best, bd = nil, math.huge
		for _, zone in ipairs(zb:GetChildren()) do
			local eggs = zone:FindFirstChild("Eggs")
			local zn0 = tonumber(zone.Name:match("%d+"))
			if eggs then
				for _, m in ipairs(eggs:GetChildren()) do
					local part = m:FindFirstChild("Egg")
					local zn = (part and tonumber(part:GetAttribute("ZoneIndex"))) or zn0
					if part and part:IsA("BasePart") and (zn == nil or TT.Zone[zn]) and eggAlive(part)
						and isTitanicEgg(m, part) then
						local d = r and (part.Position - r.Position).Magnitude or 0
						if d < bd then
							best, bd = part, d
						end
					end
				end
			end
		end
		return best
	end

	local function ttStopDist(part)
		return math.max(SW_STOP, math.max(part.Size.X, part.Size.Z) / 2 + TT_GAP)
	end

	local function ttWalkTo(part, id)
		local stop = ttStopDist(part)
		while ttAlive(id) and not titanicBlocked() and eggAlive(part) do
			local r = getHRP()
			if not r then
				return false
			end
			local dir = Vector3.new(part.Position.X - r.Position.X, 0, part.Position.Z - r.Position.Z)
			local dist = dir.Magnitude
			if dist <= stop then
				return true
			end
			local dt = math.min(RunService.Heartbeat:Wait(), 0.05)
			if not ttAlive(id) or titanicBlocked() then
				return false
			end
			local step = math.min(safeSpeed() * dt, dist - stop)
			local np = r.Position + dir.Unit * step
			np = Vector3.new(np.X, 3.693, np.Z) -- stay at ground height, never float up
			r.CFrame = CFrame.new(np, Vector3.new(part.Position.X, np.Y, part.Position.Z))
			r.AssemblyLinearVelocity = Vector3.zero
		end
		return false
	end

	local function ttPrepare()
		equipPickaxe()
		if EventGate.Active then
			return
		end
		local btn = findSwingBtn()
		local st = btn and readSwingState(btn)
		if st == true or (st == nil and SW.Assumed == true) then
			return
		end
		hookSwingEvents()
		TT.EnabledSwing = true
		enableGameSwing()
	end

	local function ttRelease()
		if TT.EnabledSwing and not SW.Running and not EventGate.Active then
			pcall(setGameSwing, false)
			pcall(setSwingEventState, false)
		end
		TT.EnabledSwing = false
	end

	local function ttHit(part, id)
		local r = getHRP()
		if not r then
			return
		end
		local holdCF = r.CFrame
		local lastEquip, lastChk, lastPress, lastStatus = 0, 0, 0, 0
		local wasHolding = nil
		while ttAlive(id) and not titanicBlocked() and eggAlive(part) do
			r = getHRP()
			if not r then
				break
			end
			r.CFrame = holdCF
			r.AssemblyLinearVelocity = Vector3.zero
			local now = os.clock()
			if now - lastEquip > 1 then
				lastEquip = now
				equipPickaxe()
			end
			if now - lastChk > 0.3 and not EventGate.Active then
				lastChk = now
				-- pickaxe came back into the hands: the cached swing state is stale, turn AutoSwing ON again
				local holding = holdingPick()
				if wasHolding == false and holding then
					enableGameSwing()
				end
				wasHolding = holding
				if SW.EvtState == false then
					setSwingEventState(true)
				end
				local btn = findSwingBtn()
				if btn and readSwingState(btn) == false and now - lastPress > 0.8 then
					lastPress = now
					pressBtn(btn)
					SW.Assumed = true
				end
			elseif EventGate.Active then
				wasHolding = nil
			end
			if now - lastStatus > 0.5 then
				lastStatus = now
				local hp = tonumber(part:GetAttribute("Health")) or 0
				local mx = tonumber(part:GetAttribute("MaxHealth")) or hp
				setTtStatus(("Breaking Titanic Egg: %d / %d"):format(math.floor(hp), math.floor(mx)))
			end
			RunService.Heartbeat:Wait()
		end
	end

	local function titanicStep(id)
		do
			if next(TT.Zone) == nil then
				TT.Working = false
				setTtStatus("Select a zone first")
				task.wait(0.5)
			elseif titanicBlocked() then
				if not TT.Paused then
					TT.Paused = true
					TT.Working = false
					setTtStatus(evBlock() and "Paused - Hell Event has priority" or "Paused - Auto Steal is working")
				end
				task.wait(0.15)
			else
				TT.Paused = false
				local egg = findTitanic()
				if not egg then
					TT.Working = false
					local nextAt = Workspace:GetAttribute("TitanicNextAt")
					local cd = nextAt and (nextAt - os.time()) or 0
					setTtStatus("Waiting for Titanic Egg" .. (cd > 0 and (" (next in " .. fmtClock(cd) .. ")") or ""))
					task.wait(0.5)
				else
					if not TT.Working then
						TT.Working = true
						TMX.Exit()
						local t0 = os.clock()
						while ttAlive(id) and SW.Running and not SW.Yielded and os.clock() - t0 < 1.5 do
							RunService.Heartbeat:Wait()
						end
						if ttAlive(id) and not titanicBlocked() then
							setTtStatus("Preparing Pickaxe / AutoSwing")
							ttPrepare()
						end
					end
					if ttAlive(id) and not titanicBlocked() then
						setTtStatus("Walking to Titanic Egg")
						if ttWalkTo(egg, id) then
							ttHit(egg, id)
						end
						if ttAlive(id) and not titanicBlocked() and not eggAlive(egg) then
							setTtStatus("Titanic Egg broken")
							Notify("Titanic Egg broken", true)
							TT.Working = false
							ttRelease()
							task.wait(1)
						end
					end
				end
			end
		end
	end

	local function titanicLoop(id)
		while ttAlive(id) do
			local ok, err = pcall(titanicStep, id)
			if not ok then
				warn("[Vader] AutoTitanicEgg: " .. tostring(err))
				task.wait(1)
			end
			task.wait()
		end
	end

	local function ttStop(msg)
		local was = TT.Running
		TT.Running = false
		TT.Job += 1
		TT.Working = false
		TT.Paused = false
		if was then
			ttRelease()
		end
		local hrp = getHRP()
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		if setTtStatus then
			setTtStatus(msg or "Stopped")
		end
	end

	local function ttStart()
		TT.Running = true
		TT.Paused = false
		TT.Job += 1
		local id = TT.Job
		task.spawn(function()
			while ttAlive(id) do
				local ok, err = pcall(titanicLoop, id)
				if ok then break end
				warn("[Vader] AutoTitanicEgg error (auto-restart): " .. tostring(err))
				TT.Working = false
				task.wait(1)
			end
		end)
		return true
	end

	-- ===== Auto Treadmill: LOWEST priority =====
	-- Walks (tp-walk) to the treadmill of your own plot and stands in its Hitbox (touching it is enough).
	-- Whenever Hell Event / Auto Steal / Auto Titanic Egg / Auto Break is working it steps out at once,
	-- and it walks back as soon as all of them are idle again.
	local TM = { Running = false, Job = 0, Speed = 55, Margin = 7, GroundY = 3.693 }
	local setTmStatus, tmToggle

	function TM.Alive(id)
		return TM.Running and TM.Job == id
	end

	-- Workspace.Plots.<Base_N (OwnerUserId = me)>.<"... Treadmill" model>.Hitbox
	function TM.Find()
		local plots = Workspace:FindFirstChild("Plots")
		if not plots then
			return nil, "Plots not found"
		end
		local uid = LocalPlayer.UserId
		for _, plot in ipairs(plots:GetChildren()) do
			if tonumber(plot:GetAttribute("OwnerUserId")) == uid then
				if plot:GetAttribute("TreadmillUnlocked") == false then
					return nil, "Treadmill is locked"
				end
				for _, c in ipairs(plot:GetChildren()) do
					if c.Name ~= "TreadmillBoard" and c.Name:lower():find("treadmill", 1, true) then
						local hb = c:FindFirstChild("Hitbox")
						if hb and hb:IsA("BasePart") then
							return hb
						end
					end
				end
				return nil, "Treadmill not found in your plot"
			end
		end
		return nil, "Your plot was not found"
	end

	-- inside the Hitbox (margin 0 = really touching it; bigger margin = still "on" while the game moves us a bit)
	function TM.Inside(hb, hrp, margin)
		local m = margin or TM.Margin
		local rel = hb.CFrame:PointToObjectSpace(hrp.Position)
		return math.abs(rel.X) <= hb.Size.X / 2 + m
			and math.abs(rel.Z) <= hb.Size.Z / 2 + m
			and math.abs(rel.Y) <= hb.Size.Y / 2 + 6
	end

	-- any other function is working -> the treadmill must give way
	function TM.Blocked()
		return ST.Working or TT.Working or SW.Working or evBlock()
	end

	-- step out of the treadmill zone right away (straight out sideways)
	TM.Leaving = false
	-- The game only lets go of the player on a JUMP: jump first, then step out sideways if still inside.
	function TM.Leave(hb, hrp)
		if TM.Leaving then
			-- another caller is already jumping off: just wait for it
			local w0 = os.clock()
			while TM.Leaving and os.clock() - w0 < 1.5 do
				task.wait(0.05)
			end
			return
		end
		TM.Leaving = true
		local ok, err = pcall(function()
			local hum = getHumanoid()
			if hum and hum.Health > 0 then
				local t0 = os.clock()
				while os.clock() - t0 < 0.3 do
					hum.Jump = true
					pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
					task.wait(0.05)
				end
			end
			local r = getHRP() or hrp
			if r and TM.Inside(hb, r) then
				local out = hb.CFrame:PointToWorldSpace(Vector3.new(hb.Size.X / 2 + TM.Margin + 4, 0, 0))
				r.CFrame = CFrame.new(out.X, TM.GroundY, out.Z)
				r.AssemblyLinearVelocity = Vector3.zero
			end
		end)
		TM.Leaving = false
		if not ok then
			warn("[Vader] Treadmill leave error: " .. tostring(err))
		end
	end

	-- other functions call this right before they start moving
	TMX.Exit = function()
		if not TM.Running then return end
		local hb = TM.Find()
		local r = getHRP()
		if hb and r and TM.Inside(hb, r) then
			TM.Leave(hb, r)
		end
	end

	local function tmLoop(id)
		local touching = false
		while TM.Alive(id) do
			local hrp = getHRP()
			if not hrp then
				touching = false
				task.wait(0.3)
				continue
			end
			local hb, why = TM.Find()
			if not hb then
				touching = false
				setTmStatus(why)
				task.wait(1)
				continue
			end
			if TM.Blocked() then
				if touching or TM.Inside(hb, hrp) then
					TM.Leave(hb, hrp)
				end
				touching = false
				setTmStatus("Paused - another function is working")
				task.wait(0.1)
			elseif touching and TM.Inside(hb, hrp) then
				setTmStatus("On treadmill")
				task.wait(0.2)
			elseif TM.Inside(hb, hrp, 0) then
				touching = true -- arrived: standing in the Hitbox
				setTmStatus("On treadmill")
				task.wait(0.2)
			else
				touching = false
				setTmStatus("Walking to treadmill")
				local dt = math.min(RunService.Heartbeat:Wait(), 0.05)
				local r = getHRP()
				if TM.Alive(id) and r and not TM.Blocked() then
					local to = Vector3.new(hb.Position.X - r.Position.X, 0, hb.Position.Z - r.Position.Z)
					if to.Magnitude > 0.3 then
						local np = r.Position + to.Unit * math.min(safeSpeed() * dt, to.Magnitude)
						np = Vector3.new(np.X, TM.GroundY, np.Z)
						r.CFrame = CFrame.new(np, np + Vector3.new(to.X, 0, to.Z))
						r.AssemblyLinearVelocity = Vector3.zero
					end
				end
			end
		end
	end

	function TM.Stop(msg)
		local was = TM.Running
		TM.Running = false
		TM.Job += 1
		if was then
			-- turned off: leave the treadmill immediately
			local hb = TM.Find()
			local hrp = getHRP()
			if hb and hrp and TM.Inside(hb, hrp) then
				TM.Leave(hb, hrp)
			end
		end
		if setTmStatus then
			setTmStatus(msg or "Stopped")
		end
	end

	function TM.Start()
		TM.Running = true
		TM.Job += 1
		local id = TM.Job
		task.spawn(function()
			while TM.Alive(id) do
				local ok, err = pcall(tmLoop, id)
				if ok then break end
				warn("[Vader] AutoTreadmill error (auto-restart): " .. tostring(err))
				task.wait(1)
			end
		end)
		return true
	end

	Section(Page, "Auto Treadmill")
	setTmStatus = StatusCard(Page, "Idle")
	local _tm
	_tm, tmToggle = Toggle(Page, "Auto Treadmill", false, function(on)
		if on then
			TM.Start()
			setTmStatus("Started")
		else
		TM.Stop()
		end
	end, nil, "Runs when idle")

	Section(Page, "Auto Titanic Egg")
	setTtStatus = StatusCard(Page, "Idle")
	local _t
	_t, ttToggle = Toggle(Page, "Auto Titanic Egg", false, function(on)
		if on then
			ttStart()
			setTtStatus("Started")
		else
			ttStop()
		end
	end)
	local TT_ZONES = {}
	for z = 1, 11 do
		TT_ZONES[z] = "Zone " .. z
	end
	_t, ttZoneDrop = Dropdown(Page, "Titanic Zone", {
		Multi = true,
		Options = TT_ZONES,
		Default = TT_ZONES,
		Placeholder = "Select zone",
		Format = function(names)
			local nums = {}
			for _, nm in ipairs(names) do
				local z = tonumber(tostring(nm):match("%d+"))
				if z then table.insert(nums, z) end
			end
			table.sort(nums)
			local parts, i = {}, 1
			while i <= #nums do
				local j = i
				while nums[j + 1] == nums[j] + 1 do j += 1 end
				table.insert(parts, j > i and (nums[i] .. "-" .. nums[j]) or tostring(nums[i]))
				i = j + 1
			end
			return "Zone " .. table.concat(parts, ", ")
		end,
		OnChange = function(chosen)
			TT.Zone = {}
			for _, n in ipairs(chosen) do
				local z = tonumber(tostring(n):match("%d+"))
				if z then
					TT.Zone[z] = true
				end
			end
		end,
	})

	Section(Page, "Auto Break")
	setSwStatus = StatusCard(Page, "Idle")
	local _
	_, swToggle = Toggle(Page, "Auto Break", false, function(on)
		if on then
			if not swStart() then
				swToggle.Set(false, true)
			else
				setSwStatus("Started")
			end
		else
			swStop()
		end
	end)
	_, swPriorityDrop = Dropdown(Page, "Egg Priority", {
		Options = { "Largest Size", "Highest Rarity" },
		Default = "Largest Size",
		OnChange = function(v)
			SW.Priority = v or "Largest Size"
		end,
	})
	_, swRarityDrop = Dropdown(Page, "Egg Rarity", {
		Options = BREAK_RARITIES,
		Default = "Legendary",
		Placeholder = "Select rarity",
		OnChange = function(v)
			SW.Rarity = { [v or "Legendary"] = true }
		end,
	})

	local START = Vector3.new(-72.500, 3.693, -139.970)
	local SAFE = Vector3.new(-72.500, 3.693, 0)
	local LAST = Vector3.new(-4210.0, 3.693, -139.970)
	local GROUND_Y = START.Y
	local ZONE_X = {
		[1] = { -174.5, -81.5 }, [2] = { -304.0, -187.0 }, [3] = { -463.2, -315.8 },
		[4] = { -681.8, -475.2 }, [5] = { -960.8, -694.2 }, [6] = { -1299.8, -973.2 },
		[7] = { -1819.5, -1311.5 }, [8] = { -2338.0, -1831.0 }, [9] = { -2863.0, -2350.0 },
		[10] = { -3565.0, -2863.0 }, [11] = { -4225.1, -3565.0 },
	}
	local stJob = 0

	local function inAnyZone(pos)
		return pos.X <= ZONE_X[1][2] and pos.X >= math.min(ZONE_X[11][1], LAST.X) - 5
	end
	EventGate.Safe = SAFE
	EventGate.InZone = inAnyZone

	local function stAlive(id)
		return ST.Running and stJob == id
	end

	local function stStatus(t)
		if setStStatus then
			setStStatus(t .. "   |   Stolen: " .. ST.Collected)
		end
	end

	local saved, humState = {}, nil

	local function lockControls(on)
		if on then
			pcall(function()
				ContextActionService:BindActionAtPriority("VaderStealLock", function()
					return Enum.ContextActionResult.Sink
				end, false, Enum.ContextActionPriority.High.Value + 100,
					Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
					Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight,
					Enum.PlayerActions.CharacterJump)
			end)
		else
			pcall(function()
				ContextActionService:UnbindAction("VaderStealLock")
			end)
		end
	end

	local function freezeHumanoid()
		local h = getHumanoid()
		if not h then
			return
		end
		if not humState then
			humState = { h = h, ws = h.WalkSpeed, jp = h.JumpPower, jh = h.JumpHeight }
		end
		if h.WalkSpeed ~= 0 then h.WalkSpeed = 0 end
		if h.JumpPower ~= 0 then h.JumpPower = 0 end
		if h.JumpHeight ~= 0 then h.JumpHeight = 0 end
	end

	local function unfreezeHumanoid()
		if humState then
			local h = humState.h
			if h and h.Parent then
				h.WalkSpeed = humState.ws
				h.JumpPower = humState.jp
				h.JumpHeight = humState.jh
			end
			humState = nil
		end
	end

	local function restoreCollide()
		for p, v in pairs(saved) do
			if p and p.Parent then
				p.CanCollide = v
			end
		end
		table.clear(saved)
	end

	local function setBusy(b)
		if ST.Busy == b then
			return
		end
		ST.Busy = b
		EventGate.StealBusy = b
		if b then
			lockControls(true)
			freezeHumanoid()
		else
			lockControls(false)
			unfreezeHumanoid()
			restoreCollide()
		end
	end

	-- The character's parts are listed again only twice a second (scanning every physics step is very slow,
	-- especially once the script is obfuscated).
	local stParts, stPartsChar, stPartsAt = {}, nil, 0
	local function stGetParts(c)
		local now = os.clock()
		if stPartsChar ~= c or now - stPartsAt > 0.5 then
			stPartsChar, stPartsAt = c, now
			stParts = {}
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then
					stParts[#stParts + 1] = p
				end
			end
		end
		return stParts
	end

	track(RunService.Stepped:Connect(function()
		if not (ST.Running and ST.Busy) then
			return
		end
		freezeHumanoid()
		if not ST.Noclip then
			return
		end
		local c = LocalPlayer.Character
		if not c then
			return
		end
		for _, p in ipairs(stGetParts(c)) do
			if saved[p] == nil then
				saved[p] = p.CanCollide
			end
			if p.CanCollide then
				p.CanCollide = false
			end
		end
	end))

	local lastRagCheck, lastRagState = 0, 0
	local function antiRagdoll()
		if os.clock() - lastRagState < 0.1 then
			return
		end
		lastRagState = os.clock()
		local c = LocalPlayer.Character
		local h = getHumanoid()
		if not (c and h) then
			return
		end
		pcall(function()
			h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			if h.PlatformStand then
				h.PlatformStand = false
			end
			local st = h:GetState()
			if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
		if os.clock() - lastRagCheck < 0.25 then
			return
		end
		lastRagCheck = os.clock()
		pcall(function()
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("BallSocketConstraint") then
					d.Enabled = false
				elseif d:IsA("Motor6D") and not d.Enabled then
					d.Enabled = true
				end
			end
		end)
	end

	local function restoreRagdollStates()
		local h = getHumanoid()
		if h then
			pcall(function()
				h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
				h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			end)
		end
	end

	track(RunService.Heartbeat:Connect(function()
		if not ST.Running then
			return
		end
		if ST.AntiRagdoll then
			antiRagdoll()
		end
		if not ST.Busy then
			return
		end
		local hrp = getHRP()
		if not hrp then
			return
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		local p = hrp.Position
		if p.Y < GROUND_Y - 3 or p.Y > GROUND_Y + 12 then
			hrp.CFrame = CFrame.new(p.X, GROUND_Y, p.Z)
		end
	end))

	track(LocalPlayer.CharacterAdded:Connect(function()
		table.clear(saved)
		humState = nil
	end))

	local TemplateRarity = {}
	pcall(function()
		local root = ReplicatedStorage:FindFirstChild("Animals") or ReplicatedStorage
		for _, d in ipairs(root:GetDescendants()) do
			local r = d:GetAttribute("Rarity")
			if r and (d:IsA("Model") or d:IsA("Folder")) then
				TemplateRarity[d.Name:lower()] = tostring(r)
			end
		end
	end)

	local rarityCache = setmetatable({}, { __mode = "k" })
	local function getRarity(obj)
		if rarityCache[obj] then
			return rarityCache[obj]
		end
		local res
		local cur = obj
		for _ = 1, 4 do
			if not cur then
				break
			end
			local v = cur:GetAttribute("Rarity")
			if typeof(v) == "string" and v ~= "" then
				res = v
				break
			end
			cur = cur.Parent
		end
		if not res then
			local nm = obj:GetAttribute("AnimalName") or obj.Name
			res = TemplateRarity[tostring(nm):lower()]
		end
		if not res then
			local rf = ReplicatedStorage:FindFirstChild("Rarities")
			if rf and rf:IsA("ModuleScript") then
				local ok, data = pcall(require, rf)
				if ok and type(data) == "table" then
					local e = data[obj.Name]
					if type(e) == "string" then
						res = e
					elseif type(e) == "table" then
						res = e.Rarity or e.rarity
					end
				end
			end
		end
		if not res then
			for _, d in ipairs(obj:GetDescendants()) do
				if (d:IsA("TextLabel") or d:IsA("TextButton")) and RANK[d.Text] then
					res = d.Text
					break
				end
				if d:IsA("UIGradient") and RANK[d.Name] then
					res = d.Name
					break
				end
				local v = d:GetAttribute("Rarity")
				if typeof(v) == "string" and v ~= "" then
					res = v
					break
				end
			end
		end
		if not res then
			local low = obj.Name:lower()
			for _, r in ipairs(STEAL_RARITIES) do
				if low:find(r:lower(), 1, true) then
					res = r
					break
				end
			end
		end
		if res then
			rarityCache[obj] = res
		end
		return res
	end

	local function zoneOfX(x)
		for z, rng in pairs(ZONE_X) do
			if x >= rng[1] - 5 and x <= rng[2] + 5 then
				return z
			end
		end
		local best, bd = nil, math.huge
		for z, rng in pairs(ZONE_X) do
			local d = math.min(math.abs(x - rng[1]), math.abs(x - rng[2]))
			if d < bd then
				best, bd = z, d
			end
		end
		return best
	end

	local function getPart(o)
		if o:IsA("BasePart") then
			return o
		end
		if o:IsA("Model") then
			return o.PrimaryPart or o:FindFirstChild("HumanoidRootPart") or o:FindFirstChildWhichIsA("BasePart", true)
		end
	end

	local function roadPoint(p)
		return START:Lerp(LAST, math.clamp(p, 0, 1))
	end

	local function project(pos)
		local seg = LAST - START
		return math.clamp((pos - START):Dot(seg) / seg:Dot(seg), 0, 1)
	end

	-- ===== income filter: the "$500K/s" text shown above each animal =====
	local MONEY_MULT = { K = 1e3, M = 1e6, B = 1e9, T = 1e12 }
	local function toNumber(num, suffix)
		local n = tonumber((tostring(num):gsub(",", "")))
		if not n then return nil end
		return n * (MONEY_MULT[tostring(suffix or ""):upper()] or 1)
	end
	-- typed by the user: "500000", "1,250,000", "$1.2M", "500K"
	local function parseAmount(text)
		if type(text) ~= "string" then return nil end
		local num, suf = text:match("([%d][%d,%.]*)%s*([KkMmBbTt]?)")
		if not num then return nil end
		return toNumber(num, suf)
	end
	-- big numbers are shown shortened: 1250000 -> "1.25M"
	local function formatAmount(n)
		if type(n) ~= "number" or n <= 0 then return "" end
		for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
			if n >= u[1] then
				local str = string.format("%.2f", n / u[1]):gsub("0+$", ""):gsub("%.$", "")
				return str .. u[2]
			end
		end
		return tostring(math.floor(n))
	end
	-- read from an animal's label: only text with "/s" counts ("$500K/s", "1.2M/s", "1,250,000/s")
	local function incomeFromText(text)
		if type(text) ~= "string" or not text:find("/", 1, true) then return nil end
		text = text:gsub("<[^>]->", "")
		local num, suf = text:match("([%d][%d,%.]*)%s*([KkMmBbTt]?)%s*/%s*[sS]")
		if not num then return nil end
		return toNumber(num, suf)
	end
	local incomeLabel = setmetatable({}, { __mode = "k" })
	-- always read live from this animal's own label (same species can earn different amounts by size)
	local function incomeOf(obj)
		local lbl = incomeLabel[obj]
		if lbl and lbl.Parent then
			local v = incomeFromText(lbl.Text)
			if v then return v end
		end
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local v = incomeFromText(d.Text)
				if v then
					incomeLabel[obj] = d
					return v
				end
			end
		end
		return nil
	end
	local function passIncome(obj)
		if ST.MinIncome <= 0 then return true end
		local inc = incomeOf(obj)
		if inc == nil then
			ST.Unread += 1 -- label not loaded / not readable: skip it rather than steal blindly
			return false
		end
		return inc >= ST.MinIncome
	end

	-- ===== mutation filter =====
	-- The game stores the mutation in the "Variant" attribute of the animal (e.g. Variant = "Diamond").
	-- Order: Variant attribute -> other *mutation*/*variant* attributes -> overhead UI ("Mutation" frame).
	local MUT_NAMES = { "Gold", "Diamond", "Lucky" }
	local MUT_CANON = {}
	for _, n in ipairs(MUT_NAMES) do MUT_CANON[n:lower()] = n end

	-- print the game's MutationConfig keys once (helps to confirm the mutation names)
	task.spawn(function()
		local m = ReplicatedStorage:FindFirstChild("MutationConfig", true)
		if m and m:IsA("ModuleScript") then
			local ok, t = pcall(require, m)
			if ok and type(t) == "table" then
				local keys = {}
				for k in pairs(t) do keys[#keys + 1] = tostring(k) end
				table.sort(keys)
				warn("[Vader] MutationConfig keys: " .. table.concat(keys, ", "))
			end
		end
	end)

	-- returns: set of mutation names found, and where it was read from
	local function mutationsOf(obj)
		local found, source = {}, nil
		local function addValue(v, from)
			if typeof(v) ~= "string" or v == "" then return end
			local canon = MUT_CANON[v:lower()]
			if canon then
				found[canon] = true
			else
				-- value contains a known name (e.g. "Diamond Mutation")? otherwise keep the raw name
				local hit = false
				for low, n in pairs(MUT_CANON) do
					if v:lower():find(low, 1, true) then found[n] = true; hit = true end
				end
				if not hit then found[v] = true end
			end
			source = source or from
		end
		local function scanAttrs(inst)
			if not inst then return end
			addValue(inst:GetAttribute("Variant"), "attr Variant")
			for k, v in pairs(inst:GetAttributes()) do
				local kl = tostring(k):lower()
				if k ~= "Variant" and (kl:find("mutation", 1, true) or kl:find("variant", 1, true)) then
					addValue(v, "attr " .. tostring(k))
				end
			end
		end
		scanAttrs(obj)
		scanAttrs(getPart(obj))
		if next(found) == nil then
			-- the model inside the pickup may carry the attribute instead
			for _, c in ipairs(obj:GetChildren()) do
				if c:IsA("Model") or c:IsA("BasePart") then scanAttrs(c) end
			end
		end
		if next(found) == nil then
			-- UI fallback: the Gold / Diamond / Lucky badge in the overhead "Mutation" frame
			for _, d in ipairs(obj:GetDescendants()) do
				if d.Name == "Mutation" and d:IsA("GuiObject") and d.Visible then
					for _, c in ipairs(d:GetChildren()) do
						if c:IsA("GuiObject") and c.Visible and MUT_CANON[c.Name:lower()] then
							found[MUT_CANON[c.Name:lower()]] = true
							source = source or "UI"
						end
					end
				end
			end
		end
		return found, source
	end
	-- animal has one of the chosen mutations
	local function chosenFrom(found)
		if next(ST.Mutation) == nil then
			return false
		end
		for n in pairs(ST.Mutation) do
			if found[n] then
				return true
			end
		end
		return false
	end
	local function hasChosenMutation(obj)
		return chosenFrom((mutationsOf(obj)))
	end

	-- debug: log each mutated animal once per change (why it is taken / skipped)
	local dbgSeen = {}
	local function dbgLog(o, msg)
		if dbgSeen[o] == msg then return end
		dbgSeen[o] = msg
		warn("[Vader] Steal: " .. tostring(o.Name) .. " " .. msg)
	end

	local function getTargets(skip)
		local list, skipped = {}, 0
		ST.Unread = 0
		ST.Why = ""
		local folder = Workspace:FindFirstChild("AnimalPickups")
		if not folder then
			return list, skipped
		end
		local hrp = getHRP()
		local cut = { rarity = 0, norarity = 0, income = 0 }
		local total = 0
		for _, o in ipairs(folder:GetChildren()) do
			local part = getPart(o)
			if part then
				total += 1
				local r = getRarity(o)
				local z = zoneOfX(part.Position.X)
				local muts, msrc = mutationsOf(o)
				local hasMut = next(muts) ~= nil
				local chosen = chosenFrom(muts)
				local mutText = ""
				if hasMut then
					local names = {}
					for n in pairs(muts) do names[#names + 1] = n end
					table.sort(names)
					mutText = table.concat(names, "+") .. " (" .. tostring(msrc) .. ")"
				end
				-- Rarity must always be ticked. A chosen mutation only skips the Min Income check.
				local reason
				if not r then
					reason = "cut: rarity unreadable"
					cut.norarity += 1
				elseif not ST.Rarity[r] then
					reason = "cut: rarity " .. r .. " not selected"
					cut.rarity += 1
				elseif not (chosen or passIncome(o)) then
					reason = hasMut and ("cut: " .. mutText .. " not chosen and income below Min Income")
						or "cut: income below Min Income / unreadable"
					cut.income += 1
				end
				if hasMut then
					dbgLog(o, ("Variant=%s rarity=%s chosen=%s -> %s"):format(mutText, tostring(r), tostring(chosen), reason or "OK"))
				end
				if not reason then
					if skip[o] and skip[o] > os.clock() then
						skipped += 1
					else
						table.insert(list, {
							obj = o,
							part = part,
							rarity = r,
							rank = RANK[r] or 0,
							mut = chosen and 1 or 0,
							zone = z or 0,
							d = hrp and (part.Position - hrp.Position).Magnitude or 0,
						})
					end
				end
			end
		end
		if total > 0 and #list == 0 and skipped == 0 then
			ST.Why = ("%d animals: rarity not selected %d, income/mutation %d, rarity unreadable %d"):format(total, cut.rarity, cut.income, cut.norarity)
		end
		-- chosen-mutation animals first, then best rarity, then nearest
		table.sort(list, function(a, b)
			if a.mut ~= b.mut then
				return a.mut > b.mut
			end
			if a.rank ~= b.rank then
				return a.rank > b.rank
			end
			return a.d < b.d
		end)
		return list, skipped
	end

	local function sleep(t, id)
		local t0 = os.clock()
		while os.clock() - t0 < t do
			if not stAlive(id) then
				return false
			end
			RunService.Heartbeat:Wait()
		end
		return stAlive(id)
	end

	local function moveTo(target, id, stopDist, abortFn)
		stopDist = stopDist or 2.5
		local nextCheck = 0
		local function resolve()
			if type(target) == "function" then
				return target()
			end
			return target
		end
		local hrp = getHRP()
		local pos = resolve()
		if not hrp or not pos then
			return false
		end
		local t0 = os.clock()
		local off0 = Vector3.new(pos.X - hrp.Position.X, 0, pos.Z - hrp.Position.Z).Magnitude
		local timeout = off0 / safeSpeed() * 3 + 8
		while stAlive(id) and not EventGate.Abort do
			hrp = getHRP()
			pos = resolve()
			if not hrp or not pos then
				return false
			end
			local off = Vector3.new(pos.X - hrp.Position.X, 0, pos.Z - hrp.Position.Z)
			if off.Magnitude <= stopDist then
				return true
			end
			if os.clock() - t0 > timeout then
				return false
			end
			if abortFn and os.clock() > nextCheck then
				nextCheck = os.clock() + 0.4
				if abortFn() then
					return false
				end
			end
			local dt = math.min(RunService.Heartbeat:Wait(), 0.05)
			if not stAlive(id) then
				return false
			end
			local step = math.min(safeSpeed() * dt, off.Magnitude)
			local np = hrp.Position + off.Unit * step
			np = Vector3.new(np.X, GROUND_Y, np.Z)
			hrp.CFrame = CFrame.new(np, np + Vector3.new(off.X, 0, off.Z))
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		return false
	end

	local lockConn
	local function cleanupLock()
		if lockConn then
			lockConn:Disconnect()
			lockConn = nil
		end
	end

	local function carriedCount()
		local f = Workspace:FindFirstChild("CarriedAnimals")
		return f and #f:GetDescendants() or 0
	end

	local function isStolen(obj, before)
		if not obj.Parent then
			return true
		end
		local f = Workspace:FindFirstChild("CarriedAnimals")
		if not f then
			return false
		end
		if obj:IsDescendantOf(f) then
			return true
		end
		if #f:GetDescendants() > before then
			for _, d in ipairs(f:GetDescendants()) do
				if d.Name == obj.Name then
					return true
				end
			end
		end
		return false
	end

	local function findPrompt(obj, part, allowGlobal)
		local found
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				if d.ActionText == "Steal" then
					return d
				end
				found = found or d
			end
		end
		if obj:IsA("ProximityPrompt") then
			return obj
		end
		if found then
			return found
		end
		if allowGlobal and part then
			local best, bd = nil, 15
			for _, d in ipairs(Workspace:GetDescendants()) do
				if d:IsA("ProximityPrompt") and (d.ActionText == "Steal" or d.ObjectText == obj.Name) then
					local p = d.Parent
					local pos = p and (p:IsA("Attachment") and p.WorldPosition or p:IsA("BasePart") and p.Position)
					if pos then
						local dist = (pos - part.Position).Magnitude
						if dist < bd then
							best, bd = d, dist
						end
					end
				end
			end
			return best
		end
	end

	local function promptPos(prompt, part)
		local p = prompt and prompt.Parent
		if p then
			if p:IsA("Attachment") then
				return p.WorldPosition
			end
			if p:IsA("BasePart") then
				return p.Position
			end
		end
		return part and part.Position
	end

	local function firePrompt(prompt, attempt)
		pcall(function()
			prompt.Enabled = true
			prompt.MaxActivationDistance = 60
			prompt.RequiresLineOfSight = false
			prompt.HoldDuration = 0
		end)
		if fireproximityprompt and attempt % 3 ~= 0 then
			pcall(fireproximityprompt, prompt)
		else
			pcall(function()
				prompt:InputHoldBegin()
				task.wait(0.2)
				prompt:InputHoldEnd()
			end)
		end
	end

	local function groundClamp(v)
		return Vector3.new(v.X, math.clamp(v.Y, GROUND_Y, GROUND_Y + 5), v.Z)
	end

	local function collect(obj, part, id)
		cleanupLock()
		local lockPos
		lockConn = RunService.Heartbeat:Connect(function()
			if not ST.Running then
				cleanupLock()
				return
			end
			local hrp = getHRP()
			if hrp and lockPos then
				hrp.CFrame = CFrame.new(lockPos)
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
		end)

		local before = carriedCount()
		local result = false
		local t0, tries, lastGlobal = os.clock(), 0, 0
		while stAlive(id) and os.clock() - t0 < 10 do
			if isStolen(obj, before) then
				result = true
				break
			end
			local allowGlobal = os.clock() - lastGlobal > 1.5
			if allowGlobal then
				lastGlobal = os.clock()
			end
			local prompt = findPrompt(obj, part, allowGlobal)
			if prompt then
				local pp = promptPos(prompt, part)
				lockPos = pp and groundClamp(pp) or lockPos
				tries += 1
				stStatus(("Stealing %s (try %d)"):format(obj.Name, tries))
				if tries == 1 then
					sleep(0.25, id)
				end
				if not stAlive(id) then
					break
				end
				firePrompt(prompt, tries)
			else
				lockPos = (part and part.Parent and groundClamp(part.Position)) or lockPos
				stStatus("Steal prompt not found for " .. obj.Name)
			end
			if not sleep(0.4, id) then
				break
			end
		end
		if not result and stAlive(id) then
			result = isStolen(obj, before)
		end
		cleanupLock()
		return result
	end

	local function claimWork(id)
		ST.Working = true
		TMX.Exit()
		local t0 = os.clock()
		while stAlive(id) and ((SW.Running and not SW.Yielded) or TT.Working) and os.clock() - t0 < 1.5 do
			RunService.Heartbeat:Wait()
		end
	end

	local function runAuto(id)
		local skip = {}
		local needSafe = true
		local startFromSafe = true
		local function hasTarget()
			local l = getTargets(skip)
			return #l > 0
		end

		while stAlive(id) do
			if evBlock() then
				-- Event first. After it ends, do NOT walk back to the Safe Zone: resume from wherever we are.
				if ST.Working or ST.Busy then
					ST.Working = false
					setBusy(false)
				end
				startFromSafe = false
				needSafe = false
				stStatus(EventGate.Active and "Paused - Hell Event has priority" or "Paused - still in Hell arena")
				sleep(0.4, id)
				continue
			end
			local hrp = getHRP()
			if not hrp then
				sleep(0.5, id)
				continue
			end

			-- Turned on before the pickup folder exists: just wait for it, then start working
			if not Workspace:FindFirstChild("AnimalPickups") then
				stStatus("Waiting for AnimalPickups folder...")
				sleep(1, id)
				continue
			end

			local list, skipped = getTargets(skip)
			local e = list[1]

			if not e then

				ST.Working = false
				startFromSafe = true
				setBusy(false)
				if skipped > 0 then
					stStatus("Waiting for next round (some skipped)")
					sleep(0.6, id)
				elseif ST.SafeWait and needSafe then
					local flat = Vector3.new(hrp.Position.X - SAFE.X, 0, hrp.Position.Z - SAFE.Z).Magnitude
					if flat > 4 and not inAnyZone(hrp.Position) then
						claimWork(id)
						stStatus("No target -> going to Safe Zone")
						setBusy(true)
						moveTo(SAFE, id, 2.5, hasTarget)
						setBusy(false)
						ST.Working = false
					end
					needSafe = false
				else
					stStatus(ST.Unread > 0 and ("Cannot read income of " .. ST.Unread .. " animal(s) yet") or (ST.Why ~= "" and ST.Why or "Waiting for animals"))
					sleep(0.6, id)
				end
				continue
			end

			if not ST.Working then
				claimWork(id)
				if not stAlive(id) then
					break
				end
			end
			needSafe = true
			setBusy(true)

			if startFromSafe then
				startFromSafe = false
				local flat = Vector3.new(hrp.Position.X - SAFE.X, 0, hrp.Position.Z - SAFE.Z).Magnitude
				if flat > 6 and not inAnyZone(hrp.Position) then
					stStatus("Going to Safe Zone first")
					moveTo(SAFE, id, 2.5)
					continue
				end
			end

			stStatus(("Going to %s [%s] zone %d"):format(e.obj.Name, e.rarity, e.zone))
			moveTo(function()
				return e.part.Parent and e.part.Position or nil
			end, id, 3)
			if not stAlive(id) then
				break
			end

			local ok = false
			for attempt = 1, 3 do
				if not stAlive(id) or not e.part.Parent or EventGate.Abort then
					break
				end
				if attempt > 1 then
					stStatus(("Retry %d: %s"):format(attempt, e.obj.Name))
					moveTo(function()
						return e.part.Parent and e.part.Position or nil
					end, id, 3)
				end
				ok = collect(e.obj, e.part, id)
				if ok then
					break
				end
			end
			if not stAlive(id) then
				break
			end

			if ok then
				ST.Collected += 1
				stStatus("Stolen! Heading back to START")
				local rp = roadPoint(project(e.part.Position))
				moveTo(Vector3.new(rp.X, GROUND_Y, rp.Z), id)
				if stAlive(id) then
					moveTo(START, id)
				end
				if stAlive(id) and ST.SafeWait then
					stStatus("At START -> going to Safe Zone")
					moveTo(SAFE, id)
					needSafe = false
				end
				startFromSafe = true
			else
				skip[e.obj] = os.clock() + 15
				needSafe = false
				stStatus("Steal failed -> next target")
			end
		end
		setBusy(false)
		ST.Working = false
	end

	local function stStop(msg)
		ST.Running = false
		ST.Working = false
		stJob += 1
		cleanupLock()
		setBusy(false)
		restoreCollide()
		restoreRagdollStates()
		local hrp = getHRP()
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		stStatus(msg or "Stopped")
	end

	local function stStart()
		local any = false
		for _, v in pairs(ST.Rarity) do
			if v then
				any = true
				break
			end
		end
		if not any then
			Notify("Select a rarity first", false)
			return false
		end
        ST.Running = true
		stJob += 1
		local id = stJob
		task.spawn(function()
			local ok, err = pcall(runAuto, id)
			if not ok then
				warn("[Vader] AutoSteal error: " .. tostring(err))
				if stJob == id then
					stStop("Error - see console")
					pcall(function()
						stToggle.Set(false, true)
					end)
				end
			end
		end)
		return true
	end

	Section(Page, "Auto Steal")
	setStStatus = StatusCard(Page, "Idle   |   Stolen: 0")
	_, stToggle = Toggle(Page, "Auto Steal", false, function(on)
		if on then
			if not stStart() then
				stToggle.Set(false, true)
			else
				stStatus("Started")
			end
		else
			stStop()
		end
	end)
	local STEAL_DEFAULT = { "Secret", "Celestial", "Inferno" }
	ST.Rarity = toSet(STEAL_DEFAULT)
	_, stMutDrop = Dropdown(Page, "Animal Mutation", {
		Multi = true,
		Options = MUT_NAMES,
		Default = {},
		Placeholder = "None",
		Desc = "Ignores Min Income",
		OnChange = function(chosen)
			ST.Mutation = toSet(chosen)
		end,
	})
	_, stRarityDrop = Dropdown(Page, "Animal Rarity", {
		Multi = true,
		Options = STEAL_RARITIES,
		Default = STEAL_DEFAULT,
		Placeholder = "Select rarity",
		OnChange = function(chosen)
			ST.Rarity = toSet(chosen)
		end,
	})
	_, stIncomeInput = TextInput(Page, "Min Income / s", "", "e.g. 500K, 1.2M", function(text)
		local v = 0
		if type(text) == "string" and text:match("%S") then
			v = parseAmount(text)
			if v == nil then
				Notify("Invalid number", false)
				v = 0
			end
		end
		ST.MinIncome = v
		-- show what was understood, shortened (500000 -> 500K, 1,250,000 -> 1.25M)
		if stIncomeInput then stIncomeInput.Set(formatAmount(v), true) end
	end, "0 = off")
	Toggle(Page, "Safe Zone First", ST.SafeWait, function(on)
		ST.SafeWait = on
	end, nil, "Return after stealing")
	Toggle(Page, "Anti Ragdoll", ST.AntiRagdoll, function(on)
		ST.AntiRagdoll = on
		if not on then
			restoreRagdollStates()
		end
	end)
	Toggle(Page, "Noclip While Working", ST.Noclip, function(on)
		ST.Noclip = on
		if not on then
			restoreCollide()
		end
	end)

	local function ttZoneList()
		local out = {}
		for z = 1, 11 do
			if TT.Zone[z] then
				table.insert(out, "Zone " .. z)
			end
		end
		return out
	end

	ConfigRuntime.Get = function()
		local function setToList(set)
			local out = {}
			for k, v in pairs(set or {}) do if v then table.insert(out, k) end end
			table.sort(out)
			return out
		end
		return {
			AutoBreak = swToggle.Get(), AutoSteal = stToggle.Get(), AutoTitanic = ttToggle.Get(), TitanicSpeed = TT.Speed, TitanicZones = ttZoneList(),
			BreakSpeed = SW.Speed, StealSpeed = ST.Speed, Priority = SW.Priority,
			BreakRarity = setToList(SW.Rarity), StealRarity = setToList(ST.Rarity), StealMutation = setToList(ST.Mutation),
			AutoTreadmill = tmToggle.Get(),
			SafeWait = ST.SafeWait, AntiRagdoll = ST.AntiRagdoll, Noclip = ST.Noclip, StealMinIncome = ST.MinIncome,
		}
	end
	ConfigRuntime.Set = function(data)
		if type(data) ~= "table" then return false end
		-- Stop first so the values are changed before either loop starts.
		pcall(function() swToggle.Set(false) end)
		pcall(function() stToggle.Set(false) end)
		pcall(function() ttToggle.Set(false) end)
		pcall(function() tmToggle.Set(false) end)
		if type(data.TitanicZones) == "table" then
			TT.Zone = {}
			for _, n in ipairs(data.TitanicZones) do
				local z = tonumber(tostring(n):match("%d+"))
				if z then TT.Zone[z] = true end
			end
			ttZoneDrop.Set(data.TitanicZones, true)
		end
		if type(data.TitanicSpeed) == "number" then TT.Speed = math.clamp(data.TitanicSpeed, MIN_SPEED, MAX_SPEED); ttSpeedCtl.Set(TT.Speed, true) end
		if type(data.BreakSpeed) == "number" then SW.Speed = math.clamp(data.BreakSpeed, MIN_SPEED, MAX_SPEED); swSpeedCtl.Set(SW.Speed, true) end
		if type(data.StealSpeed) == "number" then ST.Speed = math.clamp(data.StealSpeed, MIN_SPEED, MAX_SPEED); stSpeedCtl.Set(ST.Speed, true) end
		if type(data.Priority) == "string" then SW.Priority = data.Priority; swPriorityDrop.Set(data.Priority, true) end
		if type(data.BreakRarity) == "table" and #data.BreakRarity > 0 then SW.Rarity = { [tostring(data.BreakRarity[1])] = true }; swRarityDrop.Set(tostring(data.BreakRarity[1]), true) end
		if type(data.StealRarity) == "table" and #data.StealRarity > 0 then ST.Rarity = toSet(data.StealRarity); stRarityDrop.Set(data.StealRarity, true) end
		if type(data.StealMutation) == "table" then ST.Mutation = toSet(data.StealMutation); stMutDrop.Set(data.StealMutation, true) end
		if type(data.StealMinIncome) == "number" then
			ST.MinIncome = math.max(0, data.StealMinIncome)
			stIncomeInput.Set(formatAmount(ST.MinIncome), true)
		end
		if type(data.SafeWait) == "boolean" then ST.SafeWait = data.SafeWait end
		if type(data.AntiRagdoll) == "boolean" then ST.AntiRagdoll = data.AntiRagdoll end
		if type(data.Noclip) == "boolean" then ST.Noclip = data.Noclip end
		if data.AutoBreak == true then swToggle.Set(true) end
		if data.AutoSteal == true then task.delay(0.35, function() if stToggle then stToggle.Set(true) end end) end
		if data.AutoTitanic == true then task.delay(0.5, function() if ttToggle then ttToggle.Set(true) end end) end
		if data.AutoTreadmill == true then task.delay(0.8, function() if tmToggle then tmToggle.Set(true) end end) end
		return true
	end

	-- ===== Event tab: Halloween =====
	local EvPage = CreatePage("Event")
	Section(EvPage, "Halloween")
	for _, spec in ipairs({ { "Auto House of Horrors", "House" }, { "Auto Candy Carnage", "Candy" }, { "Auto Collect Candy", "Collect" } }) do
		Toggle(EvPage, spec[1], false, function(on)
			EVT[spec[2]] = on
			-- the event targets ride on Auto Break's walk + AutoSwing loop
			if on and not SW.Running then
				swToggle.Set(true)
			end
		end, nil, spec[2] == "House" and "Turns on Auto Break" or nil)
	end

	Section(EvPage, "Halloween Shop")
	local okShop, ShopCfg = pcall(function() return require(ReplicatedStorage.Shared.HalloweenShopConfig) end)
	local HS = { Potions = {}, Eggs = {}, On = false }
	local potionNames, eggNames, byTitle = {}, {}, {}
	if okShop then
		for id, p in pairs(ShopCfg.Potions) do
			potionNames[#potionNames + 1] = p.Title
			byTitle[p.Title] = { "BuyPotion", id, p.Price }
		end
		for id, e in pairs(ShopCfg.Eggs) do
			local title = (id:gsub("HalloweenEgg", "Halloween Egg "))
			eggNames[#eggNames + 1] = title
			byTitle[title] = { "BuyEgg", id, e.Price }
		end
		table.sort(potionNames)
		table.sort(eggNames)
	end
	Dropdown(EvPage, "Potions", { Multi = true, Options = potionNames, Default = {}, OnChange = function(list) HS.Potions = list end })
	Dropdown(EvPage, "Eggs", { Multi = true, Options = eggNames, Default = {}, OnChange = function(list) HS.Eggs = list end })
	Toggle(EvPage, "Auto Buy Selected", false, function(on)
		HS.On = on
	end, nil, "Needs 1B SpeedPower")
	task.spawn(function()
		while not closed do
			local remote = okShop and HS.On and ReplicatedStorage:FindFirstChild(ShopCfg.RemoteName)
			if remote then
				for _, list in ipairs({ HS.Potions, HS.Eggs }) do
					for _, title in ipairs(list) do
						local item = byTitle[title]
						local stock = item and LocalPlayer:GetAttribute("HalloweenStock_" .. item[2])
						if item and (tonumber(LocalPlayer:GetAttribute("CandyCorn")) or 0) >= item[3] and (stock == nil or stock > 0) then
							pcall(remote.InvokeServer, remote, item[1], item[2])
						end
					end
				end
			end
			task.wait(5)
		end
	end)

	addCleanup(function()
		swStop()
		stStop()
		ttStop()
		TM.Stop()
	end)
end
BuildAutoFarm()


-- Shop: buy the best pickaxe / trail the current cash pays for. Buying also equips it (checked in game).
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Shop = Window:AddTab({ Title = "Shop" }):AddSection("Auto Buy")
    local buyPickaxe, buyTrail = false, false
    Shop:AddToggle("AutoBuyPickaxe", {
        Title = "Auto Buy Pickaxe", Default = false,
        Description = "Best you can afford",
        Callback = function(value) buyPickaxe = value end,
    })
    Shop:AddToggle("AutoBuyTrail", {
        Title = "Auto Buy Trail", Default = false,
        Description = "Best you can afford",
        Callback = function(value) buyTrail = value end,
    })

    -- best = the highest id that is affordable and above everything already owned ("1,2,10")
    local function buyBest(remoteName, items, ownedAttribute)
        local owned = 0
        for id in tostring(LocalPlayer:GetAttribute(ownedAttribute) or ""):gmatch("%d+") do
            owned = math.max(owned, tonumber(id))
        end
        local cash = tonumber(LocalPlayer:GetAttribute("Cash")) or 0
        local best
        for id, item in pairs(items) do
            if type(id) == "number" and id > owned and type(item.Price) == "number" and item.Price <= cash
                and (best == nil or id > best) then
                best = id
            end
        end
        local remote = ReplicatedStorage:FindFirstChild(remoteName)
        if best and remote then
            remote:FireServer("Buy", best)
        end
    end

    task.spawn(function()
        local okPickaxes, Pickaxes = pcall(function() return require(ReplicatedStorage.Shared.PickaxeConfig).Tiers end)
        local okTrails, Trails = pcall(function() return require(ReplicatedStorage.Shared.TrailsConfig).Trails end)
        while not closed do
            if buyPickaxe and okPickaxes then pcall(buyBest, "PickaxeShopRequest", Pickaxes, "OwnedPickaxes") end
            if buyTrail and okTrails then pcall(buyBest, "TrailShopRequest", Trails, "OwnedTrails") end
            task.wait(2)
        end
    end)
end

-- Upgrade: the plot's treadmill and pen, one level each time the cash covers the next cost.
do
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Upgrade = Window:AddTab({ Title = "Upgrade" }):AddSection("Auto Upgrade")
    local upTreadmill, upPen = false, false
    Upgrade:AddToggle("AutoUpgradeTreadmill", {
        Title = "Auto Upgrade Treadmill", Default = false,
        Callback = function(value) upTreadmill = value end,
    })
    Upgrade:AddToggle("AutoUpgradePen", {
        Title = "Auto Upgrade Pen", Default = false,
        Callback = function(value) upPen = value end,
    })

    -- the remotes take no arguments: the server upgrades the caller's own plot by one level
    local function upgrade(remoteName, config, levelAttribute)
        local plots = workspace:FindFirstChild("Plots")
        for _, plot in ipairs(plots and plots:GetChildren() or {}) do
            if tonumber(plot:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then
                local cost = config.UpgradeCost(tonumber(plot:GetAttribute(levelAttribute)))
                local remote = ReplicatedStorage:FindFirstChild(remoteName)
                if remote and type(cost) == "number" and cost <= (tonumber(LocalPlayer:GetAttribute("Cash")) or 0) then
                    remote:FireServer()
                end
                return
            end
        end
    end

    task.spawn(function()
        local okTreadmill, Treadmill = pcall(function() return require(ReplicatedStorage.Shared.TreadmillUpgradeConfig) end)
        local okPen, Pen = pcall(function() return require(ReplicatedStorage.Shared.PlotUpgradeConfig) end)
        while not closed do
            if upTreadmill and okTreadmill then pcall(upgrade, "UpgradeTreadmillRequest", Treadmill, "TreadmillLevel") end
            if upPen and okPen then pcall(upgrade, "UpgradePlotRequest", Pen, "PlotLevel") end
            task.wait(2)
        end
    end)
end

local Tabs = { Settings = Window:AddTab({ Title = "Settings" }) }

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
