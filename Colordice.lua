--[[ ===========================================================================
     ██████╗ ██████╗ ██╗      ██████╗ ██████╗     ██████╗ ██╗ ██████╗███████╗    ██╗
    ██╔════╝██╔═══██╗██║     ██╔═══██╗██╔══██╗    ██╔══██╗██║██╔════╝██╔════╝   ██╔╝
    ██║     ██║   ██║██║     ██║   ██║██████╔╝    ██║  ██║██║██║     █████╗    ██╔╝
    ██║     ██║   ██║██║     ██║   ██║██╔══██╗    ██║  ██║██║██║     ██╔══╝   ██╔╝
    ╚██████╗╚██████╔╝███████╗╚██████╔╝██║  ██║    ██████╔╝██║╚██████╗███████╗██╔╝
     ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝    ╚═════╝ ╚═╝ ╚═════╝╚══════╝╚═╝

     ONE BIG SCRIPT  ·  v3.0  ·  DELTA + XENO (Android)
     ---------------------------------------------------------------------------
     Getestet für Delta & Xeno. Läuft auch auf Fluxus, Solara, Hydrogen, Krnl.

     ALLES IN EINER DATEI
       [ TAB 1 ] COLOR DICE  — 4 Farbwürfel, garantiert OHNE Doppelfarbe
       [ TAB 2 ] LIGHT/DARK  — Glücksrad mit LIGHT / DARK / 3X

     MOBILE FEATURES
       · Floating-Button (draggable) zum Öffnen/Schließen
       · Touch-Drag am Titelbalken, Position wird im Screen gehalten
       · Auto-Skalierung, damit das Fenster auch quer passt
       · Große Touch-Targets

     KEYS (falls Tastatur vorhanden)
       LEER = würfeln/spinnen | Z = reset | RECHTS-SHIFT = GUI ein/aus
     =========================================================================== ]]

local CONFIG = {
    NumDice      = 4,
    NoDuplicates = true,
    Sound        = true,
    SoundId      = "rbxassetid://131961136",
    SpinSeconds  = 3,
    StartTab     = "dice",
    AutoRoll     = true,
}

local Theme = {
    Bg      = Color3.fromRGB(19, 32, 49),
    Panel   = Color3.fromRGB(31, 51, 76),
    PanelHi = Color3.fromRGB(44, 70, 104),
    Accent  = Color3.fromRGB(51, 153, 255),
    Text    = Color3.fromRGB(236, 245, 255),
    Muted   = Color3.fromRGB(146, 176, 208),
    Idle    = Color3.fromRGB(212, 222, 232),
    Gold    = Color3.fromRGB(255, 213, 79),
}

if getgenv().ColorDice4 and getgenv().ColorDice4.Unload then
    pcall(getgenv().ColorDice4.Unload)
end

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local SoundService     = game:GetService("SoundService")

local LP       = Players.LocalPlayer
local NUM_DICE = CONFIG.NumDice
local IS_TOUCH = UserInputService.TouchEnabled

local COLORS = {
    { Name = "RED",    Color = Color3.fromRGB(229, 57, 53)  },
    { Name = "ORANGE", Color = Color3.fromRGB(251, 140, 0)  },
    { Name = "YELLOW", Color = Color3.fromRGB(253, 216, 53) },
    { Name = "GREEN",  Color = Color3.fromRGB(67, 160, 71)  },
    { Name = "BLUE",   Color = Color3.fromRGB(30, 136, 229) },
    { Name = "PURPLE", Color = Color3.fromRGB(142, 36, 170) },
}

