-- ============================================================
--  dump/D_Physics.lua
--  BasePart physics analysis, network ownership map,
--  unanchored parts, constraints, pathfinding agents
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local St = HL.Stats
local LP = HL.LocalPlayer

U.S_Header("SECTION 10 — PHYSICS & NETWORK OWNERSHIP")

-- ── Network Ownership Map ─────────────────────────────────────
U.S_SubHeader("10.1 Network Ownership of All BaseParts")
local allWS = {}
pcall(function() allWS = S.Workspace:GetDescendants() end)

local ownedByClient = {}
local ownedByServer = {}
local ownedByOther  = {}
local anchored      = {}
local unanchored    = {}

for _, inst in ipairs(allWS) do
    pcall(function()
        if not inst:IsA("BasePart") then return end
        St:Inc("BaseParts")

        if inst.Anchored then
            St:Inc("AnchoredParts")
            table.insert(anchored, inst)
        else
            St:Inc("UnanchoredParts")
            table.insert(unanchored, inst)
        end

        -- Network owner
        local nok, owner = pcall(function() return inst:GetNetworkOwner() end)
        if nok then
            if owner == nil then
                -- nil = server owns (no automatic ownership)
                table.insert(ownedByServer, inst)
            elseif owner == LP then
                table.insert(ownedByClient, inst)
                St:Inc("NetworkOwnedParts")
            else
                table.insert(ownedByOther, {part=inst, owner=owner})
            end
        end
    end)
end

