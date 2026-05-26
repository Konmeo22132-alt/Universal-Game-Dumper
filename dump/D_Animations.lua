-- ============================================================
--  dump/D_Animations.lua
--  All animation tracks in game, AnimationController,
--  AnimationClip info, animator discovery
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local St = HL.Stats
local LP = HL.LocalPlayer

U.S_Header("SECTION 13 — ANIMATIONS & ANIMATORS")

local allWS  = {}
local allPlayers = {}
pcall(function() allWS      = S.Workspace:GetDescendants() end)
pcall(function() allPlayers = S.Players:GetPlayers() end)

-- ── Scan all Animators in Workspace ───────────────────────────
U.S_SubHeader("13.1 All Animators in Workspace")
local animators = {}
for _, inst in ipairs(allWS) do
    pcall(function()
        if inst.ClassName == "Animator" then
            table.insert(animators, inst)
        end
    end)
end

U.S_Push(string.format("  Total Animators found: %d", #animators))

for _, anim in ipairs(animators) do
    pcall(function()
        local path = U.GetPath(anim)
        local tracks = anim:GetPlayingAnimationTracks()
        U.S_Push(string.format("  [Animator] %s | Playing tracks: %d", path, #tracks))
        for _, track in ipairs(tracks) do
            pcall(function()
                local animId = track.Animation and track.Animation.AnimationId or "?"
                U.S_Push(string.format("    -> Track: '%s' | AnimId: %s | Speed: %.2f"
                    .. " | Weight: %.2f | TimePos: %.3f | Length: %.3f | Looped: %s | Priority: %s",
                    track.Name, animId,
                    track.Speed, track.WeightCurrent, track.TimePosition,
                    track.Length, tostring(track.Looped), tostring(track.Priority)))
                St:Inc("AnimationTracks")
            end)
        end
    end)
end

-- ── Per-Player Animation State ────────────────────────────────
U.S_SubHeader("13.2 Per-Player Animation State")
for _, plr in ipairs(allPlayers) do
    pcall(function()
        local char = plr.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end

        local tracks = animator:GetPlayingAnimationTracks()
        U.S_Push(string.format("  Player: %s | Playing: %d track(s)", plr.Name, #tracks))
        for _, track in ipairs(tracks) do
            pcall(function()
                local animId = track.Animation and track.Animation.AnimationId or "?"
                U.S_Push(string.format("    Track: '%s' | Id: %s | Speed: %.2f | TimePos: %.3f | Looped: %s",
                    track.Name, animId, track.Speed, track.TimePosition, tostring(track.Looped)))
            end)
        end
    end)
end

-- ── AnimationClipProvider ─────────────────────────────────────
U.S_SubHeader("13.3 AnimationClipProvider")
if S.AnimationClipProvider then
    U.S_Push("  AnimationClipProvider is accessible.")
    -- List children if any
    local ok, kids = pcall(function() return S.AnimationClipProvider:GetChildren() end)
    if ok and #kids > 0 then
        for _, child in ipairs(kids) do
            pcall(function()
                U.S_Push(string.format("  -> [%s] %s", child.ClassName, child.Name))
            end)
        end
    else
        U.S_Push("  [No children in AnimationClipProvider]")
    end
else
    U.S_Push("  AnimationClipProvider not accessible.")
end

-- ── All Animation instances in game ───────────────────────────
U.S_SubHeader("13.4 All Animation Objects in Game (flat list)")
local allGame = {}
pcall(function() allGame = game:GetDescendants() end)
local animCount = 0
for _, inst in ipairs(allGame) do
    pcall(function()
        if inst.ClassName == "Animation" then
            animCount = animCount + 1
            local aid = U.SafeGet(inst, "AnimationId") or "?"
            local parent = inst.Parent
            local pname = parent and parent.Name or "?"
            U.S_Push(string.format("  [Animation] %s | Id: %s | Parent: %s",
                U.GetPath(inst), tostring(aid), pname))
            St:Inc("Animations")
        end
    end)
end
U.S_Push(string.format("  Total Animation objects: %d", animCount))

-- ── AnimationController (NPC usage) ───────────────────────────
U.S_SubHeader("13.5 AnimationControllers (NPC / Non-Humanoid)")
local animCtrlCount = 0
for _, inst in ipairs(allGame) do
    pcall(function()
        if inst.ClassName == "AnimationController" then
            animCtrlCount = animCtrlCount + 1
            local path   = U.GetPath(inst)
            local animtr = inst:FindFirstChildOfClass("Animator")
            local tracks = animtr and animtr:GetPlayingAnimationTracks() or {}
            U.S_Push(string.format("  [AnimController] %s | Playing: %d", path, #tracks))
            for _, track in ipairs(tracks) do
                pcall(function()
                    U.S_Push(string.format("    -> '%s' | Id: %s | Speed: %.2f",
                        track.Name,
                        track.Animation and track.Animation.AnimationId or "?",
                        track.Speed))
                end)
            end
        end
    end)
end
U.S_Push(string.format("  Total AnimationControllers: %d", animCtrlCount))

U.Log("D_Animations done", "DUMP")
return true
