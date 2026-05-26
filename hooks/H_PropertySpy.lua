-- ============================================================
--  hooks/H_PropertySpy.lua
--  Monitor property changes on key objects via
--  GetPropertyChangedSignal and instance attribute changes
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local U   = HL.Utils
local Cfg = HL.Config
local S   = HL.Services
local LP  = HL.LocalPlayer

U.Log("Setting up Property Spy...", "HOOK")

local trackedInst = {}

-- ── Track an instance's properties ────────────────────────────
local function TrackInstance(inst, label)
    if not inst then return end
    local key = tostring(inst)
    if trackedInst[key] then return end
    trackedInst[key] = true

    for _, prop in ipairs(Cfg.PropertySpyTargets) do
        pcall(function()
            inst:GetPropertyChangedSignal(prop):Connect(function()
                local val = U.SafeGet(inst, prop)
                U.LogRT("PROP_CHANGE", string.format("%s.%s", label or U.GetPath(inst), prop),
                    string.format("→ %s", tostring(val)))
            end)
        end)
    end

    -- Attribute changes
    pcall(function()
        inst.AttributeChanged:Connect(function(attrName)
            local val = nil
            pcall(function() val = inst:GetAttribute(attrName) end)
            U.LogRT("ATTR_CHANGE", string.format("%s[Attr:%s]",
                label or U.GetPath(inst), attrName),
                string.format("→ %s", tostring(val)))
        end)
    end)
end

-- ── Track LocalPlayer + Humanoid ──────────────────────────────
if LP then
    TrackInstance(LP, "LocalPlayer")

    local function OnChar(char)
        pcall(function()
            TrackInstance(char, "Character")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then TrackInstance(hum, "Humanoid") end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then TrackInstance(hrp, "HRP") end
        end)
    end

    if LP.Character then OnChar(LP.Character) end
    LP.CharacterAdded:Connect(OnChar)

    -- leaderstats value changes
    local function TrackLeaderstats()
        local ls = LP:FindFirstChild("leaderstats")
        if not ls then return end
        for _, val in ipairs(ls:GetDescendants()) do
            if U.VALUE_CLASSES[val.ClassName] then
                pcall(function()
                    val:GetPropertyChangedSignal("Value"):Connect(function()
                        local newVal = U.SafeGet(val, "Value")
                        U.LogRT("LEADERSTAT_CHANGE",
                            string.format("leaderstats.%s", val.Name),
                            string.format("→ %s", tostring(newVal)))
                    end)
                end)
            end
        end
    end
    task.delay(2, TrackLeaderstats) -- delay slightly for game to populate

    -- All LP value children
    for _, child in ipairs(LP:GetDescendants()) do
        pcall(function()
            if U.VALUE_CLASSES[child.ClassName] then
                child:GetPropertyChangedSignal("Value"):Connect(function()
                    U.LogRT("LP_VALUE_CHANGE", U.GetPath(child),
                        string.format("→ %s", tostring(U.SafeGet(child, "Value"))))
                end)
            end
        end)
    end
end

-- ── Track Camera ─────────────────────────────────────────────
pcall(function()
    local cam = S.Workspace and S.Workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("CameraType"):Connect(function()
            U.LogRT("CAM_TYPE_CHANGE", "CurrentCamera",
                string.format("→ %s", tostring(cam.CameraType)))
        end)
        cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
            U.LogRT("CAM_FOV_CHANGE", "CurrentCamera",
                string.format("→ %.2f", cam.FieldOfView))
        end)
        cam:GetPropertyChangedSignal("CameraSubject"):Connect(function()
            local subj = cam.CameraSubject
            U.LogRT("CAM_SUBJECT_CHANGE", "CurrentCamera",
                string.format("→ %s", subj and U.GetPath(subj) or "nil"))
        end)
    end
end)

-- ── Track Lighting changes ────────────────────────────────────
pcall(function()
    if S.Lighting then
        local lightingProps = {
            "Brightness", "Ambient", "OutdoorAmbient", "FogEnd",
            "FogStart", "TimeOfDay", "ClockTime", "ExposureCompensation"
        }
        for _, prop in ipairs(lightingProps) do
            S.Lighting:GetPropertyChangedSignal(prop):Connect(function()
                local val = U.SafeGet(S.Lighting, prop)
                U.LogRT("LIGHTING_CHANGE", "Lighting." .. prop,
                    string.format("→ %s", tostring(val)))
            end)
        end
    end
end)

U.Log("Property Spy active ✓", "SUCCESS")
return true
