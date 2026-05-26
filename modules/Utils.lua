-- ============================================================
--  modules/Utils.lua
--  Core utility functions shared across all HuneLog modules
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local Cfg = HL.Config
local S   = HL.Services

-- ── Console Logger ────────────────────────────────────────────
local function Log(msg, tag)
    tag = tag or "INFO"
    local color = (Cfg.Colors and Cfg.Colors[tag]) or ""
    local formatted = string.format("[HL|%s] %s", tag, tostring(msg))
    pcall(function()
        print(formatted)
        if rconsoleprint then
            if color ~= "" then rconsoleprint(color) end
            rconsoleprint(formatted .. "\n")
            if color ~= "" then rconsoleprint("@@WHITE@@") end
        end
    end)
end

-- ── Static Dump Accumulator ───────────────────────────────────
local function S_Push(text)
    table.insert(HL.StaticLines, tostring(text))
end

local function S_Header(title)
    local bar = string.rep("═", 60)
    S_Push("\n" .. bar)
    S_Push("  " .. title)
    S_Push(bar)
end

local function S_SubHeader(title)
    S_Push("\n── " .. title .. " " .. string.rep("─", math.max(0, 55 - #title)))
end

-- ── Realtime Log ──────────────────────────────────────────────
local function AppendRealtime(text)
    pcall(function()
        local line = tostring(text) .. "\n"
        if Cfg.UseAppendFile and appendfile then
            appendfile(Cfg.RealtimeFile, line)
        else
            local existing = ""
            pcall(function() existing = readfile(Cfg.RealtimeFile) end)
            writefile(Cfg.RealtimeFile, existing .. line)
        end
    end)
end

local function LogRT(prefix, path, details)
    local ts  = string.format("%.3f", os.clock())
    local msg = string.format("[%s][%s] %s", prefix, ts, tostring(path))
    if details and details ~= "" then
        msg = msg .. " | " .. tostring(details)
    end
    Log(msg, "HOOK")
    AppendRealtime(msg)
end

-- ── Instance Path ─────────────────────────────────────────────
local function GetPath(inst)
    if not inst then return "<nil>" end
    local ok, path = pcall(function() return inst:GetFullName() end)
    return ok and path or tostring(inst)
end

-- ── Safe Property Read ────────────────────────────────────────
local function SafeGet(inst, prop)
    local ok, val = pcall(function() return inst[prop] end)
    return ok and val or nil
end

-- ── JSON Serialize ────────────────────────────────────────────
local function JSONSer(...)
    local args = {...}
    local ok, result = pcall(function()
        return S.HttpService:JSONEncode(args)
    end)
    if ok then return result end
    -- Fallback: tostring each arg
    local parts = {}
    for i, v in ipairs(args) do
        local ts = ""
        pcall(function()
            if type(v) == "table" then
                local inner = {}
                for k2, v2 in pairs(v) do
                    table.insert(inner, tostring(k2) .. "=" .. tostring(v2))
                end
                ts = "{" .. table.concat(inner, ", ") .. "}"
            else
                ts = tostring(v)
            end
        end)
        parts[i] = ts ~= "" and ts or tostring(v)
    end
    return table.concat(parts, ", ")
end

-- ── Attribute Dump ────────────────────────────────────────────
local function DumpAttrs(inst)
    local parts = {}
    pcall(function()
        for k, v in pairs(inst:GetAttributes()) do
            local vs = ""
            pcall(function() vs = tostring(v) end)
            table.insert(parts, k .. "=" .. vs)
        end
    end)
    if #parts > 0 then
        return " {Attrs: " .. table.concat(parts, ", ") .. "}"
    end
    return ""
end

-- ── ValueBase Reader ──────────────────────────────────────────
local VALUE_CLASSES = {
    StringValue = true, IntValue = true, NumberValue = true,
    BoolValue = true, ObjectValue = true, Vector3Value = true,
    CFrameValue = true, Color3Value = true, RayValue = true,
    BrickColorValue = true,
}

local function DumpValue(inst)
    local ok, cls = pcall(function() return inst.ClassName end)
    if ok and VALUE_CLASSES[cls] then
        local vok, val = pcall(function() return inst.Value end)
        if vok then
            if type(val) == "userdata" then
                local str = ""
                pcall(function() str = tostring(val) end)
                return " [Value=" .. str .. "]"
            end
            return " [Value=" .. tostring(val) .. "]"
        end
    end
    return ""
end

-- ── Tree Traversal ────────────────────────────────────────────
-- Generic recursive tree printer into static dump.
-- extraFn(child, indent) -> optional string appended to the line
local function TraverseTree(root, indent, depth, trackStatsFn, extraFn)
    if not root then return end
    indent = indent or ""
    depth  = depth  or 0
    if depth > Cfg.MaxDepth then
        S_Push(indent .. "  ... [MAX DEPTH REACHED]")
        return
    end

    local children = {}
    pcall(function() children = root:GetChildren() end)
    if #children > Cfg.MaxChildren then
        S_Push(indent .. string.format("  [TRUNCATED: %d children, showing first %d]", #children, Cfg.MaxChildren))
    end

    local limit = math.min(#children, Cfg.MaxChildren)
    for i = 1, limit do
        local child = children[i]
        local name, cls = "?", "?"
        pcall(function() name = child.Name end)
        pcall(function() cls  = child.ClassName end)

        local extra = DumpAttrs(child) .. DumpValue(child)
        if extraFn then
            local ex2 = ""
            pcall(function() ex2 = extraFn(child, indent) or "" end)
            extra = extra .. ex2
        end

        S_Push(string.format("%s[%d] %s <%s>%s", indent, i, name, cls, extra))

        if trackStatsFn then
            pcall(trackStatsFn, child)
        end

        TraverseTree(child, indent .. "  ", depth + 1, trackStatsFn, extraFn)
    end
end

-- ── Hidden Property Reader (via gethiddenproperty) ────────────
local function GetHidden(inst, prop)
    if gethiddenproperty then
        local ok, val = pcall(gethiddenproperty, inst, prop)
        if ok then return val end
    end
    return nil
end

-- ── isA checker (safe) ────────────────────────────────────────
local function IsA(inst, cls)
    local ok, res = pcall(function() return inst:IsA(cls) end)
    return ok and res
end

-- ── Timestamp string ─────────────────────────────────────────
local function TS()
    return string.format("[%.3f]", os.clock())
end

-- ── Separator line ────────────────────────────────────────────
local function Sep(char, len)
    return string.rep(char or "-", len or 60)
end

-- ── Pack all into HL.Utils ────────────────────────────────────
HL.Utils = {
    Log           = Log,
    S_Push        = S_Push,
    S_Header      = S_Header,
    S_SubHeader   = S_SubHeader,
    AppendRealtime= AppendRealtime,
    LogRT         = LogRT,
    GetPath       = GetPath,
    SafeGet       = SafeGet,
    JSONSer       = JSONSer,
    DumpAttrs     = DumpAttrs,
    DumpValue     = DumpValue,
    TraverseTree  = TraverseTree,
    GetHidden     = GetHidden,
    IsA           = IsA,
    TS            = TS,
    Sep           = Sep,
    VALUE_CLASSES = VALUE_CLASSES,
}

return HL.Utils
