-- ============================================================
--  hooks/H_RemoteSpy.lua
--  Full remote spy: hookmetamethod __namecall, captures
--  FireServer, InvokeServer, FireClient, FireAllClients,
--  plus raw argument logging with JSON fallback
-- ============================================================
local HL  = (getgenv and getgenv()._HL) or _G._HL
local U   = HL.Utils
local Cfg = HL.Config
local St  = HL.Stats

U.Log("Setting up Remote Spy...", "HOOK")

-- ── Blacklist (don't log these remotes) ──────────────────────
local blacklist = {
    -- Common high-frequency/noisy remotes to ignore (add your own)
    ["DefaultChatSystemSpeakMessage"] = true,
    ["ChatBubble"] = true,
}

-- ── Argument Serializer ───────────────────────────────────────
local function SerializeArgs(...)
    local parts = {}
    local args = {...}
    for i, v in ipairs(args) do
        local s = ""
        pcall(function()
            local t = typeof(v)
            if t == "string" then
                s = string.format("[string] %q", v:sub(1, 200))
            elseif t == "number" or t == "boolean" then
                s = string.format("[%s] %s", t, tostring(v))
            elseif t == "Instance" then
                s = string.format("[Instance:%s] %s", v.ClassName, U.GetPath(v))
            elseif t == "table" then
                local ok2, json = pcall(function()
                    return HL.S.HttpService:JSONEncode(v)
                end)
                if ok2 then
                    s = "[table(JSON)] " .. json:sub(1, 300)
                else
                    local keys = {}
                    for k2, v2 in pairs(v) do
                        table.insert(keys, tostring(k2) .. "=" .. tostring(v2))
                        if #keys > 20 then table.insert(keys, "..."); break end
                    end
                    s = "[table] {" .. table.concat(keys, ", ") .. "}"
                end
            elseif t == "Vector3" then
                s = string.format("[Vector3] %s", tostring(v))
            elseif t == "CFrame" then
                s = string.format("[CFrame] %s", tostring(v))
            elseif t == "Color3" then
                s = string.format("[Color3] R=%.3f G=%.3f B=%.3f", v.R, v.G, v.B)
            elseif t == "UDim2" then
                s = string.format("[UDim2] %s", tostring(v))
            elseif t == "EnumItem" then
                s = string.format("[Enum] %s", tostring(v))
            elseif t == "BrickColor" then
                s = string.format("[BrickColor] %s", tostring(v))
            elseif t == "TweenInfo" then
                s = string.format("[TweenInfo] Time=%.2f Ease=%s Dir=%s",
                    v.Time, tostring(v.EasingStyle), tostring(v.EasingDirection))
            else
                s = string.format("[%s] %s", t, tostring(v):sub(1,100))
            end
        end)
        parts[i] = s ~= "" and s or ("arg["..i.."]="..tostring(v))
    end
    return "(" .. table.concat(parts, ", ") .. ")"
end

-- ── hookmetamethod approach ───────────────────────────────────
local hookedViaMetamethod = false
local originalNamecall = nil

if hookmetamethod then
    local ok, err = pcall(function()
        originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()

            -- Skip our own calls
            if checkcaller and checkcaller() then
                return originalNamecall(self, ...)
            end

            -- Methods to capture
            local capture = (
                (method == "FireServer"     and Cfg.LogFireServer)    or
                (method == "InvokeServer"   and Cfg.LogInvokeServer)  or
                (method == "FireAllClients" and Cfg.LogFireAllClients) or
                (method == "FireClient"     and Cfg.LogFireClient)
            )

            if capture then
                local path = U.GetPath(self)
                local name = ""
                pcall(function() name = self.Name end)

                -- Blacklist check
                if not blacklist[name] then
                    local argsStr = SerializeArgs(...)
                    local ts = string.format("%.4f", os.clock())
                    local cls = ""
                    pcall(function() cls = self.ClassName end)

                    local line = string.format("[REMOTE][%s] %s | %s | Args: %s",
                        ts, method, path, argsStr)

                    U.LogRT("REMOTE", string.format("%s | %s", method, path),
                        "Args: " .. argsStr)

                    -- Also append to raw remote file
                    pcall(function()
                        if appendfile then
                            appendfile(Cfg.RawRemoteFile, line .. "\n")
                        end
                    end)

                    St:Inc("TotalRemotesLogged")
                end
            end

            return originalNamecall(self, ...)
        end)
    end)

    if ok then
        hookedViaMetamethod = true
        U.Log("hookmetamethod __namecall installed ✓", "SUCCESS")
    else
        U.Log("hookmetamethod failed: " .. tostring(err), "WARN")
    end
end

-- ── Fallback: hookfunction on FireServer directly ─────────────
if not hookedViaMetamethod then
    U.Log("Attempting hookfunction fallback...", "WARN")
    -- Try to find FireServer via getgc
    if getgc and hookfunction then
        pcall(function()
            local gcObjs = getgc(false)
            for _, obj in ipairs(gcObjs) do
                if type(obj) == "function" then
                    local info = nil
                    pcall(function()
                        if debug and debug.getinfo then
                            info = debug.getinfo(obj)
                        end
                    end)
                    if info and (info.name == "FireServer" or info.name == "InvokeServer") then
                        local origFn = obj
                        local ok2 = pcall(function()
                            hookfunction(origFn, function(self, ...)
                                if not checkcaller() then
                                    local path = U.GetPath(self)
                                    local argsStr = SerializeArgs(...)
                                    U.LogRT("REMOTE_FB", info.name .. " | " .. path,
                                        "Args: " .. argsStr)
                                end
                                return origFn(self, ...)
                            end)
                        end)
                        if ok2 then
                            U.Log("hookfunction fallback installed on: " .. (info.name or "?"), "SUCCESS")
                        end
                    end
                end
            end
        end)
    else
        U.Log("No hookfunction fallback available.", "ERROR")
    end
end

-- ── syn.hook_function fallback (Synapse X) ────────────────────
if not hookedViaMetamethod then
    pcall(function()
        if syn and syn.hook_function then
            -- syn fallback would go here
            U.Log("syn.hook_function available (manual hook possible)", "WARN")
        end
    end)
end

-- Initialize raw remote log file
pcall(function()
    writefile(Cfg.RawRemoteFile, string.format(
        "=== HuneLog Raw Remotes | %s ===\n", tostring(HL.StartTime)))
end)

U.Log("H_RemoteSpy setup complete.", "SUCCESS")
return true
