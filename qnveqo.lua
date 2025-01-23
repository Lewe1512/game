local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Pulse Hub V1.0",
    SubTitle = "<:<:",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Farming = Window:AddTab({ Title = "Farming", Icon = "pick" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }),
    Credits = Window:AddTab({ Title = "Credits", Icon = "info" })
}

local Options = Fluent.Options
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local clickRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ClickService"):WaitForChild("RF"):WaitForChild("Click")
local rebirthRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("RebirthService"):WaitForChild("RF"):WaitForChild("Rebirth")

local AutoClick = Tabs.Farming:AddToggle("AutoClick", {
    Title = "Auto Click",
    Default = false
})

local AutoWin = Tabs.Farming:AddToggle("AutoWin", {
    Title = "Auto Win",
    Default = false
})

local AutoRebirth = Tabs.Farming:AddToggle("AutoRebirth", {
    Title = "Auto Rebirth",
    Default = false,
    Description = "Automatically rebirths every second"
})

local WalkspeedSlider = Tabs.Misc:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Description = "Adjust your walking speed",
    Default = 16,
    Min = 16,
    Max = 500,
    Rounding = 1,
    Callback = function(Value)
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

local JumpPowerSlider = Tabs.Misc:AddSlider("JumpPower", {
    Title = "Jump Power",
    Description = "Adjust your jump power",
    Default = 50,
    Min = 50,
    Max = 500,
    Rounding = 1,
    Callback = function(Value)
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

local AntiAFKToggle = Tabs.Misc:AddToggle("AntiAFK", {
    Title = "Anti AFK",
    Default = false
})

Tabs.Credits:AddParagraph({
    Title = "Script Creator",
    Content = "Created by: M3M3\nDiscord: https://discord.gg/5UPBtm7KW6"
})

Tabs.Credits:AddParagraph({
    Title = "Special Thanks",
    Content = "Thanks to the community for support!"
})

local function doClick()
    clickRemote:InvokeServer()
end

local function doRebirth()
    rebirthRemote:InvokeServer()
end

AutoClick:OnChanged(function()
    while Options.AutoClick.Value do
        doClick()
        task.wait(0.01)
    end
end)

AutoRebirth:OnChanged(function()
    while Options.AutoRebirth.Value do
        doRebirth()
        task.wait(1)
    end
end)

AntiAFKToggle:OnChanged(function()
    while Options.AntiAFK.Value do
        local VirtualUser = game:GetService("VirtualUser")
        Players.LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        task.wait(1)
    end
end)

local function getRandomTweenTime()
    return math.random(25, 35) / 100
end

local function simulateCameraMovement(character)
    if character and character:FindFirstChild("HumanoidRootPart") then
        local camera = workspace.CurrentCamera
        if camera then
            local randomAngle = math.rad(math.random(-20, 20))
            local targetCFrame = CFrame.new(camera.CFrame.Position) * CFrame.Angles(math.rad(math.random(-10, 10)), randomAngle, 0)
            local cameraTween = TweenService:Create(
                camera,
                TweenInfo.new(0.2, Enum.EasingStyle.Cubic),
                {CFrame = targetCFrame}
            )
            cameraTween:Play()
        end
    end
end

local startPosition = nil
local lastGoodPosition = nil
local failedAttempts = 0

local function verifyPosition(character, targetPosition)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local currentPos = character.HumanoidRootPart.Position
    local distance = (currentPos - targetPosition).Magnitude
    
    if distance > 50 then
        failedAttempts = failedAttempts + 1
        if failedAttempts >= 3 then
            Fluent:Notify({
                Title = "Position Error",
                Content = "Character teleported back too many times. Resetting...",
                Duration = 3
            })
            return false
        end
        
        if lastGoodPosition then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            humanoidRootPart.CFrame = lastGoodPosition
            task.wait(0.5)
        end
    else
        failedAttempts = 0
        lastGoodPosition = character.HumanoidRootPart.CFrame
    end
    
    return true
end

local function moveForward(character, distance)
    if character and character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local currentCFrame = humanoidRootPart.CFrame
        local lookVector = currentCFrame.LookVector

        if not startPosition then
            startPosition = currentCFrame.Position
        end
        
        local targetPosition = currentCFrame.Position + (lookVector * distance)
        local targetCFrame = CFrame.new(
            targetPosition.X + math.random(-15, 15) / 100,
            targetPosition.Y + math.random(-8, 8) / 100,
            targetPosition.Z + math.random(-20, 20) / 100
        ) * currentCFrame.Rotation
        
        local tweenInfo = TweenInfo.new(
            getRandomTweenTime(),
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        )
        
        local tween = TweenService:Create(
            humanoidRootPart,
            tweenInfo,
            {CFrame = targetCFrame}
        )
        
        tween:Play()
        tween.Completed:Wait()
        task.wait(0.1)

        if not verifyPosition(character, targetPosition) then
            Options.AutoWin:SetValue(false)
            task.wait(1)
            Options.AutoWin:SetValue(true)
            return true
        end
        
        return false
    end
    return false
end

AutoWin:OnChanged(function()
    startPosition = nil
    lastGoodPosition = nil
    failedAttempts = 0
    
    if Options.AutoWin.Value then
        Fluent:Notify({
            Title = "Auto Win",
            Content = "Starting auto win...",
            Duration = 2
        })
    end
    
    while Options.AutoWin.Value and task.wait() do
        local character = game.Players.LocalPlayer.Character
        if character then
            for i = 1, 12 do
                if not Options.AutoWin.Value then break end
                
                if i == 11 then
                    task.wait(0.1)
                    simulateCameraMovement(character)
                end
                
                local distance = 55000
                if i > 6 then
                    distance = 55000
                end
                if i == 11 then
                    distance = 55000
                end
                
                if moveForward(character, distance) then
                    break
                end
                
                if i == 11 then
                    task.wait(0.001)
                end
            end
            
            task.wait(0.2)
            simulateCameraMovement(character)
            
            for i = 1, 3 do
                if not Options.AutoWin.Value then break end
                if moveForward(character, 15) then
                    break
                end
            end
        end
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/ClickingSimulator")
SaveManager:BuildConfigSection(Tabs.Misc)

Window:SelectTab(1)