local WHEEL = {
    { Name = "LIGHT", Label = "LIGHT", Color = Color3.fromRGB(255,255,255), TextColor = Color3.fromRGB(25,25,30) },
    { Name = "DARK",  Label = "DARK",  Color = Color3.fromRGB(51,51,51),    TextColor = Color3.fromRGB(255,255,255) },
    { Name = "LIGHT", Label = "LIGHT", Color = Color3.fromRGB(255,255,255), TextColor = Color3.fromRGB(25,25,30) },
    { Name = "DARK",  Label = "DARK",  Color = Color3.fromRGB(51,51,51),    TextColor = Color3.fromRGB(255,255,255) },
    { Name = "LIGHT", Label = "LIGHT", Color = Color3.fromRGB(255,255,255), TextColor = Color3.fromRGB(25,25,30) },
    { Name = "DARK",  Label = "DARK",  Color = Color3.fromRGB(51,51,51),    TextColor = Color3.fromRGB(255,255,255) },
    { Name = "GRAY",  Label = "3X",    Color = Color3.fromRGB(160,160,160), TextColor = Color3.fromRGB(255,255,255) },
}
local SEG_ANGLE = 360 / #WHEEL

local excluded, history = {}, {}
local rolling, spinning = false, false
local noDup     = CONFIG.NoDuplicates
local firstRoll = true
local spinRot   = 0
local activeTab = CONFIG.StartTab

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
local function circle(p)    return new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, p) end

local function stroke(p, col, th)
    return new("UIStroke", {
        Color = col or Theme.Bg, Thickness = th or 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, p)
end

local function copyTable(t)
    local o = {}
    for i = 1, #t do o[i] = t[i] end
    return o
end

local function playSound(pitch, vol)
    if not CONFIG.Sound then return end
    local s = Instance.new("Sound")
    s.SoundId       = CONFIG.SoundId
    s.Volume        = vol or 0.3
    s.PlaybackSpeed = pitch or 1
    pcall(function() SoundService:PlayLocalSound(s) end)
end

local function executorName()
    local ok, n = pcall(function() return identifyexecutor() end)
    if ok and type(n) == "string" then return n end
    return "Executor"
end

--// GUI-Parent -------------------------------------------------------------
local parentGui
if type(gethui) == "function" then pcall(function() parentGui = gethui() end) end
if not parentGui then pcall(function() parentGui = LP:WaitForChild("PlayerGui") end) end
if not parentGui then parentGui = LP:WaitForChild("PlayerGui") end

local gui = new("ScreenGui", {
    Name = "ColorDice4",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999,
}, parentGui)

--// Fenster ---------------------------------------------------------------
local WIN_W, WIN_H = 380, 534

local win = new("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIN_W, WIN_H),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
}, gui)
corner(win, 16)
stroke(win, Theme.Accent, 2)

local scale = new("UIScale", { Scale = 1 }, win)

local function fitToScreen()
    local vp = workspace.CurrentCamera.ViewportSize
    local s = math.min(1, (vp.X - 28) / WIN_W, (vp.Y - 28) / WIN_H)
    scale.Scale = math.max(0.45, s)
end
fitToScreen()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToScreen)

local titleBar = new("Frame", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
}, win)
corner(titleBar, 16)

new("TextLabel", {
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(1, -110, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    Text = "COLOR DICE 4",
    TextSize = 14,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

new("TextLabel", {
    Position = UDim2.fromOffset(14, 20),
    Size = UDim2.new(1, -110, 0, 12),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "via " .. executorName() .. "  ·  touch to drag",
    TextSize = 9,
    TextColor3 = Theme.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

local function barButton(txt, xOff, cb)
    local b = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, xOff, 0, 6),
        Size = UDim2.fromOffset(28, 26),
        BackgroundColor3 = Theme.Bg,
        Font = Enum.Font.GothamBold,
        Text = txt,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BorderSizePixel = 0,
    }, titleBar)
    corner(b, 8)
    b.MouseButton1Click:Connect(cb)
    return b
end

barButton("X", -6, function() gui.Enabled = false end)

local content = new("Frame", {
    Position = UDim2.fromOffset(0, 36),
    Size = UDim2.new(1, 0, 1, -36),
    BackgroundTransparency = 1,
}, win)

barButton("—", -38, function()
    content.Visible = not content.Visible
    TweenService:Create(win, TweenInfo.new(0.16), {
        Size = content.Visible and UDim2.fromOffset(WIN_W, WIN_H) or UDim2.fromOffset(WIN_W, 36),
    }):Play()
end)

--// Drag (Touch + Maus) ---------------------------------------------------
local function makeDraggable(frame, handle, onTap)
    local dragging, startPos, startFrame, moved = false, nil, nil, 0

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            moved      = 0
            startPos   = input.Position
            startFrame = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if onTap and moved < 10 then onTap() end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - startPos
            moved = math.max(moved, math.abs(d.X) + math.abs(d.Y))

            local vp = workspace.CurrentCamera.ViewportSize
            local nx = math.clamp(startFrame.X.Offset + d.X, -(WIN_W * scale.Scale) + 70, vp.X - 70)
            local ny = math.clamp(startFrame.Y.Offset + d.Y, 10, vp.Y - 44)
            frame.Position = UDim2.new(startFrame.X.Scale, nx, startFrame.Y.Scale, ny)
        end
    end)
end

makeDraggable(win, titleBar)

--// Floating Button -------------------------------------------------------
local floater = new("TextButton", {
    Name = "Floater",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -16, 0, 110),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = Theme.Accent,
    Font = Enum.Font.GothamBlack,
    Text = "DICE",
    TextSize = 12,
    TextColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    ZIndex = 50,
}, gui)
circle(floater)
stroke(floater, Color3.fromRGB(255, 255, 255), 3)

