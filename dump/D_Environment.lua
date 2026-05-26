-- ============================================================
--  dump/D_Environment.lua
--  Lighting, SoundService, StarterGui, StarterPack,
--  StarterPlayerScripts, StarterCharacterScripts,
--  PathfindingService, ContentProvider info
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services

U.S_Header("SECTION 7 — ENVIRONMENT SERVICES (Lighting, Audio, Starter)")

-- ── Lighting ──────────────────────────────────────────────────
U.S_SubHeader("7.1 Lighting Properties")
if S.Lighting then
    pcall(function()
        U.S_Push(string.format("  Ambient         : %s", tostring(S.Lighting.Ambient)))
        U.S_Push(string.format("  OutdoorAmbient  : %s", tostring(S.Lighting.OutdoorAmbient)))
        U.S_Push(string.format("  Brightness      : %.2f", S.Lighting.Brightness))
        U.S_Push(string.format("  ColorShift_Top  : %s", tostring(S.Lighting.ColorShift_Top)))
        U.S_Push(string.format("  ColorShift_Bottom: %s", tostring(S.Lighting.ColorShift_Bottom)))
        U.S_Push(string.format("  FogColor        : %s", tostring(S.Lighting.FogColor)))
        U.S_Push(string.format("  FogEnd          : %.1f", S.Lighting.FogEnd))
        U.S_Push(string.format("  FogStart        : %.1f", S.Lighting.FogStart))
        U.S_Push(string.format("  GeographicLatitude: %.2f", S.Lighting.GeographicLatitude))
        U.S_Push(string.format("  GlobalShadows   : %s", tostring(S.Lighting.GlobalShadows)))
        U.S_Push(string.format("  ShadowSoftness  : %.2f", S.Lighting.ShadowSoftness))
        U.S_Push(string.format("  TimeOfDay       : %s", tostring(S.Lighting.TimeOfDay)))
        U.S_Push(string.format("  ClockTime       : %.2f", S.Lighting.ClockTime))
        U.S_Push(string.format("  ExposureCompensation: %.2f", S.Lighting.ExposureCompensation))
        U.S_Push(string.format("  EnvironmentDiffuseScale: %.2f", S.Lighting.EnvironmentDiffuseScale))
        U.S_Push(string.format("  EnvironmentSpecularScale: %.2f", S.Lighting.EnvironmentSpecularScale))
        U.S_Push(string.format("  TechnologyEnum  : %s", tostring(S.Lighting.Technology)))
    end)

    U.S_SubHeader("7.2 Lighting Children (Atmosphere, Sky, PostEffects, etc.)")
    U.TraverseTree(S.Lighting, "  ", 0, nil, function(inst)
        local cls = ""
        pcall(function() cls = inst.ClassName end)
        if cls == "Atmosphere" then
            local dens, off, haze, glare, decay = "?","?","?","?","?"
            pcall(function()
                dens  = string.format("%.3f", inst.Density)
                off   = string.format("%.3f", inst.Offset)
                haze  = string.format("%.2f", inst.Haze)
                glare = string.format("%.2f", inst.Glare)
                decay = tostring(inst.Decay)
            end)
            return string.format(" [Density:%s][Offset:%s][Haze:%s][Glare:%s][Decay:%s]",
                dens, off, haze, glare, decay)
        elseif cls == "Sky" then
            local top, bot, front, back, left, right = "?","?","?","?","?","?"
            pcall(function()
                top   = inst.SkyboxBk or "?"
                bot   = inst.SkyboxDn or "?"
            end)
            return string.format(" [Sky BK:%s BT:%s]", tostring(top), tostring(bot))
        elseif cls == "BloomEffect" then
            local sz, int, thr = "?","?","?"
            pcall(function()
                sz  = string.format("%.2f", inst.Size)
                int = string.format("%.2f", inst.Intensity)
                thr = string.format("%.2f", inst.Threshold)
            end)
            return string.format(" [Bloom Size:%s Int:%s Thr:%s]", sz, int, thr)
        elseif cls == "DepthOfFieldEffect" then
            local fn, fd, ni, fo = "?","?","?","?"
            pcall(function()
                fn = string.format("%.2f", inst.FocusDistance)
                fd = tostring(inst.FarIntensity)
                ni = tostring(inst.NearIntensity)
                fo = string.format("%.0f", inst.InFocusRadius)
            end)
            return string.format(" [DoF Focus:%s Far:%s Near:%s Radius:%s]", fn, fd, ni, fo)
        elseif cls == "ColorCorrectionEffect" then
            local br, cn, sat, tint = "?","?","?","?"
            pcall(function()
                br   = string.format("%.3f", inst.Brightness)
                cn   = string.format("%.3f", inst.Contrast)
                sat  = string.format("%.3f", inst.Saturation)
                tint = tostring(inst.TintColor)
            end)
            return string.format(" [ColorCorrect Br:%s Con:%s Sat:%s Tint:%s]", br, cn, sat, tint)
        elseif cls == "SunRaysEffect" then
            local int, spread = "?","?"
            pcall(function()
                int    = string.format("%.3f", inst.Intensity)
                spread = string.format("%.3f", inst.Spread)
            end)
            return string.format(" [SunRays Int:%s Spread:%s]", int, spread)
        end
        return ""
    end)
else
    U.S_Push("  [!] Lighting not accessible.")
end

