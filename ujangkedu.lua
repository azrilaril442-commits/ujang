-- ╔═══════════════════════════════════════════════════════════╗
-- ║                      LOW HUB                              ║
-- ║                 Beta • v0.18.0 Final                      ║
-- ║       🧬 Name-Based Pet Selection System                  ║
-- ╚═══════════════════════════════════════════════════════════╝

wait(0.5)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Clean up existing GUI
if PlayerGui:FindFirstChild("LowHub") then
    PlayerGui:FindFirstChild("LowHub"):Destroy()
    wait(0.3)
end

-- ═══════════════════════════════════════════════════════════
--                     STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════

_G.LowHubSettings = _G.LowHubSettings or {
    Speed = 16,
    WalkspeedEnabled = false,
    NoClip = false,
    InfJump = false,
    
    -- Team 1 Breeding (Store PET NAMES as strings)
    Team1Pet1 = {},  -- {"DragonPet", "PhoenixPet"}
    Team1Pet2 = {},  -- {"CatPet", "WolfPet"}
    BreedDelay = 2,
    AutoBreeding = false,
    TotalBreeds = 0,
}

local Settings = _G.LowHubSettings

-- Stop any existing threads
if _G.AutoBreedTeam1 then
    task.cancel(_G.AutoBreedTeam1)
    _G.AutoBreedTeam1 = nil
    Settings.AutoBreeding = false
end

if _G.NoClip then
    _G.NoClip:Disconnect()
    _G.NoClip = nil
end

if _G.InfJump then
    _G.InfJump:Disconnect()
    _G.InfJump = nil
end

-- ═══════════════════════════════════════════════════════════
--                     PET SYSTEM - NAME BASED
-- ═══════════════════════════════════════════════════════════

local function getPetsFromPlayerPens()
    local pets = {}
    
    local playerPens = workspace:FindFirstChild("PlayerPens")
    if not playerPens then
        warn("⚠️ PlayerPens not found in workspace!")
        return pets
    end
    
    local playerPen = nil
    
    -- Try to find by number
    for i = 1, 100 do
        local pen = playerPens:FindFirstChild(tostring(i))
        if pen then
            playerPen = pen
            break
        end
    end
    
    -- Try by player name
    if not playerPen then
        playerPen = playerPens:FindFirstChild(Player.Name)
    end
    
    if not playerPen then
        warn("⚠️ Could not find player's pen!")
        return pets
    end
    
    local petsFolder = playerPen:FindFirstChild("Pets")
    if not petsFolder then
        warn("⚠️ Pets folder not found in pen!")
        return pets
    end
    
    -- Store only pet names
    for _, pet in pairs(petsFolder:GetChildren()) do
        if pet:IsA("Model") or pet:IsA("Part") or pet:IsA("MeshPart") then
            table.insert(pets, {
                Name = pet.Name,
                Rarity = pet:GetAttribute("Rarity") or "Unknown",
                Type = pet:GetAttribute("PetType") or "Pet",
                PenNumber = playerPen.Name
            })
        end
    end
    
    print(string.format("📦 Found %d pets in PlayerPen '%s'", #pets, playerPen.Name))
    return pets
end

local function getPetObjectByName(petName)
    local playerPens = workspace:FindFirstChild("PlayerPens")
    if not playerPens then return nil end
    
    local playerPen = nil
    
    for i = 1, 100 do
        local pen = playerPens:FindFirstChild(tostring(i))
        if pen then
            playerPen = pen
            break
        end
    end
    
    if not playerPen then
        playerPen = playerPens:FindFirstChild(Player.Name)
    end
    
    if not playerPen then return nil end
    
    local petsFolder = playerPen:FindFirstChild("Pets")
    if not petsFolder then return nil end
    
    return petsFolder:FindFirstChild(petName)
end

local function breedPets(petName1, petName2)
    if not petName1 or not petName2 then
        warn("❌ Invalid pet names for breeding")
        return false
    end
    
    local pet1Object = getPetObjectByName(petName1)
    local pet2Object = getPetObjectByName(petName2)
    
    if not pet1Object or not pet2Object then
        warn(string.format("❌ Pets not found: %s or %s", petName1, petName2))
        return false
    end
    
    local success, result = pcall(function()
        local pos1 = pet1Object:IsA("Model") and pet1Object:GetPivot().Position or pet1Object.Position
        local pos2 = pet2Object:IsA("Model") and pet2Object:GetPivot().Position or pet2Object.Position
        
        local args = {
            [1] = pet1Object,
            [2] = pet2Object,
            [3] = pos1,
            [4] = pos2
        }
        
        local breedRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("breedRequest")
        local response = breedRemote:InvokeServer(unpack(args))
        
        Settings.TotalBreeds = Settings.TotalBreeds + 1
        print(string.format("✅ [Team 1] Bred: %s + %s (Total: %d)", 
            petName1, petName2, Settings.TotalBreeds))
        
        return response
    end)
    
    if not success then
        warn(string.format("❌ Breeding failed: %s", tostring(result)))
    end
    
    return success
end

-- ═══════════════════════════════════════════════════════════
--                         COLORS
-- ═══════════════════════════════════════════════════════════

local C = {
    Glass = Color3.fromRGB(15, 20, 15),
    GlassLight = Color3.fromRGB(20, 30, 20),
    Neon = Color3.fromRGB(57, 255, 20),
    NeonDark = Color3.fromRGB(34, 197, 94),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(156, 163, 175),
    Border = Color3.fromRGB(75, 85, 99),
    Shadow = Color3.fromRGB(0, 0, 0),
}

-- ═══════════════════════════════════════════════════════════
--                         HELPERS
-- ═══════════════════════════════════════════════════════════

local function Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quad), props):Play()
end

