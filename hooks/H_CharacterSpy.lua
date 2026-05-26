-- ============================================================
--  hooks/H_CharacterSpy.lua
--  Character lifecycle events, humanoid monitoring,
--  seat/tool tracking, damage detection
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local LP = HL.LocalPlayer

U.Log("Setting up Character Spy...", "HOOK")

if not LP then return end

-- ── Hook a character ─────────────────────────────────────────
local function AttachCharacter(char)
    U.LogRT("CHAR_SPAWN", U.GetPath(char),
        string.format("Name=%s", char.Name))

    -- Child tracking
    char.ChildAdded:Connect(function(child)
        U.LogRT("CHAR_CHILD_ADD", U.GetPath(child),
            string.format("<%s>", child.ClassName))
    end)
    char.ChildRemoved:Connect(function(child)
        U.LogRT("CHAR_CHILD_REM", U.GetPath(child),
            string.format("<%s>", child.ClassName))
    end)

    -- Humanoid
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        local lastHP = hum.Health

        hum.Died:Connect(function()
            U.LogRT("HUM_DIED", "Humanoid", string.format("HP at death: %.1f", hum.Health))
        end)

        hum.StateChanged:Connect(function(old, new)
            U.LogRT("HUM_STATE", "Humanoid",
                string.format("%s → %s", tostring(old), tostring(new)))
        end)

        hum.HealthChanged:Connect(function(hp)
            local delta = hp - lastHP
            local tag = delta < 0 and "DAMAGE" or "HEAL"
            U.LogRT(string.format("HUM_%s", tag), "Humanoid",
                string.format("HP: %.1f → %.1f (delta: %.1f)", lastHP, hp, delta))
            lastHP = hp
        end)

        local wasRunning = false
        hum.Running:Connect(function(speed)
            local isRunning = speed > 0.1
            if isRunning ~= wasRunning then
                wasRunning = isRunning
                U.LogRT("HUM_RUN", "Humanoid", isRunning and string.format("Started running (Speed=%.2f)", speed) or "Stopped running")
            end
        end)

        hum.Jumping:Connect(function(active)
            if active then U.LogRT("HUM_JUMP", "Humanoid", "") end
        end)

        hum.FreeFalling:Connect(function(active)
            if active then U.LogRT("HUM_FALL", "Humanoid", "") end
        end)

        hum.Swimming:Connect(function(speed)
            if speed > 0 then
                U.LogRT("HUM_SWIM", "Humanoid", string.format("Speed=%.2f", speed))
            end
        end)

        hum.Climbing:Connect(function(speed)
            if speed ~= 0 then
                U.LogRT("HUM_CLIMB", "Humanoid", string.format("Speed=%.2f", speed))
            end
        end)

        hum.Seated:Connect(function(active, seat)
            local seatPath = seat and U.GetPath(seat) or "nil"
            U.LogRT("HUM_SEATED", "Humanoid",
                string.format("Active=%s Seat=%s", tostring(active), seatPath))
        end)

        hum.PlatformStanding:Connect(function(active)
            U.LogRT("HUM_PLATSTAND", "Humanoid", tostring(active))
        end)

        -- Tool equip tracking
        hum.EquippedChanged:Connect(function(tool)
            if tool then
                U.LogRT("TOOL_EQUIP", U.GetPath(tool), string.format("Name=%s", tool.Name))
            else
                U.LogRT("TOOL_UNEQUIP", "Humanoid", "")
            end
        end)

        -- TouchedPart
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Touched:Connect(function(part)
                -- Only log "interesting" touches (not your own body parts)
                if part and part.Parent ~= char then
                    local pname = part.Parent and part.Parent.Name or "?"
                    U.LogRT("HRP_TOUCH", U.GetPath(part),
                        string.format("ParentModel=%s", pname))
                end
            end)
        end
    end
end

-- Attach to existing character
if LP.Character then
    pcall(function() AttachCharacter(LP.Character) end)
end

-- Attach to future characters (respawn)
LP.CharacterAdded:Connect(function(char)
    AttachCharacter(char)
end)

LP.CharacterRemoving:Connect(function(char)
    U.LogRT("CHAR_REMOVE", U.GetPath(char), "Character despawned")
end)

-- ── Other players' characters (for tracking enemy actions) ────
for _, plr in ipairs(S.Players:GetPlayers()) do
    if plr ~= LP then
        pcall(function()
            if plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Died:Connect(function()
                        U.LogRT("OTHER_DIED", plr.Name, "")
                    end)
                    hum.HealthChanged:Connect(function(hp)
                        U.LogRT("OTHER_HP", plr.Name, string.format("HP=%.1f", hp))
                    end)
                end
            end
        end)
    end
end

S.Players.PlayerAdded:Connect(function(plr)
    U.LogRT("PLAYER_JOIN", plr.Name, string.format("Id=%d", plr.UserId))
end)

S.Players.PlayerRemoving:Connect(function(plr)
    U.LogRT("PLAYER_LEAVE", plr.Name, string.format("Id=%d", plr.UserId))
end)

U.Log("Character Spy active ✓", "SUCCESS")
return true
