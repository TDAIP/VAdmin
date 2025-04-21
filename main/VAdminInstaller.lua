--[[
    VAdmin Installer
    Version: 1.0.1
    
    Cài đặt tự động VAdmin vào game Roblox của bạn.
    Chỉ cần đặt script này vào ServerScriptService và chạy.
    
    Hướng dẫn:
    1. Thêm script này vào ServerScriptService
    2. Chạy game
    3. VAdmin sẽ tự động được cài đặt
    4. Sử dụng lệnh "/cmds" hoặc "!help" trong game để xem danh sách lệnh
]]

-- Constants
local VERSION = "1.0.1"
local DEBUG_MODE = false

-- Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Log function
local function log(message, messageType)
    messageType = messageType or "Info"
    
    if messageType == "Info" then
        print("[VAdmin Installer] " .. message)
    elseif messageType == "Warning" then
        warn("[VAdmin Installer] " .. message)
    elseif messageType == "Error" then
        warn("[VAdmin Installer] ERROR: " .. message)
    elseif messageType == "Debug" and DEBUG_MODE then
        print("[VAdmin Installer Debug] " .. message)
    end
end

-- Utility functions
local function createFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

local function createScript(parent, name, source, scriptType)
    scriptType = scriptType or "ModuleScript"
    
    local script = parent:FindFirstChild(name)
    if script then
        log("Replacing existing script: " .. name, "Warning")
        script:Destroy()
    end
    
    script = Instance.new(scriptType)
    script.Name = name
    script.Source = source
    script.Parent = parent
    
    log("Created script: " .. name, "Debug")
    return script
end

-- Check if VAdmin is already installed
local function isVAdminInstalled()
    return ServerStorage:FindFirstChild("VAdmin") ~= nil
end

