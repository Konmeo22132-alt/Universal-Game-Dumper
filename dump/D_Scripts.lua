-- ============================================================
--  dump/D_Scripts.lua
--  Running script environments, getgenv / getrenv dump,
--  getscripts(), getrunningscripts(), LogService messages
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services

U.S_Header("SECTION 14 — SCRIPT ENVIRONMENTS & GLOBAL STATE")

-- ── Executor Global Environment (getgenv) ─────────────────────
U.S_SubHeader("14.1 Executor Global Environment (getgenv)")
pcall(function()
    if not getgenv then
        U.S_Push("  [!] getgenv not available.")
        return
    end
    local genv = getgenv()
    local count = 0
    local interesting = {}
    local skip = { _HL=true, _G=true, game=true, workspace=true, script=true,
                   print=true, warn=true, error=true, pcall=true, xpcall=true,
                   pairs=true, ipairs=true, next=true, select=true, type=true,
                   tostring=true, tonumber=true, rawget=true, rawset=true,
                   setmetatable=true, getmetatable=true, table=true, string=true,
                   math=true, os=true, coroutine=true, io=true, task=true,
                   debug=true, bit32=true, utf8=true, Enum=true, shared=true, }
    for k, v in pairs(genv) do
        if not skip[k] then
            count = count + 1
            local t = type(v)
            table.insert(interesting, string.format("    %-30s (%s)", tostring(k), t))
        end
    end
    table.sort(interesting)
    U.S_Push(string.format("  Total non-standard genv keys: %d", count))
    for _, line in ipairs(interesting) do U.S_Push(line) end
end)

-- ── Game Script Environment (getrenv) ─────────────────────────
U.S_SubHeader("14.2 Game Script Environment (getrenv)")
pcall(function()
    if not getrenv then
        U.S_Push("  [!] getrenv not available.")
        return
    end
    local renv = getrenv()
    local count = 0
    local interesting = {}
    local skip = { print=true, warn=true, error=true, pcall=true, xpcall=true,
                   pairs=true, ipairs=true, next=true, select=true, type=true,
                   tostring=true, tonumber=true, rawget=true, rawset=true,
                   setmetatable=true, getmetatable=true, table=true, string=true,
                   math=true, os=true, coroutine=true, task=true, debug=true,
                   bit32=true, utf8=true, Enum=true, game=true, workspace=true,
                   script=true, shared=true, _G=true, }
    for k, v in pairs(renv) do
        if not skip[k] then
            count = count + 1
            local t = type(v)
            local extra = ""
            if t == "boolean" or t == "number" or t == "string" then
                local ok2, str = pcall(tostring, v)
                if ok2 then extra = " = " .. str:sub(1, 80) end
            end
            table.insert(interesting, string.format("    %-30s (%s)%s", tostring(k), t, extra))
        end
    end
    table.sort(interesting)
    U.S_Push(string.format("  Total non-standard renv keys: %d", count))
    for _, line in ipairs(interesting) do U.S_Push(line) end
end)

-- ── getscripts() / getrunningscripts() ────────────────────────
U.S_SubHeader("14.3 Running Scripts (getscripts / getrunningscripts)")
pcall(function()
    local scripts = {}
    if getscripts then
        pcall(function() scripts = getscripts() end)
    elseif getrunningscripts then
        pcall(function() scripts = getrunningscripts() end)
    else
        U.S_Push("  [!] getscripts / getrunningscripts not available.")
        return
    end

    U.S_Push(string.format("  Total running scripts: %d", #scripts))
    for _, scr in ipairs(scripts) do
        pcall(function()
            local cls    = scr.ClassName or "?"
            local path   = U.GetPath(scr)
            local enable = U.SafeGet(scr, "Enabled")
            local dis    = U.SafeGet(scr, "Disabled")
            U.S_Push(string.format("  [%s] %s | Enabled=%s | Disabled=%s",
                cls, path, tostring(enable), tostring(dis)))

            -- Attempt to grab env
            if getfenv then
                local ok2, env = pcall(getfenv, scr)
                if ok2 and env then
                    local envKeys = {}
                    for k in pairs(env) do
                        if k ~= "_ENV" and k ~= "_G" then
                            table.insert(envKeys, tostring(k))
                        end
                    end
                    if #envKeys > 0 then
                        table.sort(envKeys)
                        U.S_Push("    env keys: " .. table.concat(envKeys, ", "):sub(1, 200))
                    end
                end
            end
        end)
    end
end)

-- ── LogService Messages ───────────────────────────────────────
U.S_SubHeader("14.4 LogService — Recent Log Messages")
if S.LogService then
    pcall(function()
        local msgs = S.LogService:GetLogHistory()
        U.S_Push(string.format("  Total log messages: %d", #msgs))
        -- Show last 50
        local start = math.max(1, #msgs - 49)
        for i = start, #msgs do
            local msg = msgs[i]
            if msg then
                local mtype = tostring(msg.messageType or "?")
                local mtext = tostring(msg.message or "?"):sub(1, 150)
                U.S_Push(string.format("  [%s] %s", mtype, mtext))
            end
        end
    end)
else
    U.S_Push("  [!] LogService not available.")
end

-- ── ScriptContext (error logs) ────────────────────────────────
U.S_SubHeader("14.5 ScriptContext")
if S.ScriptContext then
    pcall(function()
        U.S_Push("  ScriptContext accessible.")
        local sc = S.ScriptContext
        U.S_Push(string.format("  CallstackSamplePeriod: %s", tostring(sc.CallstackSamplePeriod)))
        -- Children
        local kids = {}
        pcall(function() kids = sc:GetChildren() end)
        for _, child in ipairs(kids) do
            pcall(function()
                U.S_Push(string.format("  -> [%s] %s", child.ClassName, child.Name))
            end)
        end
    end)
else
    U.S_Push("  ScriptContext not accessible.")
end

-- ── _G (shared game global) ───────────────────────────────────
U.S_SubHeader("14.6 _G (shared global table) Contents")
pcall(function()
    local count = 0
    local lines = {}
    for k, v in pairs(_G) do
        count = count + 1
        local t = type(v)
        local extra = ""
        if t == "string" or t == "number" or t == "boolean" then
            local ok2, str = pcall(tostring, v)
            if ok2 then extra = " = " .. str:sub(1, 80) end
        end
        table.insert(lines, string.format("  %-30s (%s)%s", tostring(k), t, extra))
    end
    table.sort(lines)
    U.S_Push(string.format("  _G key count: %d", count))
    for _, line in ipairs(lines) do U.S_Push(line) end
end)

-- ── shared (Roblox shared table) ──────────────────────────────
U.S_SubHeader("14.7 shared (Roblox shared table) Contents")
pcall(function()
    if not shared then
        U.S_Push("  [No shared table]")
        return
    end
    local count = 0
    for k, v in pairs(shared) do
        count = count + 1
        local t = type(v)
        local extra = ""
        if t == "string" or t == "number" or t == "boolean" then
            pcall(function() extra = " = " .. tostring(v):sub(1,80) end)
        end
        U.S_Push(string.format("  %-30s (%s)%s", tostring(k), t, extra))
    end
    U.S_Push(string.format("  shared key count: %d", count))
    if count == 0 then U.S_Push("  [Empty]") end
end)

U.Log("D_Scripts done", "DUMP")
return true
