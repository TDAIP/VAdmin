--[[
    VAdmin Ban/Unban Commands Module
]]

local BanCommands = {}

-- Import Utils
local Utils

-- Command definitions
local BanCmdInfo = {
    Name = "ban",
    Description = "Bans a player from the game",
    Usage = "!ban [player] [reason]",
    Rank = 2,
    Cooldown = 5
}

local UnbanCmdInfo = {
    Name = "unban",
    Description = "Unbans a player from the game",
    Usage = "!unban [userId]",
    Rank = 2,
    Cooldown = 5
}

-- Function to register these commands
function BanCommands.Register(commandManager)
    Utils = require(script.Parent.Parent.Utils)
    
    -- Register Ban Command
    commandManager:RegisterCommand(
        BanCmdInfo.Name,
        BanCmdInfo.Description,
        function(player, args) return BanCommands.ExecuteBan(commandManager, player, args) end,
        BanCmdInfo.Rank,
        BanCmdInfo.Usage,
        BanCmdInfo.Cooldown
    )
    
    -- Register Unban Command
    commandManager:RegisterCommand(
        UnbanCmdInfo.Name,
        UnbanCmdInfo.Description,
        function(player, args) return BanCommands.ExecuteUnban(commandManager, player, args) end,
        UnbanCmdInfo.Rank,
        UnbanCmdInfo.Usage,
        UnbanCmdInfo.Cooldown
    )
end

-- Function to execute the ban command
function BanCommands.ExecuteBan(commandManager, player, args)
    local core = commandManager.Core
    local dataManager = core.DataManager
    
    if #args < 1 then
        return false, "Usage: " .. BanCmdInfo.Usage
    end
    
    local targetPlayer = Utils.getPlayerByName(args[1])
    if not targetPlayer then
        return false, "Player not found"
    end
    
    -- Check if target has higher rank
    local permissionManager = core.PermissionManager
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
    local success = dataManager:BanUser(
        targetPlayer.UserId,
        targetPlayer.Name,
        reason,
        player.Name
    )
    
    if not success and dataManager.Enabled then
        Utils.log("Failed to save ban for " .. targetPlayer.Name .. " to DataStore", "Warning")
        -- Still continue with the kick since ban is recorded in memory
    end
    
    -- Log the ban
    Utils.log("Player " .. targetPlayer.Name .. " was banned by " .. player.Name .. ": " .. reason, "Info")
    
    -- Notify other admins
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if permissionManager:GetPlayerRank(p) > 0 and p ~= player then
            Utils.sendNotification(core.NotificationEvent, p, 
                player.Name .. " banned " .. targetPlayer.Name .. ": " .. reason, false)
        end
    end
    
    -- Kick the player
    targetPlayer:Kick("Banned by " .. player.Name .. ": " .. reason)
    
    return true, "Successfully banned " .. targetPlayer.Name
end

-- Function to execute the unban command
function BanCommands.ExecuteUnban(commandManager, player, args)
    local core = commandManager.Core
    local dataManager = core.DataManager
    
    if #args < 1 then
        return false, "Usage: " .. UnbanCmdInfo.Usage
    end
    
    local userId = tonumber(args[1])
    if not userId then
        return false, "Invalid user ID. Please enter a numeric user ID."
    end
    
    -- Check if user is actually banned
    local isBanned, _ = dataManager:IsBanned(userId)
    if not isBanned then
        return false, "Player is not banned"
    end
    
    -- Unban the user and save to DataStore
    local success = dataManager:UnbanUser(userId)
    
    if not success and dataManager.Enabled then
        return false, "Failed to unban player. Please try again."
    end
    
    -- Log the unban
    Utils.log("User " .. userId .. " was unbanned by " .. player.Name, "Info")
    
    -- Notify other admins
    local permissionManager = core.PermissionManager
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if permissionManager:GetPlayerRank(p) > 0 and p ~= player then
            Utils.sendNotification(core.NotificationEvent, p, 
                player.Name .. " unbanned user " .. userId, false)
        end
    end
    
    return true, "Successfully unbanned user " .. userId
end

return BanCommands