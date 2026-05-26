-- ============================================================
--  hooks/H_ProximitySpy.lua
--  ProximityPrompt spy: hooks fireproximityprompt +
--  connects to Triggered on all existing and future prompts
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local St = HL.Stats
local LP = HL.LocalPlayer

U.Log("Setting up ProximityPrompt Spy...", "HOOK")

-- ── Hook fireproximityprompt (executor function) ──────────────
local hookedFirePP = false
if fireproximityprompt and hookfunction then
    pcall(function()
        local originalFPP = fireproximityprompt
        hookfunction(fireproximityprompt, function(prompt, ...)
            if not checkcaller or not checkcaller() then
                local path = U.GetPath(prompt)
                local at, ot, md, hd = "?","?","?","?"
                pcall(function()
                    at = prompt.ActionText
                    ot = prompt.ObjectText
                    md = tostring(prompt.MaxActivationDistance)
                    hd = tostring(prompt.HoldDuration)
                end)
                U.LogRT("PP_FIRED", path, string.format(
                    "Action='%s' Object='%s' MaxDist=%s HoldDur=%s", at, ot, md, hd))
                St:Inc("TotalPromptsLogged")
            end
            return originalFPP(prompt, ...)
        end)
        hookedFirePP = true
        U.Log("fireproximityprompt hooked ✓", "SUCCESS")
    end)
end

-- ── Triggered event listener ──────────────────────────────────
local trackedPrompts = {}

local function HookPromptTriggered(inst)
    local ok, isPrompt = pcall(function() return inst:IsA("ProximityPrompt") end)
    if not (ok and isPrompt) then return end
    if trackedPrompts[inst] then return end
    trackedPrompts[inst] = true

    pcall(function()
        inst.Triggered:Connect(function(plr)
            local path = U.GetPath(inst)
            local at, ot = "?","?"
            pcall(function() at = inst.ActionText; ot = inst.ObjectText end)
            local who = plr and plr.Name or "?"
            U.LogRT("PP_TRIGGERED", path, string.format(
                "By=%s Action='%s' Object='%s'", who, at, ot))
            if plr == LP then
                St:Inc("TotalPromptsLogged")
            end
        end)

        inst.PromptShown:Connect(function()
            U.LogRT("PP_SHOWN", U.GetPath(inst), "")
        end)

        inst.PromptHidden:Connect(function()
            U.LogRT("PP_HIDDEN", U.GetPath(inst), "")
        end)

        inst.PromptButtonHoldBegan:Connect(function(plr)
            if plr == LP then
                U.LogRT("PP_HOLD_START", U.GetPath(inst), "")
            end
        end)

        inst.PromptButtonHoldEnded:Connect(function(plr)
            if plr == LP then
                U.LogRT("PP_HOLD_END", U.GetPath(inst), "")
            end
        end)
    end)
end

-- Scan existing
for _, inst in ipairs(game:GetDescendants()) do
    HookPromptTriggered(inst)
end

-- Watch for new ones
game.DescendantAdded:Connect(HookPromptTriggered)

U.Log("ProximityPrompt spy active ✓", "SUCCESS")
return true
