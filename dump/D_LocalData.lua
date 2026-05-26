-- ============================================================
--  dump/D_LocalData.lua
--  LocalPlayer folders, leaderstats, hidden attributes,
--  PlayerData patterns, DataStore proxies
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local LP = HL.LocalPlayer

U.S_Header("SECTION 9 — LOCAL PLAYER DATA & LEADERSTATS")

if not LP then
    U.S_Push("  [!] No LocalPlayer.")
    return
end

-- ── All LP Children (excluding GUI/Backpack/Scripts) ──────────
U.S_SubHeader("9.1 All LocalPlayer Children")
local kids = {}
pcall(function() kids = LP:GetChildren() end)
U.S_Push(string.format("  Total children: %d", #kids))
for _, child in ipairs(kids) do
    pcall(function()
        local cls  = child.ClassName
        local name = child.Name
        local attrs = U.DumpAttrs(child)
        local val   = U.DumpValue(child)
        U.S_Push(string.format("  [%s] '%s'%s%s", cls, name, val, attrs))
    end)
end

-- ── Leaderstats ───────────────────────────────────────────────
U.S_SubHeader("9.2 Leaderstats Values")
local ls = LP:FindFirstChild("leaderstats")
if ls then
    U.S_Push("  leaderstats found:")
    local function DumpLeaderstats(folder, indent)
        local kids2 = {}
        pcall(function() kids2 = folder:GetChildren() end)
        for _, val in ipairs(kids2) do
            pcall(function()
                local cls  = val.ClassName
                local name = val.Name
                local v    = U.DumpValue(val)
                local attrs = U.DumpAttrs(val)
                U.S_Push(string.format("%s  [%s] %s%s%s", indent, cls, name, v, attrs))
                -- Recurse sub-folders
                local subkids = {}
                pcall(function() subkids = val:GetChildren() end)
                if #subkids > 0 then DumpLeaderstats(val, indent .. "  ") end
            end)
        end
    end
    DumpLeaderstats(ls, "")
else
    U.S_Push("  [No leaderstats found]")
end

-- ── All Folders & Value Objects inside LP ─────────────────────
U.S_SubHeader("9.3 All Data Folders & Values in LocalPlayer")
local lpDesc = {}
pcall(function() lpDesc = LP:GetDescendants() end)
for _, inst in ipairs(lpDesc) do
    pcall(function()
        local cls = inst.ClassName
        if U.VALUE_CLASSES[cls] then
            local path = U.GetPath(inst)
            local val  = U.DumpValue(inst)
            local par  = inst.Parent and inst.Parent.Name or "?"
            U.S_Push(string.format("  [%s] %s%s | Parent: %s", cls, path, val, par))
        end
    end)
end

-- ── Hidden Attributes via gethiddenproperty ────────────────────
U.S_SubHeader("9.4 Hidden Properties on LocalPlayer (gethiddenproperty)")
local hiddenProps = {
    "UserId", "Name", "DisplayName", "AccountAge", "MembershipType",
    "HasVerifiedBadge", "FollowUserId", "GamepadEnabled", "MaximumSimulationRadius",
    "SimulationRadius", "ReplicationFocus", "DataComplexity", "DataComplexityLimit",
    "DataReady",
}
for _, prop in ipairs(hiddenProps) do
    local val = U.GetHidden(LP, prop)
    if val ~= nil then
        U.S_Push(string.format("  [Hidden] LP.%s = %s", prop, tostring(val)))
    end
end

-- ── LP Attributes ─────────────────────────────────────────────
U.S_SubHeader("9.5 LocalPlayer:GetAttributes()")
pcall(function()
    local attrMap = LP:GetAttributes()
    local count = 0
    for k, v in pairs(attrMap) do
        U.S_Push(string.format("  %s = %s", tostring(k), tostring(v)))
        count = count + 1
    end
    if count == 0 then U.S_Push("  [None]") end
end)

-- ── PlayerGui Sub-Trees for Data ──────────────────────────────
U.S_SubHeader("9.6 Non-Visual ScreenGuis (potential data storage)")
local pg = LP:FindFirstChild("PlayerGui")
if pg then
    local pgKids = {}
    pcall(function() pgKids = pg:GetChildren() end)
    for _, gui in ipairs(pgKids) do
        pcall(function()
            if gui:IsA("ScreenGui") then
                local en = U.SafeGet(gui, "Enabled")
                local kids2 = gui:GetChildren()
                -- If enabled=false and has value objects → data storage pattern
                local hasValues = false
                for _, k2 in ipairs(kids2) do
                    if U.VALUE_CLASSES[k2.ClassName] then
                        hasValues = true break
                    end
                end
                if not en or hasValues then
                    U.S_Push(string.format("  ⚠ Possible data ScreenGui: '%s' [Enabled=%s]", gui.Name, tostring(en)))
                    U.TraverseTree(gui, "    ", 0, nil, nil)
                end
            end
        end)
    end
end

-- ── Simulation Radius ─────────────────────────────────────────
U.S_SubHeader("9.7 Network Simulation Info")
pcall(function()
    local simR  = U.SafeGet(LP, "SimulationRadius")
    local maxR  = U.SafeGet(LP, "MaximumSimulationRadius")
    U.S_Push(string.format("  SimulationRadius        : %s", tostring(simR)))
    U.S_Push(string.format("  MaximumSimulationRadius : %s", tostring(maxR)))
end)

U.Log("D_LocalData done", "DUMP")
return true
