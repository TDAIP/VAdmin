--[[
    VAdmin - A Simple Admin System for Roblox
    Version: 1.0.0
    
    Author: VAdmin
    
    Description:
    A powerful yet simple administrative script for Roblox games. 
    Includes moderation tools and command execution.
    
    Default admin is the game creator (rank 4).
    
    Admin Ranks:
    0 - Regular player
    1 - Moderator
    2 - Admin
    3 - Super Admin
    4 - Game Owner
]]

-- Mock Roblox environment for testing outside of Roblox
local isTestEnvironment = not pcall(function() return game:GetService("Players") end)
local game, Instance, CFrame, Enum, task

-- Define warn function if it doesn't exist
if not warn then
    warn = function(...)
        print("WARNING:", ...)
    end
end

if isTestEnvironment then
    -- Create mock classes
    CFrame = {
        new = function(x, y, z)
            return {
                x = x or 0,
                y = y or 0,
                z = z or 0,
                
                -- Operator for CFrame * CFrame
                __mul = function(self, other)
                    return {
                        CFrame = {
                            x = self.x + other.x,
                            y = self.y + other.y,
                            z = self.z + other.z
                        }
                    }
                end
            }
        end
    }
    
    Enum = {
        CreatorType = {
            User = "User",
            Group = "Group"
        }
    }
    
    task = {
        wait = function(seconds)
            -- No actual wait in test environment
        end,
        spawn = function(func, ...)
            func(...)
        end
    }
    
    -- Create mock services
    local Services = {}
    
    -- Players service
    Services.Players = {
        GetPlayers = function()
            return {}
        end,
        PlayerAdded = {
            Connect = function(self, func)
                return {
                    Disconnect = function() end
                }
            end
        }
    }
    
    -- DataStoreService
    Services.DataStoreService = {
        GetDataStore = function(self, name)
            print("Getting DataStore: " .. name)
            return {
                GetAsync = function(self, key)
                    print("DataStore GetAsync: " .. key)
                    return {}
                end,
                SetAsync = function(self, key, value)
                    return true
                end
            }
        end
    }
    
    -- GroupService
    Services.GroupService = {
        GetGroupInfoAsync = function(self, groupId)
            return {
                Owner = {
                    Id = 1234567
                }
            }
        end
    }
    
    -- Lighting
    Services.Lighting = {
        ClockTime = 12
    }
    
    local mockEvents = {}
    local MockEvent = {
        Connect = function(self, func)
            table.insert(mockEvents, func)
            return {
                Disconnect = function() end
            }
        end
    }
    
    -- Setup mock game service
    game = {
        CreatorType = Enum.CreatorType.User,
        CreatorId = 1234567,
        
        GetService = function(self, serviceName)
            print("GetService: " .. serviceName .. " (mock)")
            if Services[serviceName] then
                return Services[serviceName]
            else
                return {
                    -- Default mock methods for unknown services
                }
            end
        end
    }
    
    -- Setup mock Instance
    Instance = {
        new = function(className)
            local instance = {
                Name = "",
                Parent = nil,
                ClassName = className,
                Children = {},
                Properties = {},
                
                FindFirstChild = function(self, name)
                    for _, child in pairs(self.Children) do
                        if child.Name == name then
                            return child
                        end
                    end
                    return nil
                end
            }
            
            if className == "RemoteEvent" then
                instance.OnServerEvent = MockEvent
                instance.FireClient = function(self, player, ...)
                    print("FireClient called for " .. self.Name .. " to player " .. player.Name .. " with args: " .. tostring(...))
                end
            end
            
            return instance
        end
    }
end

