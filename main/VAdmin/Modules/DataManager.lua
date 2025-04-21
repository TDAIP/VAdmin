--[[
    VAdmin DataManager Module
    Handles all DataStore operations with retry and validation
]]

local DataManager = {}
DataManager.__index = DataManager

-- Services
local DataStoreService = game:GetService("DataStoreService")

-- Import Utils
local Utils = require(script.Parent.Utils)

function DataManager.new(core)
    local self = setmetatable({}, DataManager)
    self.Core = core
    self.Enabled = false
    self.BanStore = nil
    self.RetryCount = 5
    self.InitialBackoff = 1
    self.CacheTime = 600 -- Cache data for 10 minutes before refreshing
    self.LastCacheTime = 0
    return self
end

function DataManager:Initialize()
    local success, result = Utils.retryWithBackoff(function()
        Utils.log("Initializing DataStore: VAdminBans", "Debug")
        return DataStoreService:GetDataStore("VAdminBans")
    end, self.RetryCount, self.InitialBackoff)
    
    if success then
        self.BanStore = result
        self.Enabled = true
        Utils.log("DataStore initialized successfully", "Info")
        
        -- Load banned users
        self:LoadBannedUsers()
    else
        Utils.log("DataStore initialization failed: " .. tostring(result), "Error")
    end
    
    return self.Enabled
end

function DataManager:LoadBannedUsers()
    if not self.Enabled or not self.BanStore then
        return false
    end
    
    -- Check if we need to refresh cache
    local currentTime = os.time()
    if currentTime - self.LastCacheTime < self.CacheTime and self.LastCacheTime > 0 then
        Utils.log("Using cached ban data", "Debug")
        return true
    end
    
    local success, result = Utils.retryWithBackoff(function()
        Utils.log("Loading banned users from DataStore", "Debug")
        return self.BanStore:GetAsync("BannedUsers")
    end, self.RetryCount, self.InitialBackoff)
    
    if success then
        if result and type(result) == "table" then
            self.Core.BannedUsers = result
            self.LastCacheTime = currentTime
            Utils.log("Loaded " .. self:CountBannedUsers() .. " banned users", "Info")
            return true
        else
            Utils.log("Banned users data is not a table or is nil, initializing empty table", "Warning")
            self.Core.BannedUsers = {}
            self.LastCacheTime = currentTime
            return true
        end
    else
        Utils.log("Failed to load banned users: " .. tostring(result), "Error")
        return false
    end
end

function DataManager:SaveBannedUsers()
    if not self.Enabled or not self.BanStore then
        return false
    end
    
    local success, result = Utils.retryWithBackoff(function()
        Utils.log("Saving banned users to DataStore", "Debug")
        return self.BanStore:SetAsync("BannedUsers", self.Core.BannedUsers)
    end, self.RetryCount, self.InitialBackoff)
    
    if success then
        self.LastCacheTime = os.time()
        Utils.log("Saved " .. self:CountBannedUsers() .. " banned users", "Info")
        return true
    else
        Utils.log("Failed to save banned users: " .. tostring(result), "Error")
        return false
    end
end

function DataManager:CountBannedUsers()
    local count = 0
    for _ in pairs(self.Core.BannedUsers) do
        count = count + 1
    end
    return count
end

function DataManager:BanUser(userId, name, reason, banner)
    if not self.Enabled then
        return false
    end
    
    self.Core.BannedUsers[tostring(userId)] = {
        name = name,
        reason = reason,
        banner = banner,
        timestamp = os.time()
    }
    
    return self:SaveBannedUsers()
end

function DataManager:UnbanUser(userId)
    if not self.Enabled then
        return false
    end
    
    if not self.Core.BannedUsers[tostring(userId)] then
        return false
    end
    
    self.Core.BannedUsers[tostring(userId)] = nil
    return self:SaveBannedUsers()
end

function DataManager:IsBanned(userId)
    if not self.Core.BannedUsers[tostring(userId)] then
        return false
    end
    
    return true, self.Core.BannedUsers[tostring(userId)].reason
end

return DataManager