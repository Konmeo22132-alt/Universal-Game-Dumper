-- ============================================================
--  modules/Services.lua
--  Safe service acquisition with cloneref fallback
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local cloneref = cloneref or function(o) return o end

local function GetService(name)
    local ok, svc = pcall(function() return game:GetService(name) end)
    if not ok then return nil end
    local ok2, ref = pcall(cloneref, svc)
    return ok2 and ref or svc
end

HL.Services = {
    Players              = GetService("Players"),
    Workspace            = GetService("Workspace"),
    ReplicatedStorage    = GetService("ReplicatedStorage"),
    ReplicatedFirst      = GetService("ReplicatedFirst"),
    ServerStorage        = GetService("ServerStorage"),      -- nil on client, that's fine
    CollectionService    = GetService("CollectionService"),
    Lighting             = GetService("Lighting"),
    SoundService         = GetService("SoundService"),
    StarterGui           = GetService("StarterGui"),
    StarterPack          = GetService("StarterPack"),
    StarterPlayer        = GetService("StarterPlayer"),
    RunService           = GetService("RunService"),
    TweenService         = GetService("TweenService"),
    UserInputService     = GetService("UserInputService"),
    HttpService          = GetService("HttpService"),
    MarketplaceService   = GetService("MarketplaceService"),
    TextService          = GetService("TextService"),
    PhysicsService       = GetService("PhysicsService"),
    PathfindingService   = GetService("PathfindingService"),
    Teams                = GetService("Teams"),
    Chat                 = GetService("Chat"),
    CoreGui              = GetService("CoreGui"),
    GuiService           = GetService("GuiService"),
    VirtualInputManager  = GetService("VirtualInputManager"),
    ContextActionService = GetService("ContextActionService"),
    AnimationClipProvider = GetService("AnimationClipProvider"),
    TestService          = GetService("TestService"),
    LogService           = GetService("LogService"),
    ScriptContext         = GetService("ScriptContext"),
    ContentProvider      = GetService("ContentProvider"),
}

-- Convenience shorthand
HL.S = HL.Services

-- LocalPlayer shorthand
HL.LocalPlayer = HL.Services.Players and HL.Services.Players.LocalPlayer

return HL.Services
