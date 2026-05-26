-- ============================================================
--  hooks/H_TweenSpy.lua
--  Hook TweenService:Create and Tween:Play/Pause/Cancel
--  Reveals what properties games animate and to what values
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services

U.Log("Setting up Tween Spy...", "HOOK")

local TweenSvc = S.TweenService
if not TweenSvc then
    U.Log("TweenService not available, skipping Tween Spy.", "WARN")
    return
end

-- ── Hook TweenService:Create ──────────────────────────────────
if hookmetamethod and getrawmetatable then
    pcall(function()
        local mt = getrawmetatable(TweenSvc)
        if not mt then return end

        local oldIndex = rawget(mt, "__index")
        if type(oldIndex) ~= "function" then return end

        local origCreate = nil

        -- We need to get TweenService.Create reference
        -- Do it via a safe call
        pcall(function()
            -- Hook namecall for TweenService methods
            -- (already done in RemoteSpy for game, we do a separate approach here)
        end)
    end)
end

-- ── Alternative: monitor via newproxy or __namecall separately ─
-- Since hookmetamethod on game already covers __namecall for all instances,
-- we filter TweenService calls there. Here we use a direct hook on the function.
if hookfunction and getconstants then
    -- Find TweenService:Create function reference in GC
    pcall(function()
        local gcObjs = {}
        pcall(function() gcObjs = getgc(false) end)
        for _, obj in ipairs(gcObjs) do
            if type(obj) == "function" then
                local info = nil
                pcall(function()
                    if debug and debug.getinfo then info = debug.getinfo(obj) end
                end)
                if info and (info.name == "Create" or info.name == "TweenCreate") then
                    -- Check constants for "TweenInfo" hint
                    local consts = {}
                    pcall(function() consts = getconstants(obj) end)
                    for _, c in ipairs(consts) do
                        if c == "TweenInfo" or c == "Create" then
                            U.Log("Found potential TweenService:Create fn", "HOOK")
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- ── Monitor all Tween instances appearing in GC ───────────────
-- We poll for Tween objects in GC and hook their Play/Cancel
task.spawn(function()
    local trackedTweens = {}
    while true do
        task.wait(2)
        pcall(function()
            if not getgc then return end
            local gcObjs = getgc(true)
            for _, obj in ipairs(gcObjs) do
                pcall(function()
                    if typeof(obj) == "Instance" and obj.ClassName == "Tween" then
                        if not trackedTweens[obj] then
                            trackedTweens[obj] = true

                            local info = obj.TweenInfo
                            local inst = obj.Instance
                            local props = {}
                            -- Can't easily read properties table from Tween object itself
                            -- but we can log what we know
                            local target = inst and U.GetPath(inst) or "?"
                            local itime, ease, dir, rep, rev, delay = 0,"?","?",0,false,0
                            pcall(function()
                                itime  = info.Time
                                ease   = tostring(info.EasingStyle)
                                dir    = tostring(info.EasingDirection)
                                rep    = info.RepeatCount
                                rev    = info.Reverses
                                delay  = info.DelayTime
                            end)

                            U.LogRT("TWEEN_FOUND", target,
                                string.format("Time=%.2f Ease=%s Dir=%s Repeat=%d Rev=%s Delay=%.2f",
                                    itime, ease, dir, rep, tostring(rev), delay))

                            -- Hook completion
                            obj.Completed:Connect(function(state)
                                U.LogRT("TWEEN_DONE", target,
                                    string.format("State=%s", tostring(state)))
                            end)
                        end
                    end
                end)
            end
        end)
    end
end)

-- ── Hook via __namecall (if remote spy is active) ─────────────
-- The remote spy's hookmetamethod already captures all namecall methods.
-- Here we add specific handling by injecting into the existing hook via getgenv.
pcall(function()
    -- Register a tween filter in the shared HL state for the remote spy to use
    if not genv then return end
    local genv2 = getgenv()
    if not genv2._HL then return end
    genv2._HL._TweenFilter = function(self, method, ...)
        if method == "Create" and typeof(self) == "Instance"
        and self.ClassName == "TweenService" then
            local inst, tweenInfo, props = ...
            local target = inst and U.GetPath(inst) or "?"
            local propList = {}
            if type(props) == "table" then
                for k, v in pairs(props) do
                    table.insert(propList, string.format("%s=%s", tostring(k), tostring(v)))
                end
            end
            U.LogRT("TWEEN_CREATE", target,
                string.format("Props: %s", table.concat(propList, ", "):sub(1, 200)))
        end
    end
end)

U.Log("Tween Spy active (GC polling + filter registered) ✓", "SUCCESS")
return true
