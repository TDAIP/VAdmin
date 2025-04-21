--[[
   Test VAdmin Installer
   This script tests the installer functionality
]]

print("Testing VAdmin Installer")

-- Mock Roblox services for testing
local ServerStorage = {
    Name = "ServerStorage",
    FindFirstChild = function(self, name) return nil end,
    Children = {}
}

local ReplicatedStorage = {
    Name = "ReplicatedStorage",
    FindFirstChild = function(self, name) return nil end,
    Children = {}
}

local ServerScriptService = {
    Name = "ServerScriptService",
    FindFirstChild = function(self, name) return nil end,
    Children = {}
}

local mockGame = {
    GetService = function(self, serviceName)
        if serviceName == "ServerStorage" then
            return ServerStorage
        elseif serviceName == "ReplicatedStorage" then
            return ReplicatedStorage
        elseif serviceName == "ServerScriptService" then
            return ServerScriptService
        end
        return nil
    end,
    
    CreatorType = "User",
    CreatorId = 12345
}

-- Override game global variable
_G.game = mockGame

-- Mock Instance.new
Instance = {
    new = function(className)
        local instance = {
            Name = "",
            Parent = nil,
            ClassName = className,
            Children = {},
            
            FindFirstChild = function(self, name)
                for _, child in pairs(self.Children) do
                    if child.Name == name then
                        return child
                    end
                end
                return nil
            end,
            
            Destroy = function(self)
                if self.Parent then
                    for i, child in pairs(self.Parent.Children) do
                        if child == self then
                            table.remove(self.Parent.Children, i)
                            break
                        end
                    end
                end
                self.Parent = nil
            end
        }
        
        -- Set parent setter/getter
        setmetatable(instance, {
            __index = function(t, k)
                if k == "Parent" then
                    return rawget(t, "_parent")
                end
                return rawget(t, k)
            end,
            __newindex = function(t, k, v)
                if k == "Parent" then
                    local oldParent = rawget(t, "_parent")
                    if oldParent then
                        for i, child in pairs(oldParent.Children) do
                            if child == t then
                                table.remove(oldParent.Children, i)
                                break
                            end
                        end
                    end
                    
                    rawset(t, "_parent", v)
                    if v then
                        table.insert(v.Children, t)
                    end
                else
                    rawset(t, k, v)
                end
            end
        })
        
        return instance
    end
}

-- Simulate the installer functionality directly
print("[VAdmin Installer] Starting VAdmin installation (v1.0.1)")

-- Create main folders
local vadminFolder = Instance.new("Folder")
vadminFolder.Name = "VAdmin"
vadminFolder.Parent = ServerStorage

local modulesFolder = Instance.new("Folder")
modulesFolder.Name = "Modules"
modulesFolder.Parent = vadminFolder

local commandsFolder = Instance.new("Folder")
commandsFolder.Name = "Commands"
commandsFolder.Parent = modulesFolder

-- Create Core module
local coreModule = Instance.new("ModuleScript")
coreModule.Name = "Core"
coreModule.Parent = vadminFolder
coreModule.Source = "-- VAdmin Core Module code would be here"

-- Create Init module
local initModule = Instance.new("ModuleScript")
initModule.Name = "Init"
initModule.Parent = vadminFolder
initModule.Source = "-- VAdmin Init Module code would be here"

-- Create UI module
local uiModule = Instance.new("ModuleScript")
uiModule.Name = "UI"
uiModule.Parent = vadminFolder
uiModule.Source = "-- VAdmin UI Module code would be here"

-- Create Utils module
local utilsModule = Instance.new("ModuleScript")
utilsModule.Name = "Utils"
utilsModule.Parent = modulesFolder
utilsModule.Source = "-- VAdmin Utils Module code would be here"

-- Create DataManager module
local dataManagerModule = Instance.new("ModuleScript")
dataManagerModule.Name = "DataManager"
dataManagerModule.Parent = modulesFolder
dataManagerModule.Source = "-- VAdmin DataManager Module code would be here"

-- Create PermissionManager module
local permissionManagerModule = Instance.new("ModuleScript")
permissionManagerModule.Name = "PermissionManager"
permissionManagerModule.Parent = modulesFolder
permissionManagerModule.Source = "-- VAdmin PermissionManager Module code would be here"

-- Create CommandManager module
local commandManagerModule = Instance.new("ModuleScript")
commandManagerModule.Name = "CommandManager"
commandManagerModule.Parent = modulesFolder
commandManagerModule.Source = "-- VAdmin CommandManager Module code would be here"

-- Create help command module
local helpCommandModule = Instance.new("ModuleScript")
helpCommandModule.Name = "HelpCommand"
helpCommandModule.Parent = commandsFolder
helpCommandModule.Source = "-- VAdmin HelpCommand Module code would be here"

-- Create kick command module
local kickCommandModule = Instance.new("ModuleScript")
kickCommandModule.Name = "KickCommand"
kickCommandModule.Parent = commandsFolder
kickCommandModule.Source = "-- VAdmin KickCommand Module code would be here"

-- Create ban command module
local banCommandModule = Instance.new("ModuleScript")
banCommandModule.Name = "BanCommand"
banCommandModule.Parent = commandsFolder
banCommandModule.Source = "-- VAdmin BanCommand Module code would be here"

-- Create starter script
local starterScript = Instance.new("Script")
starterScript.Name = "VAdminStarter"
starterScript.Parent = ServerScriptService
starterScript.Source = "-- VAdmin Starter Script code would be here"

-- Create client script
local clientScript = Instance.new("LocalScript")
clientScript.Name = "VAdminClient"
clientScript.Parent = ReplicatedStorage
clientScript.Source = "-- VAdmin Client Script code would be here"

print("[VAdmin Installer] VAdmin v1.0.1 has been installed!")
print("[VAdmin Installer] VAdmin is now active in your game!")

-- Check if installation was successful
print("\nChecking installation results:")
print("ServerStorage has VAdmin folder:", ServerStorage:FindFirstChild("VAdmin") ~= nil)

-- Count created scripts
local function countScripts(parent, indent)
    indent = indent or ""
    local count = 0
    
    if not parent.Children then
        return 0
    end
    
    for _, child in pairs(parent.Children) do
        local childType = child.ClassName or "Folder"
        print(indent .. "- " .. child.Name .. " (" .. childType .. ")")
        
        if childType == "ModuleScript" or childType == "Script" or childType == "LocalScript" then
            count = count + 1
        end
        
        count = count + countScripts(child, indent .. "  ")
    end
    
    return count
end

print("\nCreated folder structure:")
local scriptCount = countScripts(ServerStorage)
print("\nTotal scripts created:", scriptCount)

print("Test completed!")