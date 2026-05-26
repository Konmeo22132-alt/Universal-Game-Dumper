-- ============================================================
--  modules/StaticWriter.lua
--  Writes the accumulated StaticLines to disk and prints summary
-- ============================================================
local HL   = (getgenv and getgenv()._HL) or _G._HL
local Cfg  = HL.Config
local U    = HL.Utils
local St   = HL.Stats

U.S_Header("SUMMARY — TOTAL OBJECT COUNTS")

-- Sorted key output
local keys = {}
for k in pairs(St) do
    if type(St[k]) == "number" then
        table.insert(keys, k)
    end
end
table.sort(keys)

for _, k in ipairs(keys) do
    U.S_Push(string.format("  %-35s %d", k, St[k]))
end

U.S_Push("\n" .. string.rep("═", 60))
U.S_Push(string.format("  HuneLog Static Dump generated at: %s", tostring(HL.StartTime)))
U.S_Push(string.format("  Elapsed: %.2fs | Game: %s (PlaceId: %d)",
    os.clock() - HL.StartClock,
    tostring(game.Name),
    game.PlaceId))
U.S_Push(string.rep("═", 60))

-- Write to disk
local content = table.concat(HL.StaticLines, "\n")
local ok, err = pcall(writefile, Cfg.StaticFile, content)
if ok then
    U.Log("Static dump saved → " .. Cfg.StaticFile .. " (" .. #content .. " bytes)", "SUCCESS")
else
    U.Log("Failed to write static file: " .. tostring(err), "ERROR")
end

-- Initialize realtime file
pcall(writefile, Cfg.RealtimeFile, string.format(
    "=== HuneLog Realtime Log | %s | Place: %d ===\n",
    tostring(HL.StartTime), game.PlaceId))

return true
