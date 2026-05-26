-- ============================================================
--  HuneLog v2.0 - Universal Game Dumper
--  Entry Point: main.lua
--  Run this file in your executor.
-- ============================================================

-- ── CONFIGURATION ─────────────────────────────────────────────
-- Change these to match your GitHub repository!
local GITHUB_USER = "Konmeo22132-alt"
local GITHUB_REPO = "Universal-Game-Dumper"
local GITHUB_BRANCH = "main"

-- Set to TRUE to download modules from GitHub.
-- Set to FALSE if you want to load from your executor's local workspace.
local USE_GITHUB = true 

local BASE_PATH = "hune-log/"

-- ── Shared Global State ──────────────────────────────────────
local genv = getgenv and getgenv() or _G
genv._HL = {
    Version    = "2.0.0",
    StartClock = os.clock(),
    StartTime  = os.date(),
    BasePath   = BASE_PATH,

    Services   = {},
    Config     = {},
    Stats      = {},
    StaticLines = {},
    RealtimeQueue = {},
    _Loaded    = {},
}

-- ── Module Loader ─────────────────────────────────────────────
local function Import(relPath)
    local fullPath = BASE_PATH .. relPath
    local cached = genv._HL._Loaded[fullPath]
    if cached then return cached end

    local src
    if USE_GITHUB then
        local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", 
            GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH, relPath)
        local ok, res = pcall(game.HttpGet, game, url)
        if not ok or not res or res == "404: Not Found" then
            warn("[HuneLog] Failed to fetch from GitHub: " .. url)
            return nil
        end
        src = res
    else
        local ok, res = pcall(readfile, fullPath)
        if not ok or not res then
            warn("[HuneLog] Failed to read local module: " .. fullPath)
            return nil
        end
        src = res
    end

    local fn, compileErr = loadstring(src, "@" .. relPath)
    if not fn then
        warn("[HuneLog] Failed to compile: " .. fullPath .. " | " .. tostring(compileErr))
        return nil
    end

    local runOk, result = pcall(fn)
    if not runOk then
        warn("[HuneLog] Failed to run: " .. fullPath .. " | " .. tostring(result))
        return nil
    end

    genv._HL._Loaded[fullPath] = result or true
    return result
end
genv._HL.Import = Import

-- ── Boot Sequence ─────────────────────────────────────────────
print("[HuneLog] Booting v" .. genv._HL.Version .. " ...")

-- Core infrastructure (order matters)
Import("modules/Config.lua")
Import("modules/Services.lua")
Import("modules/Utils.lua")
Import("modules/Stats.lua")

local Utils = genv._HL.Utils
Utils.Log("Core modules loaded.", "SYS")

-- ── Static Dump Modules ───────────────────────────────────────
Utils.Log("Starting static dump...", "SYS")

Import("dump/D_Player.lua")
Import("dump/D_Workspace.lua")
Import("dump/D_Instances.lua")
Import("dump/D_Storage.lua")
Import("dump/D_PlayerGUI.lua")
Import("dump/D_Collection.lua")
Import("dump/D_Environment.lua")
Import("dump/D_LocalData.lua")
Import("dump/D_Physics.lua")
Import("dump/D_Camera.lua")
Import("dump/D_Input.lua")
Import("dump/D_Animations.lua")
Import("dump/D_Scripts.lua")
Import("dump/D_GCScanner.lua")
Import("dump/D_Metatables.lua")
Import("dump/D_Upvalues.lua")
Import("dump/D_Connections.lua")

-- Write summary & save static file
Import("modules/StaticWriter.lua")

Utils.Log("Static dump complete.", "SYS")

-- ── Realtime Hook Modules ─────────────────────────────────────
Utils.Log("Activating realtime hooks...", "SYS")

Import("hooks/H_RemoteSpy.lua")
Import("hooks/H_ProximitySpy.lua")
Import("hooks/H_ClickSpy.lua")
Import("hooks/H_GUISpy.lua")
Import("hooks/H_CharacterSpy.lua")
Import("hooks/H_WorkspaceSpy.lua")
Import("hooks/H_TweenSpy.lua")
Import("hooks/H_PropertySpy.lua")
Import("hooks/H_ChatSpy.lua")
Import("hooks/H_AntiCheat.lua")

local elapsed = string.format("%.2fs", os.clock() - genv._HL.StartClock)
Utils.Log(string.format("HuneLog fully initialized in %s. Happy logging!", elapsed), "SYS")