U.S_Push(string.format("  Total BaseParts      : %d", St.BaseParts))
U.S_Push(string.format("  Anchored             : %d", St.AnchoredParts))
U.S_Push(string.format("  Unanchored           : %d", St.UnanchoredParts))
U.S_Push(string.format("  Network → You (client): %d", #ownedByClient))
U.S_Push(string.format("  Network → Server      : %d", #ownedByServer))
U.S_Push(string.format("  Network → Other player: %d", #ownedByOther))

-- List client-owned parts (most exploitable)
U.S_SubHeader("10.2 Client-Network-Owned Parts (You control physics)")
if #ownedByClient == 0 then
    U.S_Push("  [None — you don't own any parts]")
else
    U.S_Push(string.format("  ⚠ You network-own %d part(s):", #ownedByClient))
    for _, part in ipairs(ownedByClient) do
        pcall(function()
            U.S_Push(string.format("  -> %s | Anchored:%s | Mass:%.3f | Vel:%s",
                U.GetPath(part), tostring(part.Anchored),
                part:GetMass(), tostring(part.Velocity)))
        end)
    end
end

-- Other players' owned parts
U.S_SubHeader("10.3 Parts Owned by Other Players")
for _, entry in ipairs(ownedByOther) do
    pcall(function()
        U.S_Push(string.format("  -> %s owned by %s",
            U.GetPath(entry.part), entry.owner and entry.owner.Name or "?"))
    end)
end

-- ── Unanchored High-Velocity Parts ────────────────────────────
U.S_SubHeader("10.4 Fast-Moving Unanchored Parts (Velocity > 10)")
local fastParts = 0
for _, part in ipairs(unanchored) do
    pcall(function()
        local vel = part.Velocity
        local speed = vel.Magnitude
        if speed > 10 then
            fastParts = fastParts + 1
            U.S_Push(string.format("  -> %s | Speed:%.1f | Vel:%s | Mass:%.3f",
                U.GetPath(part), speed, tostring(vel), part:GetMass()))
        end
    end)
end
if fastParts == 0 then U.S_Push("  [None at this moment]") end

-- ── All Constraints ───────────────────────────────────────────
U.S_SubHeader("10.5 All Constraints in Workspace")
local constraintClasses = {
    "HingeConstraint", "SliderConstraint", "BallSocketConstraint",
    "CylindricalConstraint", "PrismaticConstraint", "RopeConstraint",
    "RodConstraint", "SpringConstraint", "TorsionSpringConstraint",
    "UniversalConstraint", "WeldConstraint", "NoCollisionConstraint",
    "LinearVelocity", "AngularVelocity", "LineForce", "Torque",
    "VectorForce", "BodyVelocity", "BodyAngularVelocity", "BodyForce",
    "BodyPosition", "BodyGyro",
}
local constraintCls = {}
for _, c in ipairs(constraintClasses) do constraintCls[c] = true end

local constraintsFound = 0
for _, inst in ipairs(allWS) do
    pcall(function()
        if constraintCls[inst.ClassName] then
            constraintsFound = constraintsFound + 1
            local p0 = U.SafeGet(inst, "Attachment0")
            local p1 = U.SafeGet(inst, "Attachment1")
            U.S_Push(string.format("  [%s] %s | Att0=%s | Att1=%s",
                inst.ClassName, U.GetPath(inst),
                p0 and U.GetPath(p0) or "nil",
                p1 and U.GetPath(p1) or "nil"))
            St:Inc("Constraints")
        end
    end)
end
U.S_Push(string.format("  Total constraints: %d", constraintsFound))

-- ── Touched Parts (Sensor) ────────────────────────────────────
U.S_SubHeader("10.6 Touched / CanTouch Parts with Connections")
if getconnections then
    local touchedCount = 0
    for _, inst in ipairs(allWS) do
        pcall(function()
            if inst:IsA("BasePart") then
                local conns = getconnections(inst.Touched)
                if #conns > 0 then
                    touchedCount = touchedCount + 1
                    U.S_Push(string.format("  -> %s | Touch connections: %d",
                        U.GetPath(inst), #conns))
                end
            end
        end)
    end
    if touchedCount == 0 then U.S_Push("  [None found]") end
else
    U.S_Push("  [getconnections not available, skipping]")
end

-- ── CanCollide=false Parts (potential wallhacks / speed paths) ──
U.S_SubHeader("10.7 CanCollide=false Parts (potential exploitable geometry)")
local noCollide = 0
for _, inst in ipairs(allWS) do
    pcall(function()
        if inst:IsA("BasePart") and not inst.CanCollide then
            noCollide = noCollide + 1
            if noCollide <= 50 then -- limit output
                U.S_Push(string.format("  -> %s | Size:%s | Anchored:%s",
                    U.GetPath(inst), tostring(inst.Size), tostring(inst.Anchored)))
            end
        end
    end)
end
U.S_Push(string.format("  Total CanCollide=false: %d", noCollide))

-- ── CanQuery=false Parts ──────────────────────────────────────
U.S_SubHeader("10.8 CanQuery=false Parts (invisible to raycasts)")
local noQuery = 0
for _, inst in ipairs(allWS) do
    pcall(function()
        if inst:IsA("BasePart") then
            local cq = U.SafeGet(inst, "CanQuery")
            if cq == false then
                noQuery = noQuery + 1
                if noQuery <= 30 then
                    U.S_Push(string.format("  -> %s | Transparency:%.2f | Anchored:%s",
                        U.GetPath(inst),
                        tonumber(U.SafeGet(inst,"Transparency")) or 0,
                        tostring(inst.Anchored)))
                end
            end
        end
    end)
end
U.S_Push(string.format("  Total CanQuery=false: %d", noQuery))

-- ── Invisible Parts (Transparency = 1) ───────────────────────
U.S_SubHeader("10.9 Fully Transparent Parts (Transparency=1, potential hidden objects)")
local invisible = 0
for _, inst in ipairs(allWS) do
    pcall(function()
        if inst:IsA("BasePart") and inst.Transparency >= 1 then
            invisible = invisible + 1
            if invisible <= 50 then
                U.S_Push(string.format("  -> %s | Size:%s | CanCollide:%s",
                    U.GetPath(inst), tostring(inst.Size), tostring(inst.CanCollide)))
            end
        end
    end)
end
U.S_Push(string.format("  Total fully transparent: %d", invisible))

U.Log("D_Physics done", "DUMP")
return true
