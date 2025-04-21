--[[
    VAdmin Kick Command Module
]]

local KickCommand = {}

-- Import Utils
local Utils

-- Command definitions
local KickCmdInfo = {
    Name = "kick",
    Description = "Kicks a player from the game",
    Usage = "!kick [player] [reason]",
    Rank = 1,
    Cooldown = 5
}

-- Function to register this command
function KickCommand.Register(commandManager)
    Utils = require(script.Parent.Parent.Utils)
    
    commandManager:RegisterCommand(
        KickCmdInfo.Name,
        KickCmdInfo.Description,
        function(player, args) return KickCommand.Execute(commandManager, player, args) end,
        KickCmdInfo.Rank,
        KickCmdInfo.Usage,
        KickCmdInfo.Cooldown
    )
end

-- Function to execute the command
function KickCommand.Execute(commandManager, player, args)
    local core = commandManager.Core
    
    if #args < 1 then
        return false, "Usage: " .. KickCmdInfo.Usage
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
        return false, "Cannot kick a player with equal or higher rank"
    end
    
    local reason = "No reason provided"
    if #args > 1 then
        reason = table.concat(args, " ", 2)
    end
    
    -- Log the kick
    Utils.log("Player " .. targetPlayer.Name .. " was kicked by " .. player.Name .. ": " .. reason, "Info")
    
    -- Notify other admins
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if permissionManager:GetPlayerRank(p) > 0 and p ~= player then
            Utils.sendNotification(core.NotificationEvent, p, 
                player.Name .. " kicked " .. targetPlayer.Name .. ": " .. reason, false)
        end
    end
    
    -- Kick the player
    targetPlayer:Kick("Kicked by " .. player.Name .. ": " .. reason)
    
    return true, "Successfully kicked " .. targetPlayer.Name
end

return KickCommand