-- ============================================================
--  dump/D_Instances.lua
--  Global scan for ALL instances by type across the entire game
--  Uses game:GetDescendants() for a complete flat scan
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local St = HL.Stats

U.S_Header("SECTION 3 — ALL INSTANCES BY TYPE (GLOBAL SCAN)")

local all = {}
pcall(function() all = game:GetDescendants() end)
U.S_Push(string.format("  Total descendants in game: %d", #all))

-- Categorized containers
local remotes, bindables, prompts, clicks, scripts_list = {}, {}, {}, {}, {}
local localScripts, moduleScripts, sounds, animations   = {}, {}, {}, {}
local valueObjects, billboards, surfaceGuis             = {}, {}, {}
local tweens, constraints, particles, tools_list        = {}, {}, {}, {}
local folders, models, baseparts                        = {}, {}, {}
local unknownRemotes                                    = {}

for _, inst in ipairs(all) do
    pcall(function()
        local cls = inst.ClassName

        if cls == "RemoteEvent" then
            table.insert(remotes, {inst=inst, type="RemoteEvent"})
        elseif cls == "RemoteFunction" then
            table.insert(remotes, {inst=inst, type="RemoteFunction"})
        elseif cls == "UnreliableRemoteEvent" then
            table.insert(remotes, {inst=inst, type="UnreliableRemoteEvent"})
        elseif cls == "BindableEvent" then
            table.insert(bindables, {inst=inst, type="BindableEvent"})
        elseif cls == "BindableFunction" then
            table.insert(bindables, {inst=inst, type="BindableFunction"})
        elseif cls == "ProximityPrompt" then
            table.insert(prompts, inst)
        elseif cls == "ClickDetector" then
            table.insert(clicks, inst)
        elseif cls == "Script" then
            table.insert(scripts_list, inst)
        elseif cls == "LocalScript" then
            table.insert(localScripts, inst)
        elseif cls == "ModuleScript" then
            table.insert(moduleScripts, inst)
        elseif cls == "Sound" then
            table.insert(sounds, inst)
        elseif cls == "Animation" then
            table.insert(animations, inst)
        elseif cls == "BillboardGui" then
            table.insert(billboards, inst)
        elseif cls == "SurfaceGui" then
            table.insert(surfaceGuis, inst)
        elseif cls == "ParticleEmitter" then
            table.insert(particles, inst)
        elseif cls == "Tool" then
            table.insert(tools_list, inst)
        elseif cls == "Folder" then
            table.insert(folders, inst)
        elseif cls == "Model" then
            table.insert(models, inst)
        end

        -- Value objects
        if U.VALUE_CLASSES[cls] then
            table.insert(valueObjects, inst)
        end
    end)
end

-- ── 3A. Remote Events & Functions ────────────────────────────
U.S_SubHeader("3A. Remote Events, Functions & Unreliable (" .. #remotes .. " found)")
for _, r in ipairs(remotes) do
    pcall(function()
        local inst = r.inst
        local path = U.GetPath(inst)
        local parent = inst.Parent
        local parentCls = parent and parent.ClassName or "?"
        local parentPath = parent and U.GetPath(parent) or "?"

        -- Try to get connections (if executor supports it)
        local connCount = 0
        local connNames = {}
        pcall(function()
            if getconnections then
                -- OnClientEvent for RemoteEvent
                if r.type == "RemoteEvent" then
                    local conns = getconnections(inst.OnClientEvent)
                    connCount = #conns
                    for _, c in ipairs(conns) do
                        pcall(function()
                            local fn = c.Function
                            if fn then
                                local info = debug and debug.getinfo and debug.getinfo(fn)
                                if info then
                                    table.insert(connNames, tostring(info.short_src or "?") .. ":" .. tostring(info.currentline or "?"))
                                end
                            end
                        end)
                    end
                end
            end
        end)

        -- Try to detect if parent is a hidden folder (obfuscation)
        local obfNote = ""
        if parent then
            local pname = U.SafeGet(parent, "Name") or ""
            if pname:match("^%s*$") or #pname <= 1 or pname:match("^[_%d]+$") then
                obfNote = " ⚠ POSSIBLY OBFUSCATED PARENT NAME"
            end
        end

        U.S_Push(string.format("  [%s] %s", r.type, path))
        U.S_Push(string.format("       Parent: %s <%s>", parentPath, parentCls))
        U.S_Push(string.format("       Connections: %d %s", connCount,
            #connNames > 0 and ("(" .. table.concat(connNames, "; ") .. ")") or ""))
        U.S_Push(string.format("       Attrs: %s%s", U.DumpAttrs(inst), obfNote))

        if r.type == "RemoteEvent" then St:Inc("RemoteEvents")
        elseif r.type == "RemoteFunction" then St:Inc("RemoteFunctions")
        else St:Inc("UnreliableRemoteEvents")
        end
    end)
end

-- ── 3B. Bindable Events & Functions ──────────────────────────
U.S_SubHeader("3B. Bindable Events & Functions (" .. #bindables .. " found)")
for _, b in ipairs(bindables) do
    pcall(function()
        local inst = b.inst
        local path = U.GetPath(inst)
        local connCount = 0
        pcall(function()
            if getconnections and b.type == "BindableEvent" then
                local conns = getconnections(inst.Event)
                connCount = #conns
            end
        end)
        U.S_Push(string.format("  [%s] %s | Connections: %d", b.type, path, connCount))
        if b.type == "BindableEvent" then St:Inc("BindableEvents")
        else St:Inc("BindableFunctions")
        end
    end)
end

-- ── 3C. ProximityPrompts ──────────────────────────────────────
U.S_SubHeader("3C. ProximityPrompts (" .. #prompts .. " found)")
for _, inst in ipairs(prompts) do
    pcall(function()
        local path = U.GetPath(inst)
        local at, ot, md, hd, los, key, style = "","","","","","",""
        pcall(function()
            at    = inst.ActionText
            ot    = inst.ObjectText
            md    = tostring(inst.MaxActivationDistance)
            hd    = tostring(inst.HoldDuration)
            los   = tostring(inst.RequiresLineOfSight)
            key   = tostring(inst.KeyboardKeyCode)
            style = tostring(inst.Style)
        end)
        local parent = inst.Parent
        local parentPath = parent and U.GetPath(parent) or "?"

        U.S_Push(string.format("  [ProximityPrompt] %s", path))
        U.S_Push(string.format("    ActionText : '%s'", at))
        U.S_Push(string.format("    ObjectText : '%s'", ot))
        U.S_Push(string.format("    Parent     : %s", parentPath))
        U.S_Push(string.format("    MaxDist    : %s | HoldDuration: %s | LoS: %s", md, hd, los))
        U.S_Push(string.format("    Keybind    : %s | Style: %s", key, style))
        -- Connections on Triggered
        pcall(function()
            if getconnections then
                local conns = getconnections(inst.Triggered)
                U.S_Push(string.format("    Triggered connections: %d", #conns))
            end
        end)
        St:Inc("ProximityPrompts")
    end)
end

-- ── 3D. ClickDetectors ────────────────────────────────────────
U.S_SubHeader("3D. ClickDetectors (" .. #clicks .. " found)")
for _, inst in ipairs(clicks) do
    pcall(function()
        local path = U.GetPath(inst)
        local md, ci = "?","?"
        pcall(function()
            md = tostring(inst.MaxActivationDistance)
            ci = tostring(inst.CursorIcon)
        end)
        local connCount = 0
        pcall(function()
            if getconnections then
                local conns = getconnections(inst.MouseClick)
                connCount = #conns
            end
        end)
        U.S_Push(string.format("  [ClickDetector] %s | MaxDist: %s | CursorIcon: %s | Click connections: %d",
            path, md, ci, connCount))
        St:Inc("ClickDetectors")
    end)
end

-- ── 3E. Scripts ───────────────────────────────────────────────
U.S_SubHeader("3E. Scripts (" .. #scripts_list .. " found)")
for _, inst in ipairs(scripts_list) do
    pcall(function()
        local path = U.GetPath(inst)
        local en = U.SafeGet(inst, "Enabled")
        local dis = U.SafeGet(inst, "Disabled")
        -- Check if this script has an environment we can peek at
        local hasEnv = false
        pcall(function()
            if getscripts then
                -- found via getscripts later
            end
        end)
        U.S_Push(string.format("  [Script] %s | Enabled=%s | Disabled=%s",
            path, tostring(en), tostring(dis)))
        St:Inc("Scripts")
    end)
end

U.S_SubHeader("3F. LocalScripts (" .. #localScripts .. " found)")
for _, inst in ipairs(localScripts) do
    pcall(function()
        local path = U.GetPath(inst)
        local en  = U.SafeGet(inst, "Enabled")
        local dis = U.SafeGet(inst, "Disabled")
        U.S_Push(string.format("  [LocalScript] %s | Enabled=%s | Disabled=%s",
            path, tostring(en), tostring(dis)))
        St:Inc("LocalScripts")
    end)
end

U.S_SubHeader("3G. ModuleScripts (" .. #moduleScripts .. " found)")
for _, inst in ipairs(moduleScripts) do
    pcall(function()
        local path = U.GetPath(inst)
        U.S_Push(string.format("  [ModuleScript] %s", path))
        St:Inc("ModuleScripts")
    end)
end

-- ── 3H. Sounds ───────────────────────────────────────────────
U.S_SubHeader("3H. All Sounds (" .. #sounds .. " found)")
for _, inst in ipairs(sounds) do
    pcall(function()
        local path = U.GetPath(inst)
        local sid, vol, pi, lo, pl, ty = "?","?","?","?","?","?"
        pcall(function()
            sid = inst.SoundId
            vol = string.format("%.2f", inst.Volume)
            pi  = string.format("%.2f", inst.PlaybackSpeed)
            lo  = tostring(inst.Looped)
            pl  = tostring(inst.Playing)
            ty  = tostring(inst.RollOffMode)
        end)
        U.S_Push(string.format("  [Sound] %s | Id=%s | Vol=%s | Speed=%s | Loop=%s | Playing=%s | RollOff=%s",
            path, sid, vol, pi, lo, pl, ty))
        St:Inc("Sounds")
    end)
end

-- ── 3I. Value Objects ─────────────────────────────────────────
U.S_SubHeader("3I. All Value Instances (" .. #valueObjects .. " found)")
for _, inst in ipairs(valueObjects) do
    pcall(function()
        local path = U.GetPath(inst)
        local cls  = inst.ClassName
        local val  = U.DumpValue(inst)
        local par  = inst.Parent and inst.Parent.Name or "?"
        U.S_Push(string.format("  [%s] %s %s | Parent: %s", cls, path, val, par))
    end)
end

-- ── 3J. BillboardGuis & SurfaceGuis ──────────────────────────
U.S_SubHeader("3J. Billboard & SurfaceGuis (" .. (#billboards + #surfaceGuis) .. " found)")
for _, inst in ipairs(billboards) do
    pcall(function()
        local path = U.GetPath(inst)
        local en = U.SafeGet(inst, "Enabled")
        local sz = U.SafeGet(inst, "Size")
        local dist = U.SafeGet(inst, "MaxDistance")
        U.S_Push(string.format("  [BillboardGui] %s | Enabled=%s | Size=%s | MaxDist=%s",
            path, tostring(en), tostring(sz), tostring(dist)))
    end)
end
for _, inst in ipairs(surfaceGuis) do
    pcall(function()
        local path = U.GetPath(inst)
        local en   = U.SafeGet(inst, "Enabled")
        local face = U.SafeGet(inst, "Face")
        U.S_Push(string.format("  [SurfaceGui] %s | Enabled=%s | Face=%s",
            path, tostring(en), tostring(face)))
    end)
end

-- ── 3K. Tools ─────────────────────────────────────────────────
U.S_SubHeader("3K. All Tools in Game (" .. #tools_list .. " found)")
for _, inst in ipairs(tools_list) do
    pcall(function()
        local path = U.GetPath(inst)
        local par  = inst.Parent and inst.Parent.Name or "?"
        local grip, req = "?", "?"
        pcall(function()
            grip = tostring(inst.GripPos)
            req  = tostring(inst.RequiresHandle)
        end)
        U.S_Push(string.format("  [Tool] %s | Parent:%s | GripPos:%s | RequiresHandle:%s",
            path, par, grip, req))
        St:Inc("Tools")
    end)
end

-- ── 3L. Folders (potential data containers) ───────────────────
U.S_SubHeader("3L. Folders (potential data containers) (" .. #folders .. " found)")
for _, inst in ipairs(folders) do
    pcall(function()
        local path  = U.GetPath(inst)
        local kids  = inst:GetChildren()
        local attrs = U.DumpAttrs(inst)
        U.S_Push(string.format("  [Folder] %s | Children:%d%s", path, #kids, attrs))
        St:Inc("Folders")
    end)
end

-- ── 3M. ParticleEmitters ──────────────────────────────────────
U.S_SubHeader("3M. ParticleEmitters (" .. #particles .. " found)")
for _, inst in ipairs(particles) do
    pcall(function()
        local path = U.GetPath(inst)
        local en   = U.SafeGet(inst, "Enabled")
        local rate = U.SafeGet(inst, "Rate")
        U.S_Push(string.format("  [Particle] %s | Enabled=%s | Rate=%s",
            path, tostring(en), tostring(rate)))
        St:Inc("ParticleEmitters")
    end)
end

-- ── 3N. Hidden / Obfuscated Remotes Detection ─────────────────
U.S_SubHeader("3N. Obfuscation Analysis — Suspicious Names")
local suspicious = {}
for _, inst in ipairs(all) do
    pcall(function()
        local cls = inst.ClassName
        local isRemotelike = (cls == "RemoteEvent" or cls == "RemoteFunction"
            or cls == "UnreliableRemoteEvent" or cls == "BindableEvent"
            or cls == "BindableFunction" or cls == "ModuleScript"
            or cls == "LocalScript" or cls == "Script")
        if isRemotelike then
            local name = U.SafeGet(inst, "Name") or ""
            -- Suspicious: empty, whitespace-only, very short, all numbers, base64-like
            local isObf = false
            if name:match("^%s*$") then isObf = true
            elseif #name <= 2 then isObf = true
            elseif name:match("^%d+$") then isObf = true
            elseif name:match("^[A-Za-z0-9+/=]{6,}$") and name:match("[A-Z]") and name:match("[a-z]") and name:match("%d") then
                isObf = true -- looks like base64
            elseif name:match("^[_%d]+$") then isObf = true
            end
            if isObf then
                table.insert(suspicious, {
                    path = U.GetPath(inst),
                    cls  = cls,
                    name = name,
                })
            end
        end
    end)
end

if #suspicious == 0 then
    U.S_Push("  No obviously obfuscated names found.")
else
    U.S_Push(string.format("  ⚠ Found %d potentially obfuscated instances:", #suspicious))
    for _, s in ipairs(suspicious) do
        U.S_Push(string.format("    [%s] Name='%s' Path=%s", s.cls, s.name, s.path))
    end
end

U.Log("D_Instances done", "DUMP")
return true
