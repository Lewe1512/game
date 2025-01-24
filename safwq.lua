local Players = game:GetService("Players")
local player = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local placeid = game.PlaceId

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
    runs = 0,
    afkEnabled = false,
    optimizeEnabled = false,
    autoRestart = true,
    isRestarting = false,
    originalSettings = {
        waterWaveSize = workspace.Terrain.WaterWaveSize,
        waterWaveSpeed = workspace.Terrain.WaterWaveSpeed,
        waterReflectance = workspace.Terrain.WaterReflectance,
        waterTransparency = workspace.Terrain.WaterTransparency,
        renderingQuality = settings().Rendering.QualityLevel,
        graphicsMode = settings().Rendering.GraphicsMode
    }
}

if not isfolder("BABFT") then makefolder("BABFT") end
if not isfolder("BABFT/Image") then makefolder("BABFT/Image") end
if not isfolder("BABFT/Build") then makefolder("BABFT/Build") end

local path = {
    {pos = Vector3.new(-51.6584892578125, 65.02780151367188, 1001.6632690429688), wait = 2.3},      -- Stage 1
    {pos = Vector3.new(-51.6584892578125, 65.02780151367188, 1771.6632690429688), wait = 2.3},     -- Stage 2
    {pos = Vector3.new(-51.6584892578125, 65.02780151367188, 2541.6632690429688), wait = 2.3},     -- Stage 3
    {pos = Vector3.new(-51.6584892578125, 65.02780151367188, 3311.6632690429688), wait = 0.8},     -- Stage 4
    {pos = Vector3.new(-51.6584892578125, 65.02780151367188, 4081.6632690429688), wait = 0.8}      -- End
}

