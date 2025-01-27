local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Services
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "Pulse Hub",
    SubTitle = "Monke",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Initialize Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Initialize Options
local Options = Fluent.Options

-- Configuration
local AutoGreenConfig = {
    enabled = false,
    connection = nil
}

local LegitShootConfig = {
    enabled = false,
    connection = nil
}

-- Auto Green (PC) Toggle
local AutoGreenToggle = Tabs.Main:AddToggle("AutoGreenEnabled", {
    Title = "Auto Green (PC)",
    Description = "Press B for perfect 0.325s green release",
    Default = false
})

AutoGreenToggle:OnChanged(function()
    local enabled = Options.AutoGreenEnabled.Value
    AutoGreenConfig.enabled = enabled
    
    if AutoGreenConfig.connection then
        AutoGreenConfig.connection:Disconnect()
        AutoGreenConfig.connection = nil
    end

    if enabled then
        if Options.LegitShootEnabled.Value then
            Options.LegitShootEnabled:SetValue(false)
        end

        Fluent:Notify({
            Title = "Auto Green (PC)",
            Content = "System armed! Press B to activate",
            Duration = 3
        })
        
        AutoGreenConfig.connection = UIS.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.B then
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.325)
                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                
                Fluent:Notify({
                    Title = "Auto Green (PC)",
                    Content = "Activated",
                    Duration = 1.5
                })
            end
        end)
    else
        Fluent:Notify({
            Title = "Auto Green (PC)",
            Content = "System disabled",
            Duration = 3
        })
    end
end)

-- Legit Shoot Toggle
local LegitShootToggle = Tabs.Main:AddToggle("LegitShootEnabled", {
    Title = "Legit Shoot (PC)",
    Description = "Randomized timing between 0.295-0.325s",
    Default = false
})

LegitShootToggle:OnChanged(function()
    local enabled = Options.LegitShootEnabled.Value
    LegitShootConfig.enabled = enabled

    if LegitShootConfig.connection then
        LegitShootConfig.connection:Disconnect()
        LegitShootConfig.connection = nil
    end

    if enabled then
        if Options.AutoGreenEnabled.Value then
            Options.AutoGreenEnabled:SetValue(false)
        end

        Fluent:Notify({
            Title = "Legit Shoot (PC)",
            Content = "System armed! Press B for randomized timing",
            Duration = 3
        })

        LegitShootConfig.connection = UIS.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.B then
                local waitTime = math.random(295, 325)/1000
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(waitTime)
                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                
                Fluent:Notify({
                    Title = "Legit Auto Green (PC)",
                    Content = string.format("Activated after %.3fs!", waitTime),
                    Duration = 1.5
                })
            end
        end)
    else
        Fluent:Notify({
            Title = "Legit Shoot (PC)",
            Content = "System disabled",
            Duration = 3
        })
    end
end)

-- Auto Green (Mobile) Button
Tabs.Main:AddButton({
    Title = "Auto Green (Mobile)",
    Description = "Press to activate perfect green release",
    Callback = function()
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.325)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        
        Fluent:Notify({
            Title = "Auto Green (Mobile)",
            Content = "System activated!",
            Duration = 1.5
        })
    end
})

-- Setup managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("BasketballLegends")
SaveManager:SetFolder("BasketballLegends/configs")

-- Build interface
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Initial setup
Window:SelectTab(1)
Fluent:Notify({
    Title = "Basketball Legends",
    Content = "Script loaded successfully!",
    Duration = 5
})

-- Load configurations
SaveManager:LoadAutoloadConfig()