-- ── SoundService ──────────────────────────────────────────────
U.S_SubHeader("7.3 SoundService Properties & Children")
if S.SoundService then
    pcall(function()
        U.S_Push(string.format("  AmbientReverb    : %s", tostring(S.SoundService.AmbientReverb)))
        U.S_Push(string.format("  DistanceFactor   : %.4f", S.SoundService.DistanceFactor))
        U.S_Push(string.format("  DopplerScale     : %.4f", S.SoundService.DopplerScale))
        U.S_Push(string.format("  RolloffScale     : %.4f", S.SoundService.RolloffScale))
        U.S_Push(string.format("  VolumetricAudio  : %s", tostring(S.SoundService.VolumetricAudio)))
        U.S_Push(string.format("  RespectFilteringEnabled: %s", tostring(S.SoundService.RespectFilteringEnabled)))
    end)
    U.TraverseTree(S.SoundService, "  ", 0, nil, function(inst)
        local cls = ""
        pcall(function() cls = inst.ClassName end)
        if cls == "Sound" then
            local sid, vol, pl = "?","?","?"
            pcall(function()
                sid = inst.SoundId
                vol = string.format("%.2f", inst.Volume)
                pl  = tostring(inst.Playing)
            end)
            return string.format(" [Id:%s Vol:%s Playing:%s]", sid, vol, pl)
        elseif cls == "SoundGroup" then
            local vol = U.SafeGet(inst, "Volume")
            return string.format(" [Group Vol:%.2f]", tonumber(vol) or 0)
        end
        return ""
    end)
else
    U.S_Push("  [!] SoundService not accessible.")
end

-- ── StarterGui ────────────────────────────────────────────────
U.S_SubHeader("7.4 StarterGui — Tree")
if S.StarterGui then
    pcall(function()
        U.S_Push(string.format("  ShowDevelopmentGui   : %s", tostring(S.StarterGui.ShowDevelopmentGui)))
        U.S_Push(string.format("  ResetPlayerGuiOnSpawn: %s", tostring(S.StarterGui.ResetPlayerGuiOnSpawn)))
        U.S_Push(string.format("  ScreenOrientation    : %s", tostring(S.StarterGui.ScreenOrientation)))
    end)
    U.TraverseTree(S.StarterGui, "  ", 0, nil, nil)
else
    U.S_Push("  [!] StarterGui not accessible.")
end

-- ── StarterPack ───────────────────────────────────────────────
U.S_SubHeader("7.5 StarterPack — Tree")
if S.StarterPack then
    U.TraverseTree(S.StarterPack, "  ", 0, nil, nil)
else
    U.S_Push("  [!] StarterPack not accessible.")
end

-- ── StarterPlayer ─────────────────────────────────────────────
U.S_SubHeader("7.6 StarterPlayer — Properties & Scripts")
if S.StarterPlayer then
    pcall(function()
        U.S_Push(string.format("  CameraMaxZoomDistance  : %.1f", S.StarterPlayer.CameraMaxZoomDistance))
        U.S_Push(string.format("  CameraMinZoomDistance  : %.1f", S.StarterPlayer.CameraMinZoomDistance))
        U.S_Push(string.format("  CameraMode             : %s", tostring(S.StarterPlayer.CameraMode)))
        U.S_Push(string.format("  CharacterJumpHeight    : %.2f", S.StarterPlayer.CharacterJumpHeight))
        U.S_Push(string.format("  CharacterJumpPower     : %.2f", S.StarterPlayer.CharacterJumpPower))
        U.S_Push(string.format("  CharacterMaxSlopeAngle : %.2f", S.StarterPlayer.CharacterMaxSlopeAngle))
        U.S_Push(string.format("  CharacterWalkSpeed     : %.2f", S.StarterPlayer.CharacterWalkSpeed))
        U.S_Push(string.format("  DevCameraOcclusionMode : %s", tostring(S.StarterPlayer.DevCameraOcclusionMode)))
        U.S_Push(string.format("  DevComputerCameraMode  : %s", tostring(S.StarterPlayer.DevComputerCameraMode)))
        U.S_Push(string.format("  DevComputerMovementMode: %s", tostring(S.StarterPlayer.DevComputerMovementMode)))
        U.S_Push(string.format("  DevEnableMouseLock     : %s", tostring(S.StarterPlayer.DevEnableMouseLock)))
        U.S_Push(string.format("  DevTouchMovementMode   : %s", tostring(S.StarterPlayer.DevTouchMovementMode)))
        U.S_Push(string.format("  EnableMouseLockOption  : %s", tostring(S.StarterPlayer.EnableMouseLockOption)))
        U.S_Push(string.format("  HealthDisplayDistance  : %.1f", S.StarterPlayer.HealthDisplayDistance))
        U.S_Push(string.format("  NameDisplayDistance    : %.1f", S.StarterPlayer.NameDisplayDistance))
    end)

    -- StarterPlayerScripts & StarterCharacterScripts trees
    local sp = S.StarterPlayer:FindFirstChild("StarterPlayerScripts")
    if sp then
        U.S_SubHeader("  StarterPlayerScripts:")
        U.TraverseTree(sp, "    ", 0, nil, nil)
    end
    local sc = S.StarterPlayer:FindFirstChild("StarterCharacterScripts")
    if sc then
        U.S_SubHeader("  StarterCharacterScripts:")
        U.TraverseTree(sc, "    ", 0, nil, nil)
    end
else
    U.S_Push("  [!] StarterPlayer not accessible.")
end

-- ── ContentProvider ───────────────────────────────────────────
U.S_SubHeader("7.7 ContentProvider Info")
if S.ContentProvider then
    pcall(function()
        U.S_Push(string.format("  BaseUrl              : %s", tostring(S.ContentProvider.BaseUrl)))
        U.S_Push(string.format("  RequestQueueSize     : %d", S.ContentProvider.RequestQueueSize))
    end)
else
    U.S_Push("  ContentProvider not available.")
end

U.Log("D_Environment done", "DUMP")
return true