makeDraggable(floater, floater, function()
    win.Visible = not win.Visible
end)

--// Tabs ------------------------------------------------------------------
local tabRow = new("Frame", {
    Position = UDim2.fromOffset(14, 8),
    Size = UDim2.new(1, -28, 0, 32),
    BackgroundTransparency = 1,
}, content)

local function makeTab(txt, xScale, xOff)
    local b = new("TextButton", {
        Position = UDim2.new(xScale, xOff, 0, 0),
        Size = UDim2.new(0.5, -5, 1, 0),
        BackgroundColor3 = Theme.Panel,
        Font = Enum.Font.GothamBlack,
        Text = txt,
        TextSize = 12,
        TextColor3 = Theme.Muted,
        BorderSizePixel = 0,
    }, tabRow)
    corner(b, 10)
    return b
end

local tabDice  = makeTab("COLOR DICE", 0, 0)
local tabWheel = makeTab("LIGHT / DARK", 0.5, 5)

--// Panels ----------------------------------------------------------------
local PANEL_Y = 46

local dicePanel = new("Frame", {
    Position = UDim2.fromOffset(0, PANEL_Y),
    Size = UDim2.new(1, 0, 1, -PANEL_Y),
    BackgroundTransparency = 1,
}, content)

local wheelPanel = new("Frame", {
    Position = UDim2.fromOffset(0, PANEL_Y),
    Size = UDim2.new(1, 0, 1, -PANEL_Y),
    BackgroundTransparency = 1,
    Visible = false,
}, content)

--// DICE TAB --------------------------------------------------------------
local diceRow = new("Frame", {
    Position = UDim2.fromOffset(0, 6),
    Size = UDim2.new(1, 0, 0, 106),
    BackgroundTransparency = 1,
}, dicePanel)

