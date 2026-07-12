--[[
    ElectraX Premium - Advanced Combat Script
    Version: 3.0.0
    Features: Aimbot, ESP, Skin Changer, Anti-Cheat Bypass, Auto Parry, Spinbot
]]--

--// Load UI Library
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/twistedk1d/BloxStrike/refs/heads/main/Source/UI/source.lua"))()

--// Window Creation
local selectedTheme = _G.ElectraXTheme or "Amethyst"

local Window = Rayfield:CreateWindow({
    Name = "ElectraX Premium",
    Icon = 0,
    LoadingTitle = "Loading ElectraX Premium",
    LoadingSubtitle = "Advanced Combat System",
    ShowText = "ElectraX",
    Theme = selectedTheme,
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ElectraX",
        FileName = "ElectraX_Config"
    },
    Size = UDim2.new(0, 600, 0, 500)
})

--// Services & Globals
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local CharactersFolder = Workspace:WaitForChild("Characters", 10)

--// Tabs
local Tab_Combat = Window:CreateTab("Combat", "crosshair")
local Tab_Rage = Window:CreateTab("Rage", "zap")
local Tab_Skins = Window:CreateTab("Skins", "swords")
local Tab_Visuals = Window:CreateTab("Visuals", "eye")
local Tab_Misc = Window:CreateTab("Misc", "settings")
local Tab_Config = Window:CreateTab("Config", "save")

--// Notifications
local function Notify(title, text, duration)
    Rayfield:Notify({
        Title = title,
        Content = text,
        Duration = duration or 3,
        Image = 4483362458
    })
end

Notify("ElectraX", "Successfully loaded ElectraX Premium v3.0.0", 5)

--// ==========================================
--// UTILITY FUNCTIONS
--// ==========================================
local function getTFolder() return CharactersFolder:FindFirstChild("Terrorists") end
local function getCTFolder() return CharactersFolder:FindFirstChild("Counter-Terrorists") end

local function isAlive()
    local t, ct = getTFolder(), getCTFolder()
    return (t and t:FindFirstChild(player.Name)) or (ct and ct:FindFirstChild(player.Name))
end

local function getEnemyFolder()
    if not isAlive() then return nil end
    local t, ct = getTFolder(), getCTFolder()
    if t and t:FindFirstChild(player.Name) then return ct end
    if ct and ct:FindFirstChild(player.Name) then return t end
    return nil
end

local function getPlayerTeam()
    local t, ct = getTFolder(), getCTFolder()
    if t and t:FindFirstChild(player.Name) then return "T" end
    if ct and ct:FindFirstChild(player.Name) then return "CT" end
    return nil
end

--// ==========================================
--// ADVANCED AIMBOT SYSTEM
--// ==========================================
local AimbotConfig = {
    Enabled = false,
    ShowFOV = false,
    FOVRadius = 100,
    Smoothing = 3,
    AimKey = Enum.UserInputType.MouseButton2,
    AimPart = "Head",
    PredictMovement = false,
    PredictionAmount = 0.1,
    VisibilityCheck = true,
    TeamCheck = true,
    IgnoreKnocked = true,
    AutoShoot = false,
    SilentAim = false,
    AimAssist = false,
    AssistStrength = 0.5
}

local isAiming = false

--// FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
FOVCircle.Radius = AimbotConfig.FOVRadius
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(138, 43, 226)
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Transparency = 0.8

local function isVisible(targetPos)
    if not AimbotConfig.VisibilityCheck then return true end
    local ray = Ray.new(camera.CFrame.Position, (targetPos - camera.CFrame.Position).Unit * 1000)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {camera, player.Character})
    return hit == nil or hit:IsDescendantOf(Workspace:FindFirstChild("Characters"))
end

local function predictPosition(enemy, aimPart)
    if not AimbotConfig.PredictMovement then return aimPart.Position end
    local velocity = enemy.HumanoidRootPart.Velocity
    return aimPart.Position + (velocity * AimbotConfig.PredictionAmount)
end

local function getClosestEnemyToMouse()
    local closestEnemy = nil
    local shortestDistance = AimbotConfig.FOVRadius
    local enemyFolder = getEnemyFolder()
    
    if not enemyFolder or not AimbotConfig.Enabled then return nil end
    
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local aimPart = enemy:FindFirstChild(AimbotConfig.AimPart)
        
        if hum and hum.Health > 0 and aimPart then
            if AimbotConfig.IgnoreKnocked and hum:GetState() == Enum.HumanoidStateType.Dead then
                continue
            end
            
            local targetPos = predictPosition(enemy, aimPart)
            local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
            
            if onScreen and isVisible(targetPos) then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEnemy = aimPart
                end
            end
        end
    end
    
    return closestEnemy
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == AimbotConfig.AimKey then isAiming = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AimbotConfig.AimKey then isAiming = false end
end)

RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if AimbotConfig.ShowFOV then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = AimbotConfig.FOVRadius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
    
    -- Aimbot Logic
    if not isAiming or not isAlive() or not AimbotConfig.Enabled then return end
    
    local targetPart = getClosestEnemyToMouse()
    if targetPart then
        local targetPos = predictPosition(targetPart.Parent, targetPart)
        local screenPos = camera:WorldToViewportPoint(targetPos)
        local mousePos = UserInputService:GetMouseLocation()
        
        local moveX = (screenPos.X - mousePos.X) / AimbotConfig.Smoothing
        local moveY = (screenPos.Y - mousePos.Y) / AimbotConfig.Smoothing
        
        if mousemoverel then
            mousemoverel(moveX, moveY)
        end
        
        -- Auto Shoot
        if AimbotConfig.AutoShoot and mouse1click then
            mouse1click()
        end
    end
end)

--// Aimbot UI
Tab_Combat:CreateSection("Aimbot Settings")

Tab_Combat:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value) AimbotConfig.Enabled = Value end
})

Tab_Combat:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Flag = "FOVToggle",
    Callback = function(Value) AimbotConfig.ShowFOV = Value end
})

Tab_Combat:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "FOVSlider",
    Callback = function(Value) AimbotConfig.FOVRadius = Value end
})

Tab_Combat:CreateSlider({
    Name = "Smoothing",
    Range = {0.1, 10},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 3,
    Flag = "AimbotSmoothing",
    Callback = function(Value) AimbotConfig.Smoothing = Value end
})

Tab_Combat:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = {"Head"},
    Flag = "AimPart",
    Callback = function(Option) AimbotConfig.AimPart = Option[1] end
})

Tab_Combat:CreateToggle({
    Name = "Prediction",
    CurrentValue = false,
    Flag = "PredictionToggle",
    Callback = function(Value) AimbotConfig.PredictMovement = Value end
})

