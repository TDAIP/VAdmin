--[[
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
    -- Import command modules
    local commandModules = {
        require(script.Parent.Commands.HelpCommand),
        require(script.Parent.Commands.KickCommand),
        require(script.Parent.Commands.BanCommand),
        require(script.Parent.Commands.RankCommand),
        require(script.Parent.Commands.PlayerCommands),
        require(script.Parent.Commands.ServerCommands)
    }
    
    -- Register all commands from modules
    for _, module in ipairs(commandModules) do
        if typeof(module) == "table" and module.Register then
            module.Register(self)
        end
    end
end

return CommandManager