local dice = {}
for i = 1, NUM_DICE do
    local baseX = 0.125 + (i - 1) * 0.25

    local wrap = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(baseX, 0, 0.5, 0),
        Size = UDim2.fromOffset(70, 92),
        BackgroundTransparency = 1,
    }, diceRow)

    local die = new("Frame", {
        Size = UDim2.fromOffset(66, 66),
        BackgroundColor3 = Theme.Idle,
        BorderSizePixel = 0,
    }, wrap)
    corner(die, 16)

    local glow = stroke(die, Theme.Gold, 3)
    glow.Transparency = 1

    local dot = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(17, 17),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, die)
    circle(dot)

    local cap = new("TextLabel", {
        Position = UDim2.fromOffset(0, 70),
        Size = UDim2.fromOffset(70, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "?",
        TextSize = 11,
        TextColor3 = Theme.Muted,
    }, wrap)

    dice[i] = { Wrap = wrap, Die = die, Cap = cap, Glow = glow, BaseX = baseX }
end

local resultLabel = new("TextLabel", {
    Position = UDim2.fromOffset(14, 118),
    Size = UDim2.new(1, -28, 0, 26),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    Text = "",
    TextSize = 14,
    TextColor3 = Theme.Text,
    TextWrapped = true,
}, dicePanel)

local rollBtn = new("TextButton", {
    Position = UDim2.fromOffset(14, 150),
    Size = UDim2.new(1, -28, 0, 50),
    BackgroundColor3 = Theme.Accent,
    Font = Enum.Font.GothamBlack,
    Text = "ROLL !",
    TextSize = 23,
    TextColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
}, dicePanel)
corner(rollBtn, 13)
stroke(rollBtn, Color3.fromRGB(130, 196, 255), 2)

local function toggleButton(text, pos, size, cb)
    local b = new("TextButton", {
        Position = pos, Size = size,
        BackgroundColor3 = Theme.Panel,
        Font = Enum.Font.GothamBold,
        Text = text, TextSize = 11,
        TextColor3 = Theme.Muted,
        BorderSizePixel = 0,
    }, dicePanel)
    corner(b, 10)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

local noDupBtn = toggleButton("NO DOPPEL: AN",
    UDim2.fromOffset(14, 208), UDim2.new(0.5, -20, 0, 34), function(b)
        noDup = not noDup
        b.Text = "NO DOPPEL: " .. (noDup and "AN" or "AUS")
        b.BackgroundColor3 = noDup and Color3.fromRGB(118, 94, 28) or Theme.Panel
        b.TextColor3 = noDup and Theme.Gold or Theme.Muted
    end)
noDupBtn.BackgroundColor3 = Color3.fromRGB(118, 94, 28)
noDupBtn.TextColor3 = Theme.Gold

local soundBtn = toggleButton("SOUND: AN",
    UDim2.new(0.5, 6, 0, 208), UDim2.new(0.5, -20, 0, 34), function(b)
        CONFIG.Sound = not CONFIG.Sound
        b.Text = "SOUND: " .. (CONFIG.Sound and "AN" or "AUS")
        b.TextColor3 = CONFIG.Sound and Theme.Text or Theme.Muted
    end)

local resetBtn = new("TextButton", {
    Position = UDim2.fromOffset(14, 248),
    Size = UDim2.new(1, -28, 0, 32),
    BackgroundColor3 = Theme.Panel,
    Font = Enum.Font.GothamBold,
    Text = "ZURÜCKSETZEN",
    TextSize = 11,
    TextColor3 = Theme.Muted,
    BorderSizePixel = 0,
}, dicePanel)
corner(resetBtn, 10)

local chipRow = new("Frame", {
    Position = UDim2.fromOffset(14, 288),
    Size = UDim2.new(1, -28, 0, 34),
    BackgroundTransparency = 1,
}, dicePanel)

local chips = {}
for i, c in ipairs(COLORS) do
    local b = new("TextButton", {
        Position = UDim2.new((i - 1) / #COLORS, 0, 0, 0),
        Size = UDim2.new(1 / #COLORS, -6, 1, 0),
        BackgroundColor3 = c.Color,
        Font = Enum.Font.GothamBold,
        Text = string.sub(c.Name, 1, 2),
        TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, chipRow)
    corner(b, 9)
    chips[c.Name] = b

    b.MouseButton1Click:Connect(function()
        excluded[c.Name] = (not excluded[c.Name]) or nil
        b.BackgroundTransparency = excluded[c.Name] and 0.75 or 0
        b.TextColor3 = excluded[c.Name] and Theme.Muted or Color3.new(1, 1, 1)
    end)
end

local histBox = new("Frame", {
    Position = UDim2.fromOffset(14, 330),
    Size = UDim2.new(1, -28, 0, 112),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
}, dicePanel)
corner(histBox, 12)

new("TextLabel", {
    Position = UDim2.fromOffset(10, 4),
    Size = UDim2.new(1, -20, 0, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "LETZTE WÜRFE",
    TextSize = 10,
    TextColor3 = Theme.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, histBox)

local histRow = new("Frame", {
    Position = UDim2.fromOffset(10, 24),
    Size = UDim2.new(1, -20, 1, -30),
    BackgroundTransparency = 1,
}, histBox)

local histSlots = {}
for i = 1, 6 do
    local row = new("Frame", {
        Position = UDim2.fromOffset(0, (i - 1) * 14),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundTransparency = 1,
    }, histRow)
    local dots = {}
    for j = 1, NUM_DICE do
        dots[j] = new("Frame", {
            Position = UDim2.fromOffset((j - 1) * 16, 0),
            Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = Theme.Idle,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
        }, row)
        corner(dots[j], 4)
    end
    histSlots[i] = dots
end

--// WHEEL TAB -------------------------------------------------------------
local WHEEL_R = 100

local wheelHolder = new("Frame", {
    Position = UDim2.fromOffset(46, 12),
    Size = UDim2.fromOffset(220, 220),
    BackgroundTransparency = 1,
}, wheelPanel)

local wheelSpin = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 1,
}, wheelHolder)

for i, seg in ipairs(WHEEL) do
    local angle = (i - 1) * SEG_ANGLE + SEG_ANGLE / 2

    local spoke = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(100, WHEEL_R + 4),
        Rotation = angle + 90,
        BackgroundColor3 = seg.Color,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, wheelSpin)
    corner(spoke, 3)

    local lbl = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 16),
        Size = UDim2.fromOffset(64, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBlack,
        Text = seg.Label,
        TextSize = 12,
        TextColor3 = seg.TextColor,
        Rotation = -(angle + 90),
        ZIndex = 3,
    }, spoke)
    lbl.Visible = true
end

local ring = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 10,
}, wheelHolder)
circle(ring)
stroke(ring, Color3.fromRGB(255, 255, 255), 14)