local function Round(obj, r)
    Instance.new("UICorner", obj).CornerRadius = UDim.new(0, r)
end

local function Glass(obj, t)
    obj.BackgroundTransparency = t or 0.2
    local s = Instance.new("UIStroke", obj)
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1
    s.Transparency = 0.8
end

-- ═══════════════════════════════════════════════════════════
--                       CREATE GUI
-- ═══════════════════════════════════════════════════════════

local GUI = Instance.new("ScreenGui")
GUI.Name = "LowHub"
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 999
GUI.Parent = PlayerGui

-- ═══════════════════════════════════════════════════════════
--                    FLOATING ICON
-- ═══════════════════════════════════════════════════════════

local Icon = Instance.new("TextButton")
Icon.Size = UDim2.new(0, 50, 0, 50)
Icon.Position = UDim2.new(1, -60, 0, 10)
Icon.BackgroundColor3 = C.Neon
Icon.BorderSizePixel = 0
Icon.Text = "🤖"
Icon.TextSize = 26
Icon.TextColor3 = Color3.fromRGB(0, 0, 0)
Icon.Font = Enum.Font.GothamBold
Icon.ZIndex = 1000
Icon.Visible = false
Icon.Parent = GUI
Round(Icon, 25)

local iconDrag, iconStart, iconStartPos

Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDrag = true
        iconStart = input.Position
        iconStartPos = Icon.Position
    end
end)

Icon.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDrag = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if iconDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - iconStart
        Icon.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
    end
end)

-- ═══════════════════════════════════════════════════════════
--                      MAIN DASHBOARD
-- ═══════════════════════════════════════════════════════════

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 560, 0, 380)
Main.Position = UDim2.new(0.5, -280, 0.5, -190)
Main.BackgroundColor3 = C.Glass
Main.BorderSizePixel = 0
Main.ZIndex = 100
Main.Parent = GUI
Round(Main, 16)
Glass(Main, 0.15)

-- ═══════════════════════════════════════════════════════════
--                         HEADER
-- ═══════════════════════════════════════════════════════════

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = C.GlassLight
Header.BackgroundTransparency = 0.3
Header.BorderSizePixel = 0
Header.ZIndex = 102
Header.Parent = Main
Round(Header, 16)
Glass(Header, 0.3)

local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 16)
HeaderCover.Position = UDim2.new(0, 0, 1, -16)
HeaderCover.BackgroundColor3 = C.GlassLight
HeaderCover.BackgroundTransparency = 0.3
HeaderCover.BorderSizePixel = 0
HeaderCover.ZIndex = 102
HeaderCover.Parent = Header

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 36, 0, 36)
Logo.Position = UDim2.new(0, 12, 0.5, -18)
Logo.BackgroundColor3 = C.Neon
Logo.BorderSizePixel = 0
Logo.ZIndex = 103
Logo.Parent = Header
Round(Logo, 10)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "🤖"
LogoText.TextSize = 20
LogoText.TextColor3 = Color3.fromRGB(0, 0, 0)
LogoText.Font = Enum.Font.GothamBold
LogoText.ZIndex = 104
LogoText.Parent = Logo

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 55, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Low Hub"
Title.TextColor3 = C.Neon
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.ZIndex = 103
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 200, 0, 16)
Subtitle.Position = UDim2.new(0, 55, 1, -20)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Beta • v0.18.0 Final"
Subtitle.TextColor3 = C.TextDim
Subtitle.TextSize = 9
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Font = Enum.Font.Gotham
Subtitle.ZIndex = 103
Subtitle.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -75, 0.5, -16)
MinBtn.BackgroundColor3 = C.NeonDark
MinBtn.BackgroundTransparency = 0.3
MinBtn.BorderSizePixel = 0
MinBtn.Text = "─"
MinBtn.TextColor3 = C.Text
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.ZIndex = 103
MinBtn.Parent = Header
Round(MinBtn, 8)
Glass(MinBtn, 0.3)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.Text
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 103
CloseBtn.Parent = Header
Round(CloseBtn, 8)
Glass(CloseBtn, 0.3)

-- ═══════════════════════════════════════════════════════════
--                      CONTENT AREA
-- ═══════════════════════════════════════════════════════════

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -60)
Content.Position = UDim2.new(0, 10, 0, 55)
Content.BackgroundTransparency = 1
Content.ZIndex = 102
Content.Parent = Main

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = C.GlassLight
Sidebar.BackgroundTransparency = 0.4
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 0
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.ZIndex = 103
Sidebar.Parent = Content
Round(Sidebar, 12)
Glass(Sidebar, 0.4)

