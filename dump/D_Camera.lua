-- ============================================================
--  dump/D_Camera.lua
--  Camera state, CameraScript, ViewportFrames, render settings
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local LP = HL.LocalPlayer

U.S_Header("SECTION 11 — CAMERA & RENDERING")

-- ── Current Camera ────────────────────────────────────────────
U.S_SubHeader("11.1 Current Camera State")
local cam = S.Workspace and S.Workspace.CurrentCamera
if cam then
    pcall(function()
        U.S_Push(string.format("  CameraType        : %s", tostring(cam.CameraType)))
        U.S_Push(string.format("  CFrame            : %s", tostring(cam.CFrame)))
        U.S_Push(string.format("  Focus             : %s", tostring(cam.Focus)))
        U.S_Push(string.format("  FieldOfView       : %.2f", cam.FieldOfView))
        U.S_Push(string.format("  FieldOfViewMode   : %s", tostring(cam.FieldOfViewMode)))
        U.S_Push(string.format("  ViewportSize      : %s", tostring(cam.ViewportSize)))
        U.S_Push(string.format("  NearPlaneZ        : %.4f", cam.NearPlaneZ))
        U.S_Push(string.format("  CameraSubject     : %s",
            cam.CameraSubject and U.GetPath(cam.CameraSubject) or "nil"))
        U.S_Push(string.format("  HeadLocked        : %s", tostring(cam.HeadLocked)))
        U.S_Push(string.format("  HeadScale         : %.4f", cam.HeadScale))
        U.S_Push(string.format("  DiagonalFieldOfView: %.4f", cam.DiagonalFieldOfView))
        -- Projection matrix info
        local ok2, proj = pcall(function()
            return cam:GetProjectionCFrame(cam.CFrame, cam.Focus)
        end)
        if ok2 then
            U.S_Push(string.format("  ProjectionCFrame  : %s", tostring(proj)))
        end
    end)
    -- Camera children (CameraScript, etc.)
    U.S_SubHeader("11.2 Camera Children")
    U.TraverseTree(cam, "  ", 0, nil, nil)
else
    U.S_Push("  [!] CurrentCamera not found.")
end

-- ── RenderSettings (if accessible) ───────────────────────────
U.S_SubHeader("11.3 Render Settings (UserSettings)")
pcall(function()
    local rs = UserSettings and UserSettings():GetService("UserGameSettings")
    if rs then
        U.S_Push(string.format("  GraphicsQualityLevel: %s", tostring(rs.GraphicsQualityLevel)))
        U.S_Push(string.format("  SavedQualityLevel   : %s", tostring(rs.SavedQualityLevel)))
    end
end)
-- Also check RenderSettings directly
pcall(function()
    local rs = settings and settings().Rendering
    if rs then
        U.S_Push(string.format("  QualityLevel        : %s", tostring(rs.QualityLevel)))
        U.S_Push(string.format("  MaxTextureQuality   : %s", tostring(rs.MaxTextureQuality)))
        U.S_Push(string.format("  EagerBulkExecution  : %s", tostring(rs.EagerBulkExecution)))
    end
end)

-- ── CameraScript Analysis ─────────────────────────────────────
U.S_SubHeader("11.4 Camera LocalScripts (PlayerScripts)")
if LP then
    local ps = LP:FindFirstChild("PlayerScripts")
    if ps then
        local desc = ps:GetDescendants()
        for _, inst in ipairs(desc) do
            pcall(function()
                if inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
                    local name = inst.Name
                    if name:lower():find("camera") or name:lower():find("cam") then
                        U.S_Push(string.format("  -> [%s] %s", inst.ClassName, U.GetPath(inst)))
                    end
                end
            end)
        end
    end
end

-- ── ViewportFrame instances ────────────────────────────────────
U.S_SubHeader("11.5 ViewportFrames (3D in GUI)")
if LP then
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local allGUI = {}
        pcall(function() allGUI = pg:GetDescendants() end)
        for _, inst in ipairs(allGUI) do
            pcall(function()
                if inst.ClassName == "ViewportFrame" then
                    local size = U.SafeGet(inst, "CurrentCamera") and "has camera" or "no camera"
                    U.S_Push(string.format("  [ViewportFrame] %s | %s | Children:%d",
                        U.GetPath(inst), size, #inst:GetChildren()))
                end
            end)
        end
    end
end

U.Log("D_Camera done", "DUMP")
return true
