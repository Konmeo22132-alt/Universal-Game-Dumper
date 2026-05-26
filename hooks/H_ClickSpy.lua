-- ============================================================
--  hooks/H_ClickSpy.lua
--  ClickDetector spy: MouseClick, RightMouseClick, MouseHoverEnter/Leave
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local St = HL.Stats
local LP = HL.LocalPlayer

U.Log("Setting up ClickDetector Spy...", "HOOK")

local tracked = {}

local function HookClickDetector(inst)
    local ok, isCD = pcall(function() return inst:IsA("ClickDetector") end)
    if not (ok and isCD) then return end
    if tracked[inst] then return end
    tracked[inst] = true

    pcall(function()
        inst.MouseClick:Connect(function(plr)
            local path = U.GetPath(inst)
            local md = U.SafeGet(inst, "MaxActivationDistance")
            local who = plr and plr.Name or "?"
            U.LogRT("CLICK_L", path, string.format("By=%s MaxDist=%s", who, tostring(md)))
            if plr == LP then St:Inc("TotalClicksLogged") end
        end)

        inst.RightMouseClick:Connect(function(plr)
            if plr == LP then
                U.LogRT("CLICK_R", U.GetPath(inst), "RightClick")
            end
        end)

        inst.MouseHoverEnter:Connect(function(plr)
            if plr == LP then
                U.LogRT("HOVER_IN", U.GetPath(inst), "")
            end
        end)

        inst.MouseHoverLeave:Connect(function(plr)
            if plr == LP then
                U.LogRT("HOVER_OUT", U.GetPath(inst), "")
            end
        end)
    end)
end

for _, inst in ipairs(game:GetDescendants()) do
    HookClickDetector(inst)
end
game.DescendantAdded:Connect(HookClickDetector)

U.Log("ClickDetector spy active ✓", "SUCCESS")
return true
