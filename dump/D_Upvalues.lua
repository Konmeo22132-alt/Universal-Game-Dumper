-- ============================================================
--  dump/D_Upvalues.lua
--  Upvalue extraction from all running Lua scripts,
--  constantscanning, proto diving for hidden data
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local U   = HL.Utils
local Cfg = HL.Config
local St  = HL.Stats

U.S_Header("SECTION 17 — UPVALUE & CONSTANT SCANNER")

if not (getupvalues or getconstants or getprotos) then
    U.S_Push("  [!] getupvalues / getconstants / getprotos not available.")
    return
end

-- ── Helper: Scan a single function ───────────────────────────
local function ScanFunction(fn, depth, label, results)
    depth = depth or 0
    if depth > Cfg.UpvalueProtoDepth then return end

    -- Upvalues
    if getupvalues then
        local uvs = {}
        pcall(function() uvs = getupvalues(fn) end)
        for idx, val in pairs(uvs) do
            pcall(function()
                St:Inc("UpvaluesScanned")
                local t = type(val)
                local extra = ""
                if t == "string" then
                    extra = string.format(" = '%s'", val:sub(1, 80))
                elseif t == "number" or t == "boolean" then
                    extra = " = " .. tostring(val)
                elseif t == "table" then
                    local len = 0
                    for _ in pairs(val) do len=len+1 end
                    extra = string.format(" (table, %d keys)", len)
                elseif typeof and typeof(val) == "Instance" then
                    local cls = val.ClassName or "?"
                    extra = string.format(" → Instance [%s] %s", cls, U.GetPath(val))
                    -- Track remote refs
                    if cls=="RemoteEvent" or cls=="RemoteFunction"
                    or cls=="UnreliableRemoteEvent" or cls=="BindableEvent"
                    or cls=="BindableFunction" then
                        St:Inc("UpvalueRemoteRefs")
                        table.insert(results, {
                            label = label,
                            idx = idx,
                            cls = cls,
                            path = U.GetPath(val),
                            depth = depth,
                        })
                    end
                end
                if #extra > 0 then
                    U.S_Push(string.format("    [UV %d] (%s)%s", idx, t, extra))
                end
            end)
        end
    end

    -- Constants
    if getconstants then
        local consts = {}
        pcall(function() consts = getconstants(fn) end)
        for idx, val in pairs(consts) do
            pcall(function()
                local t = type(val)
                if t == "string" and #val > 2 then
                    -- Interesting strings: paths, URLs, keys
                    local interesting = val:find("rbxasset") or val:find("https?://")
                        or val:find("Remote") or val:find("Event") or val:find("Function")
                        or val:find("Server") or val:find("Client") or val:find("Data")
                        or val:find("Shop") or val:find("Currency") or val:find("Kill")
                        or val:find("Admin") or val:find("Ban") or val:find("Cash")
                    if interesting then
                        U.S_Push(string.format("    [CONST %d] '%s'", idx, val:sub(1, 120)))
                    end
                elseif typeof and typeof(val) == "Instance" then
                    local cls = val.ClassName or "?"
                    U.S_Push(string.format("    [CONST %d] Instance [%s] %s", idx, cls, U.GetPath(val)))
                end
            end)
        end
    end

    -- Recurse into protos (sub-functions)
    if getprotos then
        local protos = {}
        pcall(function() protos = getprotos(fn) end)
        for pidx, proto in ipairs(protos) do
            pcall(function()
                if type(proto) == "function" then
                    ScanFunction(proto, depth + 1,
                        label .. "/proto[" .. pidx .. "]", results)
                end
            end)
        end
    end
end

-- ── Scan All Running Scripts ───────────────────────────────────
U.S_SubHeader("17.1 Upvalue/Constant Scan of All Running Scripts")
local remoteRefs = {}

local scripts = {}
if getscripts then
    pcall(function() scripts = getscripts() end)
elseif getrunningscripts then
    pcall(function() scripts = getrunningscripts() end)
end

U.S_Push(string.format("  Scripts to scan: %d", #scripts))

for _, scr in ipairs(scripts) do
    pcall(function()
        -- Get main function from script
        local scrFn = nil
        if getscriptfunction then
            pcall(function() scrFn = getscriptfunction(scr) end)
        end
        if not scrFn then
            -- Try via thread / closure search
            if getscriptclosure then
                pcall(function() scrFn = getscriptclosure(scr) end)
            end
        end
        if not scrFn then return end

        local label = scr.ClassName .. ":" .. U.GetPath(scr)
        U.S_Push(string.format("  ── Scanning: %s", label))
        ScanFunction(scrFn, 0, label, remoteRefs)
    end)
end

-- ── Summary of Remote Refs Found ─────────────────────────────
U.S_SubHeader("17.2 Remote References Found in Script Upvalues")
if #remoteRefs == 0 then
    U.S_Push("  [None found — scripts may not store remotes as upvalues]")
else
    U.S_Push(string.format("  Found %d upvalue remote reference(s):", #remoteRefs))
    local seen = {}
    for _, ref in ipairs(remoteRefs) do
        if not seen[ref.path] then
            seen[ref.path] = true
            U.S_Push(string.format("  ⚠ [UV REMOTE] [%s] %s | Found in: %s (depth %d)",
                ref.cls, ref.path, ref.label, ref.depth))
        end
    end
end

-- ── GC Function Constant Scan ─────────────────────────────────
U.S_SubHeader("17.3 Interesting String Constants in GC Functions")
if not (getgc and getconstants) then
    U.S_Push("  [getgc or getconstants not available]")
    return
end

local gcObjs = {}
pcall(function() gcObjs = getgc(false) end)

local interestingStrings = {
    "remote", "event", "function", "server", "client", "data", "shop",
    "currency", "kill", "admin", "ban", "cash", "coins", "gems", "token",
    "key", "secret", "password", "auth", "hash", "webhook",
    "rbxasset", "rbxgameasset", "http", "https", "url",
    "loadstring", "require", "getfenv", "setfenv",
}

local foundConsts = {}
local scannedFns = 0

for i, obj in ipairs(gcObjs) do
    if i > Cfg.MaxGCObjects then break end
    pcall(function()
        if type(obj) == "function" then
            scannedFns = scannedFns + 1
            local consts = {}
            pcall(function() consts = getconstants(obj) end)
            for _, c in ipairs(consts) do
                if type(c) == "string" then
                    local cl = c:lower()
                    for _, kw in ipairs(interestingStrings) do
                        if cl:find(kw) then
                            table.insert(foundConsts, {
                                str = c,
                                keyword = kw,
                                fn = obj,
                            })
                            break
                        end
                    end
                end
            end
        end
    end)
end

U.S_Push(string.format("  Scanned %d GC functions | Interesting constants: %d",
    scannedFns, #foundConsts))

-- Deduplicate strings
local seenStr = {}
for _, fc in ipairs(foundConsts) do
    if not seenStr[fc.str] then
        seenStr[fc.str] = true
        local src = ""
        pcall(function()
            if debug and debug.getinfo then
                local info = debug.getinfo(fc.fn)
                if info then
                    src = string.format(" [%s:%s]",
                        tostring(info.short_src or "?"),
                        tostring(info.linedefined or "?"))
                end
            end
        end)
        U.S_Push(string.format("  [KW:%s] '%s'%s", fc.keyword, fc.str:sub(1, 100), src))
    end
end

U.Log("D_Upvalues done", "DUMP")
return true
