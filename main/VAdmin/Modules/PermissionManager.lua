--[[
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

return PermissionManager