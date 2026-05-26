-- ============================================================
--  dump/D_Storage.lua
--  ReplicatedStorage, ReplicatedFirst, ServerStorage (if any)
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local St = HL.Stats

U.S_Header("SECTION 4 — STORAGE SERVICES")

-- ── ReplicatedStorage ─────────────────────────────────────────
U.S_SubHeader("4.1 ReplicatedStorage — Full Tree")
if S.ReplicatedStorage then
    U.S_Push(string.format("  Children count: %d", #S.ReplicatedStorage:GetChildren()))
    U.TraverseTree(S.ReplicatedStorage, "  ", 0, function(inst) St:Track(inst) end,
    function(inst)
        local cls = ""
        pcall(function() cls = inst.ClassName end)
        if cls == "RemoteEvent" then St:Inc("RemoteEvents"); return " ★ REMOTE_EVENT"
        elseif cls == "RemoteFunction" then St:Inc("RemoteFunctions"); return " ★ REMOTE_FUNCTION"
        elseif cls == "UnreliableRemoteEvent" then St:Inc("UnreliableRemoteEvents"); return " ★ UNRELIABLE"
        elseif cls == "BindableEvent" then St:Inc("BindableEvents"); return " ★ BINDABLE_EVENT"
        elseif cls == "BindableFunction" then St:Inc("BindableFunctions"); return " ★ BINDABLE_FN"
        elseif cls == "ModuleScript" then return " [Module]"
        end
        return U.DumpValue(inst)
    end)
else
    U.S_Push("  [!] ReplicatedStorage not accessible.")
end

-- ── ReplicatedFirst ───────────────────────────────────────────
U.S_SubHeader("4.2 ReplicatedFirst — Full Tree")
if S.ReplicatedFirst then
    U.S_Push(string.format("  Children count: %d", #S.ReplicatedFirst:GetChildren()))
    U.TraverseTree(S.ReplicatedFirst, "  ", 0, function(inst) St:Track(inst) end, function(inst)
        return U.DumpValue(inst)
    end)
else
    U.S_Push("  [!] ReplicatedFirst not accessible.")
end

-- ── ServerStorage (usually inaccessible on client) ────────────
U.S_SubHeader("4.3 ServerStorage — Accessibility Check")
if S.ServerStorage then
    local ok, children = pcall(function() return S.ServerStorage:GetChildren() end)
    if ok and #children > 0 then
        U.S_Push(string.format("  ⚠ ServerStorage is READABLE from client! (%d children)", #children))
        U.TraverseTree(S.ServerStorage, "  ", 0, nil, nil)
    else
        U.S_Push("  ServerStorage: Not readable (expected on client) — children count 0 or pcall failed")
    end
else
    U.S_Push("  ServerStorage: Service not found.")
end

-- ── Deep remote scan inside ReplicatedStorage ─────────────────
U.S_SubHeader("4.4 All Remotes Inside ReplicatedStorage (flat list)")
if S.ReplicatedStorage then
    local all = {}
    pcall(function() all = S.ReplicatedStorage:GetDescendants() end)
    local found = 0
    for _, inst in ipairs(all) do
        pcall(function()
            local cls = inst.ClassName
            if cls == "RemoteEvent" or cls == "RemoteFunction"
            or cls == "UnreliableRemoteEvent" or cls == "BindableEvent"
            or cls == "BindableFunction" then
                found = found + 1
                U.S_Push(string.format("  [%s] %s", cls, U.GetPath(inst)))
            end
        end)
    end
    U.S_Push(string.format("  Total remotes in ReplicatedStorage: %d", found))
end

U.Log("D_Storage done", "DUMP")
return true
