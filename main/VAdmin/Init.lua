--[[
    VAdmin Init Module
    Entry point for VAdmin - initializes system
]]

local RunService = game:GetService("RunService")

-- Import core
local Core = require(script.Parent.Core)

-- Initialize
local function InitServer()
    local VAdmin = Core.new()
    VAdmin:Initialize()
    return VAdmin
end

local function InitClient()
    local UI = require(script.Parent.UI)
    UI.Initialize()
    return UI
end

-- Determine if we're on server or client
if RunService:IsServer() then
    return InitServer()
else
    return InitClient()
end