local SidebarPad = Instance.new("UIPadding", Sidebar)
SidebarPad.PaddingTop = UDim.new(0, 8)
SidebarPad.PaddingBottom = UDim.new(0, 8)
SidebarPad.PaddingLeft = UDim.new(0, 6)
SidebarPad.PaddingRight = UDim.new(0, 6)

local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.Padding = UDim.new(0, 5)

SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 16)
end)

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(1, -150, 1, 0)
Panel.Position = UDim2.new(0, 145, 0, 0)
Panel.BackgroundColor3 = C.GlassLight
Panel.BackgroundTransparency = 0.5
Panel.BorderSizePixel = 0
Panel.ZIndex = 103
Panel.Parent = Content
Round(Panel, 12)
Glass(Panel, 0.5)

local PanelPad = Instance.new("UIPadding", Panel)
PanelPad.PaddingTop = UDim.new(0, 12)
PanelPad.PaddingBottom = UDim.new(0, 12)
PanelPad.PaddingLeft = UDim.new(0, 12)
PanelPad.PaddingRight = UDim.new(0, 12)

local PanelTitle = Instance.new("TextLabel")
PanelTitle.Size = UDim2.new(1, 0, 0, 28)
PanelTitle.BackgroundTransparency = 1
PanelTitle.Text = "Home"
PanelTitle.TextColor3 = C.Text
PanelTitle.TextSize = 18
PanelTitle.TextXAlignment = Enum.TextXAlignment.Left
PanelTitle.Font = Enum.Font.GothamBold
PanelTitle.ZIndex = 104
PanelTitle.Parent = Panel

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -35)
Scroll.Position = UDim2.new(0, 0, 0, 35)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = C.Neon
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ZIndex = 104
Scroll.Parent = Panel

local ScrollLayout = Instance.new("UIListLayout", Scroll)
ScrollLayout.Padding = UDim.new(0, 8)

ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 8)
end)

-- ═══════════════════════════════════════════════════════════
--                       TAB SYSTEM
-- ═══════════════════════════════════════════════════════════

local ActiveTab = nil

local function CreateTab(name, icon, order)
    local Tab = Instance.new("TextButton")
    Tab.Size = UDim2.new(1, 0, 0, 38)
    Tab.BackgroundColor3 = C.GlassLight
    Tab.BackgroundTransparency = 0.7
    Tab.BorderSizePixel = 0
    Tab.Text = ""
    Tab.AutoButtonColor = false
    Tab.LayoutOrder = order
    Tab.ZIndex = 104
    Tab.Parent = Sidebar
    Round(Tab, 8)
    Glass(Tab, 0.7)
    
    local TabIcon = Instance.new("TextLabel", Tab)
    TabIcon.Size = UDim2.new(0, 20, 0, 20)
    TabIcon.Position = UDim2.new(0, 8, 0.5, -10)
    TabIcon.BackgroundTransparency = 1
    TabIcon.Text = icon
    TabIcon.TextSize = 14
    TabIcon.TextColor3 = C.TextDim
    TabIcon.Font = Enum.Font.GothamBold
    TabIcon.ZIndex = 105
    
    local TabLabel = Instance.new("TextLabel", Tab)
    TabLabel.Size = UDim2.new(1, -35, 1, 0)
    TabLabel.Position = UDim2.new(0, 32, 0, 0)
    TabLabel.BackgroundTransparency = 1
    TabLabel.Text = name
    TabLabel.TextSize = 11
    TabLabel.TextColor3 = C.TextDim
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabLabel.Font = Enum.Font.Gotham
    TabLabel.ZIndex = 105
    
    local Indicator = Instance.new("Frame", Tab)
    Indicator.Size = UDim2.new(0, 2, 0, 0)
    Indicator.Position = UDim2.new(0, 0, 0.5, 0)
    Indicator.AnchorPoint = Vector2.new(0, 0.5)
    Indicator.BackgroundColor3 = C.Neon
    Indicator.BorderSizePixel = 0
    Indicator.ZIndex = 106
    Round(Indicator, 1)
    
    Tab.MouseButton1Click:Connect(function()
        if ActiveTab == name then return end
        
        for _, tab in pairs(Sidebar:GetChildren()) do
            if tab:IsA("TextButton") then
                Tween(tab, {BackgroundTransparency = 0.7})
                local ind = tab:FindFirstChild("Frame")
                if ind then Tween(ind, {Size = UDim2.new(0, 2, 0, 0)}) end
                for _, lbl in pairs(tab:GetChildren()) do
                    if lbl:IsA("TextLabel") then lbl.TextColor3 = C.TextDim end
                end
            end
        end
        
        Tween(Tab, {BackgroundTransparency = 0.3})
        Tween(Indicator, {Size = UDim2.new(0, 2, 0, 24)})
        TabIcon.TextColor3 = C.Neon
        TabLabel.TextColor3 = C.Text
        TabLabel.Font = Enum.Font.GothamBold
        PanelTitle.Text = name
        ActiveTab = name
        
        for _, item in pairs(Scroll:GetChildren()) do
            if item:IsA("Frame") or item:IsA("TextLabel") then item:Destroy() end
        end
        
        if name == "Player" then LoadPlayerTab()
        elseif name == "Home" then LoadHomeTab()
        elseif name == "Breeding" then LoadBreedingTab()
        elseif name == "Egg" then LoadEggTab() end
    end)
    
    Tab.MouseEnter:Connect(function()
        if ActiveTab ~= name then Tween(Tab, {BackgroundTransparency = 0.5}) end
    end)
    
    Tab.MouseLeave:Connect(function()
        if ActiveTab ~= name then Tween(Tab, {BackgroundTransparency = 0.7}) end
    end)