local hub = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(48, 48),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    ZIndex = 11,
}, wheelHolder)
circle(hub)
stroke(hub, Theme.Accent, 3)

local pointer = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(1, 12, 0.5, 0),
    Size = UDim2.fromOffset(38, 38),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    Text = "◀",
    TextSize = 34,
    TextColor3 = Theme.Accent,
    ZIndex = 12,
}, wheelHolder)
stroke(pointer, Color3.fromRGB(255, 255, 255), 2)

local winnerLabel = new("TextLabel", {
    Position = UDim2.fromOffset(14, 244),
    Size = UDim2.new(1, -28, 0, 40),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    Text = "",
    TextSize = 22,
    TextColor3 = Theme.Text,
}, wheelPanel)

local spinBtn = new("TextButton", {
    Position = UDim2.fromOffset(14, 292),
    Size = UDim2.new(1, -28, 0, 50),
    BackgroundColor3 = Theme.Accent,
    Font = Enum.Font.GothamBlack,
    Text = "SPIN !",
    TextSize = 23,
    TextColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
}, wheelPanel)
corner(spinBtn, 13)
stroke(spinBtn, Color3.fromRGB(130, 196, 255), 2)

local timeRow = new("Frame", {
    Position = UDim2.fromOffset(14, 350),
    Size = UDim2.new(1, -28, 0, 32),
    BackgroundTransparency = 1,
}, wheelPanel)

local timeBtns = {}
for i = 1, 6 do
    local b = new("TextButton", {
        Position = UDim2.new((i - 1) / 6, 0, 0, 0),
        Size = UDim2.new(1 / 6, -4, 1, 0),
        BackgroundColor3 = (i == CONFIG.SpinSeconds) and Theme.Accent or Theme.Panel,
        Font = Enum.Font.GothamBold,
        Text = i .. "s",
        TextSize = 11,
        TextColor3 = (i == CONFIG.SpinSeconds) and Color3.new(1, 1, 1) or Theme.Muted,
        BorderSizePixel = 0,
    }, timeRow)
    corner(b, 8)
    timeBtns[i] = b

    b.MouseButton1Click:Connect(function()
        CONFIG.SpinSeconds = i
        for j, btn in ipairs(timeBtns) do
            btn.BackgroundColor3 = (j == i) and Theme.Accent or Theme.Panel
            btn.TextColor3 = (j == i) and Color3.new(1, 1, 1) or Theme.Muted
        end
    end)
end

new("TextLabel", {
    Position = UDim2.fromOffset(14, 388),
    Size = UDim2.new(1, -28, 0, 52),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Möglich: LIGHT · DARK · 3X (grau)\nTippe eine Farbe an, um sie auszuschließen.",
    TextSize = 11,
    TextColor3 = Theme.Muted,
    TextWrapped = true,
}, wheelPanel)

