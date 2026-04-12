-- Third Person Mouse Movement Aimbot (using mousemoverel)
-- Updated for better compatibility in third-person games

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Third Person Mouse Aimbot",
    Footer = "Mouse Movement Version",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Aimbot Variables
local AimKey = Enum.UserInputType.MouseButton2
local AimPart = "Head"
local Smoothing = 0.25          -- Lower = faster/more snappy (0.1 ~ 0.4 recommended)
local FOV = 180
local TeamCheck = true
local VisibleCheck = true
local Prediction = 0.12
local SensitivityMultiplier = 1.0   -- Adjust if aim feels too slow/fast

local Target = nil

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255, 100, 100)
FOVCircle.Filled = false
FOVCircle.Transparency = 0.6
FOVCircle.NumSides = 64
FOVCircle.Radius = FOV
FOVCircle.Visible = false

-- Get closest player (screen distance)
local function GetClosestPlayer()
    local Closest = nil
    local Shortest = FOV

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Char = Player.Character
            local Humanoid = Char:FindFirstChild("Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                if TeamCheck and Player.Team == LocalPlayer.Team then continue end

                local Part = Char:FindFirstChild(AimPart) or Char:FindFirstChild("Head")
                if not Part then continue end

                -- Visibility check
                if VisibleCheck then
                    local RayParams = RaycastParams.new()
                    RayParams.FilterDescendantsInstances = {LocalPlayer.Character or {}}
                    RayParams.FilterType = Enum.RaycastFilterType.Exclude
                    local Result = workspace:Raycast(Camera.CFrame.Position, (Part.Position - Camera.CFrame.Position).Unit * 1000, RayParams)
                    if not Result or Result.Instance:IsDescendantOf(Char) == false then continue end
                end

                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position + Vector3.new(0, 0.1, 0)) -- slight offset
                if OnScreen then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if Dist < Shortest then
                        Shortest = Dist
                        Closest = Part
                    end
                end
            end
        end
    end
    return Closest
end

-- Main loop (mouse movement)
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = FOV
    FOVCircle.Visible = Toggles.AimbotEnabled.Value and Toggles.ShowFOV.Value

    if not Toggles.AimbotEnabled.Value then return end

    -- Hold aim key (Right Click by default)
    if not UserInputService:IsMouseButtonPressed(AimKey) then
        Target = nil
        return
    end

    Target = GetClosestPlayer()

    if Target then
        local TargetPos = Target.Position

        -- Simple velocity prediction
        local Root = Target.Parent and Target.Parent:FindFirstChild("HumanoidRootPart")
        if Root then
            TargetPos = TargetPos + (Root.Velocity * Prediction)
        end

        local ScreenPos = Camera:WorldToViewportPoint(TargetPos)
        local MousePos = UserInputService:GetMouseLocation()

        local DeltaX = (ScreenPos.X - MousePos.X) * SensitivityMultiplier
        local DeltaY = (ScreenPos.Y - MousePos.Y) * SensitivityMultiplier

        -- Apply smoothing
        mousemoverel(DeltaX * (1 - Smoothing), DeltaY * (1 - Smoothing))
    end
end)

-- ==================== UI ====================

local LeftGroup = Tabs.Main:AddLeftGroupbox("Aimbot Settings")

LeftGroup:AddToggle("AimbotEnabled", { Text = "Enable Aimbot", Default = false })

LeftGroup:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
LeftGroup:AddToggle("VisibleCheck", { Text = "Visibility Check", Default = true })
LeftGroup:AddToggle("ShowFOV", { Text = "Show FOV Circle", Default = true })

LeftGroup:AddSlider("FOVSlider", {
    Text = "FOV Radius",
    Default = 180,
    Min = 50,
    Max = 600,
    Rounding = 0,
    Callback = function(v) FOV = v end,
})

LeftGroup:AddSlider("SmoothingSlider", {
    Text = "Smoothing (Lower = Snappier)",
    Default = 0.25,
    Min = 0.05,
    Max = 0.8,
    Rounding = 2,
    Callback = function(v) Smoothing = v end,
})

LeftGroup:AddSlider("PredictionSlider", {
    Text = "Prediction",
    Default = 0.12,
    Min = 0,
    Max = 0.4,
    Rounding = 2,
    Callback = function(v) Prediction = v end,
})

LeftGroup:AddSlider("SensitivitySlider", {
    Text = "Sensitivity Multiplier",
    Default = 1.0,
    Min = 0.5,
    Max = 2.5,
    Rounding = 2,
    Callback = function(v) SensitivityMultiplier = v end,
})

LeftGroup:AddDropdown("AimPartDropdown", {
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = 1,
    Text = "Aim Part",
    Callback = function(v) AimPart = v end,
})

LeftGroup:AddLabel("Aim Key"):AddKeyPicker("AimKeyPicker", {
    Default = "MouseButton2",
    Text = "Aim Key",
    Mode = "Hold",
})

-- Right side
local RightGroup = Tabs.Main:AddRightGroupbox("Misc")
RightGroup:AddButton({ Text = "Unload Script", Func = function() Library:Unload() end })

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddButton({ Text = "Unload", Func = function() Library:Unload() end })

-- Theme & Config
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("MouseAimbot")
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:BuildConfigSection(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    FOVCircle:Remove()
    print("Mouse Aimbot unloaded")
end)

-- Sync toggles
Toggles.AimbotEnabled:OnChanged(function() end)
Toggles.TeamCheck:OnChanged(function(v) TeamCheck = v end)
Toggles.VisibleCheck:OnChanged(function(v) VisibleCheck = v end)

print("Third Person Mouse Movement Aimbot loaded!")
print("Hold Right Mouse Button to aim • Open menu with RightShift")
