--[[
    VAdmin Server Commands Module
    Contains commands related to server control: message, time, shutdown
]]

local ServerCommands = {}

-- Import Utils
local Utils

-- Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-- Command definitions
local CommandDefinitions = {
    message = {
        Name = "message",
        Description = "Sends a message to all players",
        Usage = "!message [text]",
        Rank = 2,
        Cooldown = 10
    },
    time = {
        Name = "time",
        Description = "Sets the time of day",
        Usage = "!time [hour] (0-24)",
        Rank = 2,
        Cooldown = 5
    },
    shutdown = {
        Name = "shutdown",
        Description = "Shuts down the server",
        Usage = "!shutdown [reason]",
        Rank = 4,
        Cooldown = 30
    }
}

-- Function to register all commands in this module
function ServerCommands.Register(commandManager)
    Utils = require(script.Parent.Parent.Utils)
    
    -- Register message command
    commandManager:RegisterCommand(
        CommandDefinitions.message.Name,
        CommandDefinitions.message.Description,
        function(player, args) return ServerCommands.ExecuteMessage(commandManager, player, args) end,
        CommandDefinitions.message.Rank,
        CommandDefinitions.message.Usage,
        CommandDefinitions.message.Cooldown
    )
    
    -- Register time command
    commandManager:RegisterCommand(
        CommandDefinitions.time.Name,
        CommandDefinitions.time.Description,
        function(player, args) return ServerCommands.ExecuteTime(commandManager, player, args) end,
        CommandDefinitions.time.Rank,
        CommandDefinitions.time.Usage,
        CommandDefinitions.time.Cooldown
    )
    
    -- Register shutdown command
    commandManager:RegisterCommand(
        CommandDefinitions.shutdown.Name,
        CommandDefinitions.shutdown.Description,
        function(player, args) return ServerCommands.ExecuteShutdown(commandManager, player, args) end,
        CommandDefinitions.shutdown.Rank,
        CommandDefinitions.shutdown.Usage,
        CommandDefinitions.shutdown.Cooldown
    )
end

-- Execute message command
function ServerCommands.ExecuteMessage(commandManager, player, args)
    if #args < 1 then
        return false, "Usage: " .. CommandDefinitions.message.Usage
    end
    
    local message = table.concat(args, " ")
    
    -- Send message to all players
    for _, p in ipairs(Players:GetPlayers()) do
        Utils.sendNotification(commandManager.Core.NotificationEvent, p, 
            "[ANNOUNCEMENT] " .. player.Name .. ": " .. message, false)
    end
    
    Utils.log(player.Name .. " sent server message: " .. message, "Info")
    return true, "Message sent to all players"
end

-- Execute time command
function ServerCommands.ExecuteTime(commandManager, player, args)
    if #args < 1 then
        return false, "Usage: " .. CommandDefinitions.time.Usage
    end
    
    local hour = tonumber(args[1])
    if not hour or hour < 0 or hour > 24 then
        return false, "Invalid time (0-24)"
    end
    
    -- Set the time
    Lighting.ClockTime = hour
    
    Utils.log(player.Name .. " set time to " .. hour, "Info")
    return true, "Time set to " .. hour .. ":00"
end

-- Execute shutdown command
function ServerCommands.ExecuteShutdown(commandManager, player, args)
    local reason = "Server shutdown by " .. player.Name
    if #args > 0 then
        reason = reason .. ": " .. table.concat(args, " ")
    end
    
    -- Create a delay to allow message to be sent
    task.spawn(function()
        -- Log shutdown
        Utils.log(player.Name .. " shutting down server: " .. reason, "Info")
        
        -- Notify all players
        for _, p in ipairs(Players:GetPlayers()) do
            Utils.sendNotification(commandManager.Core.NotificationEvent, p, 
                "SERVER SHUTDOWN: " .. reason, false)
        end
        
        -- Wait a bit before kicking everyone
        task.wait(2)
        
        -- Kick all players
        for _, p in ipairs(Players:GetPlayers()) do
            p:Kick(reason)
        end
    end)
    
    return true, "Server shutdown initiated"
end

return ServerCommands