local VAdmin = {
    Version = "1.0.0",
    Ranks = {
        [0] = "Player",
        [1] = "Moderator",
        [2] = "Admin",
        [3] = "Super Admin",
        [4] = "Game Owner"
    },
    Commands = {},
    Admins = {},
    BannedUsers = {},
    DataStoreEnabled = false
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Setup Remote Events
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "VAdmin"
remoteFolder.Parent = ReplicatedStorage

local commandEvent = Instance.new("RemoteEvent")
commandEvent.Name = "CommandEvent"
commandEvent.Parent = remoteFolder

local notificationEvent = Instance.new("RemoteEvent")
notificationEvent.Name = "NotificationEvent"
notificationEvent.Parent = remoteFolder

-- Setup DataStore
local banStore
local function setupDataStore()
    local success, result = pcall(function()
        print("Getting DataStore: VAdminBans")
        return DataStoreService:GetDataStore("VAdminBans")
    end)
    
    if success then
        banStore = result
        VAdmin.DataStoreEnabled = true
        
        -- Load banned users
        local success, result = pcall(function()
            print("DataStore GetAsync: BannedUsers")
            return banStore:GetAsync("BannedUsers")
        end)
        
        if success and result then
            VAdmin.BannedUsers = result
        end
    else
        warn("DataStore not available: " .. tostring(result))
    end
end

-- Utility Functions
local function getPlayerByName(name)
    name = string.lower(name)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.sub(string.lower(player.Name), 1, #name) == name then
            return player
        end
    end
    return nil
end

local function sendNotification(player, message)
    notificationEvent:FireClient(player, message)
end

local function getRankName(rank)
    return VAdmin.Ranks[rank] or "Unknown"
end

local function getPlayerRank(player)
    local userId = player.UserId
    
    -- Check if player is the game creator
    if game.CreatorType == Enum.CreatorType.User then
        if userId == game.CreatorId then
            return 4 -- Game Owner
        end
    elseif game.CreatorType == Enum.CreatorType.Group then
        local groupService = game:GetService("GroupService")
        local success, result = pcall(function()
            return groupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
        end)
        if success and result == userId then
            return 4 -- Game Owner
        end
    end
    
    -- Check admin list
    if VAdmin.Admins[userId] then
        return VAdmin.Admins[userId]
    end
    
    return 0 -- Regular player
end

local function canUseCommand(player, requiredRank)
    local playerRank = getPlayerRank(player)
    return playerRank >= requiredRank
end

local function isBanned(userId)
    if VAdmin.BannedUsers[tostring(userId)] then
        return true, VAdmin.BannedUsers[tostring(userId)].reason
    end
    return false
end

-- Command Registration
function VAdmin:RegisterCommand(name, description, func, requiredRank)
    self.Commands[name] = {
        Name = name,
        Description = description,
        Function = func,
        Rank = requiredRank or 0
    }
end

-- Default Commands
local function registerDefaultCommands()
    -- Help Command
    VAdmin:RegisterCommand("help", "Shows all available commands", function(player, args)
        local playerRank = getPlayerRank(player)
        local helpMessage = "Available Commands:\n"
        
        for name, command in pairs(VAdmin.Commands) do
            if playerRank >= command.Rank then
                helpMessage = helpMessage .. "!" .. name .. " - " .. command.Description .. " (Rank: " .. command.Rank .. ")\n"
            end
        end
        
        sendNotification(player, helpMessage)
        return true
    end, 0)

    -- Kick Command
    VAdmin:RegisterCommand("kick", "Kicks a player from the game", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !kick [player] [reason]")
            return false
        end
        
        local targetPlayer = getPlayerByName(args[1])
        if not targetPlayer then
            sendNotification(player, "Player not found")
            return false
        end
        
        local reason = "No reason provided"
        if #args > 1 then
            reason = table.concat(args, " ", 2)
        end
        
        print("Player " .. targetPlayer.Name .. " was kicked: Kicked by " .. player.Name .. ": " .. reason)
        targetPlayer:Kick("Kicked by " .. player.Name .. ": " .. reason)
        return true
    end, 1)
    
    -- Ban Command
    VAdmin:RegisterCommand("ban", "Bans a player from the game", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !ban [player] [reason]")
            return false
        end
        
        local targetPlayer = getPlayerByName(args[1])
        if not targetPlayer then
            sendNotification(player, "Player not found")
            return false
        end
        
        local reason = "No reason provided"
        if #args > 1 then
            reason = table.concat(args, " ", 2)
        end
        
        local userId = targetPlayer.UserId
        VAdmin.BannedUsers[tostring(userId)] = {
            name = targetPlayer.Name,
            reason = reason,
            banner = player.Name,
            timestamp = os.time()
        }
        
        -- Save to DataStore if available
        if VAdmin.DataStoreEnabled then
            pcall(function()
                banStore:SetAsync("BannedUsers", VAdmin.BannedUsers)
            end)
        end
        
        print("Player " .. targetPlayer.Name .. " was banned: Banned by " .. player.Name .. ": " .. reason)
        targetPlayer:Kick("Banned by " .. player.Name .. ": " .. reason)
        return true
    end, 2)
    
    -- Unban Command
    VAdmin:RegisterCommand("unban", "Unbans a player from the game", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !unban [userId]")
            return false
        end
        
        local userId = tonumber(args[1])
        if not userId then
            sendNotification(player, "Invalid user ID")
            return false
        end
        
        if not VAdmin.BannedUsers[tostring(userId)] then
            sendNotification(player, "Player is not banned")
            return false
        end
        
        VAdmin.BannedUsers[tostring(userId)] = nil
        
        -- Save to DataStore if available
        if VAdmin.DataStoreEnabled then
            pcall(function()
                banStore:SetAsync("BannedUsers", VAdmin.BannedUsers)
            end)
        end
        
        sendNotification(player, "Player has been unbanned")
        return true
    end, 2)

    -- Set Rank Command
    VAdmin:RegisterCommand("setrank", "Sets a player's admin rank", function(player, args)
        if #args < 2 then
            sendNotification(player, "Usage: !setrank [player] [rank]")
            return false
        end
        
        local targetPlayer = getPlayerByName(args[1])
        if not targetPlayer then
            sendNotification(player, "Player not found")
            return false
        end
        
        local rank = tonumber(args[2])
        if not rank or rank < 0 or rank > 4 then
            sendNotification(player, "Invalid rank (0-4)")
            return false
        end
        
        local targetUserId = targetPlayer.UserId
        local playerRank = getPlayerRank(player)
        
        -- Cannot promote to a rank higher than your own
        if rank > playerRank then
            sendNotification(player, "Cannot promote to a rank higher than your own")
            return false
        end
        
        -- Cannot modify rank of someone with equal or higher rank
        local targetRank = getPlayerRank(targetPlayer)
        if targetRank >= playerRank and targetRank > 0 then
            sendNotification(player, "Cannot modify rank of someone with equal or higher rank")
            return false
        end
        
        VAdmin.Admins[targetUserId] = rank
        sendNotification(player, targetPlayer.Name .. " is now " .. getRankName(rank))
        sendNotification(targetPlayer, "You are now " .. getRankName(rank))
        return true
    end, 3)
    
    -- Kill Command
    VAdmin:RegisterCommand("kill", "Kills a player", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !kill [player]")
            return false
        end
        
        local targetPlayer = getPlayerByName(args[1])
        if not targetPlayer then
            sendNotification(player, "Player not found")
            return false
        end
        
        local character = targetPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.Health = 0
            sendNotification(player, targetPlayer.Name .. " has been killed")
            return true
        else
            sendNotification(player, "Could not kill player")
            return false
        end
    end, 2)

    -- Heal Command
    VAdmin:RegisterCommand("heal", "Heals a player to full health", function(player, args)
        local targetPlayer
        
        if #args < 1 then
            targetPlayer = player
        else
            targetPlayer = getPlayerByName(args[1])
            if not targetPlayer then
                sendNotification(player, "Player not found")
                return false
            end
        end
        
        local character = targetPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.Health = character.Humanoid.MaxHealth
            sendNotification(player, targetPlayer.Name .. " has been healed")
            if targetPlayer ~= player then
                sendNotification(targetPlayer, "You have been healed by " .. player.Name)
            end
            return true
        else
            sendNotification(player, "Could not heal player")
            return false
        end
    end, 1)
    
    -- Respawn Command
    VAdmin:RegisterCommand("respawn", "Respawns a player", function(player, args)
        local targetPlayer
        
        if #args < 1 then
            targetPlayer = player
        else
            targetPlayer = getPlayerByName(args[1])
            if not targetPlayer then
                sendNotification(player, "Player not found")
                return false
            end
        end
        
        targetPlayer:LoadCharacter()
        sendNotification(player, targetPlayer.Name .. " has been respawned")
        if targetPlayer ~= player then
            sendNotification(targetPlayer, "You have been respawned by " .. player.Name)
        end
        return true
    end, 1)
    
    -- Speed Command
    VAdmin:RegisterCommand("speed", "Sets a player's walkspeed", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !speed [player/speed] [speed]")
            return false
        end
        
        local targetPlayer
        local speed
        
        if #args == 1 then
            targetPlayer = player
            speed = tonumber(args[1])
        else
            targetPlayer = getPlayerByName(args[1])
            speed = tonumber(args[2])
        end
        
        if not targetPlayer then
            sendNotification(player, "Player not found")
            return false
        end
        
        if not speed or speed < 0 then
            sendNotification(player, "Invalid speed")
            return false
        end
        
        local character = targetPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = speed
            sendNotification(player, targetPlayer.Name .. "'s speed set to " .. speed)
            if targetPlayer ~= player then
                sendNotification(targetPlayer, "Your speed was set to " .. speed .. " by " .. player.Name)
            end
            return true
        else
            sendNotification(player, "Could not set player speed")
            return false
        end
    end, 1)
    
    -- Jump Command
    VAdmin:RegisterCommand("jump", "Sets a player's jump power", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !jump [player/power] [power]")
            return false
        end
        
        local targetPlayer
        local power
        
        if #args == 1 then
            targetPlayer = player
            power = tonumber(args[1])
        else
            targetPlayer = getPlayerByName(args[1])
            power = tonumber(args[2])
        end
        
        if not targetPlayer then
            sendNotification(player, "Player not found")
            return false
        end
        
        if not power or power < 0 then
            sendNotification(player, "Invalid jump power")
            return false
        end
        
        local character = targetPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = power
            sendNotification(player, targetPlayer.Name .. "'s jump power set to " .. power)
            if targetPlayer ~= player then
                sendNotification(targetPlayer, "Your jump power was set to " .. power .. " by " .. player.Name)
            end
            return true
        else
            sendNotification(player, "Could not set player jump power")
            return false
        end
    end, 1)
    
    -- Teleport Command
    VAdmin:RegisterCommand("tp", "Teleports a player to another player", function(player, args)
        if #args < 2 then
            sendNotification(player, "Usage: !tp [player] [destination]")
            return false
        end
        
        local targetPlayer = getPlayerByName(args[1])
        if not targetPlayer then
            sendNotification(player, "Player not found")
            return false
        end
        
        local destinationPlayer = getPlayerByName(args[2])
        if not destinationPlayer then
            sendNotification(player, "Destination player not found")
            return false
        end
        
        local targetCharacter = targetPlayer.Character
        local destinationCharacter = destinationPlayer.Character
        
        if targetCharacter and destinationCharacter then
            local humanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
            local destHumanoidRootPart = destinationCharacter:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart and destHumanoidRootPart then
                humanoidRootPart.CFrame = destHumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                sendNotification(player, "Teleported " .. targetPlayer.Name .. " to " .. destinationPlayer.Name)
                if targetPlayer ~= player then
                    sendNotification(targetPlayer, "You were teleported to " .. destinationPlayer.Name .. " by " .. player.Name)
                end
                return true
            end
        end
        
        sendNotification(player, "Could not teleport player")
        return false
    end, 1)
    
    -- Bring Command
    VAdmin:RegisterCommand("bring", "Brings a player to you", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !bring [player]")
            return false
        end
        
        local targetPlayer = getPlayerByName(args[1])
        if not targetPlayer then
            sendNotification(player, "Player not found")
            return false
        end
        
        local targetCharacter = targetPlayer.Character
        local playerCharacter = player.Character
        
        if targetCharacter and playerCharacter then
            local humanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
            local playerHumanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart and playerHumanoidRootPart then
                humanoidRootPart.CFrame = playerHumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                sendNotification(player, "Brought " .. targetPlayer.Name .. " to you")
                sendNotification(targetPlayer, "You were brought to " .. player.Name)
                return true
            end
        end
        
        sendNotification(player, "Could not bring player")
        return false
    end, 1)
    
    -- Message Command
    VAdmin:RegisterCommand("message", "Sends a message to all players", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !message [text]")
            return false
        end
        
        local message = table.concat(args, " ")
        
        for _, p in ipairs(Players:GetPlayers()) do
            sendNotification(p, "[ANNOUNCEMENT] " .. player.Name .. ": " .. message)
        end
        
        return true
    end, 2)
    
    -- Time Command
    VAdmin:RegisterCommand("time", "Sets the time of day", function(player, args)
        if #args < 1 then
            sendNotification(player, "Usage: !time [hour] (0-24)")
            return false
        end
        
        local hour = tonumber(args[1])
        if not hour or hour < 0 or hour > 24 then
            sendNotification(player, "Invalid time (0-24)")
            return false
        end
        
        local lighting = game:GetService("Lighting")
        lighting.ClockTime = hour
        
        sendNotification(player, "Time set to " .. hour .. ":00")
        return true
    end, 2)
    
    -- Shutdown Command
    VAdmin:RegisterCommand("shutdown", "Shuts down the server", function(player, args)
        local reason = "Server shutdown by " .. player.Name
        if #args > 0 then
            reason = reason .. ": " .. table.concat(args, " ")
        end
        
        for _, p in ipairs(Players:GetPlayers()) do
            sendNotification(p, "SERVER SHUTDOWN: " .. reason)
            task.wait(1)
            p:Kick(reason)
        end
        
        return true
    end, 4)
end

-- Command Handler
local function handleCommand(player, message)
    if string.sub(message, 1, 1) ~= "!" then
        return
    end
    
    local commandText = string.sub(message, 2)
    local args = {}
    
    for arg in string.gmatch(commandText, "%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 then
        return
    end
    
    local commandName = string.lower(args[1])
    table.remove(args, 1)
    
    local command = VAdmin.Commands[commandName]
    if not command then
        sendNotification(player, "Unknown command: " .. commandName)
        return
    end
    
    if not canUseCommand(player, command.Rank) then
        sendNotification(player, "You don't have permission to use this command")
        return
    end
    
    local success = command.Function(player, args)
    sendNotification(player, success)
end

-- Command Event Handler
commandEvent.OnServerEvent:Connect(function(player, command)
    handleCommand(player, command)
end)

-- Player Join Handler
local function onPlayerJoin(player)
    local userId = player.UserId
    
    -- Check if player is banned
    local banned, reason = isBanned(userId)
    if banned then
        player:Kick("You are banned: " .. reason)
        return
    end
    
    -- Set admin if player is the owner
    if game.CreatorType == Enum.CreatorType.User then
        if userId == game.CreatorId then
            VAdmin.Admins[userId] = 4 -- Game Owner
        end
    elseif game.CreatorType == Enum.CreatorType.Group then
        local groupService = game:GetService("GroupService")
        local success, result = pcall(function()
            return groupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
        end)
        if success and result == userId then
            VAdmin.Admins[userId] = 4 -- Game Owner
        end
    end
    
    -- Let the player know their admin status
    local rank = getPlayerRank(player)
    if rank > 0 then
        task.wait(1)  -- Wait for character to load
        sendNotification(player, "You are an admin with rank: " .. getRankName(rank))
    end
end

-- Initialize VAdmin
function VAdmin:Initialize()
    print("VAdmin v" .. self.Version .. " initializing...")
    
    -- Set up DataStore
    setupDataStore()
    
    -- Register default commands
    registerDefaultCommands()
    
    -- Connect to player events
    Players.PlayerAdded:Connect(onPlayerJoin)
    print("Connected to PlayerAdded event")
    
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            onPlayerJoin(player)
        end)
    end
    
    print("Connected to PlayerAdded event")
    
    -- Connect to command event
    commandEvent.OnServerEvent:Connect(function(player, command)
        handleCommand(player, command)
    end)
    print("Connected server event for CommandEvent")
    
    print("VAdmin initialized successfully!")
    return self
end

-- Create test code
local function TestVAdmin()
    print("VAdmin Demo - Beginning Test")
    
    print("Loading VAdmin module...")
    VAdmin:Initialize()
    
    print("--- Testing Commands ---")
    
    -- Create test players
    local testUser = {
        Name = "TestUser",
        UserId = 123456,
        Character = {
            Humanoid = {
                Health = 100,
                MaxHealth = 100,
                WalkSpeed = 16,
                JumpPower = 50
            },
            HumanoidRootPart = {
                CFrame = CFrame.new(0, 10, 0)
            },
            FindFirstChild = function(self, name)
                if name == "Humanoid" then
                    return self.Humanoid
                elseif name == "HumanoidRootPart" then
                    return self.HumanoidRootPart
                end
                return nil
            end
        },
        LoadCharacter = function() 
            print("LoadCharacter called for TestUser")
        end
    }
    
    local testUser2 = {
        Name = "TestUser2",
        UserId = 789012,
        Character = {
            Humanoid = {
                Health = 100,
                MaxHealth = 100,
                WalkSpeed = 16,
                JumpPower = 50
            },
            HumanoidRootPart = {
                CFrame = CFrame.new(0, 10, 0)
            },
            FindFirstChild = function(self, name)
                if name == "Humanoid" then
                    return self.Humanoid
                elseif name == "HumanoidRootPart" then
                    return self.HumanoidRootPart
                end
                return nil
            end
        },
        LoadCharacter = function() 
            print("LoadCharacter called for TestUser2")
        end
    }
    
    -- Override the getPlayerByName function for testing
    getPlayerByName = function(name)
        if string.lower(name) == "testuser" or string.lower(name) == "test" then
            return testUser
        elseif string.lower(name) == "testuser2" or string.lower(name) == "test2" then
            return testUser2
        end
        return nil
    end
    
    -- Mock Functions
    notificationEvent.FireClient = function(_, player, message)
        print("FireClient called for NotificationEvent to player " .. player.Name .. " with args: " .. tostring(message))
    end
    
    testUser.Kick = function(self, reason)
        print("Player " .. self.Name .. " was kicked: " .. reason)
    end
    
    testUser2.Kick = function(self, reason)
        print("Player " .. self.Name .. " was kicked: " .. reason)
    end
    
    -- Testing regular player commands
    print("Test: Player sending command '!help'")
    handleCommand(testUser, "!help")
    
    print("Admin List:")
    
    -- Make the test user an admin with rank 4 (Owner)
    print("Making test player an admin (rank 4)...")
    VAdmin.Admins[testUser.UserId] = 4
    
    -- Test admin commands
    print("Test: Admin sending command '!help'")
    handleCommand(testUser, "!help")
    
    -- Test kick command
    print("Test: Admin sending command '!kick TestUser2 Testing kick command'")
    handleCommand(testUser, "!kick TestUser2 Testing kick command")
    
    print("VAdmin Demo Test Completed!")
end

return {
    VAdmin = VAdmin,
    TestVAdmin = TestVAdmin
}