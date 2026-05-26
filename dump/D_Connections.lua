-- ============================================================
--  dump/D_Connections.lua
--  Signal connection analysis on key objects using getconnections
--  Reveals what scripts are listening to what events
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local U   = HL.Utils
local S   = HL.Services
local St  = HL.Stats
local LP  = HL.LocalPlayer

U.S_Header("SECTION 18 — SIGNAL CONNECTIONS ANALYSIS")

if not getconnections then
    U.S_Push("  [!] getconnections not available in this executor.")
    return
end

-- ── Helper: dump connections of a signal ─────────────────────
local function DumpConnections(signal, label)
    local conns = {}
    local ok, err = pcall(function() conns = getconnections(signal) end)
    if not ok then
        U.S_Push(string.format("  [%s] Error: %s", label, tostring(err)))
        return
    end

    U.S_Push(string.format("  [%s] → %d connection(s)", label, #conns))
    for i, conn in ipairs(conns) do
        pcall(function()
            local enabled = conn.Enabled
            local fn      = conn.Function
            local thread  = conn.Thread
            local ftype   = type(fn)
            local src, line, name = "?", "?", "?"

            if fn and debug and debug.getinfo then
                local info = debug.getinfo(fn)
                if info then
                    src  = tostring(info.short_src or info.source or "?")
                    line = tostring(info.linedefined or "?")
                    name = tostring(info.name or "?")
                end
            end

            local isC = false
            pcall(function() isC = iscclosure and iscclosure(fn) end)

            -- Upvalue count
            local uvCount = 0
            pcall(function()
                if fn and getupvalues then uvCount = #getupvalues(fn) end
            end)

            U.S_Push(string.format("    [%d] Enabled=%s | Fn=%s(%s) | Src=%s:%s | Name=%s | UVs=%d",
                i,
                tostring(enabled),
                ftype,
                isC and "C" or "Lua",
                src, line, name, uvCount))
        end)
    end
end

-- ── Game-Level Signals ────────────────────────────────────────
U.S_SubHeader("18.1 game Service Signals")
pcall(function() DumpConnections(game.DescendantAdded, "game.DescendantAdded") end)
pcall(function() DumpConnections(game.DescendantRemoving, "game.DescendantRemoving") end)
pcall(function() DumpConnections(game.Changed, "game.Changed") end)

-- ── Workspace Signals ─────────────────────────────────────────
U.S_SubHeader("18.2 Workspace Signals")
if S.Workspace then
    pcall(function() DumpConnections(S.Workspace.ChildAdded, "Workspace.ChildAdded") end)
    pcall(function() DumpConnections(S.Workspace.ChildRemoved, "Workspace.ChildRemoved") end)
    pcall(function() DumpConnections(S.Workspace.DescendantAdded, "Workspace.DescendantAdded") end)
end

-- ── Players Signals ───────────────────────────────────────────
U.S_SubHeader("18.3 Players Service Signals")
if S.Players then
    pcall(function() DumpConnections(S.Players.PlayerAdded, "Players.PlayerAdded") end)
    pcall(function() DumpConnections(S.Players.PlayerRemoving, "Players.PlayerRemoving") end)
    pcall(function() DumpConnections(S.Players.PlayerChatted, "Players.PlayerChatted") end)
end

-- ── LocalPlayer Signals ───────────────────────────────────────
U.S_SubHeader("18.4 LocalPlayer Signals")
if LP then
    pcall(function() DumpConnections(LP.CharacterAdded, "LocalPlayer.CharacterAdded") end)
    pcall(function() DumpConnections(LP.CharacterRemoving, "LocalPlayer.CharacterRemoving") end)
    pcall(function() DumpConnections(LP.Changed, "LocalPlayer.Changed") end)
    pcall(function() DumpConnections(LP.OnTeleport, "LocalPlayer.OnTeleport") end)

    -- Character signals
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() DumpConnections(hum.Died, "Humanoid.Died") end)
            pcall(function() DumpConnections(hum.StateChanged, "Humanoid.StateChanged") end)
            pcall(function() DumpConnections(hum.HealthChanged, "Humanoid.HealthChanged") end)
            pcall(function() DumpConnections(hum.Running, "Humanoid.Running") end)
            pcall(function() DumpConnections(hum.Jumping, "Humanoid.Jumping") end)
            pcall(function() DumpConnections(hum.Climbing, "Humanoid.Climbing") end)
            pcall(function() DumpConnections(hum.Swimming, "Humanoid.Swimming") end)
            pcall(function() DumpConnections(hum.FreeFalling, "Humanoid.FreeFalling") end)
            pcall(function() DumpConnections(hum.FallingDown, "Humanoid.FallingDown") end)
            pcall(function() DumpConnections(hum.GettingUp, "Humanoid.GettingUp") end)
            pcall(function() DumpConnections(hum.Seated, "Humanoid.Seated") end)
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function() DumpConnections(hrp.Touched, "HRP.Touched") end)
        end
    end
