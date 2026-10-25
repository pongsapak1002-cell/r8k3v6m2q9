local source=[====[
local Library=(function()


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
end)()
local E=getgenv()
if E.CTD and E.CTD.Stop then E.CTD.Stop() end
if E.CTDPlayMacro then E.CTDPlayMacro.Stop() end
local P=game.Players.LocalPlayer
local H=game:GetService('HttpService')
local M=game.ReplicatedStorage:WaitForChild('ModuleLoader')
local N=M:WaitForChild('Shared'):WaitForChild('Network')
local RE,RF=N:WaitForChild('RemoteEvent'),N:WaitForChild('RemoteFunction')
assert(RE:WaitForChild('Notificate',30),'Game network did not load')
if game.PlaceId==114068177100380 then
    for _,name in ipairs({'TowerAdd','TowerUpgrade','TowerRemove','TowerTarget','TowerSell','WaveSkip','ModeVote','PlayAgain'}) do assert(RE:WaitForChild(name,30),'Missing game remote: '..name) end
    assert(RF:WaitForChild('ChangeSpeed',30),'Speed remote did not load')
end
local A={alive=true,connections={},recording=false,pending=nil,run=nil,attemptedRound=false}
E.CTDPlayMacro=A
local function safeName(name)
    name=tostring(name):gsub('[<>:"/\\|?*%c]','_'):gsub('%.%.','_'):sub(1,64)
    return name~='' and name or 'Default'
end
local folder='CTD_Macros'
assert(makefolder and writefile and readfile and isfile,'Executor file support is required')
if not isfolder or not isfolder(folder) then pcall(makefolder,folder) end
local function readJSON(path,default)
    if not isfile(path) then return default end
    local ok,v=pcall(function() return H:JSONDecode(readfile(path)) end)
    if ok and type(v)=='table' then return v end
    warn('CTD: unreadable file '..path);return default
end
local S={AutoPlace=false,AutoUpgrade=false,FocusFarm=false,PlaceBeforeUpgrade=true,ShowPoint=true,
    PlaceMode='One of each first',UpgradeMode='Cheapest first',PlaceOrder={1,2,3,4,5},UpgradeOrder={1,2,3,4,5},
    Speed=1.5,Difficulty='Easy',AutoStart=false,AutoSkip=false,Repeat=false,
    MacroName='Default',PlayMacro=false,MacroWaitWave=true,AutoSwap=false,MacroSets={},Slots={},
    AutoJoin=false,JoinMap='Toilet City',JoinDelay=2,Theme='Dark',Transparency=false,MascotTransparency=.5,MinimizeKeyName='RightControl',AntiAFK=true,
    WebhookEnabled=false,WebhookURL='',ShowUnitStatus=true,
    AutoSummon=false,SummonBanner='Basic Crate',SummonCount=1,SummonReserve=0,SummonLimit=10,SummonProgress=0,EventClaimQuests=false,EventClaimTiers=false,
    EventAutoBuy=false,EventBuyItem='Exclusive Halloween Crate',EventBuyCount=1,EventBuyReserve=0,EventBuyLimit=1,EventBuyProgress=0,LobbyPurchasePending=false}
for i=1,5 do S.Slots[i]={On=true,Mode='Enemy path',Percent=25,Hug=80,Max=3,Stack=false,Positions={}} end
local saved=readJSON('CTD_PlayMacro_config.json',{})
for k,v in pairs(S) do if typeof(saved[k])==typeof(v) and k~='Slots' then S[k]=saved[k] end end
for i=1,5 do
    local cfg=saved.Slots and (saved.Slots[i] or saved.Slots[tostring(i)])
    if type(cfg)=='table' then for k,v in pairs(S.Slots[i]) do if typeof(cfg[k])==typeof(v) then S.Slots[i][k]=cfg[k] end end end
    local c=S.Slots[i];c.Percent=math.clamp(tonumber(c.Percent) or 25,0,100);c.Hug=math.clamp(tonumber(c.Hug) or 80,0,100);c.Max=math.clamp(math.floor(tonumber(c.Max) or 3),0,15)
end
local function order(value)
    local out,seen={},{}
    for _,n in ipairs(type(value)=='table' and value or {}) do if type(n)=='number' and n%1==0 and n>=1 and n<=5 and not seen[n] then seen[n]=true;table.insert(out,n) end end
    for n=1,5 do if not seen[n] then table.insert(out,n) end end
    return out
end
S.PlaceOrder=order(S.PlaceOrder);S.UpgradeOrder=order(S.UpgradeOrder)
S.MacroName=safeName(S.MacroName)
local function save() writefile('CTD_PlayMacro_config.json',H:JSONEncode(S)) end
if S.LobbyPurchasePending then S.AutoSummon=false;S.EventAutoBuy=false;save() end
local function match() return game.PlaceId==114068177100380 end
local function map() return workspace:GetAttribute('Map') end
local function mode() return workspace:GetAttribute('Mode') end
local function finished() local t=workspace:GetAttribute('Message');return t=='You Won!' or t=='You Lost!' end
local function own(t) return t and (t.OwnerUserId==P.UserId or t.OwnerName==P.Name) end
local function towers() return require(M.Client.GameReplicator).Data.Towers or {} end
local function money() return P.leaderstats.Money.Value end
local function cf(t) return t.CFrame or CFrame.new(t.Pos) end
local function key(t) return tostring(t.Id or t.Index) end
local Window=Library:CreateWindow({Title='Cameraman TD',SubTitle='Join / Auto Play / Macro',Theme=S.Theme,Size=UDim2.fromOffset(700,550),MascotTransparency=S.MascotTransparency,MinimizeKey=Enum.KeyCode[S.MinimizeKeyName] or Enum.KeyCode.RightControl})
local Join=Window:AddTab({Title='Auto Join'})
local Auto=Window:AddTab({Title='Auto Play'})
local Macro=Window:AddTab({Title='Macro'})
local Summon=Window:AddTab({Title='Summon'})
local Event=Window:AddTab({Title='Event'})
local UIControl=Window:AddTab({Title='UI Control'})
local Webhook=Window:AddTab({Title='Webhook'})
local Settings=Window:AddTab({Title='Settings'})
local joinStatus=Join:AddParagraph({Title='Join status',Content='Select a map and enable Auto Join'})
local summary=Auto:AddParagraph({Title='Status',Content='Waiting for match'})
local macroStatus=Macro:AddParagraph({Title='Macro status',Content='Record successful actions or select a saved macro'})
local function note(text,isMacro)
    local row=isMacro and macroStatus or summary
    if row.LastText~=text then row.LastText=text;row:SetDesc(text);print('[CTD PlayMacro]',text) end
end
local function connect(signal,fn) local c=signal:Connect(fn);table.insert(A.connections,c);return c end
local markers=Instance.new('Folder');markers.Name='CTD_SlotMarkers';markers.Parent=workspace
local function toggle(tab,id,title,object,k,callback,description)
    return tab:AddToggle(id,{Title=title,Description=description,Default=object[k],Callback=function(v) object[k]=v;if callback then callback(v) end;save() end})
end
local unitPanel=Instance.new('ScreenGui');unitPanel.Name='CTD_UnitStatus';unitPanel.ResetOnSpawn=false;unitPanel.DisplayOrder=Library.GUI.DisplayOrder+1;unitPanel.Parent=Library.GUI.Parent
A.UnitPanel=unitPanel
local panel=Instance.new('Frame');panel.Name='UnitStatus';panel.Size=UDim2.fromOffset(310,350);panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-16,.22,0);panel.BackgroundColor3=Color3.fromRGB(22,19,31);panel.BorderSizePixel=0;panel.Parent=unitPanel
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=panel
local panelTitle=Instance.new('TextLabel');panelTitle.Size=UDim2.new(1,-48,0,36);panelTitle.Position=UDim2.fromOffset(12,0);panelTitle.BackgroundTransparency=1;panelTitle.Font=Enum.Font.GothamBold;panelTitle.TextSize=13;panelTitle.TextXAlignment=Enum.TextXAlignment.Left;panelTitle.TextColor3=Color3.fromRGB(240,236,250);panelTitle.Text='Unit upgrades';panelTitle.Parent=panel
local closePanel=Instance.new('TextButton');closePanel.Name='ClosePanel';closePanel.Size=UDim2.fromOffset(30,30);closePanel.Position=UDim2.new(1,-35,0,3);closePanel.BackgroundTransparency=1;closePanel.Text='×';closePanel.TextSize=20;closePanel.TextColor3=panelTitle.TextColor3;closePanel.Parent=panel
local openPanel=Instance.new('TextButton');openPanel.Name='OpenUnitStatus';openPanel.Size=UDim2.fromOffset(150,36);openPanel.AnchorPoint=Vector2.new(1,0);openPanel.Position=panel.Position;openPanel.BackgroundColor3=panel.BackgroundColor3;openPanel.TextColor3=panelTitle.TextColor3;openPanel.Font=Enum.Font.GothamBold;openPanel.TextSize=13;openPanel.Text='Open Unit Panel';openPanel.Parent=unitPanel
local openCorner=Instance.new('UICorner');openCorner.CornerRadius=UDim.new(0,8);openCorner.Parent=openPanel
local panelList=Instance.new('ScrollingFrame');panelList.Name='Units';panelList.Position=UDim2.fromOffset(12,39);panelList.Size=UDim2.new(1,-24,1,-49);panelList.BackgroundTransparency=1;panelList.BorderSizePixel=0;panelList.ScrollBarThickness=3;panelList.AutomaticCanvasSize=Enum.AutomaticSize.Y;panelList.CanvasSize=UDim2.new();panelList.Parent=panel
local rowsLayout=Instance.new('UIListLayout');rowsLayout.Padding=UDim.new(0,5);rowsLayout.SortOrder=Enum.SortOrder.LayoutOrder;rowsLayout.Parent=panelList
local unitRows={}
local statusSummary=UIControl:AddParagraph({Title='Upgrade overview',Content='Waiting for match'})
toggle(UIControl,'ShowUnitStatus','Show unit upgrade panel',S,'ShowUnitStatus',function(v) panel.Visible=v;openPanel.Visible=not v end,'Shows each placed unit level and MAX status, including while the main window is hidden.')
panel.Visible=S.ShowUnitStatus;openPanel.Visible=not S.ShowUnitStatus
connect(closePanel.Activated,function() Library.Options.ShowUnitStatus:SetValue(false) end)
connect(openPanel.Activated,function() Library.Options.ShowUnitStatus:SetValue(true) end)
Join:AddDropdown('JoinMap',{Title='Map',Values={'Toilet City','Desert','Cameraman HQ'},Default=S.JoinMap,Callback=function(v) S.JoinMap=v;A.joinTarget=nil;save() end})
toggle(Join,'AutoJoin','Auto Join',S,'AutoJoin',function() A.joinTarget=nil;A.joinAt=nil end)
Join:AddSlider('JoinDelay',{Title='Join delay (seconds)',Min=1,Max=30,Default=S.JoinDelay,Rounding=0,Callback=function(v) S.JoinDelay=v;save() end})
local function validate(data)
    assert(type(data)=='table' and data.version==1 and type(data.map)=='string' and type(data.mode)=='string' and type(data.actions)=='table' and #data.actions<=5000,'Invalid macro header')
    local refs={}
    for _,a in ipairs(data.actions) do
        assert(type(a)=='table' and type(a.wave)=='number' and a.wave==a.wave and a.wave>=0 and a.wave<10000,'Invalid wave')
        if a.kind=='add' then
            assert(type(a.key)=='string' and not refs[a.key] and type(a.name)=='string' and type(a.cf)=='table' and #a.cf==12,'Invalid placement')
            for _,v in ipairs(a.cf) do assert(type(v)=='number' and v==v and math.abs(v)<1e7,'Invalid coordinate') end
            refs[a.key]=true
        elseif a.kind=='upgrade' then
            assert(refs[a.key] and type(a.level)=='number' and a.level%1==0 and a.level>=2 and a.level<=100,'Invalid upgrade')
        elseif a.kind=='sell' then assert(refs[a.key],'Invalid sale');refs[a.key]=nil
        elseif a.kind=='target' then assert(refs[a.key] and table.find({'First','Last','Closest','Strong','Weak'},a.target),'Invalid target')
        elseif a.kind=='skip' then
        else error('Unknown macro action') end
    end
    return data
end
local function macroPath(name) return folder..'/'..safeName(name)..'.json' end
local function loadMacro(name) return validate(readJSON(macroPath(name),{})) end
local function names()
    local list={}
    if listfiles then
        local ok,files=pcall(listfiles,folder)
        if ok then for _,path in ipairs(files) do local n=path:match('([^/\\]+)%.json$');if n then table.insert(list,n) end end end
    end
    if #list==0 then list={S.MacroName} end
    table.sort(list);return list
end
local function inventory() return require(M.Client.Replication).GetCurrentReplica().Data.Towers end
local function unit(slot)
    local uid=P:GetAttribute('Slot'..slot..'Id');local name=P:GetAttribute('Slot'..slot)
    if type(uid)=='string' and uid~='' and type(name)=='string' and name~='' then return name,uid end
end
local config
local function towerConfig(name)
    config=config or require(M.Configs.Config)
    return assert(config.Towers[name],'Unknown tower '..name)
end
local function price(name,level,uid)
    local upgrade=towerConfig(name).Upgrades[level]
    if not upgrade then return nil end
    -- shortcut: displayed base cost is used; server confirmation remains authoritative for signed units.
    return upgrade.Price
end
local function confirmedAdd(name,position,used,baseline)
    for id,t in pairs(towers()) do
        if own(t) and t.Name==name and (t.Pos-position).Magnitude<.5 and not used[id] and (not baseline or not baseline[id]) then return id end
    end
end
local function send(remote,payload,done,label)
    assert(not A.pending,'Previous action is still pending')
    A.pending={done=done,label=label,deadline=os.clock()+10}
    remote:FireServer(payload)
    return true
end
local function place(name,uid,position,done)
    return send(RE.TowerAdd,{Name=name,UnitId=uid,Pos=position.Position,CFrame=position},done,'Place '..name)
end
local function upgrade(id,level)
    return send(RE.TowerUpgrade,{Id=id},function() local t=towers()[id];return t and t.Level>=level end,'Upgrade')
end
local function pathPoint(percent)
    local gameFolder=workspace:FindFirstChild('Game');local waypoints=gameFolder and gameFolder:FindFirstChild('Waypoints')
    if not waypoints then return end
    local points={}
    for _,v in ipairs(waypoints:GetDescendants()) do if v:IsA('BasePart') and tonumber(v.Name) then table.insert(points,v) end end
    table.sort(points,function(a,b) return tonumber(a.Name)<tonumber(b.Name) end)
    if #points<2 then return end
    local lengths,total={},0
    for i=2,#points do local length=(points[i].Position-points[i-1].Position).Magnitude;lengths[i]=length;total+=length end
    local distance=total*percent/100
    for i=2,#points do
        if distance<=lengths[i] or i==#points then
            local direction=points[i].Position-points[i-1].Position
            local horizontal=Vector3.new(direction.X,0,direction.Z)
            if horizontal.Magnitude<.001 then horizontal=Vector3.new(1,0,0) end
            return points[i-1].Position:Lerp(points[i].Position,lengths[i]>0 and math.clamp(distance/lengths[i],0,1) or 0),horizontal.Unit
        end
        distance-=lengths[i]
    end
end
local function anchor(c)
    if c.Mode=='My position' then
        local p=c.Positions[map()]
        if type(p)=='table' and type(p[1])=='number' and type(p[2])=='number' then return Vector3.new(p[1],0,p[2]) end
        return
    end
    local p,d=pathPoint(c.Percent)
    if p then return p+Vector3.new(-d.Z,0,d.X)*(4+(100-c.Hug)*.15) end
end
local function spot(c,name,index)
    local p=anchor(c);if not p then return end
    local cfg=towerConfig(name)
    local box,size=cfg.Model:GetBoundingBox()
    local offset=math.max(cfg.Model:GetPivot().Position.Y-(box.Position.Y-size.Y/2),0)
    if not c.Stack then
        local spacing=cfg.HitboxSize and math.max(cfg.HitboxSize.X,cfg.HitboxSize.Z)+1 or 5
        local n=index-1;p+=Vector3.new(n%3*spacing,0,math.floor(n/3)*spacing)
    end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.Game.TowerArea}
    local hit=workspace:Raycast(Vector3.new(p.X,500,p.Z),Vector3.new(0,-2000,0),params)
    if hit then return CFrame.new(hit.Position+Vector3.new(0,offset,0)) end
end
local function choosePlace(candidates)
    table.sort(candidates,function(a,b)
        if S.PlaceMode=='One of each first' and a.count~=b.count then return a.count<b.count end
        return a.rank<b.rank
    end)
    return candidates[1]
end
local function chooseUpgrade(candidates)
    table.sort(candidates,function(a,b)
        if S.UpgradeMode=='Cheapest first' and a.cost~=b.cost then return a.cost<b.cost end
        if S.UpgradeMode=='Lowest level first' and a.level~=b.level then return a.level<b.level end
        if a.rank~=b.rank then return a.rank<b.rank end
        return a.id<b.id
    end)
    return candidates[1]
end
local function isFarm(cfg) return cfg.Tags and cfg.Tags.Farm~=nil end
local function autoTick()
    local owned,counts={},{}
    for id,t in pairs(towers()) do if own(t) then table.insert(owned,{id=id,t=t});counts[t.UnitId]=(counts[t.UnitId] or 0)+1 end end
    local candidates={}
    if S.AutoPlace and #owned<15 then for rank,slot in ipairs(S.PlaceOrder) do
        local c=S.Slots[slot];local name,uid=unit(slot)
        if c.On and name and (counts[uid] or 0)<math.min(c.Max,towerConfig(name).PlacementLimit or 15) and anchor(c) then table.insert(candidates,{rank=rank,slot=slot,name=name,uid=uid,c=c,count=counts[uid] or 0}) end
    end end
    if S.AutoUpgrade and S.FocusFarm then
        local farms={}
        local ranks={};for rank,slot in ipairs(S.UpgradeOrder) do local _,uid=unit(slot);if uid then ranks[uid]=rank end end
        for _,entry in ipairs(owned) do
            local t=entry.t;local cost=price(t.Name,(t.Level or 1)+1,t.UnitId)
            if cost and isFarm(towerConfig(t.Name)) then table.insert(farms,{id=entry.id,t=t,cost=cost,level=t.Level or 1,rank=ranks[t.UnitId] or 6}) end
        end
        local farm=chooseUpgrade(farms)
        if farm then
            if money()>=farm.cost then note('Focus farm: upgrade '..farm.t.Name);return upgrade(farm.id,farm.level+1) end
            note('Focus farm: saving $'..farm.cost..' for '..farm.t.Name);return
        end
    end
    local pick=choosePlace(candidates)
    if pick and money()>=price(pick.name,1,pick.uid) then
        local position=spot(pick.c,pick.name,pick.count+1)
        if position then
            local baseline={};for id in pairs(towers()) do baseline[id]=true end
            note('Place slot '..pick.slot..': '..pick.name)
            return place(pick.name,pick.uid,position,function() return confirmedAdd(pick.name,position.Position,{},baseline) end)
        end
    end
    if S.AutoUpgrade and not (S.AutoPlace and S.PlaceBeforeUpgrade and pick) then
        local ranks={};for rank,slot in ipairs(S.UpgradeOrder) do local _,uid=unit(slot);if uid then ranks[uid]=rank end end
        local upgrades={}
        for _,entry in ipairs(owned) do local t=entry.t;local cost=price(t.Name,(t.Level or 1)+1,t.UnitId)
            if cost and ranks[t.UnitId] then table.insert(upgrades,{id=entry.id,t=t,cost=cost,level=t.Level or 1,rank=ranks[t.UnitId]}) end
        end
        local nextUpgrade=chooseUpgrade(upgrades)
        if nextUpgrade and money()>=nextUpgrade.cost then note('Upgrade '..nextUpgrade.t.Name);return upgrade(nextUpgrade.id,nextUpgrade.level+1) end
    end
    note(string.format('Wave %s | $%d | Units %d/15%s',workspace:GetAttribute('Wave') or 0,money(),#owned,pick and ' | Waiting for placement cash' or ''))
end
local selected,assignment,refresh
local function saveRecording()
    if not A.data then return end
    writefile(macroPath(S.MacroName),H:JSONEncode(validate(A.data)))
end
local function stopRecord()
    saveRecording();A.recording=false
    if A.data then note('Saved '..S.MacroName..': '..#A.data.actions..' steps',true) end
    A.data=nil
    if refresh then refresh() end
end
local function append(a)
    if not A.recording then return end
    if #A.data.actions>=5000 then stopRecord();Library.Options.RecordMacro:SetValue(false);return end
    a.wave=a.wave or math.max(workspace:GetAttribute('Wave') or 0,0)
    table.insert(A.data.actions,a);saveRecording();note('Recording '..S.MacroName..': '..#A.data.actions..' steps',true)
end
local function recordAdd(t,wave)
    local id=key(t);if A.recordRefs[id] then return end
    A.recordRefs[id]=true;append({kind='add',key=id,name=t.Name,cf={cf(t):GetComponents()},wave=wave})
end
local function beginRecord()
    assert(match() and map(),'Enter a match first')
    assert(not A.pending,'Wait for the current action confirmation')
    Library.Options.PlayMacro:SetValue(false);A.run=nil;A.recordRefs={}
    A.data={version=1,map=map(),mode=mode() or S.Difficulty,actions={}};A.recording=true
    for _,t in pairs(towers()) do if own(t) then recordAdd(t,0);for level=2,t.Level or 1 do append({kind='upgrade',key=key(t),level=level,wave=0}) end end end
    saveRecording();note('Recording confirmed actions; existing towers included',true)
end
local function resolveMacro()
    local assigned=S.AutoSwap and S.MacroSets[tostring(map())..'|'..tostring(mode() or S.Difficulty)]
    if type(assigned)=='string' and assigned~='' then return safeName(assigned) end
    if S.PlayMacro then return S.MacroName end
end
local function macroTick(name)
    if not A.run or A.run.name~=name then
        local data=loadMacro(name)
        if data.map~=map() then note('Macro map differs; Auto Play handles this map',true);return false end
        assert(data.mode==(mode() or S.Difficulty),'Macro difficulty differs')
        A.run={name=name,data=data,index=1,refs={}}
    end
    local run=A.run;local a=run.data.actions[run.index]
    if not a then note('Macro finished; armed for next matching round',true);return true end
    if S.MacroWaitWave and (workspace:GetAttribute('Wave') or 0)<a.wave then note('Waiting for wave '..a.wave,true);return true end
    local function advance() run.index+=1;note(string.format('Playing %s: %d/%d',name,run.index-1,#run.data.actions),true);return true end
    if a.kind=='add' then
        local used={};for _,id in pairs(run.refs) do used[id]=true end
        local position=CFrame.new(table.unpack(a.cf));local existing=confirmedAdd(a.name,position.Position,used)
        if existing then run.refs[a.key]=existing;advance();return true end
        local uid
        for slot=1,5 do local n,u=unit(slot);if n==a.name then uid=u;break end end
        assert(uid,'Equip '..a.name..' for this macro')
        if money()<price(a.name,1,uid) then note('Waiting for placement cash: '..a.name,true);return true end
        place(a.name,uid,position,function()
            local id=confirmedAdd(a.name,position.Position,used)
            if id then run.refs[a.key]=id;return advance() end
        end)
    elseif a.kind=='skip' then
        if (workspace:GetAttribute('Wave') or 0)>a.wave then advance()
        elseif workspace:GetAttribute('CanSkip') then send(RE.WaveSkip,nil,function() return (workspace:GetAttribute('Wave') or 0)>a.wave or not workspace:GetAttribute('CanSkip') end,'Macro skip');A.pending.after=advance end
    else
        local id=run.refs[a.key];assert(id,'Missing macro tower reference')
        local t=towers()[id]
        if a.kind=='sell' and not t then advance();return true end
        assert(t,'Macro tower disappeared')
        if a.kind=='upgrade' then
            if t.Level>=a.level then advance();return true end
            local cost=price(t.Name,t.Level+1,t.UnitId);assert(cost,'Invalid upgrade level')
            if money()<cost then note('Waiting for upgrade cash',true);return true end
            upgrade(id,t.Level+1)
        elseif a.kind=='sell' then send(RE.TowerSell,{Id=id},function() return not towers()[id] end,'Macro sell');A.pending.after=advance
        elseif a.kind=='target' then
            if t.TargetMode==a.target then advance();return true end
            local oldMode=t.TargetMode
            send(RE.TowerTarget,{Id=id},function() local v=towers()[id];return v and v.TargetMode~=oldMode end,'Macro target')
        end
    end
    return true
end
local schedule=Auto:AddSection('Scheduling')
toggle(schedule,'AutoPlace','Auto Place',S,'AutoPlace')
toggle(schedule,'AutoUpgrade','Auto Upgrade',S,'AutoUpgrade')
toggle(schedule,'FocusFarm','Focus farm upgrades',S,'FocusFarm',nil,'Upgrade placed farms first; reserve cash until they are maxed. Requires Auto Upgrade.')
toggle(schedule,'PlaceBeforeUpgrade','Place before upgrading',S,'PlaceBeforeUpgrade')
toggle(schedule,'ShowPoint','Show slot anchor points',S,'ShowPoint')
local speedStatus=Join:AddParagraph({Title='Game speed status',Content='Waiting for match'})
local function syncSpeed(force)
    if not match() then speedStatus:SetDesc('Saved x'..S.Speed..' for next match');return end
    local actual=workspace:GetAttribute('GameSpeed')
    local gui=P.PlayerGui:FindFirstChild('GameUI')
    local speeds=gui and gui:FindFirstChild('GameSpeeds',true)
    local option=speeds and speeds:FindFirstChild(tostring(S.Speed))
    local troop=option and option:FindFirstChild('TroopFrame')
    local button=troop and troop:FindFirstChild('InteractiveButton')
    if speeds and actual then
        for _,item in ipairs(speeds:GetChildren()) do
            local frame=item:FindFirstChild('TroopFrame')
            local background=frame and frame:FindFirstChild('Background')
            local shadow=background and background:FindFirstChild('UIShadow')
            if shadow then shadow.Color=tonumber(item.Name)==actual and Color3.fromRGB(8,138,12) or Color3.new(0,0,0) end
        end
    end
    if actual==S.Speed then speedStatus:SetDesc('Active x'..actual);return end
    if not actual or A.speedRejected==S.Speed or not force and os.clock()<(A.nextSpeedAt or 0) then return end
    A.nextSpeedAt=os.clock()+2
    if button and firesignal then
        firesignal(button.Activated)
        speedStatus:SetDesc('Selected x'..S.Speed..' in game; checking server')
        if S.Speed==2 then task.delay(.5,function()
            if A.alive and S.Speed==2 and workspace:GetAttribute('GameSpeed')~=2 then
                A.speedRejected=2;speedStatus:SetDesc('x2 rejected: requires 200 wins or X2 Speed gamepass')
            end
        end) end
        return
    end
    local ok,accepted=pcall(function() return RF.ChangeSpeed:InvokeServer(S.Speed) end)
    if not ok then speedStatus:SetDesc('Speed request failed; retrying');return end
    if not accepted then
        A.speedRejected=S.Speed
        speedStatus:SetDesc(S.Speed==2 and 'x2 rejected: requires 200 wins or X2 Speed gamepass' or 'Speed rejected by server')
    else speedStatus:SetDesc('Requested x'..S.Speed..'; waiting for server') end
end
Join:AddDropdown('Speed',{Title='Game speed',Values={'x1','x1.5','x2'},Default='x'..S.Speed,Callback=function(v)
    S.Speed=tonumber(v:sub(2));A.speedRejected=nil;save();syncSpeed(true)
end})
Join:AddDropdown('Difficulty',{Title='Vote difficulty',Values={'Easy','Normal','Hard','Insane','Nightmare'},Default=S.Difficulty,Callback=function(v) S.Difficulty=v;save() end})
toggle(Join,'AutoStart','Auto vote difficulty',S,'AutoStart')
local function syncSkip()
    if not match() or not S.AutoSkip and not A.skipManaged then return end
    local gui=P.PlayerGui:FindFirstChild('GameUI')
    local stats=gui and gui:FindFirstChild('Stats')
    local row=stats and stats:FindFirstChild('AutoSkip')
    local button=row and row:FindFirstChild('Button')
    local enabled=button and button:FindFirstChild('UI2')
    if not enabled then return end
    if enabled.Visible~=S.AutoSkip and os.clock()>=(A.nextSkipClick or 0) then
        A.nextSkipClick=os.clock()+1
        if firesignal then firesignal(button.Activated)
        elseif getconnections then for _,c in ipairs(getconnections(button.Activated)) do if c.Enabled and c.Fire then c:Fire() end end
        else note('Executor cannot activate the native Auto Skip button');return end
    end
    A.skipManaged=S.AutoSkip
    return S.AutoSkip and (enabled.Visible or os.clock()<(A.nextSkipClick or 0))
end
toggle(Join,'AutoSkip','Auto skip waves',S,'AutoSkip',function() A.skipManaged=true;syncSkip() end)
toggle(Join,'Repeat','Replay after match',S,'Repeat')
local priorities=Auto:AddSection('Placement & upgrade order')
priorities:AddDropdown('PlaceMode',{Title='Placement mode',Values={'One of each first','Fill slot before next'},Default=S.PlaceMode,Callback=function(v) S.PlaceMode=v;save() end})
priorities:AddDropdown('UpgradeMode',{Title='Upgrade mode',Values={'Cheapest first','Priority order','Lowest level first'},Default=S.UpgradeMode,Callback=function(v) S.UpgradeMode=v;save() end})
local priorityViews={}
for _,entry in ipairs({{'PlaceOrder','Placement priority'},{'UpgradeOrder','Upgrade priority'}}) do
    local field=entry[1]
    local element=priorities:AddParagraph({Title=entry[2],Content='Top row has the highest priority. Use ↑ / ↓ to reorder slots.'})
    element.Value=S[field];Library.Options[field]=element
    local layout=Instance.new('UIListLayout');layout.Padding=UDim.new(0,6);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=element.Frame
    local list=Instance.new('Frame');list.BackgroundTransparency=1;list.Size=UDim2.new(1,0,0,0);list.AutomaticSize=Enum.AutomaticSize.Y;list.LayoutOrder=1;list.Parent=element.Frame
    local rowLayout=Instance.new('UIListLayout');rowLayout.Padding=UDim.new(0,4);rowLayout.SortOrder=Enum.SortOrder.LayoutOrder;rowLayout.Parent=list
    local view={labels={},field=field}
    local function render()
        for _,child in ipairs(list:GetChildren()) do if child:IsA('Frame') then child:Destroy() end end
        view.labels={}
        for rank,slot in ipairs(S[field]) do
            local position=rank
            local row=Instance.new('Frame');row.Size=UDim2.new(1,0,0,28);row.LayoutOrder=rank;row.BackgroundColor3=Color3.fromRGB(24,21,35);row.BorderSizePixel=0;row.Parent=list
            local label=Instance.new('TextLabel');label.BackgroundTransparency=1;label.Position=UDim2.fromOffset(8,0);label.Size=UDim2.new(1,-76,1,0);label.Font=Enum.Font.Gotham;label.TextSize=12;label.TextXAlignment=Enum.TextXAlignment.Left;label.TextTruncate=Enum.TextTruncate.AtEnd;label.TextColor3=Color3.fromRGB(240,236,250);label.Parent=row
            view.labels[rank]=label
            local name=unit(slot);label.Text=rank..'. Slot '..slot..' — '..(name or 'empty')
            for _,step in ipairs({-1,1}) do
                local direction=step
                local arrow=Instance.new('TextButton');arrow.Size=UDim2.fromOffset(26,22);arrow.AnchorPoint=Vector2.new(1,.5);arrow.Position=UDim2.new(1,step<0 and -34 or -4,.5,0);arrow.BackgroundColor3=Color3.fromRGB(61,47,88);arrow.TextColor3=label.TextColor3;arrow.Text=step<0 and '↑' or '↓';arrow.TextSize=16;arrow.BorderSizePixel=0;arrow.Parent=row
                arrow.Activated:Connect(function()
                    local target=position+direction;if target<1 or target>5 then return end
                    S[field][position],S[field][target]=S[field][target],S[field][position];element.Value=S[field];save();render()
                end)
            end
        end
    end
    function element:SetValue(value) S[field]=order(value);self.Value=S[field];save();render() end
    render();table.insert(priorityViews,view)
end
for i=1,5 do
    local slot=i;local c=S.Slots[slot];local n=unit(slot)
    local section=Auto:AddSection('Slot '..slot..' — '..(n or 'empty'))
    toggle(section,'Slot'..slot..'On','Enable slot '..slot,c,'On')
    section:AddDropdown('Slot'..slot..'Mode',{Title='Anchor mode',Values={'Enemy path','My position'},Default=c.Mode,Callback=function(v) c.Mode=v;save() end})
    for _,entry in ipairs({{'Percent','Path position (%)',100},{'Hug','Path hug (%)',100},{'Max','Maximum copies',15}}) do
        local k=entry[1];section:AddSlider('Slot'..slot..k,{Title=entry[2],Min=0,Max=entry[3],Default=c[k],Rounding=0,Callback=function(v) c[k]=v;save() end})
    end
    toggle(section,'Slot'..slot..'Stack','Stack copies at the anchor',c,'Stack')
    section:AddButton({Title='Save my position',Callback=function()
        assert(match() and map(),'Enter a match first')
        local root=assert(P.Character and P.Character:FindFirstChild('HumanoidRootPart'),'Character not ready')
        c.Positions[map()]={root.Position.X,root.Position.Z};save();note('Saved slot '..slot..' position for '..map())
    end})
end
local controls=Macro:AddSection('Record / Play')
controls:AddInput('MacroName',{Title='Macro name',Default=S.MacroName,Finished=true,Callback=function(v)
    assert(not A.recording and not A.pending,'Stop recording and wait for the pending action before renaming');S.MacroName=safeName(v);A.run=nil;save()
end})
selected=controls:AddDropdown('SavedMacro',{Title='Saved macro',Values=names(),Default=S.MacroName,Callback=function(v)
    assert(not A.recording and not A.pending,'Stop recording and wait for the pending action before changing files');S.MacroName=safeName(v);A.run=nil;save()
end})
refresh=function() selected:SetValues(names());if assignment then local choices={'<Use selected macro>'};for _,n in ipairs(names()) do table.insert(choices,n) end;assignment:SetValues(choices) end end
controls:AddButton({Title='Refresh saved macros',Callback=refresh})
toggle(controls,'RecordMacro','Record macro',A,'recording',function(v)
    if v then
        local ok,err=pcall(beginRecord)
        if not ok then A.recording=false;Library.Options.RecordMacro:SetValue(false);error(err) end
    else stopRecord() end
end)
toggle(controls,'MacroWaitWave','Wait for recorded wave',S,'MacroWaitWave')
toggle(controls,'PlayMacro','Play macro',S,'PlayMacro',function(v)
    if v then Library.Options.RecordMacro:SetValue(false) end
    A.run=nil;A.pending=nil
end)
controls:AddButton({Title='Import previous CTD_Macro.json',Callback=function()
    assert(not A.recording,'Stop recording first')
    local data=validate(readJSON('CTD_Macro.json',{}));writefile(macroPath(S.MacroName),H:JSONEncode(data));refresh();note('Imported '..#data.actions..' steps',true)
end})
local swap=Macro:AddSection('Automatic Swap Macro')
toggle(swap,'AutoSwap','Use macro assigned to map / difficulty',S,'AutoSwap',function() A.run=nil end)
local assignMap,assignMode,assignName='Toilet City','Easy','<Use selected macro>'
swap:AddDropdown('AssignMap',{Title='Map',Values={'Toilet City','Desert','Cameraman HQ'},Default=assignMap,Callback=function(v) assignMap=v end})
swap:AddDropdown('AssignMode',{Title='Difficulty',Values={'Easy','Normal','Hard','Insane','Nightmare'},Default=assignMode,Callback=function(v) assignMode=v end})
local choices={'<Use selected macro>'};for _,n in ipairs(names()) do table.insert(choices,n) end
assignment=swap:AddDropdown('AssignMacro',{Title='Assigned macro',Values=choices,Default=assignName,Callback=function(v) assignName=v end})
swap:AddButton({Title='Save assignment',Callback=function()
    if assignName~='<Use selected macro>' then local data=loadMacro(assignName);assert(data.map==assignMap and data.mode==assignMode,'Macro map/difficulty does not match assignment') end
    S.MacroSets[assignMap..'|'..assignMode]=assignName~='<Use selected macro>' and assignName or nil;save();A.run=nil;note('Assignment saved for '..assignMap..' / '..assignMode,true)
end})
local function stop()
    if A.recording then stopRecord() end
    for _,id in ipairs({'AutoJoin','AutoPlace','AutoUpgrade','AutoStart','AutoSkip','Repeat','PlayMacro','AutoSwap','WebhookEnabled','AutoSummon','EventClaimQuests','EventClaimTiers','EventAutoBuy'}) do Library.Options[id]:SetValue(false) end
    A.claimEventOnce=false
    A.pending=nil;A.run=nil;note('Stopped')
end
local originalDestroy=Library.Destroy
function Library:Destroy()
    if not A.alive then return end
    if A.recording then stopRecord() end
    A.alive=false;A.pending=nil
    for _,c in ipairs(A.connections) do c:Disconnect() end
    markers:Destroy();unitPanel:Destroy();originalDestroy(self)
end
A.Stop=function() Library:Destroy() end
local function queue()
    if A.queued or not A.alive then return end
    assert(queue_on_teleport,'Executor cannot resume after teleport')
    queue_on_teleport("repeat task.wait() until game:IsLoaded();loadstring(readfile('CTD_PlayMacro.lua'))()")
    A.queued=true
end
connect(P.OnTeleport,function()
    if A.recording then stopRecord() end
    if A.alive then local ok,err=pcall(queue);if not ok then note(tostring(err)) end end
end)
local interface=Settings:AddSection('Theme Settings')
interface:AddDropdown('Theme',{Title='Theme',Values=Library.Themes,Default=S.Theme,Callback=function(v) S.Theme=v;Library:SetTheme(v);save() end})
toggle(interface,'Transparency','Transparency',S,'Transparency',function(v) Library:ToggleTransparency(v) end)
Library:ToggleTransparency(S.Transparency)
interface:AddSlider('MascotAlpha',{Title='Background image transparency',Min=0,Max=1,Default=S.MascotTransparency,Rounding=2,Callback=function(v) S.MascotTransparency=v;Library:SetMascotTransparency(v);save() end})
Library.MinimizeKeybind=interface:AddKeybind('MinimizeKey',{Title='Show / Hide Key',Default=S.MinimizeKeyName,ChangedCallback=function(k) S.MinimizeKeyName=k.Name;save() end})
toggle(Settings,'AntiAFK','Anti-AFK',S,'AntiAFK')
connect(P.Idled,function()
    if not A.alive or not S.AntiAFK then return end
    local ok,err=pcall(function() local user=game:GetService('VirtualUser');user:CaptureController();user:ClickButton2(Vector2.new(0,0),workspace.CurrentCamera.CFrame) end)
    if not ok then note('Anti-AFK unavailable: '..tostring(err)) end
end)
Settings:AddButton({Title='STOP ALL',Callback=stop})
Settings:AddButton({Title='Unload UI',Callback=A.Stop})
local webhook=Webhook:AddSection('Discord Webhook')
local webhookStatus=webhook:AddParagraph({Title='Webhook status',Content='Enter a Discord webhook URL, then enable notifications'})
local function webhookURL(url)
    local host,path=tostring(url):match('^https://([%w%.]+)/api/(.+)$')
    if host~='discord.com' and host~='discordapp.com' and host~='ptb.discord.com' and host~='canary.discord.com' then return end
    if path:match('^webhooks/%d+/[%w_%-]+$') or path:match('^v%d+/webhooks/%d+/[%w_%-]+$') then return url..'?wait=true' end
end
local function webhookPayload(result)
    return {username='Cameraman TD',allowed_mentions={parse={}},embeds={{title=result.test and 'Webhook test' or result.won and 'Victory' or 'Defeat',color=result.test and 8673520 or result.won and 3066993 or 15158332,
        fields={{name='Map',value=tostring(result.map or 'Lobby'),inline=true},{name='Difficulty',value=tostring(result.mode or '-'),inline=true},{name='Wave',value=tostring(result.wave or 0),inline=true},{name='Time',value=tostring(result.time or '00:00'),inline=true}},footer={text='Cameraman TD | Auto Play'}}}}
end
local function postWebhook(url,payload,transport)
    local endpoint=assert(webhookURL(url),'Enter a valid Discord webhook URL')
    assert(type(transport)=='function','Executor HTTP request is unavailable')
    local ok,response=pcall(transport,{Url=endpoint,Method='POST',Headers={['Content-Type']='application/json'},Body=H:JSONEncode(payload)})
    if not ok or type(response)~='table' then return false,'Network request failed; not resent to avoid duplicates' end
    local code=tonumber(response.StatusCode)
    if code and code>=200 and code<300 then return true,'Message delivered' end
    return false,'Discord rejected the request (HTTP '..tostring(code or '?')..')'
end
local function sendWebhook(result)
    if A.webhookBusy then return end
    if not webhookURL(S.WebhookURL) then webhookStatus:SetDesc('Enter a valid Discord webhook URL');return end
    local transport=request or http_request or syn and syn.request
    if type(transport)~='function' then webhookStatus:SetDesc('Executor HTTP request is unavailable');return end
    local url,payload=S.WebhookURL,webhookPayload(result)
    A.webhookBusy=true
    task.spawn(function()
        local ok,text=postWebhook(url,payload,transport)
        A.webhookBusy=false
        if A.alive then webhookStatus:SetDesc((ok and 'Sent: ' or 'Failed: ')..text);print('[CTD Webhook]',ok,text) end
    end)
end
webhook:AddInput('WebhookURL',{Title='Webhook URL',Placeholder='https://discord.com/api/webhooks/...',Default=S.WebhookURL,MaxLength=300,Finished=true,Callback=function(v)
    v=v:match('^%s*(.-)%s*$');assert(v=='' or webhookURL(v),'Enter a valid Discord webhook URL');S.WebhookURL=v;save()
end})
toggle(webhook,'WebhookEnabled','Notify match results',S,'WebhookEnabled',nil,'Send one result per round to the configured Discord channel.')
A.TestWebhook=function() sendWebhook({test=true,map=map(),mode=mode(),wave=workspace:GetAttribute('Wave'),time=workspace:GetAttribute('TotalTime')}) end
webhook:AddButton({Title='Send test notification',Callback=A.TestWebhook})
E.CTDWebhookState=E.CTDWebhookState or {}
local webhookState=E.CTDWebhookState
if webhookState.job~=game.JobId then webhookState.job=game.JobId;webhookState.round=0;webhookState.over=false;webhookState.sent=false end
local function webhookTick()
    if not finished() then
        if webhookState.over then webhookState.round+=1;webhookState.sent=false end
        webhookState.over=false;return
    end
    webhookState.over=true
    if S.WebhookEnabled and not webhookState.sent and webhookURL(S.WebhookURL) and not A.webhookBusy then
        webhookState.sent=true
        sendWebhook({won=workspace:GetAttribute('Message')=='You Won!',map=map(),mode=mode(),wave=workspace:GetAttribute('Wave'),time=workspace:GetAttribute('TotalTime')})
    end
end
if match() then
    connect(RE.TowerAdd.OnClientEvent,function(t) if A.recording and not finished() and own(t) then recordAdd(t) end end)
    connect(RE.TowerUpgrade.OnClientEvent,function(t) if A.recording and not finished() and A.recordRefs[key(t)] then append({kind='upgrade',key=key(t),level=t.Level}) end end)
    connect(RE.TowerRemove.OnClientEvent,function(t) if A.recording and not finished() and A.recordRefs[key(t)] then append({kind='sell',key=key(t)});A.recordRefs[key(t)]=nil end end)
    connect(RE.TowerTarget.OnClientEvent,function(t) if A.recording and not finished() and A.recordRefs[key(t)] then append({kind='target',key=key(t),target=t.TargetMode}) end end)
end
connect(RE.Notificate.OnClientEvent,function(text) if type(text)=='string' then note(text) end end)
local summonStatus=Summon:AddParagraph({Title='Summon status',Content=S.LobbyPurchasePending and 'Previous purchase was not confirmed. Check inventory before enabling purchases again.' or 'Lobby only. Uses the game Auto Sell settings.'})
local summonBanner=Summon:AddDropdown('SummonBanner',{Title='Banner',Values={S.SummonBanner},Default=S.SummonBanner,Callback=function(v) S.SummonBanner=v;save() end})
Summon:AddDropdown('SummonCount',{Title='Summon amount',Values={'1','10'},Default=tostring(S.SummonCount),Callback=function(v) S.SummonCount=tonumber(v);save() end})
Summon:AddInput('SummonReserve',{Title='Keep at least this much money',Default=tostring(S.SummonReserve),Numeric=true,Finished=true,Callback=function(v) local n=tonumber(v);assert(n and n>=0 and n<1e12,'Invalid reserve');S.SummonReserve=math.floor(n);save() end})
Summon:AddInput('SummonLimit',{Title='Maximum pulls (0 = unlimited)',Default=tostring(S.SummonLimit),Numeric=true,Finished=true,Callback=function(v) local n=tonumber(v);assert(n and n>=0 and n<=100000,'Invalid pull limit');S.SummonLimit=math.floor(n);save() end})
toggle(Summon,'AutoSummon','Auto Summon',S,'AutoSummon',function(v) if v then assert(not A.lobbyBusy,'Wait for the current request');S.LobbyPurchasePending=false end end)
Summon:AddButton({Title='Reset summon counter',Callback=function() assert(not A.lobbyBusy,'Wait for the current request');S.SummonProgress=0;save();summonStatus:SetDesc('Counter reset') end})
local eventStatus=Event:AddParagraph({Title='Halloween Event / Battlepass',Content='Waiting for lobby data'})
local missionStatus=Event:AddParagraph({Title='Event missions',Content='Waiting for mission data'})
toggle(Event,'EventClaimQuests','Auto claim completed missions',S,'EventClaimQuests')
toggle(Event,'EventClaimTiers','Auto claim unlocked tiers',S,'EventClaimTiers',nil,'Claims free rewards and premium rewards only if premium is already owned.')
Event:AddButton({Title='Claim all available event rewards',Callback=function() assert(not match(),'Return to the lobby first');A.claimEventOnce=true;A.nextLobbyAt=0 end})
local shop=Event:AddSection('Event Shop')
local eventBuyStatus=shop:AddParagraph({Title='Auto Buy status',Content='Candy purchases only. Select an item and set your reserve / limit.'})
local eventItem=shop:AddDropdown('EventBuyItem',{Title='Event item',Values={S.EventBuyItem},Default=S.EventBuyItem,Callback=function(v) S.EventBuyItem=v;save() end})
shop:AddDropdown('EventBuyCount',{Title='Quantity per purchase',Values={'1','3','10'},Default=tostring(S.EventBuyCount),Callback=function(v) S.EventBuyCount=tonumber(v);save() end})
for _,entry in ipairs({{'EventBuyReserve','Keep at least this much Candy'},{'EventBuyLimit','Maximum crates (0 = unlimited)'}}) do
    local field=entry[1]
    shop:AddInput(field,{Title=entry[2],Default=tostring(S[field]),Numeric=true,Finished=true,Callback=function(v) local n=tonumber(v);assert(n and n>=0 and n<=1000000,'Invalid amount');S[field]=math.floor(n);save() end})
end
toggle(shop,'EventAutoBuy','Auto Buy Event',S,'EventAutoBuy',function(v) if v then assert(not A.lobbyBusy,'Wait for the current request');S.LobbyPurchasePending=false end end)
shop:AddButton({Title='Reset event purchase counter',Callback=function() assert(not A.lobbyBusy,'Wait for the current request');S.EventBuyProgress=0;save();eventBuyStatus:SetDesc('Purchase counter reset') end})
local function claimableQuest(q) return type(q)=='table' and type(q.Id)=='string' and not q.RewardClaimed and (q.Completed==true or q.State=='Completed') end
local function summonCost(base,count) return base*(count==10 and 9 or 1) end
local function withinBudget(wallet,reserve,cost,progress,limit,count)
    return wallet-cost>=reserve and (limit==0 or progress+count<=limit)
end
local function lobbyTick()
    if match() or A.lobbyBusy or os.clock()<(A.nextLobbyAt or 0) then return end
    A.nextLobbyAt=os.clock()+2
    local data=require(M.Client.Replication).GetCurrentReplica().Data
    local cfg=require(M.Configs.Config)
    local banners={};local banner
    for _,b in ipairs(cfg.GameSettings.SummonCrates or {}) do table.insert(banners,b.Name);if b.Name==S.SummonBanner then banner=b end end
    if not A.bannersLoaded and #banners>0 then summonBanner:SetValues(banners);A.bannersLoaded=true end
    local eventItems={};local eventProduct
    for _,item in ipairs(cfg.GameSettings.ShopCrates or {}) do
        if not item.IsRobux and type(item.Price)=='table' and item.Price.Type=='Candy' and type(item.Price.Amount)=='number' and item.Price.Amount>0 then
            table.insert(eventItems,item.Name);if item.Name==S.EventBuyItem then eventProduct=item end
        end
    end
    if not A.eventItemsLoaded and #eventItems>0 then eventItem:SetValues(eventItems);A.eventItemsLoaded=true end
    local bp=data.Battlepass or {};local missions=bp.PassQuests and bp.PassQuests.Quests or {}
    local lines={}
    for _,q in ipairs(missions) do table.insert(lines,string.format('%s: %s/%s [%s]',q.Name or q.Id or 'Mission',tostring(q.CurrentProgress or 0),tostring(q.Progress or 0),q.RewardClaimed and 'Claimed' or claimableQuest(q) and 'Ready' or 'In progress')) end
    eventStatus:SetDesc(string.format('Candy %s | Tier %s | EXP %s | Premium %s',tostring(data.Candy or 0),tostring(bp.CurrentTier or 0),tostring(bp.EXP or 0),bp.Premium and 'Owned' or 'Not owned'))
    missionStatus:SetDesc(#lines>0 and table.concat(lines,'\n') or 'No active event missions')
    local action,arg,premium
    if S.EventClaimQuests or A.claimEventOnce then for _,q in ipairs(missions) do if claimableQuest(q) then action='CollectPassQuest';arg=q.Id;break end end end
    if not action and (S.EventClaimTiers or A.claimEventOnce) then
        local claimed=bp.ClaimedTiers or {};local free=claimed.Default or {};local paid=claimed.Premium or {}
        for _,tier in ipairs(cfg.Battlepass and cfg.Battlepass.Tiers or {}) do
            local n=tier.TierNumber
            if n==(bp.NextTier or (bp.CurrentTier or 0)+1) and (bp.EXP or 0)>=(tier.TierEXP or math.huge) and not free[n] then action='ClaimTier';arg=n;premium=false;break end
            if bp.Premium and n<=(bp.CurrentTier or 0) and not paid[n] then action='ClaimTier';arg=n;premium=true;break end
        end
    end
    if not action then A.claimEventOnce=false end
    local actionKey=action and action..':'..tostring(arg)..':'..tostring(premium)
    if actionKey and A.failedEvent and A.failedEvent[actionKey] and os.clock()<A.failedEvent[actionKey] then action=nil end
    if action then
        A.lobbyBusy=true
        task.spawn(function()
            local ok,result=pcall(function()
                local remote=assert(RF:FindFirstChild(action),'Event remote unavailable')
                if action=='ClaimTier' then return remote:InvokeServer(arg,premium) end
                return remote:InvokeServer(arg)
            end)
            A.lobbyBusy=false
            if not A.alive then return end
            if ok and result then eventStatus:SetDesc('Claimed '..tostring(arg));print('[CTD Event] claimed',arg)
            else A.failedEvent=A.failedEvent or {};A.failedEvent[actionKey]=os.clock()+30;eventStatus:SetDesc('Claim rejected; retry paused for 30 seconds') end
        end)
        return
    end
    if S.EventAutoBuy then
        local count=table.find({1,3,10},S.EventBuyCount) and S.EventBuyCount or 1
        local progress=math.max(tonumber(S.EventBuyProgress) or 0,0)
        local limit=math.max(tonumber(S.EventBuyLimit) or 0,0)
        local reserve=math.max(tonumber(S.EventBuyReserve) or 0,0)
        local candy=tonumber(data.Candy) or 0
        if not eventProduct then eventBuyStatus:SetDesc('Selected Candy item is unavailable')
        elseif limit>0 and progress+count>limit then Library.Options.EventAutoBuy:SetValue(false);eventBuyStatus:SetDesc('Purchase limit reached: '..progress..'/'..limit)
        else
            local cost=eventProduct.Price.Amount*count
            if not withinBudget(candy,reserve,cost,progress,limit,count) then eventBuyStatus:SetDesc('Waiting for '..cost..' Candy + reserve '..reserve..' (have '..candy..')')
            else
                local product=eventProduct.Name
                A.lobbyBusy=true;S.LobbyPurchasePending=true;save();eventBuyStatus:SetDesc('Buying '..count..' '..product..' for '..cost..' Candy')
                task.spawn(function()
                    local ok=pcall(function() assert(RE:FindFirstChild('BuyCrate'),'Event shop unavailable'):FireServer(product,count) end)
                    local deadline=os.clock()+15
                    while ok and A.alive and (tonumber(data.Candy) or 0)>candy-cost and os.clock()<deadline do task.wait(.2) end
                    A.lobbyBusy=false
                    if ok and (tonumber(data.Candy) or 0)<=candy-cost then
                        S.EventBuyProgress=progress+count;S.LobbyPurchasePending=false;save()
                        if A.alive then eventBuyStatus:SetDesc('Bought '..S.EventBuyProgress..(limit>0 and '/'..limit or '')..' crates');print('[CTD Event Shop] bought',product,count) end
                    elseif A.alive then Library.Options.EventAutoBuy:SetValue(false);eventBuyStatus:SetDesc('Purchase not confirmed; stopped to avoid spending twice') end
                end)
                return
            end
        end
    end
    if not S.AutoSummon then return end
    if not banner or type(banner.SummonPrice)~='number' then summonStatus:SetDesc('Selected banner unavailable');return end
    local count=S.SummonCount==10 and 10 or 1
    local reserve=math.max(tonumber(S.SummonReserve) or 0,0);local limit=math.max(tonumber(S.SummonLimit) or 0,0);local progress=math.max(tonumber(S.SummonProgress) or 0,0)
    local cost=summonCost(banner.SummonPrice,count)
    if limit>0 and progress+count>limit then Library.Options.AutoSummon:SetValue(false);summonStatus:SetDesc('Pull limit reached: '..progress..'/'..limit);return end
    if not withinBudget(tonumber(data.Money) or 0,reserve,cost,progress,limit,count) then summonStatus:SetDesc('Waiting for $'..cost..' + reserve $'..reserve);return end
    local total=0;for _ in pairs(data.Towers or {}) do total+=1 end
    if total+count>(tonumber(data.InventorySpace) or 500) then Library.Options.AutoSummon:SetValue(false);summonStatus:SetDesc('Not enough inventory space');return end
    local bannerName=S.SummonBanner
    A.lobbyBusy=true;S.LobbyPurchasePending=true;save();summonStatus:SetDesc('Summoning '..count..' from '..bannerName..' ($'..cost..')')
    task.spawn(function()
        local ok,result=pcall(function() return RF.SummonTowers:InvokeServer(bannerName,count) end)
        A.lobbyBusy=false
        if ok and type(result)=='table' and #result>0 then
            S.SummonProgress=progress+#result;S.LobbyPurchasePending=false;save()
            local got={};for _,item in ipairs(result) do table.insert(got,tostring(item.Name)..(item.AutoSell and ' (auto sold)' or '')) end
            if A.alive then summonStatus:SetDesc('Pulled '..S.SummonProgress..(limit>0 and '/'..limit or '')..': '..table.concat(got,', '));print('[CTD Summon]',table.concat(got,', ')) end
        elseif A.alive then Library.Options.AutoSummon:SetValue(false);summonStatus:SetDesc('Summon not confirmed; stopped to prevent repeat spending') end
    end)
end
local lastWave,lastSkip,lastRepeat,lastVote
local function joinTick()
    if not S.AutoJoin then A.joinAt=nil;return end
    if not A.joinAt then A.joinAt=os.clock()+math.clamp(tonumber(S.JoinDelay) or 2,1,30) end
    if os.clock()<A.joinAt then joinStatus:SetDesc('Waiting for join delay');return end
    local list=workspace:FindFirstChild('Elevators');if not list then return end
    local root=P.Character and P.Character:FindFirstChild('HumanoidRootPart');if not root then return end
    local target=A.joinTarget and list:FindFirstChild(A.joinTarget)
    if not target or target:GetAttribute('Map')~=S.JoinMap then
        target=nil;A.joinTarget=nil
        for _,e in ipairs(list:GetChildren()) do if e:GetAttribute('Map')==S.JoinMap and (e:GetAttribute('Players') or 0)==0 then target=e;break end end
    end
    if not target then joinStatus:SetDesc('Waiting for an empty elevator: '..S.JoinMap);return end
    queue()
    local area=target:FindFirstChild('Area') or target:FindFirstChild('Hitbox') or target:FindFirstChildWhichIsA('BasePart')
    assert(area,'Elevator trigger missing')
    if not A.joinTarget or target:GetAttribute('Host')==0 then
        root.CFrame=area.CFrame;A.joinTarget=target.Name;joinStatus:SetDesc('Joining '..S.JoinMap)
    elseif target:GetAttribute('Host')==P.UserId and os.clock()>=(A.startAt or 0) then
        A.startAt=os.clock()+2;RF.ElevatorStart:InvokeServer(target.Name);joinStatus:SetDesc('Starting '..S.JoinMap)
    end
end
local function tick()
    if not match() then note('Enter a match to use Auto Play or record a macro');lobbyTick();if not A.lobbyBusy then joinTick() end;return end
    if not map() or not P:FindFirstChild('leaderstats') then return end
    local wave=workspace:GetAttribute('Wave') or 0
    if wave==0 and lastWave~=0 then
        if A.recording then Library.Options.RecordMacro:SetValue(false) end
        A.run=nil;A.pending=nil;lastRepeat=nil;lastVote=nil
        A.speedRejected=nil
    end
    if A.recording and lastWave and lastWave>0 and wave>lastWave then append({kind='skip',wave=wave-1}) end
    lastWave=wave
    syncSpeed();local nativeSkipOn=syncSkip();webhookTick()
    if finished() then
        if A.recording then Library.Options.RecordMacro:SetValue(false) end
        A.pending=nil
        if S.Repeat and not lastRepeat then RE.PlayAgain:FireServer();lastRepeat=true end
        return
    end
    if workspace:GetAttribute('IsVoting') then
        if (S.AutoStart or S.PlayMacro or S.AutoSwap) and not lastVote then
            local name=resolveMacro();local difficulty=name and loadMacro(name).mode or S.Difficulty
            RE.ModeVote:FireServer(difficulty);lastVote=true
        end
        return
    end
    if S.AutoSkip and not nativeSkipOn and workspace:GetAttribute('CanSkip') and lastSkip~=wave then
        local voters=workspace:GetAttribute('Votes') or 0
        if voters<(workspace:GetAttribute('RequiredVotes') or 1) then RE.WaveSkip:FireServer() end
        lastSkip=wave
    end
    if not workspace:GetAttribute('CanSkip') then lastSkip=nil end
    if A.pending then
        local pending=A.pending
        if pending.done() then A.pending=nil;if pending.after then pending.after() end
        elseif os.clock()>pending.deadline then error(pending.label..' was not confirmed; stopped to avoid duplicate spending') end
        return
    end
    if A.recording then return end
    local name=resolveMacro()
    if name and macroTick(name) then return end
    autoTick()
end
A.Tick=tick;A.Settings=S
local function updateMarkers()
    for slot=1,5 do
        local c=S.Slots[slot];local name=unit(slot)
        local marker=markers:FindFirstChild(tostring(slot))
        local point=match() and S.ShowPoint and c.On and name and spot(c,name,1)
        if point then
            if not marker then
                marker=Instance.new('Part');marker.Name=tostring(slot);marker.Shape=Enum.PartType.Ball;marker.Size=Vector3.new(1,1,1);marker.Anchored=true;marker.CanCollide=false;marker.CanTouch=false;marker.CanQuery=false;marker.Material=Enum.Material.Neon;marker.Color=Color3.fromHSV(slot/5,.7,1);marker.Transparency=.3;marker.Parent=markers
                local gui=Instance.new('BillboardGui');gui.Size=UDim2.fromOffset(150,25);gui.StudsOffset=Vector3.new(0,2,0);gui.AlwaysOnTop=true;gui.Parent=marker
                local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextColor3=marker.Color;label.TextStrokeTransparency=.3;label.Text='Slot '..slot;label.Parent=gui
            end
            marker.CFrame=point
        elseif marker then marker:Destroy() end
    end
end
local function updateUnitStatus()
    for _,view in ipairs(priorityViews) do
        for rank,label in ipairs(view.labels) do local slot=S[view.field][rank];local name=unit(slot);label.Text=rank..'. Slot '..slot..' — '..(name or 'empty') end
    end
    if not S.ShowUnitStatus then return end
    local entries={}
    if match() then for id,t in pairs(towers()) do if own(t) then table.insert(entries,{id=id,t=t}) end end end
    table.sort(entries,function(a,b) if a.t.Name~=b.t.Name then return a.t.Name<b.t.Name end;return a.id<b.id end)
    local maxed,copies=0,{}
    for index,entry in ipairs(entries) do
        local t=entry.t;local level=tonumber(t.Level) or 1;local upgrades=towerConfig(t.Name).Upgrades;local maximum=#upgrades
        local full=maximum>0 and level>=maximum
        if full then maxed+=1 end
        copies[t.Name]=(copies[t.Name] or 0)+1
        local label=unitRows[index]
        if not label then
            label=Instance.new('TextLabel');label.Name='Unit'..index;label.LayoutOrder=index;label.Size=UDim2.new(1,-5,0,35);label.BackgroundTransparency=1;label.Font=Enum.Font.Gotham;label.TextSize=12;label.TextWrapped=true;label.TextXAlignment=Enum.TextXAlignment.Left;label.Parent=panelList;unitRows[index]=label
        end
        local nextUpgrade=upgrades[level+1]
        label.Text=t.Name..' #'..copies[t.Name]..'  '..level..'/'..maximum..(full and '  MAX' or nextUpgrade and '  |  Next $'..nextUpgrade.Price or '  |  Unknown')
        label.TextColor3=full and Color3.fromRGB(90,230,130) or Color3.fromRGB(225,220,235)
    end
    for index=#unitRows,#entries+1,-1 do unitRows[index]:Destroy();unitRows[index]=nil end
    panelTitle.Text=match() and string.format('MAX %d/%d  |  Remaining %d',maxed,#entries,#entries-maxed) or 'Waiting for match'
    statusSummary:SetDesc(match() and string.format('Placed %d/15 | Fully upgraded %d | Not maxed %d',#entries,maxed,#entries-maxed) or 'Enter a match to see placed units')
    A.UnitStatusCounts={placed=#entries,maxed=maxed,remaining=#entries-maxed}
end
-- Pure checks cover order repair, priority selection and rejecting corrupt macro files.
assert(table.concat(order({3,3,9,1}),',')=='3,1,2,4,5')
assert(safeName('../bad/name')=='__bad_name')
assert(not pcall(validate,{version=1,map='Toilet City',mode='Easy',actions={{kind='upgrade',key='missing',level=2,wave=1}}}))
assert(isFarm({Tags={Farm={}}}) and not isFarm({Tags={}}))
assert(summonCost(100,1)==100 and summonCost(100,10)==900)
assert(withinBudget(1000,100,900,0,10,10))
assert(not withinBudget(999,100,900,0,10,10))
assert(not withinBudget(1000,0,100,10,10,1))
assert(not withinBudget(390,0,500,0,1,1))
assert(withinBudget(500,0,500,0,1,1))
assert(claimableQuest({Id='test',Completed=true,RewardClaimed=false}))
assert(not claimableQuest({Id='test',Completed=true,RewardClaimed=true}))
assert(not webhookURL('https://example.com/api/webhooks/123/token'))
assert(webhookURL('https://discord.com/api/webhooks/123/token')=='https://discord.com/api/webhooks/123/token?wait=true')
assert(webhookURL('https://ptb.discord.com/api/webhooks/123/token')=='https://ptb.discord.com/api/webhooks/123/token?wait=true')
local sentRequest
assert(postWebhook('https://discord.com/api/webhooks/123/token',webhookPayload({test=true}),function(r) sentRequest=r;return {StatusCode=200} end))
assert(sentRequest.Method=='POST' and H:JSONDecode(sentRequest.Body).embeds[1].title=='Webhook test')
assert(not postWebhook('https://discord.com/api/webhooks/123/token',{},function() return {StatusCode=429} end))
local oldPlace,oldUpgrade=S.PlaceMode,S.UpgradeMode
S.PlaceMode='One of each first';assert(choosePlace({{rank=1,count=2},{rank=2,count=0}}).rank==2)
S.PlaceMode='Fill slot before next';assert(choosePlace({{rank=2,count=0},{rank=1,count=2}}).rank==1)
S.UpgradeMode='Cheapest first';assert(chooseUpgrade({{cost=300,rank=1,id='a'},{cost=100,rank=2,id='b'}}).id=='b')
S.PlaceMode,S.UpgradeMode=oldPlace,oldUpgrade
print('[CTD PlayMacro] self-check passed')
Window:SelectTab(1)
task.spawn(function()
    local markerAt=0
    while A.alive and not Library.Unloaded do
        local ok,err=pcall(function() tick();if os.clock()>markerAt then markerAt=os.clock()+1;updateMarkers();updateUnitStatus() end end)
        if not ok then note(tostring(err),true);stop() end
        task.wait(.2)
    end
end)

]====]
assert(writefile,'Executor file support required')
writefile('CTD_PlayMacro.lua',source)
loadstring(source)()

