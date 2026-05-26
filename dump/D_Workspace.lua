-- ============================================================
--  dump/D_Workspace.lua
--  Full Workspace tree with per-object metadata
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local St = HL.Stats
local WS = S.Workspace

U.S_Header("SECTION 2 — WORKSPACE FULL TREE")

if not WS then
    U.S_Push("  [!] Workspace not found.")
    return
end

-- ── Workspace Properties ──────────────────────────────────────
U.S_SubHeader("2.1 Workspace Properties")
pcall(function()
    U.S_Push(string.format("  Gravity              : %.2f", WS.Gravity))
    U.S_Push(string.format("  StreamingEnabled     : %s",   tostring(WS.StreamingEnabled)))
    U.S_Push(string.format("  StreamingMinRadius   : %s",   tostring(WS.StreamingMinRadius)))
    U.S_Push(string.format("  StreamingTargetRadius: %s",   tostring(WS.StreamingTargetRadius)))
    U.S_Push(string.format("  StreamingIntegrityMode: %s",  tostring(WS.StreamingIntegrityMode)))
    U.S_Push(string.format("  FallenPartsDestroyHeight: %.1f", WS.FallenPartsDestroyHeight))
    U.S_Push(string.format("  CurrentCamera        : %s",   WS.CurrentCamera and "Present" or "nil"))
    U.S_Push(string.format("  AirDensity           : %.4f", WS.AirDensity))
    U.S_Push(string.format("  GlobalWindDirection  : %s",   tostring(WS.GlobalWindDirection)))
    U.S_Push(string.format("  GlobalWindSpeed      : %.2f", WS.GlobalWindSpeed))
    U.S_Push(string.format("  PhysicsSteppingMethod: %s",   tostring(WS.PhysicsSteppingMethod)))
    U.S_Push(string.format("  SignalBehavior       : %s",   tostring(WS.SignalBehavior)))
    U.S_Push(string.format("  RejectCharacterDeletions: %s", tostring(WS.RejectCharacterDeletions)))
    U.S_Push(string.format("  TouchesUseCollisionGroups: %s", tostring(WS.TouchesUseCollisionGroups)))
end)

-- ── Workspace.Terrain ─────────────────────────────────────────
U.S_SubHeader("2.2 Terrain Info")
pcall(function()
    local terrain = WS:FindFirstChildOfClass("Terrain")
    if terrain then
        U.S_Push("  Terrain present: YES")
        U.S_Push(string.format("  WaterColor      : %s", tostring(terrain.WaterColor)))
        U.S_Push(string.format("  WaterTransparency: %.2f", terrain.WaterTransparency))
        U.S_Push(string.format("  WaterWaveSize   : %.2f", terrain.WaterWaveSize))
        U.S_Push(string.format("  WaterWaveSpeed  : %.2f", terrain.WaterWaveSpeed))
        U.S_Push(string.format("  WaterReflectance: %.2f", terrain.WaterReflectance))
        local decorations = terrain.Decoration
        U.S_Push(string.format("  Decoration      : %s", tostring(decorations)))
        -- Region extent
        local ok2, extents = pcall(function() return terrain:GetExtentsSize() end)
        if ok2 then
            U.S_Push(string.format("  ExtentsSize     : %s", tostring(extents)))
        end
    else
        U.S_Push("  Terrain: NOT present")
    end
end)

