-- ============================================================
--  dump/D_Collection.lua
--  CollectionService tags, Teams, Chat channels
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL
local U  = HL.Utils
local S  = HL.Services
local St = HL.Stats

U.S_Header("SECTION 6 — COLLECTION SERVICE, TEAMS & CHAT")

-- ── CollectionService Tags ────────────────────────────────────
U.S_SubHeader("6.1 CollectionService — All Tags")
local tags = {}
pcall(function() tags = S.CollectionService:GetTags() end)
U.S_Push(string.format("  Total tags found: %d", #tags))
St.TotalTags = #tags

for _, tag in ipairs(tags) do
    pcall(function()
        local tagged = S.CollectionService:GetTagged(tag)
        St.TotalTaggedInstances = St.TotalTaggedInstances + #tagged
        U.S_Push(string.format("  [TAG] '%s' — %d instance(s):", tag, #tagged))
        for _, inst in ipairs(tagged) do
            pcall(function()
                local path = U.GetPath(inst)
                local cls  = U.SafeGet(inst, "ClassName") or "?"
                local attrs = U.DumpAttrs(inst)
                U.S_Push(string.format("    -> <%s> %s%s", cls, path, attrs))
            end)
        end
    end)
end

if #tags == 0 then
    U.S_Push("  [No tags found]")
end

-- ── Teams ─────────────────────────────────────────────────────
U.S_SubHeader("6.2 Teams Service")
if S.Teams then
    local teams = {}
    pcall(function() teams = S.Teams:GetTeams() end)
    U.S_Push(string.format("  Total teams: %d", #teams))
    for _, team in ipairs(teams) do
        pcall(function()
            local members = team:GetPlayers()
            U.S_Push(string.format("  [Team] '%s' | Color: %s | AutoAssignable: %s | Members: %d",
                team.Name, tostring(team.TeamColor),
                tostring(team.AutoAssignable), #members))
            for _, plr in ipairs(members) do
                U.S_Push(string.format("    -> %s (%s)", plr.Name, plr.DisplayName))
            end
        end)
    end
else
    U.S_Push("  Teams service not available.")
end

-- ── Chat (channels if accessible) ────────────────────────────
U.S_SubHeader("6.3 Chat Service")
if S.Chat then
    U.S_Push("  Chat service present.")
    local ok, kids = pcall(function() return S.Chat:GetChildren() end)
    if ok then
        for _, child in ipairs(kids) do
            pcall(function()
                U.S_Push(string.format("  -> [%s] %s", child.ClassName, child.Name))
            end)
        end
    end
else
    U.S_Push("  Chat service not accessible.")
end

-- ── MarketplaceService — Game Info ────────────────────────────
U.S_SubHeader("6.4 Game Metadata (MarketplaceService)")
if S.MarketplaceService then
    pcall(function()
        local info = S.MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
        if info then
            U.S_Push(string.format("  PlaceId       : %d", game.PlaceId))
            U.S_Push(string.format("  Name          : %s", tostring(info.Name)))
            U.S_Push(string.format("  Description   : %s", tostring(info.Description):sub(1, 200)))
            U.S_Push(string.format("  Creator       : %s", tostring(info.Creator and info.Creator.Name or "?")))
            U.S_Push(string.format("  PriceInRobux  : %s", tostring(info.PriceInRobux)))
            U.S_Push(string.format("  AssetTypeId   : %s", tostring(info.AssetTypeId)))
            U.S_Push(string.format("  IsPublicDomain: %s", tostring(info.IsPublicDomain)))
        end
    end)
    U.S_Push(string.format("  game.GameId   : %d", game.GameId))
    U.S_Push(string.format("  game.JobId    : %s", tostring(game.JobId)))
    U.S_Push(string.format("  game.CreatorId: %d", game.CreatorId))
    U.S_Push(string.format("  game.CreatorType: %s", tostring(game.CreatorType)))
    U.S_Push(string.format("  game.Name     : %s", tostring(game.Name)))
else
    U.S_Push("  MarketplaceService not available.")
end

-- ── PhysicsService — Collision Groups ─────────────────────────
U.S_SubHeader("6.5 PhysicsService — Collision Groups")
if S.PhysicsService then
    pcall(function()
        -- Modern API
        local groups = {}
        local ok2, gr = pcall(function() return S.PhysicsService:GetRegisteredPhysicsGroups() end)
        if ok2 then groups = gr end
        if #groups == 0 then
            -- Try deprecated API
            ok2, gr = pcall(function()
                local list = {}
                for i = 0, 31 do
                    local gok, name = pcall(function()
                        return S.PhysicsService:GetCollisionGroupName(i)
                    end)
                    if gok and name and name ~= "" then
                        table.insert(list, {Name=name, Id=i})
                    end
                end
                return list
            end)
            if ok2 then groups = gr end
        end
        U.S_Push(string.format("  Total collision groups: %d", #groups))
        for _, g in ipairs(groups) do
            pcall(function()
                local gname = type(g) == "table" and (g.Name or tostring(g)) or tostring(g)
                U.S_Push("    -> " .. gname)
            end)
        end
    end)
else
    U.S_Push("  PhysicsService not available.")
end

U.Log("D_Collection done", "DUMP")
return true
