--[[
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
    self.Admins = {
        [2375977619] = 4  -- Set owner ID with rank 4 (Game Owner)
    }
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

return VAdminCore