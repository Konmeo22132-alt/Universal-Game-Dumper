-- ============================================================
--  hooks/H_GUISpy.lua
--  GUI watcher: ChildAdded on entire PlayerGui tree,
--  TextBox focus/change spy, button interaction spy
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local St = HL.Stats
local LP = HL.LocalPlayer

U.Log("Setting up GUI Spy...", "HOOK")

if not LP then return end

local pg = LP:FindFirstChild("PlayerGui")
if not pg then
    LP.ChildAdded:Connect(function(child)
        if child.Name == "PlayerGui" then
            pg = child
        end
    end)
end

-- ── Track TextBox changes ──────────────────────────────────────
local trackedTB = {}
local function TrackTextBox(inst)
    local ok, isTB = pcall(function() return inst:IsA("TextBox") end)
    if not (ok and isTB) then return end
    if trackedTB[inst] then return end
    trackedTB[inst] = true

    pcall(function()
        inst.Focused:Connect(function()
            U.LogRT("GUI_TEXTBOX_FOCUS", U.GetPath(inst),
                string.format("PlaceholderText='%s'", tostring(inst.PlaceholderText)))
        end)

        inst.FocusLost:Connect(function(enterPressed)
            U.LogRT("GUI_TEXTBOX_SUBMIT", U.GetPath(inst),
                string.format("Text='%s' EnterPressed=%s", inst.Text, tostring(enterPressed)))
        end)

        inst:GetPropertyChangedSignal("Text"):Connect(function()
            -- Only log if it's actually non-empty changes (avoid spam)
            local text = inst.Text
            if #text > 0 then
                U.LogRT("GUI_TEXTBOX_CHANGE", U.GetPath(inst),
                    string.format("Text='%s'", text:sub(1, 100)))
            end
        end)
    end)
end

-- ── Track Buttons ─────────────────────────────────────────────
local trackedBtn = {}
local function TrackButton(inst)
    local ok, isBtn = pcall(function()
        return inst:IsA("TextButton") or inst:IsA("ImageButton")
    end)
    if not (ok and isBtn) then return end
    if trackedBtn[inst] then return end
    trackedBtn[inst] = true

    pcall(function()
        inst.MouseButton1Click:Connect(function()
            local path = U.GetPath(inst)
            local text = ""
            pcall(function()
                if inst:IsA("TextButton") then text = " Text='" .. inst.Text .. "'" end
            end)
            local vis  = U.SafeGet(inst, "Visible")
            local act  = U.SafeGet(inst, "Active")
            U.LogRT("GUI_BTN_CLICK", path,
                string.format("%s Visible=%s Active=%s", text, tostring(vis), tostring(act)))
        end)

        inst.MouseButton2Click:Connect(function()
            U.LogRT("GUI_BTN_RCLICK", U.GetPath(inst), "RightClick")
        end)

        inst.MouseEnter:Connect(function()
            -- Uncomment if you want hover tracking (very noisy):
            -- U.LogRT("GUI_BTN_HOVER", U.GetPath(inst), "")
        end)
    end)
end

-- ── GUI DescendantAdded listener ──────────────────────────────
local function OnGUIDescendantAdded(child)
    pcall(function()
        local cls = child.ClassName
        St:Inc("TotalGUIChanges")

        local path = U.GetPath(child)
        local vis  = U.SafeGet(child, "Visible")
        local en   = U.SafeGet(child, "Enabled") -- ScreenGui

        U.LogRT("GUI_ADDED", path, string.format("<%s> Visible=%s Enabled=%s",
            cls, tostring(vis), tostring(en)))

        TrackTextBox(child)
        TrackButton(child)

        -- Log text content for new labels/buttons immediately
        if cls == "TextLabel" or cls == "TextButton" then
            local text = U.SafeGet(child, "Text")
            if text and #tostring(text) > 0 then
                U.LogRT("GUI_TEXT_CONTENT", path,
                    string.format("Text='%s'", tostring(text):sub(1, 150)))
            end
        end

        -- ScreenGui appearing = new screen/panel
        if cls == "ScreenGui" then
            U.LogRT("GUI_SCREENGUI", path,
                string.format("Enabled=%s | Children=%d",
                    tostring(en), #child:GetChildren()))
        end
    end)
end

-- Watch for GUI elements removed too
local function OnGUIDescendantRemoving(child)
    pcall(function()
        local cls  = child.ClassName
        local path = U.GetPath(child)
        U.LogRT("GUI_REMOVED", path, string.format("<%s>", cls))
    end)
end

-- ── Apply to PlayerGui ────────────────────────────────────────
local function AttachToGui(gui)
    gui.DescendantAdded:Connect(OnGUIDescendantAdded)
    gui.DescendantRemoving:Connect(OnGUIDescendantRemoving)

    -- Retroactively track existing elements
    for _, desc in ipairs(gui:GetDescendants()) do
        pcall(function()
            TrackTextBox(desc)
            TrackButton(desc)
        end)
    end
    U.Log("PlayerGui watchers attached ✓", "SUCCESS")
end

if pg then
    AttachToGui(pg)
else
    LP.ChildAdded:Connect(function(child)
        if child.Name == "PlayerGui" then
            AttachToGui(child)
        end
    end)
end

-- ── Watch for ScreenGui Enabled changes ──────────────────────
-- Polls in background (some games toggle existing GUIs instead of adding new ones)
task.spawn(function()
    local guiStates = {}
    while true do
        task.wait(0.5)
        pcall(function()
            if not pg then return end
            for _, child in ipairs(pg:GetChildren()) do
                pcall(function()
                    if child:IsA("ScreenGui") then
                        local en = child.Enabled
                        local prev = guiStates[child]
                        if prev ~= nil and prev ~= en then
                            U.LogRT("GUI_TOGGLE", U.GetPath(child),
                                string.format("Enabled: %s → %s", tostring(prev), tostring(en)))
                        end
                        guiStates[child] = en
                    end
                end)
            end
        end)
    end
end)

return true