-- ── Per-child extra info function ─────────────────────────────
local function wsExtra(inst)
    local cls = ""
    pcall(function() cls = inst.ClassName end)

    if U.IsA(inst, "BasePart") then
        local pos, anch, mat, colg, mass = "?","?","?","?","?"
        local size, cf = "?","?"
        pcall(function()
            pos  = tostring(inst.Position)
            anch = tostring(inst.Anchored)
            mat  = tostring(inst.Material)
            colg = tostring(inst.CollisionGroupId)
            mass = string.format("%.3f", inst:GetMass())
            size = tostring(inst.Size)
            cf   = tostring(inst.CFrame)
        end)
        -- Network owner
        local no = "?"
        pcall(function()
            local nok, owner = pcall(function() return inst:GetNetworkOwner() end)
            if nok then
                no = owner and owner.Name or "Server"
                if owner == HL.LocalPlayer then
                    St:Inc("NetworkOwnedParts")
                end
            end
        end)
        St:Inc("BaseParts")
        if U.SafeGet(inst, "Anchored") then
            St:Inc("AnchoredParts")
        else
            St:Inc("UnanchoredParts")
        end
        return string.format(
            " [Pos:%s][Size:%s][Anch:%s][Mat:%s][Mass:%s][NetOwn:%s][CollGrp:%s]",
            pos, size, anch, mat, mass, no, colg)

    elseif cls == "Model" then
        local pivot = "?"
        pcall(function() pivot = tostring(inst:GetPivot().Position) end)
        local desc = U.SafeGet(inst, "PrimaryPart")
        St:Inc("Models")
        return string.format(" [Pivot:%s][Primary:%s]",
            pivot, desc and U.SafeGet(desc,"Name") or "nil")

    elseif cls == "RemoteEvent" then
        St:Inc("RemoteEvents")
        return " ★ REMOTE_EVENT"
    elseif cls == "RemoteFunction" then
        St:Inc("RemoteFunctions")
        return " ★ REMOTE_FUNCTION"
    elseif cls == "UnreliableRemoteEvent" then
        St:Inc("UnreliableRemoteEvents")
        return " ★ UNRELIABLE_REMOTE"
    elseif cls == "BindableEvent" then
        St:Inc("BindableEvents")
        return " ★ BINDABLE_EVENT"
    elseif cls == "BindableFunction" then
        St:Inc("BindableFunctions")
        return " ★ BINDABLE_FUNCTION"
    elseif cls == "ProximityPrompt" then
        St:Inc("ProximityPrompts")
        local at, ot, md, hd, los = "?","?","?","?","?"
        pcall(function()
            at  = inst.ActionText
            ot  = inst.ObjectText
            md  = tostring(inst.MaxActivationDistance)
            hd  = tostring(inst.HoldDuration)
            los = tostring(inst.RequiresLineOfSight)
        end)
        return string.format(" [PP][Action:'%s'][Object:'%s'][MaxDist:%s][Hold:%s][LoS:%s]",
            at, ot, md, hd, los)
    elseif cls == "ClickDetector" then
        St:Inc("ClickDetectors")
        local md = U.SafeGet(inst, "MaxActivationDistance")
        return string.format(" [CD][MaxDist:%s]", tostring(md))
    elseif cls == "Script" then
        St:Inc("Scripts")
        local en = U.SafeGet(inst, "Enabled")
        return string.format(" [Script.Enabled=%s]", tostring(en))
    elseif cls == "LocalScript" then
        St:Inc("LocalScripts")
        local en = U.SafeGet(inst, "Enabled")
        return string.format(" [LocalScript.Enabled=%s]", tostring(en))
    elseif cls == "ModuleScript" then
        St:Inc("ModuleScripts")
        return " [ModuleScript]"
    elseif cls == "Sound" then
        St:Inc("Sounds")
        local sid, vol, pl = "?","?","?"
        pcall(function()
            sid = inst.SoundId
            vol = string.format("%.2f", inst.Volume)
            pl  = tostring(inst.Playing)
        end)
        return string.format(" [Sound][Id:%s][Vol:%s][Playing:%s]", sid, vol, pl)
    elseif cls == "Animation" then
        St:Inc("Animations")
        local aid = U.SafeGet(inst, "AnimationId")
        return string.format(" [Anim:%s]", tostring(aid))
    elseif U.IsA(inst, "Constraint") then
        St:Inc("Constraints")
        return " [Constraint]"
    elseif cls == "WeldConstraint" or cls == "Weld" or cls == "Motor6D" then
        St:Inc("Welds")
        local p0 = U.SafeGet(inst, "Part0")
        local p1 = U.SafeGet(inst, "Part1")
        return string.format(" [%s: %s→%s]", cls,
            p0 and U.SafeGet(p0,"Name") or "nil",
            p1 and U.SafeGet(p1,"Name") or "nil")
    elseif cls == "ParticleEmitter" then
        St:Inc("ParticleEmitters")
        local en = U.SafeGet(inst, "Enabled")
        local rate = U.SafeGet(inst, "Rate")
        return string.format(" [Particles][Enabled:%s][Rate:%s]", tostring(en), tostring(rate))
    elseif cls == "BillboardGui" or cls == "SurfaceGui" then
        local en = U.SafeGet(inst, "Enabled")
        return string.format(" [%s][Enabled:%s]", cls, tostring(en))
    end
    return ""
end

-- ── Full Tree ─────────────────────────────────────────────────
U.S_SubHeader("2.3 Full Workspace Tree (all descendants)")
U.TraverseTree(WS, "  ", 0, function(inst)
    -- (stats tracked inside wsExtra via direct Inc calls)
end, wsExtra)

U.Log("D_Workspace done", "DUMP")
return true
