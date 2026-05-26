-- ============================================================
--  hooks/H_AntiCheat.lua
--  Anti-cheat fingerprinting, detection bypass indicators,
--  Hyperion/Byfron presence checks, custom AC signal detection
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local U   = HL.Utils
local Cfg = HL.Config
local S   = HL.Services
local LP  = HL.LocalPlayer

U.Log("Running Anti-Cheat Analysis...", "ANTI")

-- ── Executor Capability Fingerprint ──────────────────────────
U.LogRT("ANTI_CAPS", "ExecutorCapabilities", (function()
    local caps = {}
    local fns = {
        "hookmetamethod","hookfunction","getrawmetatable","getgenv","getrenv",
        "getgc","getupvalues","setupvalue","getconstants","getprotos",
        "getconnections","getscripts","getrunningscripts","getscriptfunction",
        "getscriptclosure","appendfile","readfile","writefile","loadstring",
        "fireproximityprompt","fireclickdetector","firetouchinterest",
        "firebindable","gethiddenproperty","sethiddenproperty",
        "checkcaller","getnamecallmethod","iscclosure","islclosure","isluau",
        "cloneref","decompile","getinfo","identifyexecutor","whatexecutor",
        "rconsoleprint","rconsolewarn","rconsoleerr","rconsoleclear",
        "rconsolename","rconsoleinput","setclipboard","getclipboard",
        "setfpscap","syn","is_synapse_function","is_executor_closure",
        "debug","newcclosure","protect_gui","getsenv","getmenv",
    }
    for _, fn in ipairs(fns) do
        local exists = rawget(getgenv and getgenv() or _G, fn) ~= nil
        table.insert(caps, fn .. "=" .. (exists and "Y" or "N"))
    end
    return table.concat(caps, " | ")
end)())

-- ── Identify Executor ─────────────────────────────────────────
U.LogRT("ANTI_EXECUTOR", "Identity", (function()
    local id = "Unknown"
    pcall(function()
        if identifyexecutor then
            id = tostring(identifyexecutor())
        elseif whatexecutor then
            id = tostring(whatexecutor())
        elseif syn then
            id = "Synapse X (syn table found)"
        elseif KRNL_LOADED then
            id = "KRNL"
        elseif FLUXUS then
            id = "Fluxus"
        elseif Drawing then
            id = "Executor with Drawing support"
        end
    end)
    return id
end)())

-- ── Hyperion / Byfron Detection ───────────────────────────────
U.LogRT("ANTI_HYPERION", "Check", (function()
    local result = "Not detected"
    pcall(function()
        -- Byfron injects a "CoreGui" protection or modifies certain metatables
        if getrawmetatable then
            local mt = getrawmetatable(game)
            if mt then
                local nc = rawget(mt, "__namecall")
                if nc then
                    local isC = false
                    pcall(function() isC = iscclosure and iscclosure(nc) end)
                    if isC then
                        result = "LIKELY BYFRON/HYPERION: __namecall is C closure"
                    else
                        result = "__namecall is Lua closure (possibly normal or hooked)"
                    end
                end
            end
        end
    end)
    return result
end)())

-- ── Custom AC Signal Detection ────────────────────────────────
-- Many games use RemoteEvents named something suspicious to report cheaters
U.LogRT("ANTI_AC_REMOTES", "Scanning", (function()
    local acKeywords = {
        "cheat","hack","exploit","ban","kick","anticheat","ac",
        "detect","report","security","integrity","check","flag",
        "alert","warn","monitor","log","telemetry",
    }
    local found = {}
    local allDescs = {}
    pcall(function() allDescs = game:GetDescendants() end)
    for _, inst in ipairs(allDescs) do
        pcall(function()
            local cls = inst.ClassName
            if cls == "RemoteEvent" or cls == "RemoteFunction" or cls == "UnreliableRemoteEvent" then
                local name = inst.Name:lower()
                for _, kw in ipairs(acKeywords) do
                    if name:find(kw) then
                        table.insert(found, string.format("[%s] %s", cls, U.GetPath(inst)))
                        break
                    end
                end
            end
        end)
    end
    if #found == 0 then return "None found by keyword scan"
    else return string.format("%d found: %s", #found, table.concat(found, " | ")) end
end)())

-- ── Suspicious LocalScript Detection ─────────────────────────
U.LogRT("ANTI_SCRIPTS", "LocalScript AC scan", (function()
    local acKeywords = {"anticheat","ac","cheat","detect","security","monitor","ban","kick"}
    local found = {}
    local allDescs = {}
    pcall(function() allDescs = game:GetDescendants() end)
    for _, inst in ipairs(allDescs) do
        pcall(function()
            if inst.ClassName == "LocalScript" then
                local name = inst.Name:lower()
                for _, kw in ipairs(acKeywords) do
                    if name:find(kw) then
                        table.insert(found, U.GetPath(inst))
                        break
                    end
                end
            end
        end)
    end
    if #found == 0 then return "None found"
    else return table.concat(found, " | ") end
end)())

-- ── Protect Against Kick/Teleport Detection ────────────────────
-- Log if LocalPlayer.OnTeleport fires
if LP then
    pcall(function()
        LP.OnTeleport:Connect(function(state, placeId, spawnName)
            U.LogRT("TELEPORT_DETECT", "LocalPlayer.OnTeleport",
                string.format("State=%s PlaceId=%d Spawn=%s",
                    tostring(state), tonumber(placeId) or 0, tostring(spawnName)))
        end)
    end)
end

-- ── RunService.Heartbeat Timing Analysis ─────────────────────
-- Detect if the game is doing per-frame anti-cheat checks
local heartbeatConns = 0
if getconnections then
    pcall(function()
        local conns = getconnections(S.RunService.Heartbeat)
        heartbeatConns = #conns
        local suspicious = 0
        for _, conn in ipairs(conns) do
            pcall(function()
                local fn = conn.Function
                if fn and debug and debug.getinfo then
                    local info = debug.getinfo(fn)
                    local src = tostring(info and info.short_src or "?"):lower()
                    if src:find("anticheat") or src:find("check") or src:find("ac") then
                        suspicious = suspicious + 1
                        U.LogRT("ANTI_HB_CONN", "Heartbeat connection",
                            string.format("⚠ Suspicious: %s:%s",
                                src, tostring(info.linedefined or "?")))
                    end
                end
            end)
        end
        U.LogRT("ANTI_HB_TOTAL", "Heartbeat",
            string.format("Total connections: %d | Suspicious: %d", heartbeatConns, suspicious))
    end)
end

-- ── Hook LocalPlayer.Kick detection ──────────────────────────
if hookmetamethod and getrawmetatable then
    pcall(function()
        -- If RemoteSpy's hookmetamethod is already active,
        -- we just add kick detection via monitoring LP children
        LP.ChildAdded:Connect(function(child)
            if child.Name == "KickMessage" or child.Name:lower():find("kick") then
                U.LogRT("ANTI_KICK", U.GetPath(child),
                    "⚠ Potential kick message object detected!")
            end
        end)
    end)
end

U.Log("Anti-Cheat analysis complete ✓", "ANTI")
return true