-- Main installer function
local function installVAdmin()
    log("Starting VAdmin installation (v" .. VERSION .. ")")
    
    if isVAdminInstalled() then
        log("VAdmin is already installed. Reinstalling...", "Warning")
        ServerStorage:FindFirstChild("VAdmin"):Destroy()
    end
    
    -- Create main folders
    local vadminFolder = createFolder(ServerStorage, "VAdmin")
    local modulesFolder = createFolder(vadminFolder, "Modules")
    local commandsFolder = createFolder(modulesFolder, "Commands")
    
    -- Create Core module
    createScript(vadminFolder, "Core", [[--[[
    VAdmin Core Module
    Main controller module for VAdmin system
]]

local VAdminCore = {}
VAdminCore.__index = VAdminCore

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Import Modules
local Utils
local DataManager
local PermissionManager
local CommandManager

-- Constants
local VERSION = "1.0.1"
local RANKS = {
    [0] = "Player",
    [1] = "Moderator",
    [2] = "Admin",
    [3] = "Super Admin",
    [4] = "Game Owner"
}

-- Create new VAdmin instance
function VAdminCore.new()
    local self = setmetatable({}, VAdminCore)
    
    -- Setup core properties
    self.Version = VERSION
    self.Ranks = RANKS
    self.Initialized = false
    self.Admins = {}
    self.BannedUsers = {}
    self.Debug = false
    
    -- Create RemoteEvents folder
    self.RemoteFolder = nil
    self.CommandEvent = nil
    self.NotificationEvent = nil
    
    -- Initialize module references to nil
    self.DataManager = nil
    self.PermissionManager = nil
    self.CommandManager = nil
    
    return self
end

-- Initialize VAdmin
function VAdminCore:Initialize()
    if self.Initialized then
        Utils.log("VAdmin already initialized", "Warning")
        return self
    end
    
    Utils.log("VAdmin v" .. self.Version .. " initializing...", "Info")
    
    -- Setup RemoteEvents
    self:SetupRemoteEvents()
    
    -- Load modules
    Utils = require(script.Parent.Modules.Utils)
    DataManager = require(script.Parent.Modules.DataManager)
    PermissionManager = require(script.Parent.Modules.PermissionManager)
    CommandManager = require(script.Parent.Modules.CommandManager)
    
    -- Initialize modules
    self.DataManager = DataManager.new(self)
    self.DataManager:Initialize()
    
    self.PermissionManager = PermissionManager.new(self)
    self.PermissionManager:Initialize()
    
    self.CommandManager = CommandManager.new(self)
    self.CommandManager:Initialize()
    
    -- Connect events
    self:ConnectEvents()
    
    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:OnPlayerJoin(player)
        end)
    end
    
    self.Initialized = true
    Utils.log("VAdmin initialized successfully!", "Info")
    
    return self
end

-- Setup Remote Events
function VAdminCore:SetupRemoteEvents()
    -- Create folder in ReplicatedStorage
    self.RemoteFolder = Instance.new("Folder")
    self.RemoteFolder.Name = "VAdmin"
    self.RemoteFolder.Parent = ReplicatedStorage
    
    -- Create command event
    self.CommandEvent = Instance.new("RemoteEvent")
    self.CommandEvent.Name = "CommandEvent"
    self.CommandEvent.Parent = self.RemoteFolder
    
    -- Create notification event
    self.NotificationEvent = Instance.new("RemoteEvent")
    self.NotificationEvent.Name = "NotificationEvent"
    self.NotificationEvent.Parent = self.RemoteFolder
end

-- Connect to events
function VAdminCore:ConnectEvents()
    -- Connect to player joining
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoin(player)
    end)
    Utils.log("Connected to PlayerAdded event", "Debug")
    
    -- Connect to command event
    self.CommandEvent.OnServerEvent:Connect(function(player, command)
        self.CommandManager:HandleCommand(player, command)
    end)
    Utils.log("Connected server event for CommandEvent", "Debug")
end

-- Handle player joining
function VAdminCore:OnPlayerJoin(player)
    local userId = player.UserId
    
    -- Check if player is banned
    local isBanned, reason = self.DataManager:IsBanned(userId)
    if isBanned then
        player:Kick("You are banned: " .. reason)
        return
    end
    
    -- Let the player know their admin status after a short delay
    task.spawn(function()
        task.wait(1)  -- Wait for character to load
        local rank = self.PermissionManager:GetPlayerRank(player)
        if rank > 0 then
            Utils.sendNotification(self.NotificationEvent, player, 
                "You are an admin with rank: " .. Utils.getRankName(self.Ranks, rank), false)
        end
    end)
end

-- Enable debug mode
function VAdminCore:EnableDebug(enable)
    self.Debug = enable
    _G.VAdminDebug = enable
    Utils.log("Debug mode " .. (enable and "enabled" or "disabled"), "Info")
end

return VAdminCore]])

    -- Create Init module
    createScript(vadminFolder, "Init", [[--[[
    VAdmin Init Module
    Entry point for VAdmin - initializes system
]]

local RunService = game:GetService("RunService")

-- Import core
local Core = require(script.Parent.Core)

-- Initialize
local function InitServer()
    local VAdmin = Core.new()
    VAdmin:Initialize()
    return VAdmin
end

local function InitClient()
    local UI = require(script.Parent.UI)
    UI.Initialize()
    return UI
end

-- Determine if we're on server or client
if RunService:IsServer() then
    return InitServer()
else
    return InitClient()
end]])

    -- Create UI module
    createScript(vadminFolder, "UI", [[--[[
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

return VAdminUI]])

    -- Create Utils module
    createScript(modulesFolder, "Utils", [[--[[
    VAdmin Utilities Module
    Contains utility functions for VAdmin system
]]

local Utils = {}

-- Services
local Players = game:GetService("Players")

-- Get player by name, with exact match priority
function Utils.getPlayerByName(name)
    name = string.lower(name)
    
    -- First, try exact match
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == name then
            return player
        end
    end
    
    -- If no exact match, try prefix match
    for _, player in ipairs(Players:GetPlayers()) do
        if string.sub(string.lower(player.Name), 1, #name) == name then
            return player
        end
    end
    
    -- If still no match, try partial match
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), name, 1, true) then
            return player
        end
    end
    
    return nil
end

-- Get player by UserId
function Utils.getPlayerByUserId(userId)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then
            return player
        end
    end
    return nil
end

-- Send notification to a player
function Utils.sendNotification(notificationEvent, player, message, isError)
    -- If isError is true, this is an error notification
    notificationEvent:FireClient(player, message, isError or false)
end

-- Get rank name from numeric rank
function Utils.getRankName(ranks, rank)
    return ranks[rank] or "Unknown"
end

-- Log message with VAdmin prefix
function Utils.log(message, logLevel)
    logLevel = logLevel or "Info"
    
    if logLevel == "Info" then
        print("[VAdmin] " .. message)
    elseif logLevel == "Warning" then
        warn("[VAdmin] " .. message)
    elseif logLevel == "Error" then
        warn("[VAdmin] ERROR: " .. message)
    elseif logLevel == "Debug" then
        if _G.VAdminDebug then
            print("[VAdmin Debug] " .. message)
        end
    end
end

-- Rate limiting for commands
local cooldowns = {}

function Utils.checkCooldown(player, commandName, cooldownTime)
    cooldownTime = cooldownTime or 1 -- Default cooldown is 1 second
    
    local playerId = player.UserId
    local commandKey = playerId .. "_" .. commandName
    
    if not cooldowns[commandKey] then
        cooldowns[commandKey] = os.time()
        return true
    end
    
    local timePassed = os.time() - cooldowns[commandKey]
    if timePassed < cooldownTime then
        return false, cooldownTime - timePassed
    end
    
    cooldowns[commandKey] = os.time()
    return true
end

-- Retry function with exponential backoff
-- For DataStore operations that might fail temporarily
function Utils.retryWithBackoff(func, maxRetries, initialBackoff)
    maxRetries = maxRetries or 5
    initialBackoff = initialBackoff or 1
    
    local success, result
    local retries = 0
    local backoff = initialBackoff
    
    repeat
        success, result = pcall(func)
        
        if not success then
            retries = retries + 1
            if retries >= maxRetries then
                return false, result
            end
            
            Utils.log("Operation failed, retrying in " .. backoff .. " seconds. Error: " .. tostring(result), "Warning")
            wait(backoff)
            backoff = backoff * 2 -- Exponential backoff
        end
    until success
    
    return true, result
end

return Utils]])

    -- Create DataManager module
    createScript(modulesFolder, "DataManager", [[--[[
    VAdmin DataManager Module
    Handles all DataStore operations with retry and validation
]]

local DataManager = {}
DataManager.__index = DataManager

-- Services
local DataStoreService = game:GetService("DataStoreService")

-- Import Utils
local Utils = require(script.Parent.Utils)

function DataManager.new(core)
    local self = setmetatable({}, DataManager)
    self.Core = core
    self.Enabled = false
    self.BanStore = nil
    self.RetryCount = 5
    self.InitialBackoff = 1
    self.CacheTime = 600 -- Cache data for 10 minutes before refreshing
    self.LastCacheTime = 0
    return self
end

function DataManager:Initialize()
    local success, result = Utils.retryWithBackoff(function()
        Utils.log("Initializing DataStore: VAdminBans", "Debug")
        return DataStoreService:GetDataStore("VAdminBans")
    end, self.RetryCount, self.InitialBackoff)
    
    if success then
        self.BanStore = result
        self.Enabled = true
        Utils.log("DataStore initialized successfully", "Info")
        
        -- Load banned users
        self:LoadBannedUsers()
    else
        Utils.log("DataStore initialization failed: " .. tostring(result), "Error")
    end
    
    return self.Enabled
end

function DataManager:LoadBannedUsers()
    if not self.Enabled or not self.BanStore then
        return false
    end
    
    -- Check if we need to refresh cache
    local currentTime = os.time()
    if currentTime - self.LastCacheTime < self.CacheTime and self.LastCacheTime > 0 then
        Utils.log("Using cached ban data", "Debug")
        return true
    end
    
    local success, result = Utils.retryWithBackoff(function()
        Utils.log("Loading banned users from DataStore", "Debug")
        return self.BanStore:GetAsync("BannedUsers")
    end, self.RetryCount, self.InitialBackoff)
    
    if success then
        if result and type(result) == "table" then
            self.Core.BannedUsers = result
            self.LastCacheTime = currentTime
            Utils.log("Loaded " .. self:CountBannedUsers() .. " banned users", "Info")
            return true
        else
            Utils.log("Banned users data is not a table or is nil, initializing empty table", "Warning")
            self.Core.BannedUsers = {}
            self.LastCacheTime = currentTime
            return true
        end
    else
        Utils.log("Failed to load banned users: " .. tostring(result), "Error")
        return false
    end
end

function DataManager:SaveBannedUsers()
    if not self.Enabled or not self.BanStore then
        return false
    end
    
    local success, result = Utils.retryWithBackoff(function()
        Utils.log("Saving banned users to DataStore", "Debug")
        return self.BanStore:SetAsync("BannedUsers", self.Core.BannedUsers)
    end, self.RetryCount, self.InitialBackoff)
    
    if success then
        self.LastCacheTime = os.time()
        Utils.log("Saved " .. self:CountBannedUsers() .. " banned users", "Info")
        return true
    else
        Utils.log("Failed to save banned users: " .. tostring(result), "Error")
        return false
    end
end

function DataManager:CountBannedUsers()
    local count = 0
    for _ in pairs(self.Core.BannedUsers) do
        count = count + 1
    end
    return count
end

function DataManager:BanUser(userId, name, reason, banner)
    if not self.Enabled then
        return false
    end
    
    self.Core.BannedUsers[tostring(userId)] = {
        name = name,
        reason = reason,
        banner = banner,
        timestamp = os.time()
    }
    
    return self:SaveBannedUsers()
end

function DataManager:UnbanUser(userId)
    if not self.Enabled then
        return false
    end
    
    if not self.Core.BannedUsers[tostring(userId)] then
        return false
    end
    
    self.Core.BannedUsers[tostring(userId)] = nil
    return self:SaveBannedUsers()
end

function DataManager:IsBanned(userId)
    if not self.Core.BannedUsers[tostring(userId)] then
        return false
    end
    
    return true, self.Core.BannedUsers[tostring(userId)].reason
end

return DataManager]])

    -- Create PermissionManager module
    createScript(modulesFolder, "PermissionManager", [[--[[
    VAdmin PermissionManager Module
    Handles admin permissions and ranks
]]

local PermissionManager = {}
PermissionManager.__index = PermissionManager

-- Services
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

-- Import Utils
local Utils = require(script.Parent.Utils)

function PermissionManager.new(core)
    local self = setmetatable({}, PermissionManager)
    self.Core = core
    self.GroupOwnerCache = {} -- Cache Group Owner IDs
    return self
end

function PermissionManager:Initialize()
    -- Cache the game's creator information
    self.CreatorType = game.CreatorType
    self.CreatorId = game.CreatorId
    
    -- If it's a group game, cache the owner ID
    if self.CreatorType == Enum.CreatorType.Group then
        self:CacheGroupOwner(self.CreatorId)
    end
    
    Utils.log("Permission Manager initialized", "Info")
    return true
end

function PermissionManager:CacheGroupOwner(groupId)
    local success, result = pcall(function()
        return GroupService:GetGroupInfoAsync(groupId)
    end)
    
    if success and result and result.Owner then
        self.GroupOwnerCache[groupId] = result.Owner.Id
        Utils.log("Cached owner ID " .. result.Owner.Id .. " for group " .. groupId, "Debug")
    else
        Utils.log("Failed to cache owner for group " .. groupId, "Warning")
    end
end

function PermissionManager:IsGameCreator(userId)
    if self.CreatorType == Enum.CreatorType.User then
        return userId == self.CreatorId
    elseif self.CreatorType == Enum.CreatorType.Group then
        -- Check cached group owner first
        if self.GroupOwnerCache[self.CreatorId] then
            return userId == self.GroupOwnerCache[self.CreatorId]
        end
        
        -- If not cached, try to get it
        local success, result = pcall(function()
            return GroupService:GetGroupInfoAsync(self.CreatorId)
        end)
        
        if success and result and result.Owner then
            self.GroupOwnerCache[self.CreatorId] = result.Owner.Id
            return userId == result.Owner.Id
        end
    end
    
    return false
end

function PermissionManager:GetPlayerRank(player)
    local userId = player.UserId
    
    -- Check if player is the game creator
    if self:IsGameCreator(userId) then
        return 4 -- Game Owner
    end
    
    -- Check admin list
    if self.Core.Admins[userId] then
        return self.Core.Admins[userId]
    end
    
    return 0 -- Regular player
end

function PermissionManager:SetRank(userId, rank)
    if rank < 0 or rank > 4 then
        return false, "Invalid rank (0-4)"
    end
    
    self.Core.Admins[userId] = rank
    Utils.log("Set rank " .. rank .. " for user " .. userId, "Info")
    return true
end

function PermissionManager:CanUseCommand(player, requiredRank)
    local playerRank = self:GetPlayerRank(player)
    return playerRank >= requiredRank
end

function PermissionManager:CanModifyRank(player, targetUserId, newRank)
    local playerRank = self:GetPlayerRank(player)
    
    -- Game creators (rank 4) can do anything
    if playerRank == 4 then
        return true
    end
    
    -- Cannot promote to a rank higher than your own
    if newRank > playerRank then
        return false, "Cannot promote to a rank higher than your own"
    end
    
    -- Cannot modify rank of someone with equal or higher rank
    local targetPlayer = Utils.getPlayerByUserId(targetUserId)
    if targetPlayer then
        local targetRank = self:GetPlayerRank(targetPlayer)
        if targetRank >= playerRank and targetRank > 0 then
            return false, "Cannot modify rank of someone with equal or higher rank"
        end
    end
    
    return true
end

return PermissionManager]])

    -- Create CommandManager module
    createScript(modulesFolder, "CommandManager", [[--[[
    VAdmin CommandManager Module
    Handles command registration and execution
]]

local CommandManager = {}
CommandManager.__index = CommandManager

-- Import Utils
local Utils = require(script.Parent.Utils)

function CommandManager.new(core)
    local self = setmetatable({}, CommandManager)
    self.Core = core
    self.Commands = {}
    self.CommandPrefix = "!"
    self.CommandCooldown = 1 -- Default cooldown for commands (in seconds)
    return self
end

function CommandManager:Initialize()
    -- Register built-in commands
    self:RegisterDefaultCommands()
    Utils.log("Command Manager initialized with " .. self:CountCommands() .. " commands", "Info")
    return true
end

function CommandManager:RegisterCommand(name, description, func, requiredRank, usage, cooldown)
    self.Commands[string.lower(name)] = {
        Name = name,
        Description = description,
        Function = func,
        Rank = requiredRank or 0,
        Usage = usage or "",
        Cooldown = cooldown or self.CommandCooldown
    }
    Utils.log("Registered command: " .. name, "Debug")
end

function CommandManager:CountCommands()
    local count = 0
    for _ in pairs(self.Commands) do
        count = count + 1
    end
    return count
end

function CommandManager:HandleCommand(player, message)
    -- Check if message starts with the command prefix
    if string.sub(message, 1, 1) ~= self.CommandPrefix then
        return false
    end
    
    local commandText = string.sub(message, 2)
    local args = {}
    
    for arg in string.gmatch(commandText, "%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 then
        return false
    end
    
    local commandName = string.lower(args[1])
    table.remove(args, 1)
    
    local command = self.Commands[commandName]
    if not command then
        Utils.sendNotification(self.Core.NotificationEvent, player, "Unknown command: " .. commandName, true)
        return false
    end
    
    -- Check if player has permission to use this command
    if not self.Core.PermissionManager:CanUseCommand(player, command.Rank) then
        Utils.sendNotification(self.Core.NotificationEvent, player, "You don't have permission to use this command", true)
        return false
    end
    
    -- Check cooldown
    local canUse, timeLeft = Utils.checkCooldown(player, commandName, command.Cooldown)
    if not canUse then
        Utils.sendNotification(self.Core.NotificationEvent, player, "Command on cooldown. Try again in " .. timeLeft .. " seconds", true)
        return false
    end
    
    -- Execute the command and capture results
    local success, message = pcall(function()
        return command.Function(player, args)
    end)
    
    if not success then
        Utils.log("Error executing command " .. commandName .. ": " .. tostring(message), "Error")
        Utils.sendNotification(self.Core.NotificationEvent, player, "Error executing command", true)
        return false
    end
    
    -- For commands that return a boolean + message
    if type(message) == "table" and message[1] ~= nil then
        local cmdSuccess, cmdMessage = message[1], message[2]
        
        if cmdSuccess == false and cmdMessage then
            Utils.sendNotification(self.Core.NotificationEvent, player, cmdMessage, true)
        elseif cmdSuccess == true and cmdMessage then
            Utils.sendNotification(self.Core.NotificationEvent, player, cmdMessage, false)
        end
        
        return cmdSuccess
    end
    
    -- For legacy commands that just return a boolean
    if type(message) == "boolean" then
        return message
    end
    
    return true
end

function CommandManager:RegisterDefaultCommands()
    -- Help Command
    self:RegisterCommand("help", "Shows all available commands", function(player, args)
        local permissionManager = self.Core.PermissionManager
        local playerRank = permissionManager:GetPlayerRank(player)
        
        -- If a specific command is requested
        if args[1] then
            local commandName = string.lower(args[1])
            local command = self.Commands[commandName]
            
            if not command then
                return false, "Command not found: " .. commandName
            end
            
            if playerRank < command.Rank then
                return false, "You don't have permission to view this command"
            end
            
            local helpMessage = "Command Info: " .. command.Name .. "\n" ..
                               "Description: " .. command.Description .. "\n" ..
                               "Usage: " .. command.Usage .. "\n" ..
                               "Required Rank: " .. command.Rank .. " (" .. Utils.getRankName(self.Core.Ranks, command.Rank) .. ")"
            
            return true, helpMessage
        end
        
        -- Show all available commands for the player's rank
        local helpMessage = "Available Commands:\n"
        local categories = {}
        
        -- Organize commands by rank
        for _, command in pairs(self.Commands) do
            if playerRank >= command.Rank then
                local rankName = Utils.getRankName(self.Core.Ranks, command.Rank)
                if not categories[rankName] then
                    categories[rankName] = {}
                end
                table.insert(categories[rankName], command)
            end
        end
        
        -- Display commands by category
        for rankName, commands in pairs(categories) do
            helpMessage = helpMessage .. "\n--- " .. rankName .. " Commands ---\n"
            for _, command in pairs(commands) do
                helpMessage = helpMessage .. "!" .. command.Name .. " - " .. command.Description .. "\n"
            end
        end
        
        helpMessage = helpMessage .. "\nUse !help [command] for more information about a specific command."
        
        return true, helpMessage
    end, 0, "!help [command]", 2)
    
    -- Also register "cmds" as alias for help
    self:RegisterCommand("cmds", "Shows all available commands (alias for help)", function(player, args)
        return self.Commands["help"].Function(player, args)
    end, 0, "!cmds [command]", 2)
    
    -- Kick Command
    self:RegisterCommand("kick", "Kicks a player from the game", function(player, args)
        if #args < 1 then
            return false, "Usage: !kick [player] [reason]"
        end
        
        local targetPlayer = Utils.getPlayerByName(args[1])
        if not targetPlayer then
            return false, "Player not found"
        end
        
        -- Check if target has higher rank
        local permissionManager = self.Core.PermissionManager
        local playerRank = permissionManager:GetPlayerRank(player)
        local targetRank = permissionManager:GetPlayerRank(targetPlayer)
        
        if targetRank >= playerRank then
            return false, "Cannot kick a player with equal or higher rank"
        end
        
        local reason = "No reason provided"
        if #args > 1 then
            reason = table.concat(args, " ", 2)
        end
        
        -- Kick the player
        targetPlayer:Kick("Kicked by " .. player.Name .. ": " .. reason)
        
        return true, "Successfully kicked " .. targetPlayer.Name
    end, 1, "!kick [player] [reason]", 5)
    
    -- Ban Command
    self:RegisterCommand("ban", "Bans a player from the game", function(player, args)
        if #args < 1 then
            return false, "Usage: !ban [player] [reason]"
        end
        
        local targetPlayer = Utils.getPlayerByName(args[1])
        if not targetPlayer then
            return false, "Player not found"
        end
        
        -- Check if target has higher rank
        local permissionManager = self.Core.PermissionManager
        local playerRank = permissionManager:GetPlayerRank(player)
        local targetRank = permissionManager:GetPlayerRank(targetPlayer)
        
        if targetRank >= playerRank then
            return false, "Cannot ban a player with equal or higher rank"
        end
        
        local reason = "No reason provided"
        if #args > 1 then
            reason = table.concat(args, " ", 2)
        end
        
        -- Add to banned users and save to DataStore
        self.Core.DataManager:BanUser(
            targetPlayer.UserId,
            targetPlayer.Name,
            reason,
            player.Name
        )
        
        -- Kick the player
        targetPlayer:Kick("Banned by " .. player.Name .. ": " .. reason)
        
        return true, "Successfully banned " .. targetPlayer.Name
    end, 2, "!ban [player] [reason]", 5)
    
    -- Unban Command
    self:RegisterCommand("unban", "Unbans a player from the game", function(player, args)
        if #args < 1 then
            return false, "Usage: !unban [userId]"
        end
        
        local userId = tonumber(args[1])
        if not userId then
            return false, "Invalid user ID. Please enter a numeric user ID."
        end
        
        -- Check if user is actually banned
        local isBanned, _ = self.Core.DataManager:IsBanned(userId)
        if not isBanned then
            return false, "Player is not banned"
        end
        
        -- Unban the user
        self.Core.DataManager:UnbanUser(userId)
        
        return true, "Successfully unbanned user " .. userId
    end, 2, "!unban [userId]", 5)
    
    -- Set Rank Command
    self:RegisterCommand("setrank", "Sets a player's admin rank", function(player, args)
        if #args < 2 then
            return false, "Usage: !setrank [player] [rank]"
        end
        
        local targetPlayer = Utils.getPlayerByName(args[1])
        if not targetPlayer then
            return false, "Player not found"
        end
        
        local rank = tonumber(args[2])
        if not rank or rank < 0 or rank > 4 then
            return false, "Invalid rank (0-4)"
        end
        
        -- Check if player can modify target's rank
        local permissionManager = self.Core.PermissionManager
        local canModify, reason = permissionManager:CanModifyRank(player, targetPlayer.UserId, rank)
        if not canModify then
            return false, reason
        end
        
        -- Set the rank
        permissionManager:SetRank(targetPlayer.UserId, rank)
        
        -- Get the rank name for display
        local rankName = Utils.getRankName(self.Core.Ranks, rank)
        
        -- Notify target player of rank change
        Utils.sendNotification(self.Core.NotificationEvent, targetPlayer, 
            "Your admin rank has been set to " .. rankName .. " by " .. player.Name, false)
        
        return true, "Successfully set " .. targetPlayer.Name .. "'s rank to " .. rankName
    end, 3, "!setrank [player] [rank]", 5)
    
    -- Kill Command
    self:RegisterCommand("kill", "Kills a player", function(player, args)
        if #args < 1 then
            return false, "Usage: !kill [player]"
        end
        
        local targetPlayer = Utils.getPlayerByName(args[1])
        if not targetPlayer then
            return false, "Player not found"
        end
        
        -- Check if target has higher rank
        local permissionManager = self.Core.PermissionManager
        local playerRank = permissionManager:GetPlayerRank(player)
        local targetRank = permissionManager:GetPlayerRank(targetPlayer)
        
        if targetRank >= playerRank and player ~= targetPlayer then
            return false, "Cannot kill a player with equal or higher rank"
        end
        
        -- Try to kill the player
        local character = targetPlayer.Character
        if not character or not character:FindFirstChild("Humanoid") then
            return false, "Could not kill player (character not loaded)"
        end
        
        character.Humanoid.Health = 0
        
        return true, "Successfully killed " .. targetPlayer.Name
    end, 2, "!kill [player]", 3)
    
    -- Heal Command
    self:RegisterCommand("heal", "Heals a player to full health", function(player, args)
        local targetPlayer
        
        if #args < 1 then
            targetPlayer = player
        else
            targetPlayer = Utils.getPlayerByName(args[1])
        end
        
        if not targetPlayer then
            return false, "Player not found"
        end
        
        -- Check if target has higher rank (if not self)
        if targetPlayer ~= player then
            local permissionManager = self.Core.PermissionManager
            local playerRank = permissionManager:GetPlayerRank(player)
            local targetRank = permissionManager:GetPlayerRank(targetPlayer)
            
            if targetRank >= playerRank then
                return false, "Cannot heal a player with equal or higher rank"
            end
        end
        
        -- Try to heal the player
        local character = targetPlayer.Character
        if not character or not character:FindFirstChild("Humanoid") then
            return false, "Could not heal player (character not loaded)"
        end
        
        character.Humanoid.Health = character.Humanoid.MaxHealth
        
        local message
        if targetPlayer == player then
            message = "You have healed yourself"
        else
            Utils.sendNotification(self.Core.NotificationEvent, targetPlayer, 
                "You have been healed by " .. player.Name, false)
            message = "You have healed " .. targetPlayer.Name
        end
        
        return true, message
    end, 1, "!heal [player]", 3)
    
    -- Add other commands...
    -- Respawn, Speed, Jump, TP, Bring, Message, Time, Shutdown, etc.
    
    -- (For brevity, I've included the most commonly used commands)
    -- You can expand this section with more commands as needed
    
    -- Message Command
    self:RegisterCommand("message", "Sends a message to all players", function(player, args)
        if #args < 1 then
            return false, "Usage: !message [text]"
        end
        
        local message = table.concat(args, " ")
        
        -- Send message to all players
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            Utils.sendNotification(self.Core.NotificationEvent, p, 
                "[ANNOUNCEMENT] " .. player.Name .. ": " .. message, false)
        end
        
        return true, "Message sent to all players"
    end, 2, "!message [text]", 10)
    
    -- Shutdown Command
    self:RegisterCommand("shutdown", "Shuts down the server", function(player, args)
        local reason = "Server shutdown by " .. player.Name
        if #args > 0 then
            reason = reason .. ": " .. table.concat(args, " ")
        end
        
        -- Create a delay to allow message to be sent
        task.spawn(function()
            -- Notify all players
            for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                Utils.sendNotification(self.Core.NotificationEvent, p, 
                    "SERVER SHUTDOWN: " .. reason, false)
            end
            
            -- Wait a bit before kicking everyone
            task.wait(2)
            
            -- Kick all players
            for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                p:Kick(reason)
            end
        end)
        
        return true, "Server shutdown initiated"
    end, 4, "!shutdown [reason]", 30)
end

return CommandManager]])

    -- Create script to start VAdmin
    local VAdminStarter = createScript(ServerScriptService, "VAdminStarter", [[--[[
    VAdmin Starter Script
    This script starts the VAdmin system
]]

-- Get the VAdmin module
local VAdmin = require(game:GetService("ServerStorage"):WaitForChild("VAdmin"):WaitForChild("Init"))

-- That's it! VAdmin is now running.
print("VAdmin is now active. Use ! commands in-game.")]], "Script")

    -- Create client script for UI
    local VAdminClient = createScript(ReplicatedStorage, "VAdminClient", [[--[[
    VAdmin Client Script
    This script handles the client-side UI for VAdmin
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for player to be fully loaded
if not player then
    player = Players.PlayerAdded:Wait()
end

-- Wait for character to load
if not player.Character then
    player.CharacterAdded:Wait()
end

-- Load the VAdmin UI module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VAdminModule = ReplicatedStorage:WaitForChild("VAdmin", 10)

if VAdminModule then
    -- Delay slightly to ensure everything is loaded
    task.wait(1)
    
    -- Load VAdmin UI
    local success, err = pcall(function()
        local VAdminUI = require(game:GetService("ServerStorage"):WaitForChild("VAdmin"):WaitForChild("UI"))
        VAdminUI.Initialize()
    end)
    
    if not success then
        warn("Failed to initialize VAdmin UI: " .. tostring(err))
    end
else
    warn("VAdmin not found in ReplicatedStorage")
end]], "LocalScript")

    log("VAdmin v" .. VERSION .. " has been installed!")
    log("Place VAdminStarter in ServerScriptService and VAdminClient in ReplicatedStorage or StarterPlayerScripts")
    log("VAdmin is now active in your game!")
    
    -- Return a success message
    return true, "VAdmin successfully installed!"
end

-- Check for the right environment
local success, message = pcall(function()
    return installVAdmin()
end)

if not success then
    log("Error during installation: " .. tostring(message), "Error")
    error("VAdmin installation failed: " .. tostring(message))
end