local startFarming

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
local ServerHopTab = Window:AddTab({ Title = "Server Hop", Icon = "network" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

local StatsLabel = MainTab:AddParagraph({
    Title = "Farm Stats",
    Content = "Waiting to start..."
})

local function setupAntiAFK()
    player.Idled:Connect(function()
        if farming.afkEnabled then
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
end

local function optimizeGame(enable)
    if enable then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                if not obj:GetAttribute("OriginalMaterial") then
                    obj:SetAttribute("OriginalMaterial", obj.Material.Name)
                end
                obj.Material = Enum.Material.SmoothPlastic
                
                if obj:IsA("Texture") or obj:IsA("Decal") then
                    if not obj:GetAttribute("WasVisible") then
                        obj:SetAttribute("WasVisible", true)
                    end
                    obj.Transparency = 1
                end
            end
        end
        
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 0
        
        settings().Rendering.QualityLevel = 1
        settings().Rendering.GraphicsMode = 2

        -- Hide unnecessary parts
        local Stuff = {
            "Blocks", "Challenge", "TempStuff", "Teams", "MainTerrain", 
            "OtherStages", "BlackZone", "CamoZone", "MagentaZone", 
            "New YellerZone", "Really blueZone", "Really redZone", 
            "Sand", "Water", "WhiteZone", "WaterMask"
        }
        
        for _, v in ipairs(Stuff) do
            local object = workspace:FindFirstChild(v) or workspace.BoatStages:FindFirstChild("OtherStages")
            if object then
                object.Parent = game:GetService("ReplicatedStorage")
            end
        end
    else
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                local originalMaterial = obj:GetAttribute("OriginalMaterial")
                if originalMaterial then
                    obj.Material = Enum.Material[originalMaterial]
                    obj:SetAttribute("OriginalMaterial", nil)
                end
                
                if (obj:IsA("Texture") or obj:IsA("Decal")) and obj:GetAttribute("WasVisible") then
                    obj.Transparency = 0
                    obj:SetAttribute("WasVisible", nil)
                end
            end
        end
        
        workspace.Terrain.WaterWaveSize = farming.originalSettings.waterWaveSize
        workspace.Terrain.WaterWaveSpeed = farming.originalSettings.waterWaveSpeed
        workspace.Terrain.WaterReflectance = farming.originalSettings.waterReflectance
        workspace.Terrain.WaterTransparency = farming.originalSettings.waterTransparency
        
        settings().Rendering.QualityLevel = farming.originalSettings.renderingQuality
        settings().Rendering.GraphicsMode = farming.originalSettings.graphicsMode

        -- Restore hidden parts
        local Stuff = {
            "Blocks", "Challenge", "TempStuff", "Teams", "MainTerrain", 
            "OtherStages", "BlackZone", "CamoZone", "MagentaZone", 
            "New YellerZone", "Really blueZone", "Really redZone", 
            "Sand", "Water", "WhiteZone", "WaterMask"
        }
        
        for _, v in ipairs(Stuff) do
            local object = game:GetService("ReplicatedStorage"):FindFirstChild(v)
            if object then
                if v == "OtherStages" then
                    object.Parent = workspace.BoatStages
                else
                    object.Parent = workspace
                end
            end
        end
    end
end

local function updateStats()
    if not farming.enabled then
        StatsLabel:SetDesc("Waiting to start...")
        return
    end
    
    local timeElapsed = (tick() - farming.startTime) / 3600
    if timeElapsed <= 0 then return end
    
    local goldPerHour = math.floor(farming.gold / timeElapsed)
    
    StatsLabel:SetDesc(string.format(
        "Time: %02d:%02d\nGold: %d\nGold/Hour: %d\nRuns: %d\nAFK: %s\nOptimize: %s",
        math.floor(timeElapsed * 60),
        math.floor(timeElapsed * 3600) % 60,
        farming.gold,
        goldPerHour,
        farming.runs,
        farming.afkEnabled and "On" or "Off",
        farming.optimizeEnabled and "On" or "Off"
    ))
end

local function removeLock()
    local Teams = {
        "BlackZone", "CamoZone", "MagentaZone", "New YellerZone",
        "Really blueZone", "Really redZone", "WhiteZone"
    }
    for _, teamName in ipairs(Teams) do
        local teamPart = workspace:FindFirstChild(teamName)
        if teamPart then
            local lockFolder = teamPart:FindFirstChild("Lock")
            if lockFolder then
                lockFolder:Destroy()
            end
        end
    end
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

    removeLock()

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

startFarming = function()
    if not farming.enabled or farming.isRestarting then return end
    
    if not farming.startTime or farming.startTime == 0 then
        farming.startTime = tick()
        farming.gold = 0
        farming.runs = 0
    end

    if farming.optimizeEnabled then
        optimizeGame(true)
    end

    task.spawn(function()
        while farming.enabled do
            updateStats()
            task.wait(1)
        end
    end)
    
    local stage = 1
    while farming.enabled and not farming.isRestarting do
        local current = path[stage]
        if not current then 
            stage = 1
            current = path[1]
        end
        
        if teleportTo(current.pos) then
            if stage == #path then
                pcall(function()
                    local trigger = workspace.BoatStages.NormalStages.TheEnd.GoldenChest.Trigger
                    if trigger then
                        firetouchinterest(player.Character.HumanoidRootPart, trigger, 0)
                        firetouchinterest(player.Character.HumanoidRootPart, trigger, 1)
                        task.wait(current.wait)
                        workspace.ClaimRiverResultsGold:FireServer()
                        farming.gold = farming.gold + 100
                        farming.runs = farming.runs + 1
                    end
                end)
                stage = 1
            else
                task.wait(current.wait)
                if stage ~= 4 then
                    workspace.ClaimRiverResultsGold:FireServer()
                end
                stage = stage + 1
            end
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

local function restartFarming()
    if farming.isRestarting then return end
    farming.isRestarting = true
    
    if farming.platform then
        farming.platform:Destroy()
        farming.platform = nil
    end
    
    task.wait(5)
    
    local oldGold = farming.gold
    local oldRuns = farming.runs
    local oldStartTime = farming.startTime
    
    farming.isRestarting = false
    if farming.enabled then
        task.spawn(function()
            farming.gold = oldGold
            farming.runs = oldRuns
            farming.startTime = oldStartTime
            startFarming()
        end)
    end
end

local function setupHealthDetection()
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            if farming.enabled and farming.autoRestart then
                restartFarming()
            end
        end)
    end)
    
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                if farming.enabled and farming.autoRestart then
                    restartFarming()
                end
            end)
        end
    end
end

-- Main Tab Sections
local FarmingSection = MainTab:AddSection("Auto Farming")
local OptimizationSection = MainTab:AddSection("Optimization")
local AFKSection = MainTab:AddSection("AFK Settings")

-- Farming Section
local FarmToggle = FarmingSection:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Description = "Start farming gold",
    Default = false
})

local AutoRestartToggle = FarmingSection:AddToggle("AutoRestart", {
    Title = "Auto Restart",
    Description = "Automatically restart farming when you die",
    Default = true
})

