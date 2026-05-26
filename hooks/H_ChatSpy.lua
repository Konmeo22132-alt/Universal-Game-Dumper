-- ============================================================
--  hooks/H_ChatSpy.lua
--  Chat spy: intercept outgoing and incoming messages,
--  TextChatService and legacy Chat service
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local LP = HL.LocalPlayer

U.Log("Setting up Chat Spy...", "HOOK")

-- ── Modern TextChatService ────────────────────────────────────
local textChat = nil
pcall(function()
    textChat = game:GetService("TextChatService")
end)

if textChat then
    -- Incoming messages
    pcall(function()
        textChat.MessageReceived:Connect(function(msg)
            local sender = msg.TextSource and msg.TextSource.Name or "?"
            local text   = msg.Text or ""
            local chan   = msg.TextChannel and msg.TextChannel.Name or "?"
            U.LogRT("CHAT_RECV", string.format("[#%s] %s", chan, sender),
                string.format("'%s'", text:sub(1, 200)))
        end)
    end)

    -- Outgoing (intercept SendAsync)
    if hookmetamethod and getrawmetatable then
        pcall(function()
            -- Monitor all TextChannel:SendAsync calls via __namecall
            -- (already covered by remote spy's namecall hook, we just filter here)
            U.Log("TextChat outgoing covered by RemoteSpy namecall hook", "HOOK")
        end)
    end

    -- ShouldDeliverCallback (if we can set it)
    pcall(function()
        -- Can intercept local filtering
        textChat.OnIncomingMessage = function(msg)
            -- Don't modify, just log if different from MessageReceived
            return nil
        end
    end)
end

-- ── Legacy Chat.Chatted ───────────────────────────────────────
if S.Players then
    for _, plr in ipairs(S.Players:GetPlayers()) do
        pcall(function()
            plr.Chatted:Connect(function(msg, recipient)
                local recv = recipient and recipient.Name or "ALL"
                U.LogRT("CHAT_LEGACY", plr.Name,
                    string.format("[→%s] '%s'", recv, msg:sub(1, 200)))
            end)
        end)
    end

    S.Players.PlayerAdded:Connect(function(plr)
        plr.Chatted:Connect(function(msg, recipient)
            local recv = recipient and recipient.Name or "ALL"
            U.LogRT("CHAT_LEGACY", plr.Name,
                string.format("[→%s] '%s'", recv, msg:sub(1, 200)))
        end)
    end)
end

-- ── LocalPlayer chat spy (outgoing via TextBox) ────────────────
-- The GUI spy already captures TextBox changes. We register a specific
-- listener here for the chat input box.
task.spawn(function()
    task.wait(3)
    pcall(function()
        if not LP then return end
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return end

        -- Try to find the chat TextBox (various games use different names)
        local function FindChatBox(root)
            for _, desc in ipairs(root:GetDescendants()) do
                pcall(function()
                    if desc:IsA("TextBox") then
                        local name = desc.Name:lower()
                        if name:find("chat") or name:find("message") or name:find("input") then
                            desc.FocusLost:Connect(function(enter)
                                if enter and #desc.Text > 0 then
                                    U.LogRT("CHAT_SEND", "ChatTextBox",
                                        string.format("Text='%s'", desc.Text:sub(1,200)))
                                end
                            end)
                            U.Log("Found chat TextBox: " .. desc.Name, "HOOK")
                        end
                    end
                end)
            end
        end
        FindChatBox(pg)
    end)
end)

U.Log("Chat Spy active ✓", "SUCCESS")
return true