end

-- ═══════════════════════════════════════════════════════════
--                      COMPONENTS
-- ═══════════════════════════════════════════════════════════

local function CreateToggle(title, setting, callback)
    local Opt = Instance.new("Frame")
    Opt.Size = UDim2.new(1, 0, 0, 40)
    Opt.BackgroundColor3 = C.Glass
    Opt.BackgroundTransparency = 0.3
    Opt.BorderSizePixel = 0
    Opt.ZIndex = 105
    Opt.Parent = Scroll
    Round(Opt, 8)
    Glass(Opt, 0.3)
    
    local TitleLbl = Instance.new("TextLabel", Opt)
    TitleLbl.Size = UDim2.new(1, -50, 1, 0)
    TitleLbl.Position = UDim2.new(0, 10, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = title
    TitleLbl.TextSize = 11
    TitleLbl.TextColor3 = C.Text
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Font = Enum.Font.GothamMedium
    TitleLbl.ZIndex = 106
    
    local ToggleBG = Instance.new("Frame", Opt)
    ToggleBG.Size = UDim2.new(0, 38, 0, 20)
    ToggleBG.Position = UDim2.new(1, -45, 0.5, -10)
    ToggleBG.BackgroundColor3 = Settings[setting] and C.Neon or Color3.fromRGB(60, 60, 70)
    ToggleBG.BackgroundTransparency = 0.2
    ToggleBG.BorderSizePixel = 0
    ToggleBG.ZIndex = 106
    Round(ToggleBG, 10)
    Glass(ToggleBG, 0.2)
    
    local Circle = Instance.new("Frame", ToggleBG)
    Circle.Size = UDim2.new(0, 14, 0, 14)
    Circle.Position = Settings[setting] and UDim2.new(0, 21, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Circle.BackgroundColor3 = C.Text
    Circle.BorderSizePixel = 0
    Circle.ZIndex = 107
    Round(Circle, 7)
    
    local Btn = Instance.new("TextButton", ToggleBG)
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.ZIndex = 108
    
    Btn.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        Tween(ToggleBG, {BackgroundColor3 = Settings[setting] and C.Neon or Color3.fromRGB(60, 60, 70)})
        Tween(Circle, {Position = Settings[setting] and UDim2.new(0, 21, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)})
        if callback then callback(Settings[setting]) end
    end)
end

local function CreateInput(title, setting, callback)
    local Opt = Instance.new("Frame")
    Opt.Size = UDim2.new(1, 0, 0, 40)
    Opt.BackgroundColor3 = C.Glass
    Opt.BackgroundTransparency = 0.3
    Opt.BorderSizePixel = 0
    Opt.ZIndex = 105
    Opt.Parent = Scroll
    Round(Opt, 8)
    Glass(Opt, 0.3)
    
    local TitleLbl = Instance.new("TextLabel", Opt)
    TitleLbl.Size = UDim2.new(0.4, 0, 1, 0)
    TitleLbl.Position = UDim2.new(0, 10, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = title
    TitleLbl.TextSize = 11
    TitleLbl.TextColor3 = C.Text
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Font = Enum.Font.GothamMedium
    TitleLbl.ZIndex = 106
    
    local Input = Instance.new("TextBox", Opt)
    Input.Size = UDim2.new(0, 110, 0, 26)
    Input.Position = UDim2.new(1, -120, 0.5, -13)
    Input.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Input.BackgroundTransparency = 0.3
    Input.BorderSizePixel = 0
    Input.Text = tostring(Settings[setting])
    Input.PlaceholderText = "Enter..."
    Input.TextColor3 = C.Text
    Input.PlaceholderColor3 = C.TextDim
    Input.TextSize = 10
    Input.Font = Enum.Font.Gotham
    Input.ZIndex = 106
    Round(Input, 6)
    Glass(Input, 0.3)
    
    Input.FocusLost:Connect(function(enter)
        if enter then
            local value = tonumber(Input.Text)
            if value then
                Settings[setting] = value
                if callback then callback(value) end
            else
                Input.Text = tostring(Settings[setting])
            end
        end
    end)
end

local function CreateButton(title, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 40)
    Btn.BackgroundColor3 = C.Neon
    Btn.BackgroundTransparency = 0.3
    Btn.BorderSizePixel = 0
    Btn.Text = title
    Btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    Btn.TextSize = 11
    Btn.Font = Enum.Font.GothamBold
    Btn.AutoButtonColor = false
    Btn.ZIndex = 105
    Btn.Parent = Scroll
    Round(Btn, 8)
    Glass(Btn, 0.3)
    
    Btn.MouseButton1Click:Connect(callback)
    
    Btn.MouseEnter:Connect(function()
        Tween(Btn, {BackgroundTransparency = 0.1})
    end)
    
    Btn.MouseLeave:Connect(function()
        Tween(Btn, {BackgroundTransparency = 0.3})
    end)
    
    return Btn
end

-- ═══════════════════════════════════════════════════════════
--           MULTI-SELECT PET DROPDOWN (NAME BASED)
-- ═══════════════════════════════════════════════════════════

local function isPetNameSelected(petSlot, petName)
    for _, name in ipairs(Settings[petSlot]) do
        if name == petName then return true end
    end
    return false
end

local function isPetNameInOtherTeam(currentPetSlot, petName)
    local otherPetSlot = (currentPetSlot == "Team1Pet1") and "Team1Pet2" or "Team1Pet1"
    return isPetNameSelected(otherPetSlot, petName)
end

local function togglePetNameSelection(petSlot, petName)
    local isSelected = isPetNameSelected(petSlot, petName)
    
    if isSelected then
        for i, name in ipairs(Settings[petSlot]) do
            if name == petName then
                table.remove(Settings[petSlot], i)
                print(string.format("❌ Removed: %s from %s", petName, petSlot))
                break
            end
        end
    else
        if isPetNameInOtherTeam(petSlot, petName) then
            warn(string.format("⚠️ Pet '%s' is already selected in the other team!", petName))
            return false
        end
        
        table.insert(Settings[petSlot], petName)
        print(string.format("✅ Added: %s to %s", petName, petSlot))
    end
    
    return true
end

local function CreateMultiSelectPetDropdown(labelText, petSlot, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundColor3 = C.Glass
    Container.BackgroundTransparency = 0.3
    Container.BorderSizePixel = 0
    Container.ZIndex = 105
    Container.Parent = Scroll
    Round(Container, 8)
    Glass(Container, 0.3)
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 70, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = C.TextDim
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.GothamMedium
    Label.ZIndex = 106
    Label.Parent = Container
    
    local DropBtn = Instance.new("TextButton")
    DropBtn.Size = UDim2.new(1, -90, 0, 30)
    DropBtn.Position = UDim2.new(0, 80, 0, 5)
    DropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    DropBtn.BackgroundTransparency = 0.3
    DropBtn.BorderSizePixel = 0
    DropBtn.Text = string.format("Selected: %d pets", #Settings[petSlot])
    DropBtn.TextColor3 = C.Text
    DropBtn.TextSize = 10
    DropBtn.TextTruncate = Enum.TextTruncate.AtEnd
    DropBtn.Font = Enum.Font.Gotham
    DropBtn.ZIndex = 106
    DropBtn.Parent = Container
    Round(DropBtn, 6)
    Glass(DropBtn, 0.3)
    
    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Position = UDim2.new(1, -25, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.TextColor3 = C.TextDim
    Arrow.TextSize = 10
    Arrow.Font = Enum.Font.GothamBold
    Arrow.ZIndex = 107
    Arrow.Parent = DropBtn
    
    local DropList = Instance.new("ScrollingFrame")
    DropList.Size = UDim2.new(1, -90, 0, 0)
    DropList.Position = UDim2.new(0, 80, 0, 40)
    DropList.BackgroundColor3 = Color3.fromRGB(25, 30, 25)
    DropList.BackgroundTransparency = 0.1
    DropList.BorderSizePixel = 0
    DropList.ScrollBarThickness = 4
    DropList.ScrollBarImageColor3 = C.Neon
    DropList.CanvasSize = UDim2.new(0, 0, 0, 0)
    DropList.Visible = false
    DropList.ZIndex = 200
    DropList.Parent = Container
    Round(DropList, 6)
    
    local ListStroke = Instance.new("UIStroke", DropList)
    ListStroke.Color = C.Neon
    ListStroke.Thickness = 2
    ListStroke.Transparency = 0.5
    
    local ListLayout = Instance.new("UIListLayout", DropList)
    ListLayout.Padding = UDim.new(0, 2)
    
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        DropList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 4)
    end)
    
    DropBtn.MouseButton1Click:Connect(function()
        if DropList.Visible then
            Tween(DropList, {Size = UDim2.new(1, -90, 0, 0)}, 0.2)
            Tween(Arrow, {Rotation = 0}, 0.2)
            wait(0.2)
            DropList.Visible = false
        else
            for _, child in pairs(DropList:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
            end
            
            local allPets = getPetsFromPlayerPens()
            
            local availablePets = {}
            for _, pet in ipairs(allPets) do
                if not isPetNameInOtherTeam(petSlot, pet.Name) then
                    table.insert(availablePets, pet)
                end
            end
            
            if #availablePets == 0 then
                local EmptyLabel = Instance.new("TextLabel")
                EmptyLabel.Size = UDim2.new(1, 0, 0, 30)
                EmptyLabel.BackgroundTransparency = 1
                EmptyLabel.Text = "❌ No available pets"
                EmptyLabel.TextColor3 = C.TextDim
                EmptyLabel.TextSize = 9
                EmptyLabel.Font = Enum.Font.Gotham
                EmptyLabel.ZIndex = 201
                EmptyLabel.Parent = DropList
            else
                for i, pet in ipairs(availablePets) do
                    local PetItem = Instance.new("TextButton")
                    PetItem.Size = UDim2.new(1, 0, 0, 32)
                    PetItem.BackgroundColor3 = Color3.fromRGB(35, 40, 35)
                    PetItem.BackgroundTransparency = 0.3
                    PetItem.BorderSizePixel = 0
                    PetItem.AutoButtonColor = false
                    PetItem.ZIndex = 201
                    PetItem.Parent = DropList
                    Round(PetItem, 4)
                    
                    local PetIcon = Instance.new("TextLabel")
                    PetIcon.Size = UDim2.new(0, 25, 0, 25)
                    PetIcon.Position = UDim2.new(0, 5, 0.5, -12.5)
                    PetIcon.BackgroundTransparency = 1
                    PetIcon.Text = "🐾"
                    PetIcon.TextSize = 16
                    PetIcon.ZIndex = 202
                    PetIcon.Parent = PetItem
                    
                    local PetName = Instance.new("TextLabel")
                    PetName.Size = UDim2.new(1, -80, 0, 14)
                    PetName.Position = UDim2.new(0, 35, 0, 4)
                    PetName.BackgroundTransparency = 1
                    PetName.Text = pet.Name
                    PetName.TextColor3 = C.Text
                    PetName.TextSize = 9
                    PetName.TextXAlignment = Enum.TextXAlignment.Left
                    PetName.TextTruncate = Enum.TextTruncate.AtEnd
                    PetName.Font = Enum.Font.GothamBold
                    PetName.ZIndex = 202
                    PetName.Parent = PetItem
                    
                    local PetInfo = Instance.new("TextLabel")
                    PetInfo.Size = UDim2.new(1, -80, 0, 10)
                    PetInfo.Position = UDim2.new(0, 35, 0, 18)
                    PetInfo.BackgroundTransparency = 1
                    PetInfo.Text = string.format("%s • Pen %s", pet.Rarity, pet.PenNumber)
                    PetInfo.TextColor3 = C.TextDim
                    PetInfo.TextSize = 7
                    PetInfo.TextXAlignment = Enum.TextXAlignment.Left
                    PetInfo.Font = Enum.Font.Gotham
                    PetInfo.ZIndex = 202
                    PetInfo.Parent = PetItem
                    
                    local CheckBox = Instance.new("Frame")
                    CheckBox.Size = UDim2.new(0, 16, 0, 16)
                    CheckBox.Position = UDim2.new(1, -25, 0.5, -8)
                    CheckBox.BackgroundColor3 = isPetNameSelected(petSlot, pet.Name) and C.Neon or Color3.fromRGB(60, 60, 70)
                    CheckBox.BackgroundTransparency = 0.2
                    CheckBox.BorderSizePixel = 0
                    CheckBox.ZIndex = 202
                    CheckBox.Parent = PetItem
                    Round(CheckBox, 4)
                    
                    local CheckMark = Instance.new("TextLabel")
                    CheckMark.Size = UDim2.new(1, 0, 1, 0)
                    CheckMark.BackgroundTransparency = 1
                    CheckMark.Text = isPetNameSelected(petSlot, pet.Name) and "✓" or ""
                    CheckMark.TextColor3 = Color3.fromRGB(0, 0, 0)
                    CheckMark.TextSize = 12
                    CheckMark.Font = Enum.Font.GothamBold
                    CheckMark.ZIndex = 203
                    CheckMark.Parent = CheckBox
                    
                    PetItem.MouseButton1Click:Connect(function()
                        local success = togglePetNameSelection(petSlot, pet.Name)
                        
                        if success then
                            local isSelected = isPetNameSelected(petSlot, pet.Name)
                            Tween(CheckBox, {BackgroundColor3 = isSelected and C.Neon or Color3.fromRGB(60, 60, 70)})
                            CheckMark.Text = isSelected and "✓" or ""
                            
                            DropBtn.Text = string.format("Selected: %d pets", #Settings[petSlot])
                            
                            if callback then callback(Settings[petSlot]) end
                        end
                    end)
                    
                    PetItem.MouseEnter:Connect(function()
                        Tween(PetItem, {BackgroundTransparency = 0.1})
                    end)
                    
                    PetItem.MouseLeave:Connect(function()
                        Tween(PetItem, {BackgroundTransparency = 0.3})
                    end)
                end
            end
            
            DropList.Visible = true
            local targetHeight = math.min(150, ListLayout.AbsoluteContentSize.Y + 4)
            Tween(DropList, {Size = UDim2.new(1, -90, 0, targetHeight)}, 0.2)
            Tween(Arrow, {Rotation = 180}, 0.2)
        end
    end)
    
    DropBtn.MouseEnter:Connect(function()
        Tween(DropBtn, {BackgroundTransparency = 0.1})
    end)
    
    DropBtn.MouseLeave:Connect(function()
        Tween(DropBtn, {BackgroundTransparency = 0.3})
    end)
    
    return Container
end

-- ═══════════════════════════════════════════════════════════
--                      TAB CONTENTS
-- ═══════════════════════════════════════════════════════════

function LoadHomeTab()
    local welcome = Instance.new("TextLabel")
    welcome.Size = UDim2.new(1, 0, 0, 100)
    welcome.BackgroundColor3 = C.Glass
    welcome.BackgroundTransparency = 0.3
    welcome.BorderSizePixel = 0
    welcome.Text = "Welcome to Low Hub\n\nv0.18.0 Final\nName-Based Pet System\n\n✨ Direct from workspace.PlayerPens"
    welcome.TextColor3 = C.Neon
    welcome.TextSize = 12
    welcome.Font = Enum.Font.GothamBold
    welcome.ZIndex = 105
    welcome.Parent = Scroll
    Round(welcome, 8)
    Glass(welcome, 0.3)
    
    local features = Instance.new("TextLabel")
    features.Size = UDim2.new(1, 0, 0, 110)
    features.BackgroundColor3 = C.Glass
    features.BackgroundTransparency = 0.3
    features.BorderSizePixel = 0
    features.Text = "🎯 Features:\n\n✅ Name-Based Pet Selection\n✅ Real-time Object Fetching\n✅ Smart Pet Exclusion\n✅ Multi-Select System\n✅ Auto Breed with Cycle\n\n🔄 Pets fetched by name!"
    features.TextColor3 = C.Text
    features.TextSize = 10
    features.TextXAlignment = Enum.TextXAlignment.Left
    features.Font = Enum.Font.Gotham
    features.ZIndex = 105
    features.Parent = Scroll
    Round(features, 8)
    Glass(features, 0.3)
    
    local featuresPad = Instance.new("UIPadding", features)
    featuresPad.PaddingLeft = UDim.new(0, 10)
end

function LoadPlayerTab()
    CreateInput("Set Speed", "Speed", function(value)
        Humanoid.WalkSpeed = value
    end)
    
    CreateToggle("Enable Walkspeed", "WalkspeedEnabled", function(enabled)
        Humanoid.WalkSpeed = enabled and 100 or Settings.Speed
    end)
    
    CreateToggle("No Clip", "NoClip", function(enabled)
        if enabled then
            _G.NoClip = RunService.Stepped:Connect(function()
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        else
            if _G.NoClip then
                _G.NoClip:Disconnect()
                _G.NoClip = nil
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
    end)
    
    CreateToggle("Infinite Jump", "InfJump", function(enabled)
        if enabled then
            _G.InfJump = UserInputService.JumpRequest:Connect(function()
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        else
            if _G.InfJump then 
                _G.InfJump:Disconnect()
                _G.InfJump = nil
            end
        end
    end)
    
    if Settings.WalkspeedEnabled then
        Humanoid.WalkSpeed = 100
    else
        Humanoid.WalkSpeed = Settings.Speed
    end
    
    if Settings.NoClip and not _G.NoClip then
        _G.NoClip = RunService.Stepped:Connect(function()
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
    
    if Settings.InfJump and not _G.InfJump then
        _G.InfJump = UserInputService.JumpRequest:Connect(function()
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end

function LoadBreedingTab()
    local pets = getPetsFromPlayerPens()
    
    local InfoPanel = Instance.new("TextLabel")
    InfoPanel.Size = UDim2.new(1, 0, 0, 60)
    InfoPanel.BackgroundColor3 = C.Glass
    InfoPanel.BackgroundTransparency = 0.3
    InfoPanel.BorderSizePixel = 0
    InfoPanel.Name = "InfoPanel"
    InfoPanel.Text = string.format("🧬 Team 1 Breeding\n\n%d pets in PlayerPen • %d total breeds", 
        #pets, Settings.TotalBreeds)
    InfoPanel.TextColor3 = C.Text
    InfoPanel.TextSize = 11
    InfoPanel.Font = Enum.Font.Gotham
    InfoPanel.ZIndex = 105
    InfoPanel.Parent = Scroll
    Round(InfoPanel, 8)
    Glass(InfoPanel, 0.3)
    
    CreateMultiSelectPetDropdown("Pet 1:", "Team1Pet1")
    CreateMultiSelectPetDropdown("Pet 2:", "Team1Pet2")
    
    CreateButton("🗑️ Clear Pet 1 Selection", function()
        Settings.Team1Pet1 = {}
        print("🗑️ Cleared Pet 1 selection")
        LoadBreedingTab()
    end)
    
    CreateButton("🗑️ Clear Pet 2 Selection", function()
        Settings.Team1Pet2 = {}
        print("🗑️ Cleared Pet 2 selection")
        LoadBreedingTab()
    end)
    
    CreateInput("Breed Delay (seconds)", "BreedDelay")
    
    CreateToggle("Auto Breed Team 1", "AutoBreeding", function(enabled)
        if enabled then
            if #Settings.Team1Pet1 == 0 or #Settings.Team1Pet2 == 0 then
                warn("⚠️ Please select pets first!")
                Settings.AutoBreeding = false
                return
            end
            
            if _G.AutoBreedTeam1 then
                task.cancel(_G.AutoBreedTeam1)
                _G.AutoBreedTeam1 = nil
            end
            
            _G.AutoBreedTeam1 = task.spawn(function()
                print("════════════════════════════════════════════")
                print("🚀 AUTO BREED STARTED!")
                print(string.format("📊 Pet 1: %d pets selected", #Settings.Team1Pet1))
                print(string.format("📊 Pet 2: %d pets selected", #Settings.Team1Pet2))
                print(string.format("⏱️  Delay: %d seconds", Settings.BreedDelay))
                print("════════════════════════════════════════════")
                
                local pet1Index = 1
                local pet2Index = 1
                
                while Settings.AutoBreeding do
                    if #Settings.Team1Pet1 > 0 and #Settings.Team1Pet2 > 0 then
                        local petName1 = Settings.Team1Pet1[pet1Index]
                        local petName2 = Settings.Team1Pet2[pet2Index]
                        
                        breedPets(petName1, petName2)
                        
                        pet2Index = pet2Index + 1
                        if pet2Index > #Settings.Team1Pet2 then
                            pet2Index = 1
                            pet1Index = pet1Index + 1
                            if pet1Index > #Settings.Team1Pet1 then
                                pet1Index = 1
                                print(string.format("🔄 Cycled all pets. Total: %d", Settings.TotalBreeds))
                            end
                        end
                        
                        local info = Scroll:FindFirstChild("InfoPanel")
                        if info then
                            info.Text = string.format("🧬 Team 1 Breeding\n\n%d pets in PlayerPen • %d total breeds", 
                                #getPetsFromPlayerPens(), Settings.TotalBreeds)
                        end
                    else
                        warn("⚠️ No pets available!")
                        Settings.AutoBreeding = false
                        break
                    end
                    
                    task.wait(Settings.BreedDelay)
                end
                
                print("════════════════════════════════════════════")
                print("⏹️  AUTO BREED STOPPED!")
                print(string.format("📈 Total Breeds: %d", Settings.TotalBreeds))
                print("════════════════════════════════════════════")
            end)
        else
            if _G.AutoBreedTeam1 then
                task.cancel(_G.AutoBreedTeam1)
                _G.AutoBreedTeam1 = nil
                print("⏹️  Auto breeding stopped!")
            end
        end
    end)
    
    CreateButton("🔄 Refresh Pet List", function()
        LoadBreedingTab()
        print("✅ Pet list refreshed!")
    end)
end

function LoadEggTab()
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 80)
    info.BackgroundColor3 = C.Glass
    info.BackgroundTransparency = 0.3
    info.BorderSizePixel = 0
    info.Text = "🥚 Egg Features\n\nComing Soon...\n\n🚧 Under Development"
    info.TextColor3 = C.Neon
    info.TextSize = 12
    info.Font = Enum.Font.GothamBold
    info.ZIndex = 105
    info.Parent = Scroll
    Round(info, 8)
    Glass(info, 0.3)
end

-- ═══════════════════════════════════════════════════════════
--                      CREATE TABS
-- ═══════════════════════════════════════════════════════════

CreateTab("Home", "🏠", 1)
CreateTab("Player", "👤", 2)
CreateTab("Breeding", "🧬", 3)
CreateTab("Egg", "🥚", 4)

-- ═══════════════════════════════════════════════════════════
--                     FUNCTIONALITY
-- ═══════════════════════════════════════════════════════════

Icon.MouseButton1Click:Connect(function()
    Main.Visible = true
    Icon.Visible = false
    Main.Size = UDim2.new(0, 0, 0, 0)
    Tween(Main, {Size = UDim2.new(0, 560, 0, 380)}, 0.4)
end)

CloseBtn.MouseButton1Click:Connect(function()
    if _G.AutoBreedTeam1 then
        task.cancel(_G.AutoBreedTeam1)
        _G.AutoBreedTeam1 = nil
        Settings.AutoBreeding = false
    end
    
    Tween(Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    Tween(Icon, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    wait(0.4)
    GUI:Destroy()
end)

MinBtn.MouseButton1Click:Connect(function()
    Tween(Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    wait(0.3)
    Main.Visible = false
    Icon.Visible = true
end)

CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {BackgroundTransparency = 0.1}) end)
CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {BackgroundTransparency = 0.3}) end)
MinBtn.MouseEnter:Connect(function() Tween(MinBtn, {BackgroundTransparency = 0.1}) end)
MinBtn.MouseLeave:Connect(function() Tween(MinBtn, {BackgroundTransparency = 0.3}) end)

local dragging, dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ═══════════════════════════════════════════════════════════
--                      AUTO START
-- ═══════════════════════════════════════════════════════════

wait(0.5)

for _, tab in pairs(Sidebar:GetChildren()) do
    if tab:IsA("TextButton") then
        tab.MouseButton1Click:Fire()
        break
    end
end

print("════════════════════════════════════════════")
print("✅ LOW HUB v0.18.0 FINAL LOADED!")
print("🧬 Name-Based Pet Selection System")
print("📍 Pets from workspace.PlayerPens")
print("🚫 Smart Pet Exclusion Enabled")
print("⚙️  Auto Breed: Toggle ON to start")
print("🔄 Real-time pet fetching by name")
print("💾 Pets stored as names only")
print("════════════════════════════════════════════")
