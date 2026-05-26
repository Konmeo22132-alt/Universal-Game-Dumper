# 👁️ Universal Game Dumper (HuneLog v2.0)

A highly advanced, modular, and comprehensive Roblox Game Dumper and Real-time Spy script. Capable of performing extreme deep scans on any Roblox game and logging real-time events.

## 🔥 Features
- **Deep Static Dumper**: Dumps everything from WorkSpace geometry, Network Ownership, Lighting, Physics, to Hidden Instances.
- **Garbage Collector Scan**: Uses `getgc()` to find hidden RemoteEvents, secret Tables, and loaded ModuleScripts.
- **Metatable & Anti-Cheat Analysis**: Detects hooks on `__namecall`, scans upvalues, and flags potential Anti-Cheat measures.
- **Real-time Spy Hooks**: 
  - 📡 **Remote Spy**: Logs `FireServer`, `InvokeServer`, and serialized arguments.
  - 🖱️ **Proximity & Click Spy**: Logs all prompt interactions and ClickDetector events.
  - 🖥️ **GUI Spy**: Watches for new UI elements, buttons clicks, and TextBox inputs.
  - 🏃 **Character Spy**: Tracks damage, state changes, tool equips, and touches.

## 🚀 How to Execute

You do not need to download the files! Just run this single `loadstring` in your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Konmeo22132-alt/Universal-Game-Dumper/main/main.lua"))()
```

## 🛠️ Configuration
If you want to run it locally from your executor's `workspace` folder instead of GitHub, open `main.lua` and set:
```lua
local USE_GITHUB = false
```

*Note: The script outputs logs to your executor's `workspace/HuneLog_Dumps/` folder.*
