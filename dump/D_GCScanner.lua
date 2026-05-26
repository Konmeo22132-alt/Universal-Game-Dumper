-- ============================================================
--  dump/D_GCScanner.lua
--  Garbage Collector deep scan: find hidden instances,
--  functions, tables, remote refs buried in memory
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local U   = HL.Utils
local Cfg = HL.Config
local St  = HL.Stats

U.S_Header("SECTION 15 — GARBAGE COLLECTOR DEEP SCAN (getgc)")

if not getgc then
    U.S_Push("  [!] getgc not available in this executor.")
    return
end

U.S_Push("  Initiating GC scan... (this may take a moment)")

local gcObjects = {}
pcall(function()
    gcObjects = getgc(false) -- false = exclude tables (faster first pass)
end)
U.S_Push(string.format("  GC objects (no tables): %d", #gcObjects))

-- ── Find Hidden RemoteEvent/Function References ───────────────
U.S_SubHeader("15.1 Hidden Remote References in GC (functions/closures)")
local hiddenRemotes = {}
local gcFnCount = 0
local remoteClasses = {
    RemoteEvent=true, RemoteFunction=true, UnreliableRemoteEvent=true,
    BindableEvent=true, BindableFunction=true,
}

for _, obj in ipairs(gcObjects) do
    pcall(function()
        if type(obj) == "function" then
            gcFnCount = gcFnCount + 1
            St:Inc("GCFunctionsFound")

            -- Scan upvalues for remote refs
            if getupvalues then
                local uvs = {}
                pcall(function() uvs = getupvalues(obj) end)
                for uvIdx, uvVal in pairs(uvs) do
                    pcall(function()
                        if typeof(uvVal) == "Instance" then
                            local cls = uvVal.ClassName
                            if remoteClasses[cls] then
                                St:Inc("GCRemoteRefs")
                                table.insert(hiddenRemotes, {
                                    fn  = obj,
                                    uvIdx = uvIdx,
                                    remote = uvVal,
                                    cls = cls,
                                    path = U.GetPath(uvVal),
                                })
                            end
                        end
                    end)
                end
            end

            -- Scan constants for remote refs
            if getconstants then
                local consts = {}
                pcall(function() consts = getconstants(obj) end)
                for _, c in ipairs(consts) do
                    pcall(function()
                        if typeof(c) == "Instance" and remoteClasses[c.ClassName] then
                            St:Inc("GCRemoteRefs")
                            table.insert(hiddenRemotes, {
                                fn   = obj,
                                const= true,
                                remote = c,
                                cls  = c.ClassName,
                                path = U.GetPath(c),
                            })
                        end
                    end)
                end
            end
        end
    end)
end

U.S_Push(string.format("  Functions scanned: %d | Remote refs found: %d", gcFnCount, #hiddenRemotes))

-- Deduplicate by path
local seen = {}
local unique = {}
for _, entry in ipairs(hiddenRemotes) do
    if not seen[entry.path] then
        seen[entry.path] = true
        table.insert(unique, entry)
    end
end

U.S_Push(string.format("  Unique hidden remote paths: %d", #unique))
for _, entry in ipairs(unique) do
    U.S_Push(string.format("  ⚠ [HIDDEN via GC] [%s] %s", entry.cls, entry.path))
    -- Try to get debug info on the function
    pcall(function()
        if debug and debug.getinfo then
            local info = debug.getinfo(entry.fn)
            if info then
                U.S_Push(string.format("    Found in: %s | Line: %s",
                    tostring(info.short_src or info.source or "?"),
                    tostring(info.linedefined or "?")))
            end
        end
    end)
end

-- ── GC Table Scan ─────────────────────────────────────────────
U.S_SubHeader("15.2 GC Table Scan (getgc with tables)")
if not Cfg.GCScanTables then
    U.S_Push("  [Disabled in Config.GCScanTables]")
    return
end

local gcWithTables = {}
pcall(function()
    gcWithTables = getgc(true) -- include tables
end)
U.S_Push(string.format("  GC objects (with tables): %d", #gcWithTables))

local tableCount = 0
local suspiciousTables = {}
local limitGC = math.min(#gcWithTables, Cfg.MaxGCObjects)

for i = 1, limitGC do
    local obj = gcWithTables[i]
    pcall(function()
        if type(obj) == "table" then
            tableCount = tableCount + 1
            St:Inc("GCTablesFound")

            -- Look for tables with remote instance keys or values
            for k, v in pairs(obj) do
                pcall(function()
                    -- Value is a remote instance
                    if typeof(v) == "Instance" and remoteClasses[v.ClassName] then
                        table.insert(suspiciousTables, {
                            tableRef = obj,
                            key = tostring(k),
                            inst = v,
                            cls = v.ClassName,
                            path = U.GetPath(v),
                        })
                    end
                    -- Key is a remote instance
                    if typeof(k) == "Instance" and remoteClasses[k.ClassName] then
                        table.insert(suspiciousTables, {
                            tableRef = obj,
                            key = "(instance key)",
                            inst = k,
                            cls = k.ClassName,
                            path = U.GetPath(k),
                        })
                    end
                end)
            end
        end
    end)
end

U.S_Push(string.format("  Tables scanned: %d | Suspicious tables with remote refs: %d",
    tableCount, #suspiciousTables))

-- Deduplicate
local seen2 = {}
for _, entry in ipairs(suspiciousTables) do
    if not seen2[entry.path] then
        seen2[entry.path] = true
        U.S_Push(string.format("  ⚠ [TABLE HIDDEN] [%s] key='%s' → %s",
            entry.cls, entry.key, entry.path))
    end
end

-- ── Module Return Values ──────────────────────────────────────
U.S_SubHeader("15.3 Module Return Values in GC (loaded modules)")
-- RequireCache via getgc: look for tables with function values that have debug info
local moduleResults = {}
for i = 1, limitGC do
    local obj = gcWithTables[i]
    pcall(function()
        if type(obj) == "table" then
            -- A loaded module usually returns a table of functions
            local funcCount = 0
            local totalKeys = 0
            local source = nil
            for k, v in pairs(obj) do
                totalKeys = totalKeys + 1
                if type(v) == "function" then
                    funcCount = funcCount + 1
                    -- Get source of first function found
                    if not source and debug and debug.getinfo then
                        local info = debug.getinfo(v)
                        if info and info.short_src and not info.short_src:find("^%[") then
                            source = info.short_src
                        end
                    end
                end
            end
            -- Heuristic: table with several functions + a debug source
            if funcCount >= 2 and source then
                table.insert(moduleResults, {
                    source   = source,
                    funcCount= funcCount,
                    keyCount = totalKeys,
                })
            end
        end
    end)
end

-- Deduplicate by source
local seenSrc = {}
local uniqMods = {}
for _, m in ipairs(moduleResults) do
    if not seenSrc[m.source] then
        seenSrc[m.source] = true
        table.insert(uniqMods, m)
    end
end
table.sort(uniqMods, function(a,b) return a.source < b.source end)
U.S_Push(string.format("  Detected ~%d unique loaded module namespaces:", #uniqMods))
for _, m in ipairs(uniqMods) do
    U.S_Push(string.format("  -> Source: %s | Functions: %d | Keys: %d",
        m.source, m.funcCount, m.keyCount))
end

U.Log("D_GCScanner done", "DUMP")
return true