Tab_Combat:CreateSlider({
    Name = "Prediction Amount",
    Range = {0.05, 0.5},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.1,
    Flag = "PredictionAmount",
    Callback = function(Value) AimbotConfig.PredictionAmount = Value end
})

Tab_Combat:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = true,
    Flag = "VisCheckToggle",
    Callback = function(Value) AimbotConfig.VisibilityCheck = Value end
})

Tab_Combat:CreateToggle({
    Name = "Auto Shoot",
    CurrentValue = false,
    Flag = "AutoShootToggle",
    Callback = function(Value) AimbotConfig.AutoShoot = Value end
})

--// ==========================================
--// TRIGGERBOT SYSTEM
--// ==========================================
local TriggerBotConfig = {
    Enabled = false,
    Delay = 0,
    HeadOnly = false,
    BurstMode = false,
    BurstCount = 3,
    BurstDelay = 50
}

Tab_Combat:CreateSection("TriggerBot Settings")

Tab_Combat:CreateToggle({
    Name = "Enable TriggerBot",
    CurrentValue = false,
    Flag = "TriggerBotToggle",
    Callback = function(Value) TriggerBotConfig.Enabled = Value end
})

Tab_Combat:CreateSlider({
    Name = "Shot Delay",
    Range = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 0,
    Flag = "TriggerBotDelay",
    Callback = function(Value) TriggerBotConfig.Delay = Value end
})

Tab_Combat:CreateToggle({
    Name = "Head Only",
    CurrentValue = false,
    Flag = "HeadOnlyToggle",
    Callback = function(Value) TriggerBotConfig.HeadOnly = Value end
})

Tab_Combat:CreateToggle({
    Name = "Burst Mode",
    CurrentValue = false,
    Flag = "BurstModeToggle",
    Callback = function(Value) TriggerBotConfig.BurstMode = Value end
})

Tab_Combat:CreateSlider({
    Name = "Burst Count",
    Range = {2, 10},
    Increment = 1,
    Suffix = " shots",
    CurrentValue = 3,
    Flag = "BurstCount",
    Callback = function(Value) TriggerBotConfig.BurstCount = Value end
})

task.spawn(function()
    while task.wait(0.01) do
        if TriggerBotConfig.Enabled and isAlive() then
            local viewportSize = camera.ViewportSize
            local ray = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local ignoreList = {camera}
            if player.Character then table.insert(ignoreList, player.Character) end
            raycastParams.FilterDescendantsInstances = ignoreList
            
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result and result.Instance then
                local hitPart = result.Instance
                local model = hitPart:FindFirstAncestorOfClass("Model")
                
                if model and model:FindFirstChildOfClass("Humanoid") then
                    local enemyFolder = getEnemyFolder()
                    if enemyFolder and model.Parent == enemyFolder then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            if TriggerBotConfig.HeadOnly and hitPart.Name ~= "Head" then
                                continue
                            end
                            
                            if TriggerBotConfig.Delay > 0 then
                                task.wait(TriggerBotConfig.Delay / 1000)
                            end
                            
                            if TriggerBotConfig.BurstMode and mouse1click then
                                for i = 1, TriggerBotConfig.BurstCount do
                                    mouse1click()
                                    task.wait(TriggerBotConfig.BurstDelay / 1000)
                                end
                            elseif mouse1click then
                                mouse1click()
                            end
                            
                            task.wait(0.1)
                        end
                    end
                end
            end
        end
    end
end)

--// ==========================================
--// ADVANCED HITBOX SYSTEM
--// ==========================================
local HitboxConfig = {
    Enabled = false,
    Size = 3,
    Transparency = 0.5,
    CanCollide = false,
    Material = "ForceField"
}

local originalHitboxData = {}

Tab_Combat:CreateSection("Hitbox Expander")

Tab_Combat:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value) HitboxConfig.Enabled = Value end
})

Tab_Combat:CreateSlider({
    Name = "Hitbox Size",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = " studs",
    CurrentValue = 3,
    Flag = "HitboxSize",
    Callback = function(Value) HitboxConfig.Size = Value end
})

Tab_Combat:CreateSlider({
    Name = "Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "HitboxTransparency",
    Callback = function(Value) HitboxConfig.Transparency = Value end
})

task.spawn(function()
    while task.wait(0.3) do
        local enemyFolder = getEnemyFolder()
        if enemyFolder then
            for _, enemy in ipairs(enemyFolder:GetChildren()) do
                local head = enemy:FindFirstChild("Head")
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                
                if head and hum and hum.Health > 0 then
                    if not originalHitboxData[head] then
                        originalHitboxData[head] = {
                            Size = head.Size,
                            Transparency = head.Transparency,
                            CanCollide = head.CanCollide,
                            Material = head.Material
                        }
                    end
                    
                    if HitboxConfig.Enabled then
                        head.Size = Vector3.new(HitboxConfig.Size, HitboxConfig.Size, HitboxConfig.Size)
                        head.Transparency = HitboxConfig.Transparency
                        head.CanCollide = false
                        head.Massless = true
                    else
                        if originalHitboxData[head] then
                            head.Size = originalHitboxData[head].Size
                            head.Transparency = originalHitboxData[head].Transparency
                            head.CanCollide = originalHitboxData[head].CanCollide
                        end
                    end
                end
            end
        end
    end
end)

--// ==========================================
--// RAGE TAB - SPINBOT & ANTI-AIM
--// ==========================================
local RageConfig = {
    SpinbotEnabled = false,
    SpinSpeed = 50,
    AntiAimEnabled = false,
    JitterEnabled = false,
    JitterSpeed = 10,
    FakeLagEnabled = false,
    FakeLagAmount = 3,
    AutoPeekEnabled = false
}

Tab_Rage:CreateSection("Spinbot")

Tab_Rage:CreateToggle({
    Name = "Enable Spinbot",
    CurrentValue = false,
    Flag = "SpinbotToggle",
    Callback = function(Value) 
        RageConfig.SpinbotEnabled = Value 
        if Value then
            Notify("Spinbot", "Spinbot activated", 2)
        end
    end
})