--// Tab-Wechsel -----------------------------------------------------------
local function setTab(name)
    activeTab = name
    dicePanel.Visible  = (name == "dice")
    wheelPanel.Visible = (name == "wheel")

    tabDice.BackgroundColor3  = (name == "dice")  and Theme.Accent or Theme.Panel
    tabWheel.BackgroundColor3 = (name == "wheel") and Theme.Accent or Theme.Panel
    tabDice.TextColor3  = (name == "dice")  and Color3.new(1, 1, 1) or Theme.Muted
    tabWheel.TextColor3 = (name == "wheel") and Color3.new(1, 1, 1) or Theme.Muted
end

tabDice.MouseButton1Click:Connect(function() setTab("dice") end)
tabWheel.MouseButton1Click:Connect(function() setTab("wheel") end)
setTab(CONFIG.StartTab)

--// Logik -----------------------------------------------------------------
local function activePool()
    local pool = {}
    for _, c in ipairs(COLORS) do
        if not excluded[c.Name] then table.insert(pool, c) end
    end
    if #pool == 0 then pool = COLORS end
    return pool
end

local function pickResults()
    local pool = activePool()
    local out = {}
    if noDup and #pool >= NUM_DICE then
        local c = copyTable(pool)
        for i = #c, 2, -1 do
            local j = math.random(i)
            c[i], c[j] = c[j], c[i]
        end
        for i = 1, NUM_DICE do out[i] = c[i] end
    else
        for i = 1, NUM_DICE do out[i] = pool[math.random(#pool)] end
    end
    return out
end

local function pop(frame)
    local base = frame.Size
    TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(base.X.Scale, base.X.Offset + 10, base.Y.Scale, base.Y.Offset + 10) }):Play()
    task.delay(0.12, function()
        TweenService:Create(frame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = base }):Play()
    end)
end

local function renderHistory()
    for i, dots in ipairs(histSlots) do
        local row = history[i]
        for j, d in ipairs(dots) do
            if row and row[j] then
                d.BackgroundTransparency = 0
                d.BackgroundColor3 = row[j].Color
            else
                d.BackgroundTransparency = 1
            end
        end
    end
end

local function roll()
    if rolling or not dicePanel.Visible then
        if rolling then return end
        setTab("dice")
    end
    if rolling then return end
    rolling = true
    rollBtn.Text = "WÜRFLE..."

    for _, d in ipairs(dice) do
        d.Glow.Transparency = 1
        d.Die.BackgroundColor3 = Theme.Idle
        d.Cap.Text = "?"
        d.Cap.TextColor3 = Theme.Muted
    end
    resultLabel.Text = ""

    local results = pickResults()

    if not firstRoll then
        for i = 1, 10 do
            task.delay(i * 0.085, function() playSound(0.9 + math.random() * 0.35, 0.2) end)
        end
    end

    local shake = RunService.RenderStepped:Connect(function()
        local t = tick()
        for i, d in ipairs(dice) do
            d.Die.Rotation = math.sin(t * 34 + i * 1.7) * 9
            d.Wrap.Position = UDim2.new(d.BaseX, math.sin(t * 27 + i) * 3,
                                        0.5, math.cos(t * 31 + i * 2) * 3)
        end
    end)

    task.wait(0.9)

    for i, d in ipairs(dice) do
        local c = results[i]
        d.Die.Rotation = 0
        d.Wrap.Position = UDim2.new(d.BaseX, 0, 0.5, 0)
        d.Die.BackgroundColor3 = c.Color
        d.Cap.Text = c.Name
        d.Cap.TextColor3 = Theme.Text
        pop(d.Die)
        if not firstRoll then playSound(1.15, 0.18) end
        task.wait(0.13)
    end

    shake:Disconnect()

    local counts, maxCount, names = {}, 0, {}
    for _, c in ipairs(results) do
        counts[c.Name] = (counts[c.Name] or 0) + 1
        if counts[c.Name] > maxCount then maxCount = counts[c.Name] end
        table.insert(names, c.Name)
    end

    if maxCount > 1 then
        local winners = {}
        for i, c in ipairs(results) do
            if counts[c.Name] == maxCount then
                dice[i].Glow.Transparency = 0
                table.insert(winners, c.Name)
            end
        end
        resultLabel.Text = table.concat(winners, " + ") .. " x" .. maxCount .. " — GEWINN!"
        resultLabel.TextColor3 = Theme.Gold
        if not firstRoll then playSound(1.5, 0.35) end
    else
        resultLabel.Text = table.concat(names, " · ") .. " — KEINE DOPPEL"
        resultLabel.TextColor3 = Theme.Text
        if not firstRoll then playSound(1.35, 0.22) end
    end

    table.insert(history, 1, results)
    while #history > 6 do table.remove(history) end
    renderHistory()

    rolling = false
    rollBtn.Text = "ROLL !"
    firstRoll = false