end

-- ── RunService Signals ────────────────────────────────────────
U.S_SubHeader("18.5 RunService Signals")
if S.RunService then
    pcall(function() DumpConnections(S.RunService.Heartbeat, "RunService.Heartbeat") end)
    pcall(function() DumpConnections(S.RunService.RenderStepped, "RunService.RenderStepped") end)
    pcall(function() DumpConnections(S.RunService.Stepped, "RunService.Stepped") end)
end

-- ── All RemoteEvent.OnClientEvent Connections ─────────────────
U.S_SubHeader("18.6 All RemoteEvent.OnClientEvent Connections")
local allDescs = {}
pcall(function() allDescs = game:GetDescendants() end)
local remoteConnTotal = 0
for _, inst in ipairs(allDescs) do
    pcall(function()
        if inst.ClassName == "RemoteEvent" then
            local conns = getconnections(inst.OnClientEvent)
            if #conns > 0 then
                remoteConnTotal = remoteConnTotal + #conns
                U.S_Push(string.format("  RemoteEvent: %s → %d listener(s)", U.GetPath(inst), #conns))
                for i, conn in ipairs(conns) do
                    pcall(function()
                        local fn = conn.Function
                        local src, line = "?", "?"
                        if fn and debug and debug.getinfo then
                            local info = debug.getinfo(fn)
                            if info then
                                src  = tostring(info.short_src or "?")
                                line = tostring(info.linedefined or "?")
                            end
                        end
                        U.S_Push(string.format("    [%d] Src: %s:%s | Enabled: %s",
                            i, src, line, tostring(conn.Enabled)))
                    end)
                end
            end
        end
    end)
end
U.S_Push(string.format("  Total OnClientEvent connections: %d", remoteConnTotal))

-- ── Bindable Event connections ────────────────────────────────
U.S_SubHeader("18.7 All BindableEvent.Event Connections")
local bindableTotal = 0
for _, inst in ipairs(allDescs) do
    pcall(function()
        if inst.ClassName == "BindableEvent" then
            local conns = getconnections(inst.Event)
            if #conns > 0 then
                bindableTotal = bindableTotal + #conns
                U.S_Push(string.format("  BindableEvent: %s → %d listener(s)", U.GetPath(inst), #conns))
                for i, conn in ipairs(conns) do
                    pcall(function()
                        local fn = conn.Function
                        local src, line = "?", "?"
                        if fn and debug and debug.getinfo then
                            local info = debug.getinfo(fn)
                            if info then src = info.short_src or "?"; line = info.linedefined or "?" end
                        end
                        U.S_Push(string.format("    [%d] %s:%s", i, tostring(src), tostring(line)))
                    end)
                end
            end
        end
    end)
end
U.S_Push(string.format("  Total BindableEvent connections: %d", bindableTotal))

U.Log("D_Connections done", "DUMP")
return true
