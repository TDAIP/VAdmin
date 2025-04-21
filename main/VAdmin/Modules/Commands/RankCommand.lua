--[[
    VAdmin Rank Command Module
]]

local RankCommand = {}

-- Import Utils
local Utils

-- Command definitions
local RankCmdInfo = {
    Name = "setrank",
    Description = "Sets a player's admin rank",
    Usage = "!setrank [player] [rank]",
    Rank = 3,
    Cooldown = 5
}

-- Function to register this command
function RankCommand.Register(commandManager)
    Utils = require(script.Parent.Parent.Utils)
    
    commandManager:RegisterCommand(
        RankCmdInfo.Name,
        RankCmdInfo.Description,
        function(player, args) return RankCommand.Execute(commandManager, player, args) end,
        RankCmdInfo.Rank,
        RankCmdInfo.Usage,
        RankCmdInfo.Cooldown
    )
end

-- Function to execute the command
function RankCommand.Execute(commandManager, player, args)
    local core = commandManager.Core
    local permissionManager = core.PermissionManager
    
    if #args < 2 then
        return false, "Usage: " .. RankCmdInfo.Usage
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
    local canModify, reason = permissionManager:CanModifyRank(player, targetPlayer.UserId, rank)
    if not canModify then
        return false, reason
    end
    
    -- Set the rank
    permissionManager:SetRank(targetPlayer.UserId, rank)
    
    -- Get the rank name for display
    local rankName = Utils.getRankName(core.Ranks, rank)
    
    -- Log the rank change
    Utils.log(player.Name .. " set " .. targetPlayer.Name .. "'s rank to " .. rank .. " (" .. rankName .. ")", "Info")
    
    -- Notify target player of rank change
    Utils.sendNotification(core.NotificationEvent, targetPlayer, 
        "Your admin rank has been set to " .. rankName .. " by " .. player.Name, false)
    
    -- Notify other admins
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= player and p ~= targetPlayer and permissionManager:GetPlayerRank(p) > 0 then
            Utils.sendNotification(core.NotificationEvent, p, 
                player.Name .. " set " .. targetPlayer.Name .. "'s rank to " .. rankName, false)
        end
    end
    
    return true, "Successfully set " .. targetPlayer.Name .. "'s rank to " .. rankName
end

return RankCommand