local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local farming = {
    enabled = false,
    platform = nil,
    lastTP = 0,
    tpCooldown = 1,
    startTime = 0,
    gold = 0,
    runs = 0
}

local path = {
    {pos = Vector3.new(160.161, 29.595, 973.813), wait = 2.3}, -- Start
    {pos = Vector3.new(-51, 65, 984), wait = 2.3},      -- Stage 1
    {pos = Vector3.new(-51, 65, 1754), wait = 2.3},     -- Stage 2
    {pos = Vector3.new(-51, 65, 2524), wait = 2.3},     -- Stage 3
    {pos = Vector3.new(-51, 65, 3294), wait = 0.8}      -- End
}

local Window = Fluent:CreateWindow({
    Title = "PulseHub V1.0",
    SubTitle = "by Who? <:",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "home" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

local StatsLabel = MainTab:AddParagraph({
    Title = "Farm Stats",
    Content = "Waiting to start..."
})

local function updateStats()
    if not farming.enabled then
        StatsLabel:SetDesc("Waiting to start...")
        return
    end
    
    local timeElapsed = (tick() - farming.startTime) / 3600
    if timeElapsed <= 0 then return end
    
    local goldPerHour = math.floor(farming.gold / timeElapsed)
    
    StatsLabel:SetDesc(string.format(
        "Time: %02d:%02d\nGold: %d\nGold/Hour: %d\nRuns: %d",
        math.floor(timeElapsed * 60),
        math.floor(timeElapsed * 3600) % 60,
        farming.gold,
        goldPerHour,
        farming.runs
    ))
end

local function teleportTo(pos)
    if not farming.enabled then return false end

    local now = tick()
    if now - farming.lastTP < farming.tpCooldown then
        task.wait(farming.tpCooldown - (now - farming.lastTP))
    end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        return false 
    end
    
    local root = char.HumanoidRootPart
    local humanoid = char:FindFirstChild("Humanoid")
    
    if humanoid and humanoid.Health <= 0 then 
        return false 
    end

    if not farming.platform then
        local plat = Instance.new("Part")
        plat.Size = Vector3.new(5, 1, 5)
        plat.Transparency = 1
        plat.CanCollide = true
        plat.Anchored = true
        plat.Parent = workspace
        farming.platform = plat
    end

    pcall(function()
        root.CFrame = CFrame.new(pos)
        farming.platform.Position = root.Position - Vector3.new(0, 2, 0)
    end)
    
    farming.lastTP = now
    return true
end

local function startFarming()
    if not farming.enabled then return end
    
    farming.startTime = tick()
    farming.gold = 0
    farming.runs = 0

    task.spawn(function()
        while farming.enabled do
            updateStats()
            task.wait(1)
        end
    end)
    
    local stage = 1
    while farming.enabled do
        local current = path[stage]
        if not current then 
            stage = 1
            current = path[1]
        end
        
        if teleportTo(current.pos) then
            if stage == #path then
                pcall(function()
                    local trigger = workspace.BoatStages.NormalStages.TheEnd.GoldenChest.Trigger
                    firetouchinterest(player.Character.HumanoidRootPart, trigger, 0)
                    task.wait(current.wait)
                    workspace.ClaimRiverResultsGold:FireServer()
                    farming.gold = farming.gold + 100
                    farming.runs = farming.runs + 1
                end)
            else
                task.wait(current.wait)
                if stage ~= 4 then
                    workspace.ClaimRiverResultsGold:FireServer()
                end
            end
            stage = stage + 1
        else
            task.wait(1)
        end
        
        task.wait(0.1)
    end
    
    if farming.platform then
        farming.platform:Destroy()
        farming.platform = nil
    end
end

local FarmToggle = MainTab:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Description = "Start farming gold",
    Default = false
})

FarmToggle:OnChanged(function(Value)
    farming.enabled = Value
    if Value then
        task.spawn(startFarming)
    else
        StatsLabel:SetDesc("Waiting to start...")
    end
end)

-- Load Settings
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("PulseHub")
InterfaceManager:SetFolder("PulseHub")

InterfaceManager:BuildInterfaceSection(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig() 
