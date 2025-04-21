--[[
    VAdmin UI Module
    Client-side UI for VAdmin
]]

local VAdminUI = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Constants
local NOTIFICATION_DURATION = 5  -- Seconds
local MAX_NOTIFICATIONS = 5
local NOTIFICATION_COLORS = {
    Default = Color3.fromRGB(0, 120, 255),
    Error = Color3.fromRGB(255, 50, 50),
    Success = Color3.fromRGB(50, 200, 50)
}

-- Variables
local player = Players.LocalPlayer
local screenGui
local notificationFrame
local commandBar
local activeNotifications = {}

-- Create UI elements
local function createCommandBar()
    commandBar = Instance.new("Frame")
    commandBar.Name = "CommandBar"
    commandBar.Size = UDim2.new(0, 300, 0, 30)
    commandBar.Position = UDim2.new(0.5, -150, 0.95, -30)
    commandBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    commandBar.BackgroundTransparency = 0.3
    commandBar.BorderSizePixel = 0
    commandBar.Visible = false
    commandBar.Parent = screenGui
    
    local textBox = Instance.new("TextBox")
    textBox.Name = "CommandInput"
    textBox.Size = UDim2.new(1, -10, 1, -6)
    textBox.Position = UDim2.new(0, 5, 0, 3)
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    textBox.BackgroundTransparency = 0.3
    textBox.BorderSizePixel = 0
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 18
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Text = ""
    textBox.PlaceholderText = "Type command here..."
    textBox.Parent = commandBar
    
    return textBox
end

local function createNotificationFrame()
    notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0, 300, 0, 0)
    notificationFrame.Position = UDim2.new(0.99, -310, 0.05, 0)
    notificationFrame.BackgroundTransparency = 1
    notificationFrame.Parent = screenGui
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = notificationFrame
end

-- Initialize UI
function VAdminUI.Initialize()
    -- Find existing UI or create new one
    screenGui = player:FindFirstChild("PlayerGui"):FindFirstChild("VAdminUI")
    
    if screenGui then
        screenGui:Destroy()
    end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VAdminUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    -- Create UI components
    createNotificationFrame()
    local commandInput = createCommandBar()
    
    -- Connect events
    local remoteFolder = ReplicatedStorage:WaitForChild("VAdmin")
    local commandEvent = remoteFolder:WaitForChild("CommandEvent")
    local notificationEvent = remoteFolder:WaitForChild("NotificationEvent")
    
    -- Connect notification event
    notificationEvent.OnClientEvent:Connect(function(message, isError)
        VAdminUI.ShowNotification(message, isError and "Error" or "Default")
    end)
    
    -- Connect command input
    commandInput.FocusLost:Connect(function(enterPressed)
        if enterPressed and commandInput.Text ~= "" then
            local command = commandInput.Text
            commandEvent:FireServer(command)
            commandInput.Text = ""
        end
        commandBar.Visible = false
    end)
    
    -- Connect slash key to show command bar
    local userInputService = game:GetService("UserInputService")
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Slash then
            commandBar.Visible = true
            commandInput:CaptureFocus()
            wait()
            commandInput.Text = ""
        end
    end)
    
    -- Show welcome message
    VAdminUI.ShowNotification("VAdmin UI initialized. Press / to enter commands.", "Success")
    
    return true
end

-- Show notification
function VAdminUI.ShowNotification(message, colorType)
    colorType = colorType or "Default"
    
    -- Limit number of active notifications
    if #activeNotifications >= MAX_NOTIFICATIONS then
        -- Remove oldest notification
        local oldest = table.remove(activeNotifications, 1)
        oldest:Destroy()
    end
    
    -- Create notification
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(1, 0, 0, 0) -- Start with 0 height
    notification.BackgroundColor3 = NOTIFICATION_COLORS[colorType]
    notification.BackgroundTransparency = 0.2
    notification.BorderSizePixel = 0
    notification.AutomaticSize = Enum.AutomaticSize.Y
    notification.Parent = notificationFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = notification
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Message"
    textLabel.Size = UDim2.new(1, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextSize = 16
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.AutomaticSize = Enum.AutomaticSize.Y
    textLabel.Text = message
    textLabel.Parent = notification
    
    -- Add to active notifications
    table.insert(activeNotifications, notification)
    
    -- Fade in
    notification.BackgroundTransparency = 1
    textLabel.TextTransparency = 1
    
    local fadeInInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeIn = TweenService:Create(notification, fadeInInfo, {BackgroundTransparency = 0.2})
    local textFadeIn = TweenService:Create(textLabel, fadeInInfo, {TextTransparency = 0})
    
    fadeIn:Play()
    textFadeIn:Play()
    
    -- Fade out after delay
    spawn(function()
        wait(NOTIFICATION_DURATION)
        
        -- Check if notification still exists
        if notification and notification.Parent then
            local fadeOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local fadeOut = TweenService:Create(notification, fadeOutInfo, {BackgroundTransparency = 1})
            local textFadeOut = TweenService:Create(textLabel, fadeOutInfo, {TextTransparency = 1})
            
            fadeOut:Play()
            textFadeOut:Play()
            
            fadeOut.Completed:Wait()
            
            -- Remove from active notifications
            for i, notif in ipairs(activeNotifications) do
                if notif == notification then
                    table.remove(activeNotifications, i)
                    break
                end
            end
            
            notification:Destroy()
        end
    end)
end

return VAdminUI