--[[
    VAdmin Player Commands Module
    Contains commands related to player control: heal, kill, respawn, speed, jump, teleport, bring
]]

local PlayerCommands = {}

-- Import Utils
local Utils

-- Command definitions
local CommandDefinitions = {
    heal = {
        Name = "heal",
        Description = "Heals a player to full health",
        Usage = "!heal [player]",
        Rank = 1,
        Cooldown = 3
    },
    kill = {
        Name = "kill",
        Description = "Kills a player",
        Usage = "!kill [player]",
        Rank = 2,
        Cooldown = 3
    },
    respawn = {
        Name = "respawn",
        Description = "Respawns a player",
        Usage = "!respawn [player]",
        Rank = 1,
        Cooldown = 3
    },
    speed = {
        Name = "speed",
        Description = "Sets a player's walkspeed",
        Usage = "!speed [player] [speed]",
        Rank = 1,
        Cooldown = 2
    },
    jump = {
        Name = "jump",
        Description = "Sets a player's jump power",
        Usage = "!jump [player] [power]",
        Rank = 1,
        Cooldown = 2
    },
    tp = {
        Name = "tp",
        Description = "Teleports a player to another player",
        Usage = "!tp [player] [destination]",
        Rank = 1,
        Cooldown = 3
    },
    bring = {
        Name = "bring",
        Description = "Brings a player to you",
        Usage = "!bring [player]",
        Rank = 1,
        Cooldown = 3
    }
}

-- Function to register all commands in this module
function PlayerCommands.Register(commandManager)
    Utils = require(script.Parent.Parent.Utils)
    
    -- Register all commands
    commandManager:RegisterCommand(
        CommandDefinitions.heal.Name,
        CommandDefinitions.heal.Description,
        function(player, args) return PlayerCommands.ExecuteHeal(commandManager, player, args) end,
        CommandDefinitions.heal.Rank,
        CommandDefinitions.heal.Usage,
        CommandDefinitions.heal.Cooldown
    )
    
    commandManager:RegisterCommand(
        CommandDefinitions.kill.Name,
        CommandDefinitions.kill.Description,
        function(player, args) return PlayerCommands.ExecuteKill(commandManager, player, args) end,
        CommandDefinitions.kill.Rank,
        CommandDefinitions.kill.Usage,
        CommandDefinitions.kill.Cooldown
    )
    
    commandManager:RegisterCommand(
        CommandDefinitions.respawn.Name,
        CommandDefinitions.respawn.Description,
        function(player, args) return PlayerCommands.ExecuteRespawn(commandManager, player, args) end,
        CommandDefinitions.respawn.Rank,
        CommandDefinitions.respawn.Usage,
        CommandDefinitions.respawn.Cooldown
    )
    
    commandManager:RegisterCommand(
        CommandDefinitions.speed.Name,
        CommandDefinitions.speed.Description,
        function(player, args) return PlayerCommands.ExecuteSpeed(commandManager, player, args) end,
        CommandDefinitions.speed.Rank,
        CommandDefinitions.speed.Usage,
        CommandDefinitions.speed.Cooldown
    )
    
    commandManager:RegisterCommand(
        CommandDefinitions.jump.Name,
        CommandDefinitions.jump.Description,
        function(player, args) return PlayerCommands.ExecuteJump(commandManager, player, args) end,
        CommandDefinitions.jump.Rank,
        CommandDefinitions.jump.Usage,
        CommandDefinitions.jump.Cooldown
    )
    
    commandManager:RegisterCommand(
        CommandDefinitions.tp.Name,
        CommandDefinitions.tp.Description,
        function(player, args) return PlayerCommands.ExecuteTeleport(commandManager, player, args) end,
        CommandDefinitions.tp.Rank,
        CommandDefinitions.tp.Usage,
        CommandDefinitions.tp.Cooldown
    )
    
    commandManager:RegisterCommand(
        CommandDefinitions.bring.Name,
        CommandDefinitions.bring.Description,
        function(player, args) return PlayerCommands.ExecuteBring(commandManager, player, args) end,
        CommandDefinitions.bring.Rank,
        CommandDefinitions.bring.Usage,
        CommandDefinitions.bring.Cooldown
    )
end

-- Check if player has permission to modify target player
function PlayerCommands.CanModifyPlayer(commandManager, player, targetPlayer)
    local permissionManager = commandManager.Core.PermissionManager
    
    local playerRank = permissionManager:GetPlayerRank(player)
    local targetRank = permissionManager:GetPlayerRank(targetPlayer)
    
    if targetRank >= playerRank and player ~= targetPlayer then
        return false, "Cannot modify a player with equal or higher rank"
    end
    
    return true
end

-- Helper function to get target player from args
function PlayerCommands.GetTargetPlayer(player, args)
    if #args == 0 then
        return player  -- Default to self if no player specified
    end
    
    local targetPlayer = Utils.getPlayerByName(args[1])
    if not targetPlayer then
        return nil, "Player not found: " .. args[1]
    end
    
    return targetPlayer