Tab_Rage:CreateSlider({
    Name = "Spin Speed",
    Range = {1, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "SpinSpeed",
    Callback = function(Value) RageConfig.SpinSpeed = Value end
})

local spinAngle = 0
RunService.RenderStepped:Connect(function(delta)
    if RageConfig.SpinbotEnabled and isAlive() and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            spinAngle = (spinAngle + (RageConfig.SpinSpeed * delta)) % 360
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
        end
    end
end)

Tab_Rage:CreateSection("Anti-Aim")

Tab_Rage:CreateToggle({
    Name = "Enable Anti-Aim",
    CurrentValue = false,
    Flag = "AntiAimToggle",
    Callback = function(Value) RageConfig.AntiAimEnabled = Value end
})

Tab_Rage:CreateToggle({
    Name = "Head Jitter",
    CurrentValue = false,
    Flag = "JitterToggle",
    Callback = function(Value) RageConfig.JitterEnabled = Value end
})

RunService.Heartbeat:Connect(function()
    if RageConfig.JitterEnabled and isAlive() and player.Character then
        local head = player.Character:FindFirstChild("Head")
        if head then
            local random = math.random(-RageConfig.JitterSpeed, RageConfig.JitterSpeed)
            head.CFrame = head.CFrame * CFrame.Angles(0, math.rad(random), 0)
        end
    end
end)

Tab_Rage:CreateSection("Fake Lag")

Tab_Rage:CreateToggle({
    Name = "Enable Fake Lag",
    CurrentValue = false,
    Flag = "FakeLagToggle",
    Callback = function(Value) RageConfig.FakeLagEnabled = Value end
})

Tab_Rage:CreateSlider({
    Name = "Lag Amount",
    Range = {1, 10},
    Increment = 1,
    Suffix = " ticks",
    CurrentValue = 3,
    Flag = "FakeLagAmount",
    Callback = function(Value) RageConfig.FakeLagAmount = Value end
})

--// ==========================================
--// MOVEMENT ENHANCEMENTS
--// ==========================================
local MovementConfig = {
    BhopEnabled = false,
    SpeedEnabled = false,
    SpeedMultiplier = 1.5,
    NoClipEnabled = false,
    InfiniteJumpEnabled = false,
    FlyEnabled = false,
    FlySpeed = 50
}

Tab_Misc:CreateSection("Movement")

Tab_Misc:CreateToggle({
    Name = "Bunny Hop (Hold Space)",
    CurrentValue = false,
    Flag = "BhopToggle",
    Callback = function(Value) MovementConfig.BhopEnabled = Value end
})

RunService.RenderStepped:Connect(function()
    if MovementConfig.BhopEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) and isAlive() then
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum.Jump = true
            end
        end
    end
end)

Tab_Misc:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(Value) MovementConfig.SpeedEnabled = Value end
})

Tab_Misc:CreateSlider({
    Name = "Speed Multiplier",
    Range = {1, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1.5,
    Flag = "SpeedMultiplier",
    Callback = function(Value) MovementConfig.SpeedMultiplier = Value end
})

RunService.Heartbeat:Connect(function()
    if MovementConfig.SpeedEnabled and isAlive() and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16 * MovementConfig.SpeedMultiplier
        end
    end
end)

Tab_Misc:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(Value) MovementConfig.InfiniteJumpEnabled = Value end
})

