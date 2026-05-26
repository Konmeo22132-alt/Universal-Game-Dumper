-- ============================================================
--  hooks/H_WorkspaceSpy.lua
--  Workspace monitor: new objects, removed objects,
--  NPC detection, projectile tracking
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services

U.Log("Setting up Workspace Spy...", "HOOK")

if not S.Workspace then return end

local interestingClasses = {
    RemoteEvent=true, RemoteFunction=true, UnreliableRemoteEvent=true,
    BindableEvent=true, BindableFunction=true,
    LocalScript=true, Script=true, ModuleScript=true,
    ProximityPrompt=true, ClickDetector=true,
    Model=true, BasePart=true, Part=true, MeshPart=true,
    Tool=true, HopperBin=true,
    SpecialMesh=true, Sound=true,
}

-- Top-level ChildAdded
S.Workspace.ChildAdded:Connect(function(child)
    pcall(function()
        local cls  = child.ClassName
        local name = child.Name
        U.LogRT("WS_ADD", U.GetPath(child), string.format("<%s>", cls))

        -- If it's a Model with Humanoid → new NPC or player character
        if cls == "Model" then
            local hum = child:FindFirstChildOfClass("Humanoid")
            if hum then
                local hp = U.SafeGet(hum, "Health")
                local maxhp = U.SafeGet(hum, "MaxHealth")
                U.LogRT("NPC_SPAWN", U.GetPath(child),
                    string.format("HP=%.0f/%.0f", tonumber(hp) or 0, tonumber(maxhp) or 0))
                -- Hook NPC Died
                hum.Died:Connect(function()
                    U.LogRT("NPC_DIED", U.GetPath(child), string.format("Name=%s", name))
                end)
            end
        end

        -- If it's a part with very high velocity (projectile?)
        if child:IsA and child:IsA("BasePart") then
            local vel = U.SafeGet(child, "Velocity")
            if vel and vel.Magnitude > 50 then
                U.LogRT("PROJECTILE?", U.GetPath(child),
                    string.format("Speed=%.1f", vel.Magnitude))
            end
        end
    end)
end)

S.Workspace.ChildRemoved:Connect(function(child)
    pcall(function()
        local cls = child.ClassName
        U.LogRT("WS_REMOVE", U.GetPath(child), string.format("<%s>", cls))
    end)
end)

-- ── Descendant scan for new scripts inside workspace ──────────
S.Workspace.DescendantAdded:Connect(function(child)
    pcall(function()
        local cls = child.ClassName
        if cls == "LocalScript" or cls == "Script" or cls == "ModuleScript" then
            U.LogRT("SCRIPT_INJECT", U.GetPath(child),
                string.format("<%s> Enabled=%s", cls, tostring(U.SafeGet(child, "Enabled"))))
        elseif cls == "RemoteEvent" or cls == "RemoteFunction" or cls == "UnreliableRemoteEvent" then
            U.LogRT("REMOTE_APPEAR", U.GetPath(child),
                string.format("<%s> ⚠ Remote appeared in Workspace!", cls))
        end
    end)
end)

U.Log("Workspace Spy active ✓", "SUCCESS")
return true
