-- ============================================================
--  modules/Config.lua
--  Central configuration & constants for HuneLog v2.0
-- ============================================================
local HL = getgenv and getgenv()._HL or _G._HL

HL.Config = {
    -- File output names (relative to executor workspace)
    StaticFile      = "HuneLog_static.txt",
    RealtimeFile    = "HuneLog_realtime.txt",
    RawRemoteFile   = "HuneLog_remotes_raw.txt",
    GCDumpFile      = "HuneLog_gc_dump.txt",
    MetaFile        = "HuneLog_metatables.txt",
    UpvalueFile     = "HuneLog_upvalues.txt",

    -- Traversal limits (prevent infinite recursion / huge output)
    MaxDepth        = 999,   -- Max tree recursion depth (practical limit)
    MaxChildren     = 5000,  -- Max children to iterate per instance
    MaxGCObjects    = 8000,  -- Max objects to inspect from GC

    -- Realtime logging
    UseAppendFile   = true,  -- Try appendfile() first, fallback to readfile+writefile
    QueueFlushSize  = 20,    -- Flush realtime queue every N entries

    -- Remote spy
    LogFireAllClients   = true,
    LogFireClient       = true,
    LogInvokeServer     = true,
    LogFireServer       = true,
    SerializeArgsJSON   = true,  -- Try JSON first, fallback tostring

    -- Anti-cheat detection
    ScanForHyperion     = true,
    ScanForByfron       = true,
    ScanForCustomAC     = true,

    -- GC scanner
    GCScanFunctions     = true,
    GCScanTables        = true,
    GCScanUserdata      = false, -- Can be slow/crash

    -- Physics scan
    CheckNetworkOwner   = true,
    LogUnanchoredParts  = true,

    -- Property spy (H_PropertySpy)
    PropertySpyTargets  = {
        "Health", "WalkSpeed", "JumpPower", "MaxHealth",
        "CFrame", "Position", "Velocity", "RotVelocity",
        "Value", "Enabled", "Visible", "Text",
    },

    -- Tween spy
    LogTweenCreation    = true,
    LogTweenPlay        = true,

    -- Chat spy
    LogIncomingChat     = true,
    LogOutgoingChat     = true,

    -- Upvalue scanner targets (class names to look for upvalue refs)
    UpvalueClassTargets = {
        "RemoteEvent", "RemoteFunction", "BindableEvent",
        "UnreliableRemoteEvent", "BindableFunction",
    },

    -- Upvalue max depth for nested protos
    UpvalueProtoDepth   = 3,

    -- Connection spy (which signals to dump)
    ConnectionScanSignals = {
        "MouseClick", "Triggered", "FireServer", "InvokeServer",
        "Changed", "ChildAdded", "ChildRemoved", "DescendantAdded",
        "StateChanged", "Died", "OnClientEvent",
    },

    -- Console color codes (rconsoleprint format)
    Colors = {
        SYS     = "@@CYAN@@",
        DUMP    = "@@WHITE@@",
        HOOK    = "@@YELLOW@@",
        ERROR   = "@@RED@@",
        SUCCESS = "@@GREEN@@",
        WARN    = "@@ORANGE@@",
        REMOTE  = "@@MAGENTA@@",
        GC      = "@@LIGHTBLUE@@",
        META    = "@@PINK@@",
        ANTI    = "@@RED@@",
    },
}

return HL.Config
