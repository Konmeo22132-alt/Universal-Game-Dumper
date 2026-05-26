-- ============================================================
--  dump/D_Player.lua
--  Full LocalPlayer info: character tree, humanoid, tools,
--  team, userId, stats, clothing, accessories, motors
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local St = HL.Stats
local LP = HL.LocalPlayer

U.S_Header("SECTION 1 — LOCAL PLAYER INFO")

if not LP then
    U.S_Push("  [!] No LocalPlayer found.")
    return
end

-- ── Basic Identity ────────────────────────────────────────────
U.S_SubHeader("1.1 Identity")
pcall(function()
    U.S_Push(string.format("  Name          : %s",  LP.Name))
    U.S_Push(string.format("  DisplayName   : %s",  LP.DisplayName))
    U.S_Push(string.format("  UserId        : %d",  LP.UserId))
    U.S_Push(string.format("  AccountAge    : %d days", LP.AccountAge))

    local ok1, team = pcall(function() return LP.Team and LP.Team.Name or "None" end)
    U.S_Push(string.format("  Team          : %s", ok1 and team or "?"))

    local ok2, teamColor = pcall(function() return tostring(LP.TeamColor) end)
    U.S_Push(string.format("  TeamColor     : %s", ok2 and teamColor or "?"))

    local ok3, ns = pcall(function() return tostring(LP.Neutral) end)
    U.S_Push(string.format("  Neutral       : %s", ok3 and ns or "?"))

    local ok4, fc = pcall(function() return LP.FollowUserId end)
    U.S_Push(string.format("  FollowUserId  : %s", ok4 and tostring(fc) or "?"))

    local ok5, rf = pcall(function() return LP.ReplicationFocus end)
    U.S_Push(string.format("  ReplicationFocus: %s", ok5 and U.GetPath(rf) or "nil"))

    U.S_Push(string.format("  MembershipType: %s", tostring(LP.MembershipType)))
    U.S_Push(string.format("  GamepadEnabled: %s", tostring(LP.GamepadEnabled)))
    U.S_Push(string.format("  HasVerifiedBadge: %s", tostring(LP.HasVerifiedBadge)))
end)

