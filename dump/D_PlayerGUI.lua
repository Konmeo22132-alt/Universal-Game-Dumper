-- ============================================================
--  dump/D_PlayerGUI.lua
--  Deep scan of PlayerGui, all players, UI elements, text,
--  button scripts, textboxes, remote interactions
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local St = HL.Stats
local LP = HL.LocalPlayer

U.S_Header("SECTION 5 — PLAYERS & PLAYER GUI")

-- ── All Players List ──────────────────────────────────────────
U.S_SubHeader("5.1 All Players in Server")
local allPlayers = {}
pcall(function() allPlayers = S.Players:GetPlayers() end)
U.S_Push(string.format("  Player count: %d", #allPlayers))
for _, plr in ipairs(allPlayers) do
    pcall(function()
        local teamName = "None"
        pcall(function()
            if plr.Team then teamName = plr.Team.Name end
        end)
        local isSelf = (plr == LP) and " ← YOU" or ""
        U.S_Push(string.format("  [Player] %s (%s) | ID: %d | Age: %d | Team: %s | Neutral: %s%s",
            plr.Name, plr.DisplayName, plr.UserId, plr.AccountAge,
            teamName, tostring(plr.Neutral), isSelf))

        -- Character check for other players
        if plr ~= LP then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    U.S_Push(string.format("    Char HP: %.0f/%.0f | WalkSpeed: %.1f | RootPos: %s",
                        hum.Health, hum.MaxHealth, hum.WalkSpeed,
                        tostring(char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position or "?")))
                end
            else
                U.S_Push("    [Character not loaded]")
            end
        end
    end)
end

-- ── LocalPlayer GUI Deep Scan ─────────────────────────────────
U.S_SubHeader("5.2 LocalPlayer PlayerGui — Deep Scan")
if not LP then
    U.S_Push("  [!] No LocalPlayer.")
    return
end

local playerGui = LP:FindFirstChild("PlayerGui")
if not playerGui then
    U.S_Push("  [!] PlayerGui not found.")
    return
end

-- Recursive GUI tree with rich metadata
local guiStats = { buttons=0, labels=0, textboxes=0, frames=0, images=0, screenguis=0 }

local function DumpGUITree(root, indent, depth)
    if depth and depth > 50 then return end
    local children = {}
    pcall(function() children = root:GetChildren() end)

    for _, child in ipairs(children) do
        pcall(function()
            local cls = child.ClassName
            local name = U.SafeGet(child, "Name") or "?"
            local line = string.format("%s[%s] '%s'", indent, cls, name)

            -- ScreenGui
            if cls == "ScreenGui" then
                local en = U.SafeGet(child, "Enabled")
                local zindex = U.SafeGet(child, "ZIndexBehavior")
                local reset = U.SafeGet(child, "ResetOnSpawn")
                line = line .. string.format(" [Enabled=%s][ZIndex=%s][ResetOnSpawn=%s]",
                    tostring(en), tostring(zindex), tostring(reset))
                guiStats.screenguis = guiStats.screenguis + 1
                St:Inc("ScreenGuis")

            -- Frame & ScrollingFrame
            elseif cls == "Frame" or cls == "ScrollingFrame" then
                local vis = U.SafeGet(child, "Visible")
                local size = U.SafeGet(child, "Size")
                local bgcol = U.SafeGet(child, "BackgroundColor3")
                local bgtrans = U.SafeGet(child, "BackgroundTransparency")
                line = line .. string.format(" [Visible=%s][Size=%s][BGColor=%s][BGTrans=%.2f]",
                    tostring(vis), tostring(size), tostring(bgcol), tonumber(bgtrans) or 0)
                if cls == "Frame" then guiStats.frames = guiStats.frames + 1; St:Inc("Frames")
                else St:Inc("ScrollingFrames") end

            -- TextButton / ImageButton
            elseif cls == "TextButton" or cls == "ImageButton" then
                local vis = U.SafeGet(child, "Visible")
                local act = U.SafeGet(child, "Active")
                local inter = U.SafeGet(child, "Interactable")
                local text = cls == "TextButton" and U.SafeGet(child, "Text") or nil
                local imgId = cls == "ImageButton" and U.SafeGet(child, "Image") or nil
                local pos = U.SafeGet(child, "Position")
                local size = U.SafeGet(child, "Size")
                line = line .. string.format(
                    " [Visible=%s][Active=%s][Interactable=%s][Pos=%s][Size=%s]",
                    tostring(vis), tostring(act), tostring(inter),
                    tostring(pos), tostring(size))
                if text then line = line .. string.format("[Text='%s']", tostring(text)) end
                if imgId then line = line .. string.format("[Image=%s]", tostring(imgId)) end
                -- Check connections (click events)
                pcall(function()
                    if getconnections then
                        local conns = getconnections(child.MouseButton1Click)
                        line = line .. string.format(" [ClickConnections=%d]", #conns)
                        for _, c in ipairs(conns) do
                            pcall(function()
                                local fn = c.Function
                                if fn and debug and debug.getinfo then
                                    local info = debug.getinfo(fn)
                                    if info then
                                        U.S_Push(indent .. "  ↳ Script: " .. tostring(info.short_src or "?") .. ":" .. tostring(info.currentline or "?"))
                                    end
                                end
                            end)
                        end
                    end
                end)
                guiStats.buttons = guiStats.buttons + 1
                if cls == "TextButton" then St:Inc("TextButtons") else St:Inc("ImageButtons") end

            -- TextLabel
            elseif cls == "TextLabel" then
                local text = U.SafeGet(child, "Text")
                local vis  = U.SafeGet(child, "Visible")
                local tcol = U.SafeGet(child, "TextColor3")
                local fs   = U.SafeGet(child, "TextSize")
                local ts   = U.SafeGet(child, "TextScaled")
                line = line .. string.format(" [Text='%s'][Visible=%s][Color=%s][Size=%s][Scaled=%s]",
                    tostring(text), tostring(vis), tostring(tcol), tostring(fs), tostring(ts))
                guiStats.labels = guiStats.labels + 1
                St:Inc("TextLabels")

            -- TextBox
            elseif cls == "TextBox" then
                local text = U.SafeGet(child, "Text")
                local ph   = U.SafeGet(child, "PlaceholderText")
                local vis  = U.SafeGet(child, "Visible")
                local focused = U.SafeGet(child, "ClearTextOnFocus")
                line = line .. string.format(" [Text='%s'][Placeholder='%s'][Visible=%s][ClearOnFocus=%s]",
                    tostring(text), tostring(ph), tostring(vis), tostring(focused))
                guiStats.textboxes = guiStats.textboxes + 1
                St:Inc("TextBoxes")

            -- ImageLabel
            elseif cls == "ImageLabel" then
                local img = U.SafeGet(child, "Image")
                local vis = U.SafeGet(child, "Visible")
                local trans = U.SafeGet(child, "ImageTransparency")
                line = line .. string.format(" [Image=%s][Visible=%s][Trans=%.2f]",
                    tostring(img), tostring(vis), tonumber(trans) or 0)
                guiStats.images = guiStats.images + 1
                St:Inc("ImageLabels")

            -- UIListLayout / UIGridLayout
            elseif cls == "UIListLayout" or cls == "UIGridLayout" or cls == "UITableLayout" then
                local so = U.SafeGet(child, "SortOrder")
                local fill = U.SafeGet(child, "FillDirection")
                line = line .. string.format(" [SortOrder=%s][Fill=%s]", tostring(so), tostring(fill))

            -- LocalScript inside GUI
            elseif cls == "LocalScript" or cls == "ModuleScript" then
                local en = U.SafeGet(child, "Enabled")
                line = line .. string.format(" ⚠ SCRIPT INSIDE GUI [Enabled=%s]", tostring(en))
                St:Inc(cls == "LocalScript" and "LocalScripts" or "ModuleScripts")

            -- RemoteEvent/Function inside GUI (rare but possible obfuscation)
            elseif cls == "RemoteEvent" or cls == "RemoteFunction" or cls == "UnreliableRemoteEvent" then
                line = line .. " ⚠⚠ REMOTE INSIDE GUI!"
                St:Inc(cls == "RemoteEvent" and "RemoteEvents"
                    or cls == "RemoteFunction" and "RemoteFunctions"
                    or "UnreliableRemoteEvents")
            end

            line = line .. U.DumpAttrs(child)
            U.S_Push(line)
        end)
        DumpGUITree(child, indent .. "  ", (depth or 0) + 1)
    end
end

DumpGUITree(playerGui, "  ", 0)

-- GUI Stats Summary
U.S_SubHeader("5.3 GUI Element Counts")
U.S_Push(string.format("  ScreenGuis : %d", guiStats.screenguis))
U.S_Push(string.format("  Frames     : %d", guiStats.frames))
U.S_Push(string.format("  Buttons    : %d", guiStats.buttons))
U.S_Push(string.format("  TextLabels : %d", guiStats.labels))
U.S_Push(string.format("  TextBoxes  : %d", guiStats.textboxes))
U.S_Push(string.format("  ImageLabels: %d", guiStats.images))

-- ── All Interactable Buttons Flat List ────────────────────────
U.S_SubHeader("5.4 All Interactable Buttons — Flat List")
local allGUIDesc = {}
pcall(function() allGUIDesc = playerGui:GetDescendants() end)
local interactable = {}
for _, inst in ipairs(allGUIDesc) do
    pcall(function()
        if (inst:IsA("TextButton") or inst:IsA("ImageButton")) then
            local act   = U.SafeGet(inst, "Active")
            local inter = U.SafeGet(inst, "Interactable")
            local vis   = U.SafeGet(inst, "Visible")
            if act or inter or vis then
                table.insert(interactable, inst)
            end
        end
    end)
end
U.S_Push(string.format("  Found %d interactable buttons:", #interactable))
for _, inst in ipairs(interactable) do
    pcall(function()
        local text = ""
        if inst:IsA("TextButton") then
            pcall(function() text = " Text='" .. inst.Text .. "'" end)
        end
        U.S_Push(string.format("    %s [%s]%s | Vis=%s | Act=%s | Interactable=%s",
            U.GetPath(inst), inst.ClassName, text,
            tostring(U.SafeGet(inst, "Visible")),
            tostring(U.SafeGet(inst, "Active")),
            tostring(U.SafeGet(inst, "Interactable"))))
    end)
end

-- ── CoreGui ───────────────────────────────────────────────────
U.S_SubHeader("5.5 CoreGui — Top Level Children")
if S.CoreGui then
    local ok, kids = pcall(function() return S.CoreGui:GetChildren() end)
    if ok then
        for _, child in ipairs(kids) do
            pcall(function()
                U.S_Push(string.format("  [%s] %s", child.ClassName, child.Name))
            end)
        end
    end
end

U.Log("D_PlayerGUI done", "DUMP")
return true