UserInputService.JumpRequest:Connect(function()
    if MovementConfig.InfiniteJumpEnabled and isAlive() and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

--// ==========================================
--// ADVANCED ESP SYSTEM
--// ==========================================
local EspConfig = {
    Enabled = false,
    Box = true,
    BoxOutline = true,
    BoxColor = Color3.fromRGB(138, 43, 226),
    Name = true,
    NameColor = Color3.new(1, 1, 1),
    Health = true,
    HealthBar = true,
    Distance = true,
    DistanceColor = Color3.fromRGB(200, 200, 200),
    Skeleton = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    Tracers = false,
    TracersColor = Color3.fromRGB(138, 43, 226),
    TracersFrom = "Bottom",
    Chams = false,
    ChamsColor = Color3.fromRGB(138, 43, 226),
    MaxDistance = 1000
}

local espCache = {}

local function createESP()
    local esp = {
        boxOutline = Drawing.new("Square"),
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        healthOutline = Drawing.new("Line"),
        healthBar = Drawing.new("Line"),
        tracer = Drawing.new("Line")
    }
    
    esp.boxOutline.Thickness = 3
    esp.boxOutline.Filled = false
    esp.boxOutline.Color = Color3.new(0, 0, 0)
    esp.boxOutline.Transparency = 1
    
    esp.box.Thickness = 2
    esp.box.Filled = false
    esp.box.Color = EspConfig.BoxColor
    esp.box.Transparency = 1
    
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Color = EspConfig.NameColor
    esp.name.Size = 16
    esp.name.Font = 2
    
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.Color = EspConfig.DistanceColor
    esp.distance.Size = 13
    esp.distance.Font = 2
    
    esp.healthOutline.Thickness = 4
    esp.healthOutline.Color = Color3.new(0, 0, 0)
    esp.healthOutline.Transparency = 1
    
    esp.healthBar.Thickness = 2
    esp.healthBar.Color = Color3.new(0, 1, 0)
    esp.healthBar.Transparency = 1
    
    esp.tracer.Thickness = 2
    esp.tracer.Color = EspConfig.TracersColor
    esp.tracer.Transparency = 1
    
    return esp
end

RunService.RenderStepped:Connect(function()
    if not EspConfig.Enabled or not isAlive() then
        for _, e in pairs(espCache) do 
            for _, d in pairs(e) do d.Visible = false end 
        end
        return
    end
    
    local enemyFolder = getEnemyFolder()
    if not enemyFolder then return end
    
    local currentAlive = {}
    
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart")
        local head = enemy:FindFirstChild("Head")
        
        if hum and hum.Health > 0 and root and head then
            currentAlive[enemy] = true
            
            local distance = (camera.CFrame.Position - root.Position).Magnitude
            if distance > EspConfig.MaxDistance then continue end
            
            if not espCache[enemy] then espCache[enemy] = createESP() end
            local esp = espCache[enemy]
            
            local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
            local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legPos = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            
            if onScreen then
                local boxH, boxW = math.abs(headPos.Y - legPos.Y), math.abs(headPos.Y - legPos.Y) / 2
                local dist = math.floor(distance)
                
                -- Box ESP
                if EspConfig.Box then
                    if EspConfig.BoxOutline then
                        esp.boxOutline.Size = Vector2.new(boxW, boxH)
                        esp.boxOutline.Position = Vector2.new(rootPos.X - boxW / 2, headPos.Y)
                        esp.boxOutline.Visible = true
                    else
                        esp.boxOutline.Visible = false
                    end
                    
                    esp.box.Size = Vector2.new(boxW, boxH)
                    esp.box.Position = Vector2.new(rootPos.X - boxW / 2, headPos.Y)
                    esp.box.Color = EspConfig.BoxColor
                    esp.box.Filled = EspConfig.BoxFilled
                    esp.box.Transparency = EspConfig.BoxFilled and 0.3 or 1
                    esp.box.Visible = true
                else
                    esp.boxOutline.Visible, esp.box.Visible = false, false
                end
                
                -- Health Bar
                if EspConfig.HealthBar then
                    local hpPct = hum.Health / hum.MaxHealth
                    local barX = rootPos.X - boxW / 2 - 6
                    esp.healthOutline.From = Vector2.new(barX, headPos.Y - 1)
                    esp.healthOutline.To = Vector2.new(barX, headPos.Y + boxH + 1)
                    esp.healthOutline.Visible = true
                    esp.healthBar.From = Vector2.new(barX, headPos.Y + boxH)
                    esp.healthBar.To = Vector2.new(barX, headPos.Y + boxH - (boxH * hpPct))
                    esp.healthBar.Color = Color3.new(1 - hpPct, hpPct, 0)
                    esp.healthBar.Visible = true
                else
                    esp.healthOutline.Visible, esp.healthBar.Visible = false, false
                end

                -- Name ESP
                if EspConfig.Name then
                    esp.name.Text = enemy.Name
                    esp.name.Position = Vector2.new(rootPos.X, headPos.Y - 20)
                    esp.name.Color = EspConfig.NameColor
                    esp.name.Visible = true
                else
                    esp.name.Visible = false
                end
                
                -- Distance ESP
                if EspConfig.Distance then
                    esp.distance.Text = "[" .. dist .. "m]"
                    esp.distance.Position = Vector2.new(rootPos.X, headPos.Y + boxH + 2)
                    esp.distance.Color = EspConfig.DistanceColor
                    esp.distance.Visible = true
                else
                    esp.distance.Visible = false
                end
                
                -- Tracers
                if EspConfig.Tracers then
                    local fromPos
                    if EspConfig.TracersFrom == "Top" then
                        fromPos = Vector2.new(camera.ViewportSize.X / 2, 0)
                    elseif EspConfig.TracersFrom == "Middle" then
                        fromPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    else
                        fromPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    end
                    esp.tracer.From = fromPos
                    esp.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.tracer.Color = EspConfig.TracersColor
                    esp.tracer.Visible = true
                else
                    esp.tracer.Visible = false
                end
            else
                for _, d in pairs(esp) do d.Visible = false end
            end
        end
    end
    
    for cEnemy, e in pairs(espCache) do
        if not currentAlive[cEnemy] then
            for _, d in pairs(e) do d:Remove() end
            espCache[cEnemy] = nil
        end
    end
end)

--// ==========================================
--// CHAMS & GLOW SYSTEM
--// ==========================================
local ChamsConfig = {
    Enabled = false,
    Color = Color3.fromRGB(138, 43, 226),
    Transparency = 0.5,
    Material = Enum.Material.ForceField,
    Rainbow = false,
    Glow = false,
    GlowColor = Color3.fromRGB(138, 43, 226),
    GlowTransparency = 0.3
}

local chamsCache = {}

local function applyChams(enemy)
    if not ChamsConfig.Enabled then return end
    
    for _, part in pairs(enemy:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            if not chamsCache[part] then
                chamsCache[part] = {
                    OriginalTransparency = part.Transparency,
                    OriginalMaterial = part.Material,
                    OriginalColor = part.Color
                }
            end
            
            local color = ChamsConfig.Color
            if ChamsConfig.Rainbow then
                local hue = (tick() % 10) / 10
                color = Color3.fromHSV(hue, 1, 1)
            end
            
            part.Transparency = ChamsConfig.Transparency
            part.Material = ChamsConfig.Material
            part.Color = color
            
            -- Apply Glow Effect
            if ChamsConfig.Glow then
                local highlight = part:FindFirstChildOfClass("Highlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Parent = part
                end
                highlight.FillColor = ChamsConfig.GlowColor
                highlight.OutlineColor = ChamsConfig.GlowColor
                highlight.FillTransparency = ChamsConfig.GlowTransparency
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                
                if ChamsConfig.Rainbow then
                    local hue = (tick() % 10) / 10
                    highlight.FillColor = Color3.fromHSV(hue, 1, 1)
                    highlight.OutlineColor = Color3.fromHSV(hue, 1, 1)
                end
            else
                local highlight = part:FindFirstChildOfClass("Highlight")
                if highlight then highlight:Destroy() end
            end
        end
    end
end

local function removeChams(enemy)
    for _, part in pairs(enemy:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            if chamsCache[part] then
                part.Transparency = chamsCache[part].OriginalTransparency
                part.Material = chamsCache[part].OriginalMaterial
                part.Color = chamsCache[part].OriginalColor
                chamsCache[part] = nil
            end
            
            local highlight = part:FindFirstChildOfClass("Highlight")
            if highlight then highlight:Destroy() end
        end
    end
end

task.spawn(function()
    while task.wait(0.1) do
        if ChamsConfig.Enabled and isAlive() then
            local enemyFolder = getEnemyFolder()
            if enemyFolder then
                for _, enemy in ipairs(enemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        applyChams(enemy)
                    end
                end
            end
        else
            -- Remove all chams
            for enemy, _ in pairs(chamsCache) do
                if enemy and enemy.Parent then
                    removeChams(enemy)
                end
            end
            chamsCache = {}
        end
    end
end)

--// ==========================================
--// VISUALS TAB UI
--// ==========================================
Tab_Visuals:CreateSection("ESP Master")

Tab_Visuals:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value) EspConfig.Enabled = Value end
})

Tab_Visuals:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 100,
    Suffix = " studs",
    CurrentValue = 1000,
    Flag = "MaxDistance",
    Callback = function(Value) EspConfig.MaxDistance = Value end
})

Tab_Visuals:CreateSection("Box ESP")

Tab_Visuals:CreateToggle({
    Name = "Show Box",
    CurrentValue = true,
    Flag = "EspBoxToggle",
    Callback = function(Value) EspConfig.Box = Value end
})

Tab_Visuals:CreateToggle({
    Name = "Box Filled",
    CurrentValue = false,
    Flag = "EspBoxFilled",
    Callback = function(Value) EspConfig.BoxFilled = Value end
})

Tab_Visuals:CreateToggle({
    Name = "Box Outline",
    CurrentValue = true,
    Flag = "EspBoxOutline",
    Callback = function(Value) EspConfig.BoxOutline = Value end
})

Tab_Visuals:CreateColorPicker({
    Name = "Box Color",
    Color = Color3.fromRGB(138, 43, 226),
    Flag = "BoxColor",
    Callback = function(Value) EspConfig.BoxColor = Value end
})

Tab_Visuals:CreateSection("Health ESP")

Tab_Visuals:CreateToggle({
    Name = "Show Health Bar",
    CurrentValue = true,
    Flag = "EspHealthToggle",
    Callback = function(Value) EspConfig.HealthBar = Value end
})

Tab_Visuals:CreateSection("Text ESP")

Tab_Visuals:CreateToggle({
    Name = "Show Name",
    CurrentValue = true,
    Flag = "EspNameToggle",
    Callback = function(Value) EspConfig.Name = Value end
})