-- ── Humanoid (Character) ──────────────────────────────────────
U.S_SubHeader("1.2 Character & Humanoid")
local char = LP.Character
if char then
    pcall(function()
        U.S_Push("  Character Name: " .. char.Name)
        U.S_Push("  Character Path: " .. U.GetPath(char))
        U.S_Push(U.S_Push and "" or "")   -- spacer

        -- Humanoid
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            U.S_Push(string.format("  Health          : %.1f / %.1f", hum.Health, hum.MaxHealth))
            U.S_Push(string.format("  WalkSpeed       : %.2f", hum.WalkSpeed))
            U.S_Push(string.format("  JumpPower       : %.2f", hum.JumpPower))
            U.S_Push(string.format("  JumpHeight      : %.2f", hum.JumpHeight))
            U.S_Push(string.format("  HipHeight       : %.2f", hum.HipHeight))
            U.S_Push(string.format("  AutoJumpEnabled : %s",   tostring(hum.AutoJumpEnabled)))
            U.S_Push(string.format("  AutoRotate      : %s",   tostring(hum.AutoRotate)))
            U.S_Push(string.format("  PlatformStand   : %s",   tostring(hum.PlatformStand)))
            U.S_Push(string.format("  Sit             : %s",   tostring(hum.Sit)))
            U.S_Push(string.format("  RigType         : %s",   tostring(hum.RigType)))
            U.S_Push(string.format("  DisplayName     : %s",   tostring(hum.DisplayName)))
            U.S_Push(string.format("  NameDisplayDistance: %s", tostring(hum.NameDisplayDistance)))
            U.S_Push(string.format("  HealthDisplayType : %s", tostring(hum.HealthDisplayType)))
            U.S_Push(string.format("  FloorMaterial   : %s",   tostring(hum.FloorMaterial)))
            U.S_Push(string.format("  MoveDirection   : %s",   tostring(hum.MoveDirection)))
            U.S_Push(string.format("  CameraOffset    : %s",   tostring(hum.CameraOffset)))
            U.S_Push(string.format("  State (current) : %s",   tostring(hum:GetState())))
            -- Humanoid states supported
            local stateList = {}
            for _, st in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                if st ~= Enum.HumanoidStateType.None then
                    local ok2, enabled = pcall(function() return hum:GetStateEnabled(st) end)
                    if ok2 and enabled then
                        table.insert(stateList, tostring(st.Name))
                    end
                end
            end
            U.S_Push("  Enabled States  : " .. table.concat(stateList, ", "))
        else
            U.S_Push("  [!] No Humanoid found in character")
        end

        -- HumanoidRootPart
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            U.S_Push(string.format("  HRP.CFrame      : %s", tostring(hrp.CFrame)))
            U.S_Push(string.format("  HRP.Position    : %s", tostring(hrp.Position)))
            U.S_Push(string.format("  HRP.Velocity    : %s", tostring(hrp.Velocity)))
            U.S_Push(string.format("  HRP.RotVelocity : %s", tostring(hrp.RotVelocity)))
            U.S_Push(string.format("  HRP.Mass        : %.4f", hrp:GetMass()))
            U.S_Push(string.format("  HRP.NetworkOwnership: %s", tostring(pcall(function() return hrp:GetNetworkOwner() end))))
        end
    end)

    -- ── Character Full Tree ────────────────────────────────────
    U.S_SubHeader("1.3 Character Full Tree")
    U.TraverseTree(char, "  ", 0, function(inst)
        St:Track(inst)
    end, function(inst)
        -- Extra info for accessories, tools, welds, scripts in char
        local cls = ""
        pcall(function() cls = inst.ClassName end)
        if cls == "Accessory" then
            local h = U.SafeGet(inst, "Handle")
            return h and " [Accessory Handle]" or ""
        elseif cls == "Motor6D" then
            local p0 = U.SafeGet(inst, "Part0")
            local p1 = U.SafeGet(inst, "Part1")
            local n0 = p0 and U.SafeGet(p0, "Name") or "nil"
            local n1 = p1 and U.SafeGet(p1, "Name") or "nil"
            return string.format(" [Motor6D: %s → %s]", tostring(n0), tostring(n1))
        elseif cls == "WeldConstraint" then
            local p0 = U.SafeGet(inst, "Part0")
            local p1 = U.SafeGet(inst, "Part1")
            return string.format(" [Weld: %s → %s]",
                p0 and U.SafeGet(p0,"Name") or "nil",
                p1 and U.SafeGet(p1,"Name") or "nil")
        elseif cls == "Script" or cls == "LocalScript" or cls == "ModuleScript" then
            local enabled = U.SafeGet(inst, "Enabled")
            return string.format(" [Script.Enabled=%s]", tostring(enabled))
        end
        return ""
    end)

    -- ── Accessories ────────────────────────────────────────────
    U.S_SubHeader("1.4 Accessories & Clothing")
    pcall(function()
        local desc = char:FindFirstChildOfClass("HumanoidDescription")
        if desc then
            U.S_Push("  HumanoidDescription found:")
            local props = {
                "HatAccessory","HairAccessory","FaceAccessory","NeckAccessory",
                "ShouldersAccessory","FrontAccessory","BackAccessory","WaistAccessory",
                "Shirt","Pants","GraphicTShirt","Face","Head","LeftArm","RightArm",
                "LeftLeg","RightLeg","Torso","ClimbAnimation","FallAnimation",
                "IdleAnimation","JumpAnimation","RunAnimation","SwimAnimation","WalkAnimation"
            }
            for _, prop in ipairs(props) do
                local ok2, val = pcall(function() return desc[prop] end)
                if ok2 and val then
                    U.S_Push(string.format("    %s = %s", prop, tostring(val)))
                end
            end
        end
        local acc = {}
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Accessory") then
                table.insert(acc, child.Name)
            end
        end
        U.S_Push("  Accessories (" .. #acc .. "): " .. table.concat(acc, ", "))
    end)

    -- ── AnimationTracks ────────────────────────────────────────
    U.S_SubHeader("1.5 Playing Animation Tracks")
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                local tracks = animator:GetPlayingAnimationTracks()
                if #tracks == 0 then
                    U.S_Push("  [None playing]")
                end
                for _, track in ipairs(tracks) do
                    U.S_Push(string.format("  Track: %s | AnimId: %s | Speed: %.2f | Weight: %.2f | TimePos: %.3f | Looped: %s",
                        track.Name,
                        tostring(track.Animation and track.Animation.AnimationId or "?"),
                        track.Speed,
                        track.WeightCurrent,
                        track.TimePosition,
                        tostring(track.Looped)))
                    St:Inc("AnimationTracks")
                end
            end
        end
    end)
else
    U.S_Push("  [!] Character not loaded yet.")
end

-- ── Backpack ──────────────────────────────────────────────────
U.S_SubHeader("1.6 Backpack & Tools")
pcall(function()
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        local tools = bp:GetChildren()
        U.S_Push(string.format("  %d item(s) in Backpack:", #tools))
        for _, t in ipairs(tools) do
            local isT = U.IsA(t, "Tool")
            local grip, handle = "", ""
            if isT then
                pcall(function() grip = tostring(t.GripPos) end)
                pcall(function()
                    local h = t:FindFirstChild("Handle")
                    handle = h and "HasHandle" or "NoHandle"
                end)
            end
            U.S_Push(string.format("  -> %s <%s> %s %s %s",
                t.Name, t.ClassName,
                isT and ("GripPos:" .. grip) or "",
                isT and handle or "",
                U.DumpAttrs(t)))
        end
    else
        U.S_Push("  [!] No Backpack found.")
    end
end)

-- ── PlayerScripts ─────────────────────────────────────────────
U.S_SubHeader("1.7 PlayerScripts Tree")
pcall(function()
    local ps = LP:FindFirstChild("PlayerScripts")
    if ps then
        U.TraverseTree(ps, "  ", 0, nil, nil)
    else
        U.S_Push("  [!] No PlayerScripts found.")
    end
end)

U.Log("D_Player done", "DUMP")

return true