end

-- Execute heal command
function PlayerCommands.ExecuteHeal(commandManager, player, args)
    local targetPlayer, errorMsg = PlayerCommands.GetTargetPlayer(player, args)
    
    if not targetPlayer then
        return false, errorMsg
    end
    
    -- Check permission
    local canModify, reason = PlayerCommands.CanModifyPlayer(commandManager, player, targetPlayer)
    if not canModify then
        return false, reason
    end
    
    -- Try to heal the player
    local character = targetPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") then
        return false, "Could not heal player (character not loaded)"
    end
    
    local humanoid = character.Humanoid
    humanoid.Health = humanoid.MaxHealth
    
    -- Notify players
    local message
    if targetPlayer == player then
        message = "You have healed yourself"
    else
        Utils.sendNotification(commandManager.Core.NotificationEvent, targetPlayer, 
            "You have been healed by " .. player.Name, false)
        message = "You have healed " .. targetPlayer.Name
    end
    
    Utils.log(player.Name .. " healed " .. targetPlayer.Name, "Info")
    return true, message
end

-- Execute kill command
function PlayerCommands.ExecuteKill(commandManager, player, args)
    if #args < 1 then
        return false, "Usage: " .. CommandDefinitions.kill.Usage
    end
    
    local targetPlayer = Utils.getPlayerByName(args[1])
    if not targetPlayer then
        return false, "Player not found: " .. args[1]
    end
    
    -- Check permission
    local canModify, reason = PlayerCommands.CanModifyPlayer(commandManager, player, targetPlayer)
    if not canModify then
        return false, reason
    end
    
    -- Try to kill the player
    local character = targetPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") then
        return false, "Could not kill player (character not loaded)"
    end
    
    character.Humanoid.Health = 0
    
    -- Notify players
    if targetPlayer ~= player then
        Utils.sendNotification(commandManager.Core.NotificationEvent, targetPlayer, 
            "You were killed by " .. player.Name, false)
    end
    
    Utils.log(player.Name .. " killed " .. targetPlayer.Name, "Info")
    return true, "Successfully killed " .. targetPlayer.Name
end

-- Execute respawn command
function PlayerCommands.ExecuteRespawn(commandManager, player, args)
    local targetPlayer, errorMsg = PlayerCommands.GetTargetPlayer(player, args)
    
    if not targetPlayer then
        return false, errorMsg
    end
    
    -- Check permission
    local canModify, reason = PlayerCommands.CanModifyPlayer(commandManager, player, targetPlayer)
    if not canModify then
        return false, reason
    end
    
    -- Respawn the player
    targetPlayer:LoadCharacter()
    
    -- Notify players
    local message
    if targetPlayer == player then
        message = "You have respawned yourself"
    else
        Utils.sendNotification(commandManager.Core.NotificationEvent, targetPlayer, 
            "You were respawned by " .. player.Name, false)
        message = "You have respawned " .. targetPlayer.Name
    end
    
    Utils.log(player.Name .. " respawned " .. targetPlayer.Name, "Info")
    return true, message
end

-- Execute speed command
function PlayerCommands.ExecuteSpeed(commandManager, player, args)
    local targetPlayer
    local speed
    
    -- Parse args
    if #args == 0 then
        return false, "Usage: " .. CommandDefinitions.speed.Usage
    elseif #args == 1 then
        -- !speed [value] - Set own speed
        targetPlayer = player
        speed = tonumber(args[1])
    else
        -- !speed [player] [value] - Set other player's speed
        targetPlayer = Utils.getPlayerByName(args[1])
        speed = tonumber(args[2])
    end
    
    if not targetPlayer then
        return false, "Player not found"
    end
    
    if not speed or speed < 0 then
        return false, "Invalid speed value. Please provide a positive number."
    end
    
    -- Check permission
    local canModify, reason = PlayerCommands.CanModifyPlayer(commandManager, player, targetPlayer)
    if not canModify then
        return false, reason
    end
    
    -- Try to set speed
    local character = targetPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") then
        return false, "Could not set speed (character not loaded)"
    end
    
    character.Humanoid.WalkSpeed = speed
    
    -- Notify players
    local message
    if targetPlayer == player then
        message = "Your speed has been set to " .. speed
    else
        Utils.sendNotification(commandManager.Core.NotificationEvent, targetPlayer, 
            "Your speed was set to " .. speed .. " by " .. player.Name, false)
        message = "Set " .. targetPlayer.Name .. "'s speed to " .. speed
    end
    
    Utils.log(player.Name .. " set " .. targetPlayer.Name .. "'s speed to " .. speed, "Info")
    return true, message
end