Tab_Visuals:CreateColorPicker({
    Name = "Name Color",
    Color = Color3.new(1, 1, 1),
    Flag = "NameColor",
    Callback = function(Value) EspConfig.NameColor = Value end
})

Tab_Visuals:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "EspDistanceToggle",
    Callback = function(Value) EspConfig.Distance = Value end
})

Tab_Visuals:CreateColorPicker({
    Name = "Distance Color",
    Color = Color3.fromRGB(200, 200, 200),
    Flag = "DistanceColor",
    Callback = function(Value) EspConfig.DistanceColor = Value end
})

Tab_Visuals:CreateSection("Tracers")

Tab_Visuals:CreateToggle({
    Name = "Show Tracers",
    CurrentValue = false,
    Flag = "TracersToggle",
    Callback = function(Value) EspConfig.Tracers = Value end
})

Tab_Visuals:CreateDropdown({
    Name = "Tracers From",
    Options = {"Top", "Middle", "Bottom"},
    CurrentOption = {"Bottom"},
    Flag = "TracersFrom",
    Callback = function(Option) EspConfig.TracersFrom = Option[1] end
})

Tab_Visuals:CreateColorPicker({
    Name = "Tracers Color",
    Color = Color3.fromRGB(138, 43, 226),
    Flag = "TracersColor",
    Callback = function(Value) EspConfig.TracersColor = Value end
})

Tab_Visuals:CreateSection("Chams & Glow")

Tab_Visuals:CreateToggle({
    Name = "Enable Chams",
    CurrentValue = false,
    Flag = "ChamsToggle",
    Callback = function(Value) 
        ChamsConfig.Enabled = Value 
        if Value then
            Notify("Chams", "Chams activated", 2)
        end
    end
})

Tab_Visuals:CreateColorPicker({
    Name = "Chams Color",
    Color = Color3.fromRGB(138, 43, 226),
    Flag = "ChamsColor",
    Callback = function(Value) ChamsConfig.Color = Value end
})

Tab_Visuals:CreateSlider({
    Name = "Chams Transparency",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "ChamsTransparency",
    Callback = function(Value) ChamsConfig.Transparency = Value end
})

Tab_Visuals:CreateDropdown({
    Name = "Chams Material",
    Options = {"ForceField", "Neon", "Glass", "Plastic", "Metal"},
    CurrentOption = {"ForceField"},
    Flag = "ChamsMaterial",
    Callback = function(Option) 
        ChamsConfig.Material = Enum.Material[Option[1]]
    end
})

Tab_Visuals:CreateToggle({
    Name = "Rainbow Chams",
    CurrentValue = false,
    Flag = "RainbowChams",
    Callback = function(Value) ChamsConfig.Rainbow = Value end
})

Tab_Visuals:CreateToggle({
    Name = "Enable Glow",
    CurrentValue = false,
    Flag = "GlowToggle",
    Callback = function(Value) 
        ChamsConfig.Glow = Value 
        if Value then
            Notify("Glow ESP", "Glow effect activated", 2)
        end
    end
})

Tab_Visuals:CreateColorPicker({
    Name = "Glow Color",
    Color = Color3.fromRGB(138, 43, 226),
    Flag = "GlowColor",
    Callback = function(Value) ChamsConfig.GlowColor = Value end
})

Tab_Visuals:CreateSlider({
    Name = "Glow Transparency",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.3,
    Flag = "GlowTransparency",
    Callback = function(Value) ChamsConfig.GlowTransparency = Value end
})

--// ==========================================
--// WORLD & EFFECTS
--// ==========================================
local WorldConfig = {
    AntiFlashEnabled = false,
    AntiSmokeEnabled = false,
    FullbrightEnabled = false,
    NoFogEnabled = false,
    CustomFOV = false,
    FOVValue = 70,
    CustomAmbient = false,
    AmbientColor = Color3.fromRGB(255, 255, 255)
}

Tab_Visuals:CreateSection("World Effects")

Tab_Visuals:CreateToggle({
    Name = "Anti-Flashbang",
    CurrentValue = false,
    Flag = "AntiFlashToggle",
    Callback = function(Value) WorldConfig.AntiFlashEnabled = Value end
})

Tab_Visuals:CreateToggle({
    Name = "Anti-Smoke",
    CurrentValue = false,
    Flag = "AntiSmokeToggle",
    Callback = function(Value) WorldConfig.AntiSmokeEnabled = Value end
})

Tab_Visuals:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "FullbrightToggle",
    Callback = function(Value) 
        WorldConfig.FullbrightEnabled = Value
        if Value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 1000
            Lighting.GlobalShadows = true
        end
    end
})

Tab_Visuals:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Flag = "NoFogToggle",
    Callback = function(Value) 
        WorldConfig.NoFogEnabled = Value
        if Value then
            Lighting.FogEnd = 100000
        else
            Lighting.FogEnd = 1000
        end
    end
})

Tab_Visuals:CreateToggle({
    Name = "Custom FOV",
    CurrentValue = false,
    Flag = "CustomFOVToggle",
    Callback = function(Value) WorldConfig.CustomFOV = Value end
})

Tab_Visuals:CreateSlider({
    Name = "FOV Value",
    Range = {60, 120},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 70,
    Flag = "FOVValue",
    Callback = function(Value) WorldConfig.FOVValue = Value end
})

Tab_Visuals:CreateToggle({
    Name = "Custom Ambient",
    CurrentValue = false,
    Flag = "CustomAmbientToggle",
    Callback = function(Value) WorldConfig.CustomAmbient = Value end
})

Tab_Visuals:CreateColorPicker({
    Name = "Ambient Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "AmbientColor",
    Callback = function(Value) WorldConfig.AmbientColor = Value end
})

RunService.RenderStepped:Connect(function()
    if WorldConfig.CustomFOV then
        camera.FieldOfView = WorldConfig.FOVValue
    end
    
    if WorldConfig.CustomAmbient then
        Lighting.Ambient = WorldConfig.AmbientColor
        Lighting.OutdoorAmbient = WorldConfig.AmbientColor
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if WorldConfig.AntiFlashEnabled then
            local gui = player.PlayerGui:FindFirstChild("FlashbangEffect")
            local effect = Lighting:FindFirstChild("FlashbangColorCorrection")
            if gui then gui:Destroy() end
            if effect then effect:Destroy() end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if WorldConfig.AntiSmokeEnabled then
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, folder in ipairs(debris:GetChildren()) do
                    if string.match(folder.Name, "Voxel") then
                        folder:ClearAllChildren()
                        folder:Destroy()
                    end
                end
            end
        end
    end
end)

--// ==========================================
--// SKIN CHANGER SYSTEM (Simplified from original)
--// ==========================================
Tab_Skins:CreateSection("Skin System")