-- AFK Section
local AFKToggle = AFKSection:AddToggle("AFKMode", {
    Title = "AFK Mode",
    Description = "Enable anti-AFK system",
    Default = false
})

-- Optimization Section
local OptimizeToggle = OptimizationSection:AddToggle("Optimize", {
    Title = "Optimize Performance",
    Description = "Reduce graphics for better performance",
    Default = false
})

FarmToggle:OnChanged(function(Value)
    farming.enabled = Value
    if Value then
        setupHealthDetection()
        task.spawn(startFarming)
    else
        StatsLabel:SetDesc("Waiting to start...")
    end
end)

AFKToggle:OnChanged(function(Value)
    farming.afkEnabled = Value
    if Value then
        setupAntiAFK()
    end
end)

OptimizeToggle:OnChanged(function(Value)
    farming.optimizeEnabled = Value
    optimizeGame(Value)
end)

AutoRestartToggle:OnChanged(function(Value)
    farming.autoRestart = Value
end)

local queueonteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)

if not game:IsLoaded() then
    local notLoaded = Instance.new("Message")
    notLoaded.Parent = game:GetService("CoreGui")
    notLoaded.Text = "PulseHub is waiting for the game to load"
    game.Loaded:Wait()
    notLoaded:Destroy()
end

local function getServers(placeid, cursor)
    local success, response = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..placeid.."/servers/Public?sortOrder=Desc&limit=100"
        if cursor then
            url = url.."&cursor="..cursor
        end
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and response and response.data then
        return response
    end
    return {data = {}, nextPageCursor = nil}
end

local function autoExecute()
    if queueonteleport then
        local success, script = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/Lewe1512/game/refs/heads/main/safwq.lua')
        end)
        
        if success and script then
            queueonteleport(script)
        end
    end
end

local function serverHop(option)
    autoExecute()
    
    local servers = getServers(game.PlaceId)
    if not servers or not servers.data then return end
    
    local bestServer = nil
    local bestPing = math.huge
    local targetPlayers = {
        ["most"] = {min = 6, max = 6},
        ["least"] = {min = 1, max = 1},
        ["random"] = {min = 1, max = 6}
    }
    
    while servers and #servers.data > 0 do
        for _, s in pairs(servers.data) do
            if s and s.playing and s.ping and s.id and s.id ~= game.JobId then
                local matchesPlayerCount = false
                
                if option == "random" then
                    matchesPlayerCount = s.playing >= targetPlayers[option].min and s.playing <= targetPlayers[option].max
                else
                    matchesPlayerCount = s.playing == targetPlayers[option].min
                end
                
                if matchesPlayerCount and s.ping < bestPing then
                    bestPing = s.ping
                    bestServer = s
                end
            end
        end
        
        if bestServer then break end
        if servers.nextPageCursor then
            servers = getServers(game.PlaceId, servers.nextPageCursor)
            if not servers or not servers.data then break end
        else
            break
        end
    end
    
    if bestServer then
        pcall(function()
            Fluent:Notify({
                Title = "Server Found",
                Content = string.format("Players: %d | Ping: %d ms", bestServer.playing, bestServer.ping),
                Duration = 3
            })
            task.wait(1)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, bestServer.id)
        end)
    else
        Fluent:Notify({
            Title = "No Server Found",
            Content = "Could not find a suitable server",
            Duration = 3
        })
    end
end

-- Server Hop Tab Sections
local ServerSection = ServerHopTab:AddSection("Server Hop Options")

-- Server Hop Section
local ServerHopButton = ServerSection:AddButton({
    Title = "Random Server (1-6 Players)",
    Description = "Join random server with 1-6 players and best ping",
    Callback = function()
        serverHop("random")
    end
})

local MostPlayersButton = ServerSection:AddButton({
    Title = "Most Players (6 Players)",
    Description = "Join server with 6 players and best ping",
    Callback = function()
        serverHop("most")
    end
})

local LeastPlayersButton = ServerSection:AddButton({
    Title = "Least Players (1 Player)",
    Description = "Join server with 1 player and best ping",
    Callback = function()
        serverHop("least")
    end
})

local RejoinButton = ServerSection:AddButton({
    Title = "Rejoin",
    Description = "Rejoin the same server",
    Callback = function()
        autoExecute()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end
})

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