-- Execute jump command
function PlayerCommands.ExecuteJump(commandManager, player, args)
    local targetPlayer
    local jumpPower
    
    -- Parse args
    if #args == 0 then
        return false, "Usage: " .. CommandDefinitions.jump.Usage
    elseif #args == 1 then
        -- !jump [value] - Set own jump power
        targetPlayer = player
        jumpPower = tonumber(args[1])
    else
        -- !jump [player] [value] - Set other player's jump power
        targetPlayer = Utils.getPlayerByName(args[1])
        jumpPower = tonumber(args[2])
    end
    
    if not targetPlayer then
        return false, "Player not found"
    end
    
    if not jumpPower or jumpPower < 0 then
        return false, "Invalid jump power value. Please provide a positive number."
    end
    
    -- Check permission
    local canModify, reason = PlayerCommands.CanModifyPlayer(commandManager, player, targetPlayer)
    if not canModify then
        return false, reason
    end
    
    -- Try to set jump power
    local character = targetPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") then
        return false, "Could not set jump power (character not loaded)"
    end
    
    character.Humanoid.JumpPower = jumpPower
    
    -- Notify players
    local message
    if targetPlayer == player then
        message = "Your jump power has been set to " .. jumpPower
    else
        Utils.sendNotification(commandManager.Core.NotificationEvent, targetPlayer, 
            "Your jump power was set to " .. jumpPower .. " by " .. player.Name, false)
        message = "Set " .. targetPlayer.Name .. "'s jump power to " .. jumpPower
    end
    
    Utils.log(player.Name .. " set " .. targetPlayer.Name .. "'s jump power to " .. jumpPower, "Info")
    return true, message
end

-- Execute teleport command
function PlayerCommands.ExecuteTeleport(commandManager, player, args)
    if #args < 2 then
        return false, "Usage: " .. CommandDefinitions.tp.Usage
    end
    
    local targetPlayer = Utils.getPlayerByName(args[1])
    if not targetPlayer then
        return false, "Player not found: " .. args[1]
    end
    
    local destinationPlayer = Utils.getPlayerByName(args[2])
    if not destinationPlayer then
        return false, "Destination player not found: " .. args[2]
    end
    
    -- Check permission to teleport the target
    local canModify, reason = PlayerCommands.CanModifyPlayer(commandManager, player, targetPlayer)
    if not canModify then
        return false, reason
    end
    
    -- Try to teleport
    local targetCharacter = targetPlayer.Character
    local destCharacter = destinationPlayer.Character
    
    if not targetCharacter or not destCharacter then
        return false, "Could not teleport (character not loaded)"
    end
    
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local destRoot = destCharacter:FindFirstChild("HumanoidRootPart")
    
    if not targetRoot or not destRoot then
        return false, "Could not teleport (HumanoidRootPart not found)"
    end
    
    -- Teleport with offset to avoid overlapping
    targetRoot.CFrame = destRoot.CFrame * CFrame.new(0, 0, 3)
    
    -- Notify players
    if targetPlayer ~= player then
        Utils.sendNotification(commandManager.Core.NotificationEvent, targetPlayer, 
            "You were teleported to " .. destinationPlayer.Name .. " by " .. player.Name, false)
    end
    
    Utils.log(player.Name .. " teleported " .. targetPlayer.Name .. " to " .. destinationPlayer.Name, "Info")
    return true, "Successfully teleported " .. targetPlayer.Name .. " to " .. destinationPlayer.Name
end

-- Execute bring command
function PlayerCommands.ExecuteBring(commandManager, player, args)
    if #args < 1 then
        return false, "Usage: " .. CommandDefinitions.bring.Usage
    end
    
    local targetPlayer = Utils.getPlayerByName(args[1])
    if not targetPlayer then
        return false, "Player not found: " .. args[1]
    end
    
    -- Check permission
    local canModify, reason = PlayerCommands.CanModifyPlayer(commandManager, player, targetPlayer)
    if not canModify then
        return false, reason
    end
    
    -- Try to teleport
    local targetCharacter = targetPlayer.Character
    local playerCharacter = player.Character
    
    if not targetCharacter or not playerCharacter then
        return false, "Could not bring player (character not loaded)"
    end
    
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local playerRoot = playerCharacter:FindFirstChild("HumanoidRootPart")
    
    if not targetRoot or not playerRoot then
        return false, "Could not bring player (HumanoidRootPart not found)"
    end
    
    -- Teleport with offset to avoid overlapping
    targetRoot.CFrame = playerRoot.CFrame * CFrame.new(0, 0, 3)
    
    -- Notify players
    Utils.sendNotification(commandManager.Core.NotificationEvent, targetPlayer, 
        "You were brought to " .. player.Name, false)
    
    Utils.log(player.Name .. " brought " .. targetPlayer.Name, "Info")
    return true, "Successfully brought " .. targetPlayer.Name .. " to you"
end

return PlayerCommands