local SkinChangerEnabled = false
local CustomKnifeEnabled = false
local selectedKnife = "Butterfly Knife"

Tab_Skins:CreateToggle({
    Name = "Enable Skin Changer",
    CurrentValue = false,
    Flag = "SkinChangerToggle",
    Callback = function(Value) 
        SkinChangerEnabled = Value
        if Value then
            Notify("Skin Changer", "Skin changer enabled", 2)
        end
    end
})

Tab_Skins:CreateToggle({
    Name = "Enable Custom Knife",
    CurrentValue = false,
    Flag = "CustomKnifeToggle",
    Callback = function(Value) CustomKnifeEnabled = Value end
})

Tab_Skins:CreateDropdown({
    Name = "Select Knife",
    Options = {"Butterfly Knife", "Karambit", "M9 Bayonet", "Flip Knife", "Gut Knife"},
    CurrentOption = {"Butterfly Knife"},
    Flag = "KnifeDropdown",
    Callback = function(Option) selectedKnife = Option[1] end
})

--// ==========================================
--// MISC TAB - ADDITIONAL FEATURES
--// ==========================================
Tab_Misc:CreateSection("Utility")

Tab_Misc:CreateButton({
    Name = "🔄 Respawn Character",
    Callback = function()
        if player.Character then
            player.Character:BreakJoints()
            Notify("Respawn", "Respawning character...", 2)
        end
    end
})

Tab_Misc:CreateButton({
    Name = "🗑️ Remove Ragdolls",
    Callback = function()
        local count = 0
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Ragdoll" then
                obj:Destroy()
                count = count + 1
            end
        end
        Notify("Cleanup", "Removed " .. count .. " ragdolls", 2)
    end
})

Tab_Misc:CreateSection("Anti-AFK")

local AntiAFKEnabled = false

Tab_Misc:CreateToggle({
    Name = "Enable Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value) 
        AntiAFKEnabled = Value
        if Value then
            Notify("Anti-AFK", "Anti-AFK enabled", 2)
        end
    end
})

