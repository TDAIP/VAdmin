--[[
    VAdmin Help Command Module
]]

local HelpCommand = {}

-- Import Utils
local Utils

-- Command definitions
local HelpCmdInfo = {
    Name = "help",
    Description = "Shows all available commands",
    Usage = "!help [command]",
    Rank = 0,
    Cooldown = 2
}

-- Function to register this command
function HelpCommand.Register(commandManager)
    Utils = require(script.Parent.Parent.Utils)
    
    commandManager:RegisterCommand(
        HelpCmdInfo.Name,
        HelpCmdInfo.Description,
        function(player, args) return HelpCommand.Execute(commandManager, player, args) end,
        HelpCmdInfo.Rank,
        HelpCmdInfo.Usage,
        HelpCmdInfo.Cooldown
    )
end

-- Function to execute the command
function HelpCommand.Execute(commandManager, player, args)
    local core = commandManager.Core
    local permissionManager = core.PermissionManager
    local playerRank = permissionManager:GetPlayerRank(player)
    
    -- If a specific command is requested
    if args[1] then
        local commandName = string.lower(args[1])
        local command = commandManager.Commands[commandName]
        
        if not command then
            return false, "Command not found: " .. commandName
        end
        
        if playerRank < command.Rank then
            return false, "You don't have permission to view this command"
        end
        
        local helpMessage = "Command Info: " .. command.Name .. "\n" ..
                           "Description: " .. command.Description .. "\n" ..
                           "Usage: " .. command.Usage .. "\n" ..
                           "Required Rank: " .. command.Rank .. " (" .. Utils.getRankName(core.Ranks, command.Rank) .. ")"
        
        return true, helpMessage
    end
    
    -- Show all available commands for the player's rank
    local helpMessage = "Available Commands:\n"
    local categories = {}
    
    -- Organize commands by rank
    for _, command in pairs(commandManager.Commands) do
        if playerRank >= command.Rank then
            local rankName = Utils.getRankName(core.Ranks, command.Rank)
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
end

return HelpCommand