end

local function spin()
    if spinning then return end
    spinning = true
    spinBtn.Text = "..."
    winnerLabel.Text = ""

    local pool = {}
    for i, s in ipairs(WHEEL) do
        if not excluded[s.Name] then table.insert(pool, i) end
    end
    if #pool == 0 then
        for i = 1, #WHEEL do pool[i] = i end
    end

    local winIdx = pool[math.random(#pool)]
    local targetAngle = (winIdx - 1) * SEG_ANGLE + SEG_ANGLE / 2

    local target = spinRot + 360 * (4 + math.random() * 2)
    target = target + ((-targetAngle - target) % 360 + 360) % 360

    local dur = CONFIG.SpinSeconds
    local tw = TweenService:Create(
        wheelSpin,
        TweenInfo.new(dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Rotation = target }
    )

    task.spawn(function()
        local t0 = tick()
        while tick() - t0 < dur - 0.05 do
            playSound(1.15 + math.random() * 0.4, 0.11)
            local p = (tick() - t0) / dur
            task.wait(0.08 + p * 0.42)
        end
    end)

    tw:Play()
    tw.Completed:Wait()
    spinRot = target

    local seg = WHEEL[winIdx]
    if seg.Name == "GRAY" then
        winnerLabel.Text = "3X GRAY!"
        winnerLabel.TextColor3 = Theme.Gold
    elseif seg.Name == "LIGHT" then
        winnerLabel.Text = "LIGHT"
        winnerLabel.TextColor3 = Color3.new(1, 1, 1)
    else
        winnerLabel.Text = "DARK"
        winnerLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
    end
    playSound(1.6, 0.32)

    spinBtn.Text = "SPIN !"
    spinning = false
end

local function resetAll()
    history = {}
    renderHistory()
    for _, d in ipairs(dice) do
        d.Glow.Transparency = 1
        d.Die.BackgroundColor3 = Theme.Idle
        d.Cap.Text = "?"
        d.Cap.TextColor3 = Theme.Muted
    end
    resultLabel.Text = ""
    winnerLabel.Text = ""
    excluded = {}
    for _, b in pairs(chips) do
        b.BackgroundTransparency = 0
        b.TextColor3 = Color3.new(1, 1, 1)
    end
end

rollBtn.MouseButton1Click:Connect(roll)
spinBtn.MouseButton1Click:Connect(spin)
resetBtn.MouseButton1Click:Connect(resetAll)

--// Keybinds (falls Tastatur) ---------------------------------------------
local COLOR_KEYS = {}
for _, c in ipairs(COLORS) do COLOR_KEYS[c.Name] = c end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then
        if activeTab == "dice" then roll() else spin() end
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        win.Visible = not win.Visible
    elseif input.KeyCode == Enum.KeyCode.Z then
        resetAll()
    end
end)

--// Unload -----------------------------------------------------------------
getgenv().ColorDice4 = {
    Gui = gui,
    Roll = roll,
    Spin = spin,
    Reset = resetAll,
    Unload = function()
        pcall(function() gui:Destroy() end)
        getgenv().ColorDice4 = nil
    end,
}

if CONFIG.AutoRoll then task.delay(0.5, roll) end
print("[Color Dice 4] geladen auf " .. executorName() .. " — Floating-Button nutzen")