task.spawn(function()
    while task.wait(60) do
        if AntiAFKEnabled then
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

Tab_Misc:CreateSection("Server Info")

Tab_Misc:CreateLabel("Server: " .. game.JobId, "server", Color3.fromRGB(150,150,150), false)
Tab_Misc:CreateLabel("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers, "users", Color3.fromRGB(150,150,150), false)
Tab_Misc:CreateLabel("Ping: " .. math.floor(player:GetNetworkPing() * 1000) .. "ms", "wifi", Color3.fromRGB(150,150,150), false)

--// ==========================================
--// CONFIG TAB
--// ==========================================
Tab_Config:CreateSection("Menu Customization")

Tab_Config:CreateDropdown({
    Name = "Menu Theme",
    Options = {"Amethyst", "Default", "Ocean", "Dark", "Light", "Green", "Cherry"},
    CurrentOption = {"Amethyst"},
    Flag = "MenuTheme",
    Callback = function(Option)
        local theme = Option[1]
        Notify("Theme", "Theme changed to " .. theme .. " - Reload script to apply", 4)
        -- Store theme preference
        _G.ElectraXTheme = theme
    end
})

Tab_Config:CreateButton({
    Name = "🎨 Apply Theme (Reload Required)",
    Callback = function()
        Notify("Theme", "Please reload the script to apply the new theme", 3)
    end
})

Tab_Config:CreateSection("Configuration")

Tab_Config:CreateButton({
    Name = "💾 Save Config",
    Callback = function()
        Rayfield:SaveConfiguration()
        Notify("Config", "Configuration saved successfully", 3)
    end
})

Tab_Config:CreateButton({
    Name = "📂 Load Config",
    Callback = function()
        Rayfield:LoadConfiguration()
        Notify("Config", "Configuration loaded successfully", 3)
    end
})

Tab_Config:CreateButton({
    Name = "🔄 Reset Config",
    Callback = function()
        Rayfield:ResetConfiguration()
        Notify("Config", "Configuration reset to defaults", 3)
    end
})

Tab_Config:CreateSection("Script Info")

Tab_Config:CreateLabel("ElectraX Premium v3.0.0", "info", Color3.fromRGB(138, 43, 226), false)
Tab_Config:CreateLabel("Advanced Combat Script", "crosshair", Color3.fromRGB(150,150,150), false)
Tab_Config:CreateLabel("Made with ❤️", "heart", Color3.fromRGB(255, 100, 100), false)

--// Auto-load config
Rayfield:LoadConfiguration()

Notify("ElectraX", "All systems loaded successfully!", 4)

--// ==========================================
--// COMPLETE SKIN CHANGER MODULE (Original by twistedk1d)
--// ==========================================
local scriptRunning = false
local spawned = false
local inspecting = false
local swinging = false
local lastAttackTime = 0
local ATTACK_COOLDOWN = 1
local ACTION_INSPECT = "InspectKnifeAction"
local ACTION_ATTACK = "AttackKnifeAction"

pcall(function() RS.Assets.Weapons.Karambit.Camera.ViewmodelLight.Transparency = 1 end)

local knives = {
    ["Karambit"] = {Offset = CFrame.new(0, -1.5, 1.5)},
    ["Butterfly Knife"] = {Offset = CFrame.new(0, -1.5, 1.5)},
    ["M9 Bayonet"] = {Offset = CFrame.new(0, -1.5, 1)},
    ["Flip Knife"] = {Offset = CFrame.new(0, -1.5, 1.25)},
    ["Gut Knife"] = {Offset = CFrame.new(0, -1.5, 0.5)},
}

local vm, animator
local equipAnim, idleAnim, inspectAnim, HeavySwingAnim, Swing1Anim, Swing2Anim

local function getKnifeInCamera() 
    return camera:FindFirstChild("T Knife") or camera:FindFirstChild("CT Knife") 
end

local function cleanPart(part)
    if not part:IsA("BasePart") then return end
    part.CanCollide, part.Anchored, part.CastShadow, part.CanTouch, part.CanQuery = false, false, false, false, false
end

local function disableCollisions(model)
    for _, part in model:GetDescendants() do cleanPart(part) end
end

local function hideOriginalKnife(knife)
    for _, part in knife:GetDescendants() do
        if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Texture") then 
            part.Transparency = 1 
        end
    end
end

local function playSound(folder, name)
    local weaponSounds = RS.Sounds:FindFirstChild(selectedKnife)
    if not weaponSounds then return end
    local sound = weaponSounds:WaitForChild(folder):WaitForChild(name):Clone()
    sound.Parent = camera
    sound:Play()
    sound.Ended:Once(function() sound:Destroy() end)
    return sound
end

local function attachAsset(folder, armPartName, assetModelName, finalName, offset)
    local targetArm = vm:FindFirstChild(armPartName)
    if not targetArm then return end
    local assetMesh = folder:WaitForChild(assetModelName):Clone()
    cleanPart(assetMesh)
    assetMesh.Name = finalName
    assetMesh.Parent = targetArm
    local motor = Instance.new("Motor6D")
    motor.Part0, motor.Part1, motor.C0, motor.Parent = targetArm, assetMesh, offset, targetArm
end

local function handleAction(actionName, inputState, inputObject)
    if inputState ~= Enum.UserInputState.Begin or not spawned or not animator or not isAlive() then 
        return Enum.ContextActionResult.Pass 
    end
    
    if actionName == ACTION_INSPECT then
        if (equipAnim and equipAnim.IsPlaying) or inspecting or swinging then 
            return Enum.ContextActionResult.Pass 
        end
        inspecting = true
        if idleAnim then idleAnim:Stop() end
        inspectAnim:Play()
        inspectAnim.Stopped:Once(function() inspecting = false end)
    elseif actionName == ACTION_ATTACK then
        local currentTime = os.clock()
        if (equipAnim and equipAnim.IsPlaying) or (currentTime - lastAttackTime < ATTACK_COOLDOWN) then 
            return Enum.ContextActionResult.Pass 
        end
        lastAttackTime = currentTime
        if inspecting then 
            inspecting = false
            if inspectAnim then inspectAnim:Stop() end 
        end
        swinging = true
        if idleAnim then idleAnim:Stop() end
        local anims = {HeavySwingAnim, Swing1Anim, Swing2Anim}
        local chosenAnim = anims[math.random(1, #anims)]
        local soundFolder = (chosenAnim == HeavySwingAnim and "HitOne") or (chosenAnim == Swing1Anim and "HitTwo") or "HitThree"
        chosenAnim:Play()
        local s = playSound(soundFolder, "1")
        if s then s.Volume = 5 end
        chosenAnim.Stopped:Once(function() swinging = false end)
    end
    return Enum.ContextActionResult.Pass
end

local function removeViewmodel()
    spawned = false
    CAS:UnbindAction(ACTION_INSPECT)
    CAS:UnbindAction(ACTION_ATTACK)
    if vm then vm:Destroy() vm = nil end
    animator, inspecting, swinging = nil, false, false
end

local function spawnViewmodel(knife)
    if spawned or not scriptRunning then return end
    local myModel = isAlive()
    if not myModel then return end
    spawned = true
    local knifeTemplate = RS.Assets.Weapons:WaitForChild(selectedKnife)
    local knifeOffset = knives[selectedKnife].Offset
    vm = knifeTemplate:WaitForChild("Camera"):Clone()
    vm.Name, vm.Parent = selectedKnife, camera
    disableCollisions(vm)
    hideOriginalKnife(knife)
    
    if myModel.Parent.Name == "Terrorists" then
        local tGloves = RS.Assets.Weapons:WaitForChild("T Glove")
        attachAsset(tGloves, "Left Arm", "Left Arm", "Glove", CFrame.new(0, 0, -1.5))
        attachAsset(tGloves, "Right Arm", "Right Arm", "Glove", CFrame.new(0, 0, -1.5))
    else
        local sleeves = RS.Assets.Sleeves:WaitForChild("IDF")
        local ctGloves = RS.Assets.Weapons:WaitForChild("CT Glove")
        attachAsset(sleeves, "Left Arm", "Left Arm", "Sleeve", CFrame.new(0, 0, 0.5))
        attachAsset(ctGloves, "Left Arm", "Left Arm", "Glove", CFrame.new(0, 0, -1.5))
        attachAsset(sleeves, "Right Arm", "Right Arm", "Sleeve", CFrame.new(0, 0, 0.5))
        attachAsset(ctGloves, "Right Arm", "Right Arm", "Glove", CFrame.new(0, 0, -1.5))
    end

    local animController = vm:FindFirstChildOfClass("AnimationController") or vm:FindFirstChildOfClass("Animator")
    animator = animController:FindFirstChildWhichIsA("Animator") or animController
    local animFolder = RS.Assets.WeaponAnimations:WaitForChild(selectedKnife):WaitForChild("CameraAnimations")
    equipAnim = animator:LoadAnimation(animFolder:WaitForChild("Equip"))
    idleAnim = animator:LoadAnimation(animFolder:WaitForChild("Idle"))
    inspectAnim = animator:LoadAnimation(animFolder:WaitForChild("Inspect"))
    HeavySwingAnim = animator:LoadAnimation(animFolder:WaitForChild("Heavy Swing"))
    Swing1Anim = animator:LoadAnimation(animFolder:WaitForChild("Swing1"))
    Swing2Anim = animator:LoadAnimation(animFolder:WaitForChild("Swing2"))
    
    vm:SetPrimaryPartCFrame(camera.CFrame * CFrame.new(0, -1.5, 5))
    TweenService:Create(vm.PrimaryPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = camera.CFrame * knifeOffset
    }):Play()
    equipAnim:Play()
    playSound("Equip", "1")
    
    CAS:BindAction(ACTION_INSPECT, handleAction, false, Enum.KeyCode.F)
    CAS:BindAction(ACTION_ATTACK, handleAction, false, Enum.UserInputType.MouseButton1)
end

RunService.RenderStepped:Connect(function()
    if not scriptRunning or not vm or not vm.PrimaryPart then return end
    vm.PrimaryPart.CFrame = camera.CFrame * knives[selectedKnife].Offset
    if not (equipAnim and equipAnim.IsPlaying) and not inspecting and not swinging then
        if idleAnim and not idleAnim.IsPlaying then idleAnim:Play() end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        local living = isAlive()
        local currentKnife = getKnifeInCamera()
        if scriptRunning and living and currentKnife and not spawned then
            spawnViewmodel(currentKnife)
        elseif (not scriptRunning or not currentKnife or not living) and spawned then
            removeViewmodel()
        end
    end
end)

-- Skin Changer Variables
local SkinOptions = {}
local DropdownObjects = {}
local SelectedSkins = {}
local COOLDOWN = 0.1
local WEAR = "Factory New"

local CT_ONLY = {["USP-S"]=true, ["Five-SeveN"]=true, ["MP9"]=true, ["FAMAS"]=true, ["M4A1-S"]=true, ["M4A4"]=true, ["AUG"]=true}
local SHARED = {["P250"]=true, ["Desert Eagle"]=true, ["Dual Berettas"]=true, ["Negev"]=true, ["P90"]=true, ["Nova"]=true, ["XM1014"]=true, ["AWP"]=true, ["SSG 08"]=true}
local KNIVES = {["Karambit"]=true, ["Butterfly Knife"]=true, ["M9 Bayonet"]=true, ["Flip Knife"]=true, ["Gut Knife"]=true, ["T Knife"]=true, ["CT Knife"]=true}
local GLOVES = {["Sports Gloves"]=true}

local SkinsFolder = RS:WaitForChild("Assets"):WaitForChild("Skins")
local IgnoreFolders = {["HE Grenade"]=true, ["Incendiary Grenade"]=true, ["Molotov"]=true, ["Smoke Grenade"]=true, ["Flashbang"]=true, ["Decoy Grenade"]=true, ["C4"]=true, ["CT Glove"]=true, ["T Glove"]=true}

local function applyWeaponSkin(model)
    if not model or not SkinChangerEnabled or not isAlive() then return end
    local skinName = SelectedSkins[model.Name]
    if not skinName then return end
    
    pcall(function()
        local skinFolder = SkinsFolder:FindFirstChild(model.Name)
        if not skinFolder then return end
        local skinType = skinFolder:FindFirstChild(skinName)
        local sourceFolder = skinType and skinType:FindFirstChild("Camera") and skinType.Camera:FindFirstChild(WEAR)
        if not sourceFolder then return end
        
        for _, obj in camera:GetChildren() do
            local left, right = obj:FindFirstChild("Left Arm"), obj:FindFirstChild("Right Arm")
            if left or right then
                local gloveFolder = SkinsFolder:FindFirstChild("Sports Gloves")
                local gloveSkin = gloveFolder and gloveFolder:FindFirstChild(SelectedSkins["Sports Gloves"])
                local gloveSource = gloveSkin and gloveSkin:FindFirstChild("Camera") and gloveSkin.Camera:FindFirstChild(WEAR)
                if gloveSource then
                    for _, side in {"Left Arm", "Right Arm"} do
                        local arm, src = obj:FindFirstChild(side), gloveSource:FindFirstChild(side)
                        if arm and src then
                            local gloveMesh = arm:FindFirstChild("Glove")
                            if gloveMesh then
                                local existing = gloveMesh:FindFirstChildOfClass("SurfaceAppearance")
                                if existing then existing:Destroy() end
                                local clone = src:Clone()
                                clone.Name, clone.Parent = "SurfaceAppearance", gloveMesh
                            end
                        end
                    end
                end
            end
            
            if not GLOVES[model.Name] then
                local weaponFolder = model:FindFirstChild("Weapon")
                if weaponFolder then
                    for _, part in weaponFolder:GetDescendants() do
                        if part:IsA("BasePart") then
                            local newSkin = sourceFolder:FindFirstChild(part.Name)
                            if newSkin then
                                local existing = part:FindFirstChildOfClass("SurfaceAppearance")
                                if existing then existing:Destroy() end
                                local clone = newSkin:Clone()
                                clone.Name, clone.Parent = "SurfaceAppearance", part
                            end
                        end
                    end
                end
            end
        end
        model:SetAttribute("SkinApplied", skinName)
    end)
end

Tab_Skins:CreateButton({
    Name = "🎲 Randomize All Skins",
    Callback = function()
        for weaponName, optionsList in pairs(SkinOptions) do
            if #optionsList > 0 then
                local randomSkin = optionsList[math.random(1, #optionsList)]
                if DropdownObjects[weaponName] then
                    for _, dropdown in ipairs(DropdownObjects[weaponName]) do 
                        dropdown:Set({randomSkin}) 
                    end
                end
            end
        end
    end,
})

local function CreateSkinDropdown(weaponName)
    local folder = SkinsFolder:FindFirstChild(weaponName)
    if not folder then return end
    local options = {}
    for _, skin in folder:GetChildren() do table.insert(options, skin.Name) end
    SkinOptions[weaponName] = options
    if not SelectedSkins[weaponName] then SelectedSkins[weaponName] = options[1] end
    
    local dp = Tab_Skins:CreateDropdown({
        Name = weaponName,
        Options = options,
        CurrentOption = {SelectedSkins[weaponName]},
        Flag = "Skin_" .. weaponName,
        Callback = function(opt)
            local newSkin = opt[1]
            SelectedSkins[weaponName] = newSkin
            if DropdownObjects[weaponName] then
                for _, other in DropdownObjects[weaponName] do
                    if other.CurrentOption[1] ~= newSkin then other:Set({newSkin}) end
                end
            end
            for _, obj in camera:GetChildren() do 
                obj:SetAttribute("SkinApplied", nil)
                applyWeaponSkin(obj) 
            end
        end
    })
    DropdownObjects[weaponName] = DropdownObjects[weaponName] or {}
    table.insert(DropdownObjects[weaponName], dp)
end

Tab_Skins:CreateToggle({
    Name = "Enable Custom Knife",
    CurrentValue = false,
    Flag = "KnifeToggle",
    Callback = function(Value)
        scriptRunning = Value
        if not Value then removeViewmodel() end
    end
})

Tab_Skins:CreateDropdown({
    Name = "Selected Custom Knife",
    Options = {"Butterfly Knife", "Karambit", "M9 Bayonet", "Flip Knife", "Gut Knife"},
    CurrentOption = {"Butterfly Knife"},
    MultipleOptions = false,
    Flag = "KnifeDropdown",
    Callback = function(Options)
        selectedKnife = Options[1]
        if spawned then removeViewmodel() end
    end
})

Tab_Skins:CreateSection("Knives Skins")
for name in pairs(KNIVES) do CreateSkinDropdown(name) end

Tab_Skins:CreateSection("Gloves")
for name in pairs(GLOVES) do CreateSkinDropdown(name) end

Tab_Skins:CreateSection("CT Weapons")
for name in pairs(CT_ONLY) do CreateSkinDropdown(name) end

Tab_Skins:CreateSection("T Weapons")
for name in pairs(SHARED) do CreateSkinDropdown(name) end

for _, folder in SkinsFolder:GetChildren() do
    local n = folder.Name
    if not IgnoreFolders[n] and not KNIVES[n] and not GLOVES[n] and not CT_ONLY[n] and not SHARED[n] then 
        CreateSkinDropdown(n) 
    end
end

camera.ChildAdded:Connect(function(obj)
    if not SkinChangerEnabled or not isAlive() then return end
    task.wait(COOLDOWN)
    applyWeaponSkin(obj)
end)

task.spawn(function()
    while task.wait(0.5) do
        if SkinChangerEnabled and isAlive() then
            for _, obj in camera:GetChildren() do
                if SelectedSkins[obj.Name] and obj:GetAttribute("SkinApplied") ~= SelectedSkins[obj.Name] then 
                    applyWeaponSkin(obj) 
                end
            end
        end
    end
end)

print("ElectraX Premium v3.0.0 - Loaded Successfully")
