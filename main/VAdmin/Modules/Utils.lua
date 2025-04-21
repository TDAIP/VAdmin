--[[
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

return Utils