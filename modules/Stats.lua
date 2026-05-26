-- ============================================================
--  modules/Stats.lua
--  Global statistics counters for the static dump summary
-- ============================================================
local HL = (getgenv and getgenv()._HL) or _G._HL

HL.Stats = {
    -- Remotes & Bindables
    RemoteEvents          = 0,
    RemoteFunctions       = 0,
    UnreliableRemoteEvents= 0,
    BindableEvents        = 0,
    BindableFunctions     = 0,

    -- Interaction objects
    ProximityPrompts      = 0,
    ClickDetectors        = 0,

    -- Scripts
    Scripts               = 0,
    LocalScripts          = 0,
    ModuleScripts         = 0,

    -- GUI elements
    ScreenGuis            = 0,
    Frames                = 0,
    ScrollingFrames       = 0,
    TextLabels            = 0,
    TextButtons           = 0,
    ImageButtons          = 0,
    ImageLabels           = 0,
    TextBoxes             = 0,
    BillboardGuis         = 0,
    SurfaceGuis           = 0,

    -- Values
    StringValues          = 0,
    IntValues             = 0,
    NumberValues          = 0,
    BoolValues            = 0,
    ObjectValues          = 0,
    Vector3Values         = 0,
    CFrameValues          = 0,

    -- Physics/World
    BaseParts             = 0,
    AnchoredParts         = 0,
    UnanchoredParts       = 0,
    NetworkOwnedParts     = 0,
    Models                = 0,
    Welds                 = 0,
    Constraints           = 0,

    -- Sound
    Sounds                = 0,
    SoundGroups           = 0,

    -- Animations
    AnimationTracks       = 0,
    Animations            = 0,

    -- Particles
    ParticleEmitters      = 0,

    -- Tools
    Tools                 = 0,

    -- Folders
    Folders               = 0,

    -- CollectionService
    TotalTags             = 0,
    TotalTaggedInstances  = 0,

    -- GC scanner
    GCFunctionsFound      = 0,
    GCTablesFound         = 0,
    GCRemoteRefs          = 0,

    -- Metatables
    MetatablesFound       = 0,
    HookedMetamethods     = 0,

    -- Upvalues
    UpvaluesScanned       = 0,
    UpvalueRemoteRefs     = 0,

    -- Realtime (updated at runtime)
    TotalRemotesLogged    = 0,
    TotalClicksLogged     = 0,
    TotalPromptsLogged    = 0,
    TotalGUIChanges       = 0,
}

-- Convenience increment
function HL.Stats:Inc(key, amount)
    amount = amount or 1
    if self[key] ~= nil then
        self[key] = self[key] + amount
    end
end

-- Track an instance for stats
function HL.Stats:Track(inst)
    pcall(function()
        local cls = inst.ClassName
        if cls == "RemoteEvent"           then self:Inc("RemoteEvents")
        elseif cls == "RemoteFunction"    then self:Inc("RemoteFunctions")
        elseif cls == "UnreliableRemoteEvent" then self:Inc("UnreliableRemoteEvents")
        elseif cls == "BindableEvent"     then self:Inc("BindableEvents")
        elseif cls == "BindableFunction"  then self:Inc("BindableFunctions")
        elseif cls == "ProximityPrompt"   then self:Inc("ProximityPrompts")
        elseif cls == "ClickDetector"     then self:Inc("ClickDetectors")
        elseif cls == "Script"            then self:Inc("Scripts")
        elseif cls == "LocalScript"       then self:Inc("LocalScripts")
        elseif cls == "ModuleScript"      then self:Inc("ModuleScripts")
        elseif cls == "ScreenGui"         then self:Inc("ScreenGuis")
        elseif cls == "Frame"             then self:Inc("Frames")
        elseif cls == "ScrollingFrame"    then self:Inc("ScrollingFrames")
        elseif cls == "TextLabel"         then self:Inc("TextLabels")
        elseif cls == "TextButton"        then self:Inc("TextButtons")
        elseif cls == "ImageButton"       then self:Inc("ImageButtons")
        elseif cls == "ImageLabel"        then self:Inc("ImageLabels")
        elseif cls == "TextBox"           then self:Inc("TextBoxes")
        elseif cls == "BillboardGui"      then self:Inc("BillboardGuis")
        elseif cls == "SurfaceGui"        then self:Inc("SurfaceGuis")
        elseif cls == "StringValue"       then self:Inc("StringValues")
        elseif cls == "IntValue"          then self:Inc("IntValues")
        elseif cls == "NumberValue"       then self:Inc("NumberValues")
        elseif cls == "BoolValue"         then self:Inc("BoolValues")
        elseif cls == "ObjectValue"       then self:Inc("ObjectValues")
        elseif cls == "Vector3Value"      then self:Inc("Vector3Values")
        elseif cls == "CFrameValue"       then self:Inc("CFrameValues")
        elseif cls == "Sound"             then self:Inc("Sounds")
        elseif cls == "SoundGroup"        then self:Inc("SoundGroups")
        elseif cls == "Animation"         then self:Inc("Animations")
        elseif cls == "ParticleEmitter"   then self:Inc("ParticleEmitters")
        elseif cls == "Tool"              then self:Inc("Tools")
        elseif cls == "Folder"            then self:Inc("Folders")
        elseif cls == "WeldConstraint" or cls == "Weld" or cls == "Motor6D" then self:Inc("Welds")
        elseif cls == "Model"             then self:Inc("Models")
        end
        -- BasePart check
        local ok = pcall(function()
            if inst:IsA("BasePart") then
                self:Inc("BaseParts")
                if inst.Anchored then
                    self:Inc("AnchoredParts")
                else
                    self:Inc("UnanchoredParts")
                end
            end
        end)
    end)
end

return HL.Stats
