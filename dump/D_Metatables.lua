-- ============================================================
--  dump/D_Metatables.lua
--  Metatable analysis: getrawmetatable on key services,
--  __index, __newindex, __namecall, __call inspection,
--  hook detection (is the game already hooked by something?)
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local U   = HL.Utils
local S   = HL.Services
local St  = HL.Stats

U.S_Header("SECTION 16 — METATABLE ANALYSIS")

if not getrawmetatable then
    U.S_Push("  [!] getrawmetatable not available in this executor.")
    return
end

-- ── Helper: dump a metatable ──────────────────────────────────
local metamethodNames = {
    "__index", "__newindex", "__namecall", "__call", "__len",
    "__eq", "__lt", "__le", "__add", "__sub", "__mul", "__div",
    "__mod", "__pow", "__unm", "__concat", "__tostring",
    "__metatable", "__iter", "__close",
}

local function DumpMetatable(obj, label)
    local ok, mt = pcall(getrawmetatable, obj)
    if not ok or not mt then
        U.S_Push(string.format("  [%s] No metatable or access denied: %s", label, tostring(ok and "nil mt" or mt)))
        return
    end

    St:Inc("MetatablesFound")
    U.S_Push(string.format("  [%s] Metatable found (%s)", label, type(mt)))

    -- Protection field
    local prot = rawget(mt, "__metatable")
    if prot ~= nil then
        U.S_Push(string.format("    __metatable (protected) = %s", tostring(prot)))
    end

    for _, mmName in ipairs(metamethodNames) do
        local val = rawget(mt, mmName)
        if val ~= nil then
            local t = type(val)
            local extra = ""
            if t == "function" then
                -- Type of function
                local isC = false
                pcall(function() isC = iscclosure and iscclosure(val) end)
                local isL = false
                pcall(function() isL = islclosure and islclosure(val) end)
                extra = string.format(" [%s]", isC and "C-closure" or (isL and "Lua-closure" or "function"))

                -- Debug info
                pcall(function()
                    if debug and debug.getinfo then
                        local info = debug.getinfo(val)
                        if info then
                            extra = extra .. string.format(" [src: %s:%s]",
                                tostring(info.short_src or info.source or "?"),
                                tostring(info.linedefined or "?"))
                        end
                    end
                end)

                -- Check if this metamethod is already hooked
                -- (common hook pattern: the function closure wraps another)
                local uvCount = 0
                pcall(function()
                    if getupvalues then
                        uvCount = #getupvalues(val)
                    end
                end)
                if uvCount > 0 then
                    extra = extra .. string.format(" [upvalues: %d]", uvCount)
                end
            elseif t == "table" then
                local len = 0
                pcall(function() for _ in pairs(val) do len = len + 1 end end)
                extra = string.format(" [table, %d keys]", len)
            end
            U.S_Push(string.format("    %-16s = %s%s", mmName, t, extra))
            St:Inc("HookedMetamethods")
        end
    end
end

-- ── Scan Key Roblox Objects ───────────────────────────────────
U.S_SubHeader("16.1 Metatables on Core Objects")
DumpMetatable(game, "game")
DumpMetatable(S.Workspace, "Workspace")
DumpMetatable(S.Players, "Players")
DumpMetatable(S.ReplicatedStorage, "ReplicatedStorage")

-- LocalPlayer
if HL.LocalPlayer then
    DumpMetatable(HL.LocalPlayer, "LocalPlayer")
end

-- ── Scan All Remotes ──────────────────────────────────────────
U.S_SubHeader("16.2 Metatables on First RemoteEvent/Function")
local allDescs = {}
pcall(function() allDescs = game:GetDescendants() end)
local doneSample = {remote=false, fn=false, bindable=false}
for _, inst in ipairs(allDescs) do
    pcall(function()
        local cls = inst.ClassName
        if cls == "RemoteEvent" and not doneSample.remote then
            DumpMetatable(inst, "RemoteEvent sample: " .. inst.Name)
            doneSample.remote = true
        elseif cls == "RemoteFunction" and not doneSample.fn then
            DumpMetatable(inst, "RemoteFunction sample: " .. inst.Name)
            doneSample.fn = true
        elseif cls == "BindableEvent" and not doneSample.bindable then
            DumpMetatable(inst, "BindableEvent sample: " .. inst.Name)
            doneSample.bindable = true
        end
    end)
    if doneSample.remote and doneSample.fn and doneSample.bindable then break end
end

-- ── Scan LocalPlayer + Character ─────────────────────────────
U.S_SubHeader("16.3 Metatables on LocalPlayer Parts")
if HL.LocalPlayer then
    local char = HL.LocalPlayer.Character
    if char then
        DumpMetatable(char, "Character Model")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then DumpMetatable(hrp, "HumanoidRootPart") end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then DumpMetatable(hum, "Humanoid") end
    end
end

-- ── Is __namecall Already Hooked? ────────────────────────────
U.S_SubHeader("16.4 __namecall Hook Detection")
pcall(function()
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt then
        local nc = rawget(mt, "__namecall")
        if nc then
            local isC = false
            pcall(function() isC = iscclosure and iscclosure(nc) end)
            local uvs = {}
            pcall(function()
                if getupvalues then uvs = getupvalues(nc) end
            end)
            -- If it's a Lua closure with many upvalues → likely hooked
            if not isC and #uvs > 0 then
                U.S_Push(string.format("  ⚠ __namecall appears to be HOOKED (Lua closure, %d upvalues)", #uvs))
                -- Try to find original in upvalues
                for idx, uv in ipairs(uvs) do
                    if type(uv) == "function" then
                        local isC2 = false
                        pcall(function() isC2 = iscclosure and iscclosure(uv) end)
                        U.S_Push(string.format("    upvalue[%d] = function (%s) ← possible original",
                            idx, isC2 and "C" or "Lua"))
                    end
                end
            elseif isC then
                U.S_Push("  __namecall is a C closure (native/unhooked)")
            else
                U.S_Push("  __namecall is a Lua closure with 0 upvalues")
            end
        else
            U.S_Push("  No __namecall in game metatable")
        end
    end
end)

-- ── Metatable on Script Objects ───────────────────────────────
U.S_SubHeader("16.5 Script Metatable Sample")
pcall(function()
    if getscripts then
        local scripts = getscripts()
        if scripts and #scripts > 0 then
            DumpMetatable(scripts[1], "Script[1]: " .. (scripts[1].Name or "?"))
        end
    end
end)

U.Log("D_Metatables done", "DUMP")
return true
