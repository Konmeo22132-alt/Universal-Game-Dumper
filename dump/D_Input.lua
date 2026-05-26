-- ============================================================
--  dump/D_Input.lua
--  UserInputService state, keybinds, context actions,
--  VirtualInputManager, mouse/gamepad state
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services

U.S_Header("SECTION 12 — INPUT & CONTROLS")

local UIS = S.UserInputService
if not UIS then
    U.S_Push("  [!] UserInputService not accessible.")
    return
end

-- ── Platform & Device Info ────────────────────────────────────
U.S_SubHeader("12.1 Platform & Input Devices")
pcall(function()
    U.S_Push(string.format("  KeyboardEnabled    : %s", tostring(UIS.KeyboardEnabled)))
    U.S_Push(string.format("  MouseEnabled       : %s", tostring(UIS.MouseEnabled)))
    U.S_Push(string.format("  TouchEnabled       : %s", tostring(UIS.TouchEnabled)))
    U.S_Push(string.format("  GamepadEnabled     : %s", tostring(UIS.GamepadEnabled)))
    U.S_Push(string.format("  AccelerometerEnabled: %s", tostring(UIS.AccelerometerEnabled)))
    U.S_Push(string.format("  GyroscopeEnabled   : %s", tostring(UIS.GyroscopeEnabled)))
    U.S_Push(string.format("  MouseDeltaSensitivity: %.4f", UIS.MouseDeltaSensitivity))
    U.S_Push(string.format("  MouseBehavior      : %s", tostring(UIS.MouseBehavior)))
    U.S_Push(string.format("  MouseIconEnabled   : %s", tostring(UIS.MouseIconEnabled)))
    U.S_Push(string.format("  OverrideMouseIconBehavior: %s", tostring(UIS.OverrideMouseIconBehavior)))
    U.S_Push(string.format("  VREnabled          : %s", tostring(UIS.VREnabled)))
end)

-- ── Current Mouse State ───────────────────────────────────────
U.S_SubHeader("12.2 Mouse State")
pcall(function()
    local mloc  = UIS:GetMouseLocation()
    local delta = UIS:GetMouseDelta()
    U.S_Push(string.format("  MouseLocation : X=%.0f Y=%.0f", mloc.X, mloc.Y))
    U.S_Push(string.format("  MouseDelta    : X=%.4f Y=%.4f", delta.X, delta.Y))
    U.S_Push(string.format("  MouseIcon     : %s", tostring(UIS.MouseIcon)))

    -- Mouse buttons
    local mb1 = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    local mb2 = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local mb3 = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
    U.S_Push(string.format("  MB1 pressed   : %s | MB2: %s | MB3 (middle): %s",
        tostring(mb1), tostring(mb2), tostring(mb3)))
end)

-- ── Currently Held Keys ───────────────────────────────────────
U.S_SubHeader("12.3 Keys Currently Pressed (all Enum.KeyCode)")
pcall(function()
    local pressed = {}
    for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
        local ok, held = pcall(function() return UIS:IsKeyDown(key) end)
        if ok and held then
            table.insert(pressed, key.Name)
        end
    end
    if #pressed > 0 then
        U.S_Push("  Held keys: " .. table.concat(pressed, ", "))
    else
        U.S_Push("  [No keys currently held]")
    end
end)

-- ── Gamepad State ─────────────────────────────────────────────
U.S_SubHeader("12.4 Gamepad State")
pcall(function()
    local gamepads = UIS:GetConnectedGamepads()
    U.S_Push(string.format("  Connected gamepads: %d", #gamepads))
    for _, gp in ipairs(gamepads) do
        U.S_Push(string.format("  Gamepad: %s", tostring(gp)))
        local supportOk, keycodesSupported = pcall(function()
            return UIS:GetSupportedGamepadKeyCodes(gp)
        end)
        if supportOk then
            local names = {}
            for _, kc in ipairs(keycodesSupported) do
                table.insert(names, kc.Name)
            end
            U.S_Push("    Supported: " .. table.concat(names, ", "))
        end
        -- State of each button
        for _, kc in pairs(Enum.KeyCode:GetEnumItems()) do
            local ok2, state = pcall(function()
                return UIS:GetGamepadState(gp, kc)
            end)
            if ok2 and state and state.UserInputState == Enum.UserInputState.Begin then
                U.S_Push(string.format("    [Pressed] %s", kc.Name))
            end
        end
    end
end)

-- ── ContextActionService ──────────────────────────────────────
U.S_SubHeader("12.5 ContextActionService — Bound Actions")
local CAS = S.ContextActionService
if CAS then
    pcall(function()
        local actions = CAS:GetAllBoundActionInfo()
        local count = 0
        for name, info in pairs(actions) do
            count = count + 1
            local keys = {}
            if info.inputTypes then
                for _, it in ipairs(info.inputTypes) do
                    table.insert(keys, tostring(it))
                end
            end
            U.S_Push(string.format("  [Action] '%s' | Keys: %s | Priority: %s | Sink: %s",
                tostring(name),
                table.concat(keys, ", "),
                tostring(info.priorityLevel),
                tostring(info.sinkInput)))
        end
        U.S_Push(string.format("  Total bound actions: %d", count))
    end)
else
    U.S_Push("  ContextActionService not available.")
end

-- ── Touch Inputs ──────────────────────────────────────────────
U.S_SubHeader("12.6 Active Touch Points")
pcall(function()
    if UIS.TouchEnabled then
        local touches = UIS:GetTouchingParts()
        U.S_Push(string.format("  Touching parts: %d", #touches))
    else
        U.S_Push("  [Touch not enabled on this device]")
    end
end)

-- ── VirtualInputManager ───────────────────────────────────────
U.S_SubHeader("12.7 VirtualInputManager")
local VIM = S.VirtualInputManager
if VIM then
    U.S_Push("  VirtualInputManager is accessible (can simulate inputs)")
    U.S_Push("  Children:")
    local ok, kids = pcall(function() return VIM:GetChildren() end)
    if ok then
        for _, child in ipairs(kids) do
            pcall(function()
                U.S_Push(string.format("    -> [%s] %s", child.ClassName, child.Name))
            end)
        end
    end
else
    U.S_Push("  VirtualInputManager not accessible.")
end

U.Log("D_Input done", "DUMP")
return true
