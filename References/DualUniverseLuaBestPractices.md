# Dual Universe Lua Best Practices and Ruleset

## Overview
This document outlines the best practices and ruleset for programming in Dual Universe Lua, focusing on the following components:
- Programming Boards (default executable for scripts on non-flying tasks)
- ScreenUnits (displaying Lua code as visual elements similar to HTML with bidirectional output)
- Databanks (persistent data storage between run-cycles)
- LUA-CHAT (runtime text input system)

This guide covers screen-based interactive interfaces, AR-functionalities, modular design patterns, and foundational framework architecture for Dual Universe scripting.

## Core Systems and Architecture

### 1. Slot System and Unit Integration
The slot system is fundamental to DU-Lua scripting. Each programming board has multiple slots for connecting different unit types:

- **Slot Naming Conventions**: Name slots descriptively (e.g., `radar_1`, `screen`, `databank_main`)
- **Auto-Detection Pattern**: Use class detection to automatically identify and organize slots:

```lua
-- Auto-detect unit types by class
Doors = {}
Fields = {}
Screens = {}
for slotName, slot in pairs(unit) do
    if type(slot) == "table" and slot.getClass then
        local ElementClass = slot.getClass():lower()
        if ElementClass:find("doorunit") then
            table.insert(Doors, slot)
        elseif ElementClass:find("forcefieldunit") then
            table.insert(Fields, slot)
        elseif ElementClass:find("screensignunit") or ElementClass:find("screenunit") then
            table.insert(Screens, slot)
        end
    end
end
```

### 2. Event Handler System
DU-Lua uses event-driven architecture with handlers triggered by specific events. Handler signatures must match exactly including capitalization:

**Unit-Specific Event Handlers:**

*Radar Unit:*
- `enter(id)` - Entity enters radar detection range
- `onLeave(id)` - Entity leaves radar detection range

*Programming Board (System):*
- `start()` - Script initialization (called once when script starts)
- `tick(timerId)` - Timer-based execution (called when timer fires)
- `stop()` - Script termination (called when script stops)
- `onUpdate()` - System update event
- `onInputText(text)` - LUA-CHAT text input received

*Note: Handler names are case-sensitive and must match slot connections exactly*

**Best Practice - Event Handler Template:**
```lua
-- Initialize variables
local state = {
    timer = 0,
    lastId = 0,
    color = ""
}

-- Start handler - initialization
unit.setTimer("UpdateLoop", 0.8)
system.showScreen(1)

-- Tick handler - update loop
if state.timer > 0 then
    state.timer = state.timer - 1
end
```

## Best Practices

### 1. Programming Boards - Script Structure and Organization
- **Use Modular Design**: Break scripts into logical functions with single responsibilities
- **Optimize Performance**: 
  - Avoid complex calculations within tight loops
  - Cache frequently accessed values
  - Use timers for periodic updates instead of continuous loops
  - Monitor script execution time and optimize critical sections

**Performance Optimization Example:**
```lua
-- BAD: Complex calculation in loop
for i = 1, 1000 do
    local result = math.sin(i) * math.cos(i) * math.tan(i)
end

-- GOOD: Pre-calculate and use timer
local precalculated = {}
function precalculate()
    for i = 1, 1000 do
        precalculated[i] = math.sin(i) * math.cos(i) * math.tan(i)
    end
end

unit.setTimer("update", 1.0)
```

- **Library Utilization**: Common functions for string operations, table manipulation, etc.

```lua
-- String splitting utility (commonly used)
function split(s, delimiter)
    local t = {}
    s:gsub("[^" .. delimiter .. "]+", function(w)
        table.insert(t, w)
    end)
    return t
end
```

### 2. ScreenUnits - Visual Rendering and Interaction

#### SVG Rendering System
ScreenUnits support SVG-based rendering for advanced visual interfaces:

```lua
-- Get screen resolution for responsive design
local screenWidth = system.getScreenWidth()
local screenHeight = system.getScreenHeight()

-- Basic SVG with border
local svg = [[
    <style>
        .screen-container {
            position: absolute;
            left: 0;
            top: 0;
            height: 100vh;
            width: 100vw;
        }
    </style>
    <svg class="screen-container">
        <rect x="7" y="7" width="]] .. screenWidth - 15 .. [[" height="]] .. screenHeight - 15 .. [[" 
              stroke="red" stroke-width="15" fill="transparent" />
    </svg>
]]

-- For system screen (Programming Board display)
system.setScreen(svg)

-- For ScreenUnit display (if connected to board)
if screen then
    screen.setSVG(svg)
end
```

#### Render Script System
Advanced visual rendering using render scripts for dynamic, frame-based updates:

```lua
-- Set render script on screen
function setRenderScriptOnScreens(accessGranted)
    for _, screen in pairs(Screens) do
        screen.setRenderScript(getRenderScript(accessGranted))
    end
end

-- Render script with custom drawing
function getRenderScript(access)
    local color = access and "white" or "red"
    local message = access and "Access Granted" or "Access Denied"
    
    return [[
        setBackgroundColor(15/255, 24/255, 29/255)
        local rx, ry = getResolution()
        local smallBold = loadFont('Play-Bold', 40)
        local front = createLayer()
        
        setDefaultFillColor(front, Shape_Text, 0.710, 0.878, 0.941, 1)
        addText(front, smallBold, "]] .. message .. [[", rx/2, ry/2)
        
        requestAnimationFrame(10)
    ]]
end
```

- **Interactive Interfaces**: Design UX with clear feedback and intuitive layouts
- **Bidirectional Communication**: Use screens to display data and receive input through LUA-CHAT
- **Direct Text Output**: Use `screen.setCenteredText()` for simple text display on ScreenUnits

```lua
-- Display text on ScreenUnit
if screen then
    screen.setCenteredText(messageText)
end
```

- **Mouse and Input Handling**:

```lua
-- Detect mouse movement for interaction (on system screen)
if system.getMouseDeltaX() ~= 0 or system.getMouseDeltaY() ~= 0 then
    -- User is interacting with screen
    resetIdleTimer()
end
```

### 3. Databanks - Persistent Data Management

**Data Storage Patterns:**
```lua
-- Initialize data structure
local dataTable = {
    shipInfo = {},
    lastUpdate = 0,
    settings = {}
}

-- Convert to JSON for storage
local jsonData = system.D2K(dataTable)
databank.setData(jsonData)

-- Retrieve and parse
local retrievedData = system.K2D(databank.getData())
```

**Best Practices for Databanks:**
- Serialize complex data structures using system utilities
- Implement versioning for backward compatibility
- Regularly clean up obsolete data to prevent overflow
- Use meaningful keys for organization

```lua
-- Structured databank storage with versioning
local saveData = {
    version = "1.0",
    timestamp = system.getTime(),
    shipRegistry = {},
    config = {
        alertRadius = 5000,
        scanInterval = 0.8
    }
}

-- Save with version check
function saveState()
    if databank then
        databank.setData(system.D2K(saveData))
    end
end
```

### 4. LUA-CHAT and Runtime Input System

**Input Validation and Processing:**
```lua
-- Handle text input from LUA-CHAT
unit.setInputText("Enter command")

function onInputText(text)
    -- Validate input
    if text == nil or text == "" then
        return
    end
    
    -- Parse and execute commands
    if text == "clear" then
        clearData()
        system.print("Data cleared")
    elseif text:match("^set%s+(.+)") then
        local param = text:match("^set%s+(.+)")
        updateParameter(param)
    end
end
```

- **Feedback Mechanism**: Always acknowledge user input with system messages
- **Command Validation**: Implement checks to prevent invalid operations

### 5. Time Management and Scheduling

```lua
-- Convert seconds to formatted time
function convertSectoDay(seconds)
    local day = math.floor(seconds / (24 * 3600))
    seconds = seconds % (24 * 3600)
    local hour = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return day, hour, minutes, secs
end

-- Timer-based scheduling
function onTick(timerId)
    if timerId == "UpdateLoop" then
        local currentTime = system.getTime()
        if currentTime - lastUpdate >= updateInterval then
            performUpdate()
            lastUpdate = currentTime
        end
    end
end

-- Set timer
unit.setTimer("UpdateLoop", 0.8)  -- Tick every 0.8 seconds
```

### 6. System-Level Operations

**Audio and System Feedback:**
```lua
-- Play system sounds for feedback
system.playSound("contact.mp3")      -- On new contact
system.playSound("targetleft.mp3")   -- On target loss
system.playSound("alert.mp3")        -- On alert condition
```

**System State Management:**
```lua
-- Control UI visibility
system.showScreen(1)      -- Show screen
system.hideWidget()        -- Hide unit widget
unit.hideWidget()         -- Alternative hide method

-- Get player position and waypoints
local waypoint = system.getWaypointFromPlayerPos()

-- Retrieve organization data
local org = system.getOrganization(orgId)
if org.name then
    system.print("Organization: " .. org.name)
end
```

## Ruleset and Limitations

### 1. Script Length Constraints
- **Maximum Script Size**: DU-Lua scripts have practical limits based on execution environment
  - Handler code per slot: Keep reasonable (typically under 50KB per handler)
  - Total script per board: Can handle moderate sizes but test for performance
- **Breaking Up Complex Scripts**: 
  - If a script handler exceeds ~30KB of code, consider modular breakup
  - Split functionality into separate programming boards with inter-board communication
  - Use databanks to share state between boards
  - Document dependencies clearly between boards

### 2. Performance Limitations
- **Execution Time Budget**: Each handler execution should complete quickly
  - Target: Keep handler execution under 10-20ms
  - Maximum: Avoid handlers that exceed 100ms execution time
  - Each `tick()` call budget: ~5-10ms for responsive UI
- **Optimization Requirements**:
  - Avoid nested loops with high iteration counts (>1000 iterations)
  - Cache calculations that don't change frequently  
  - Use efficient data structures (tables, local variables)
  - Profile and optimize hot paths
  - Use timer-based updates instead of frame-based when possible
  
```lua
-- INEFFICIENT: Recalculating every frame
function onTick(timerId)
    for i = 1, #bigTable do
        for j = 1, #anotherTable do
            local value = expensiveCalculation(i, j)
        end
    end
end

-- EFFICIENT: Cache and batch process
local cache = {}
function precomputeValues()
    for i = 1, #bigTable do
        for j = 1, #anotherTable do
            cache[i][j] = expensiveCalculation(i, j)
        end
    end
end

function onTick(timerId)
    -- Use cached values instead
    processWithCache()
end
```

### 3. Slot Connection and Handler Execution

**Handler Execution Model:**
- Each slot connection to a unit triggers specific event handlers
- Handlers for the same unit connection run sequentially in definition order
- Different unit connections (different slots) can have independent event triggering
- Timer events execute independently based on timer ID

**Best Practice - Handler Organization:**
```lua
-- Handler organization in JSON (slot-based):
-- Slot 0 (Radar) Handler: enter() event -> high priority
-- Slot -1 (System) Handler: tick() event -> update game state
-- Slot -1 (System) Handler: onUpdate() event -> display changes
```

*Important: Verify slot connections in your JSON configuration - handlers only fire if connected to correct slot*

### 4. System API and Current Implementation

**Current DU-Lua API (As of 2026):**
- `system.setScreen(svgString)` - Display SVG on system screen (Programming Board display)
- `screen.setSVG(svgString)` - Display SVG on connected ScreenUnit
- `screen.setRenderScript(luaScript)` - Advanced rendering with render script (ScreenUnit only)
- `screen.setCenteredText(text)` - Simple text display (ScreenUnit)
- `system.getScreenWidth()` / `system.getScreenHeight()` - Get display dimensions
- `system.getMouseDeltaX()` / `system.getMouseDeltaY()` - Get mouse input
- `system.playSound(filename)` - Play audio feedback
- `unit.setTimer(timerId, interval)` - Create recurring timer
- `system.D2K(table)` / `system.K2D(jsonString)` - Serialize/deserialize data

**API Guidelines:**
- Always check [DU-Lua Codex](https://du-lua.dev/#/codex) for latest method signatures
- When updating constructs, test all handler connections thoroughly
- Use `system.print()` for debugging - output goes to construct logs
- Verify object types before calling methods (use `type()` checks)

### 5. Library Outsourcing Policy

**Conditions for Outsourcing to Local Libraries:**
1. ⚠️ **Requires explicit approval before implementation**
2. Libraries must be:
   - Thoroughly documented with examples
   - Version-controlled with clear versioning
   - Well-maintained and tested
   - Properly imported and managed

```lua
-- Library usage pattern (after approval)
require('library_name')

-- Include with namespace
local myLib = require('my_utility_library')
result = myLib.customFunction(param)
```

## Common Patterns and Best Practices

### Pattern 1: Configuration Management
```lua
-- Centralized configuration
local Config = {
    AllowedUsersName = "UserA,UserB,UserC",  -- export
    AllowedUserOrgsName = "MyOrg",            -- export
    alertRadius = 5000,                       -- export
    scanInterval = 0.8                        -- export
}

-- Parse configuration
local function parseConfig(configString)
    local items = split(configString, ',')
    return items
end
```

### Pattern 2: Access Control
```lua
-- Multi-layer permission checking
local function checkAccess(player)
    -- Check user ID
    if isUserAllowed(player.getId()) then
        return true
    end
    
    -- Check user name
    if isUserNameAllowed(player.getName()) then
        return true
    end
    
    -- Check organization
    local orgIds = player.getOrgIds()
    for _, orgId in pairs(orgIds) do
        if isOrgAllowed(orgId) then
            return true
        end
    end
    
    return false
end
```

### Pattern 3: Hashing and Identification
```lua
-- Generate consistent identifiers
function getHash(x)
    x = ((x >> 16) ~ x) * 0x45d9f3b
    x = ((x >> 16) ~ x) * 0x45d9f3b
    x = (x >> 16) ~ x
    if x < 0 then x = ~x end
    return x
end

-- Use for ship naming
function getShortName(id)
    local seed = getHash(id) % 8388593
    local a = (seed * 653276) % 8388593
    local b = (a * 653276) % 8388593
    local c = (b * 653276) % 8388593
    return kCharSet[a % kCharSetSize + 1] .. 
           kCharSet[b % kCharSetSize + 1] .. 
           kCharSet[c % kCharSetSize + 1]
end
```

## Advanced Topics

### Radar Systems and Entity Tracking

The radar system is crucial for awareness and automation in space-based constructs:

```lua
-- Radar event handler - detect new contacts
function onRadarEnter(contactId)
    system.print("New Ship on radar: " .. contactId)
    alarm.lastId = contactId
    alarm.timer = 3
    system.playSound("contact.mp3")
end

-- Radar event handler - contact lost
function onRadarLeave(contactId)
    system.playSound("targetleft.mp3")
    removeFromTracking(contactId)
end

-- Extract and classify radar contact
function getShipInfo(shipId)
    if shipId <= 0 then return end
    
    local name = radar_1.getConstructName(shipId)
    local sizeCode = radar_1.getConstructSize(shipId)[1]
    local isAbandoned = radar_1.isConstructAbandoned(shipId) == 1
    local isAlly = radar_1.hasMatchingTransponder(shipId) == 1
    
    -- Map size codes to names
    local sizeMap = {
        [32] = "XS",
        [64] = "S",
        [128] = "M",
        [256] = "L"
    }
    local size = sizeMap[sizeCode] or "Unknown"
    
    -- Determine entity type
    local entityType = "Unknown"
    local displayColor = "red"
    
    if isAbandoned then
        entityType = "Abandoned"
        displayColor = "yellow"
    elseif isAlly then
        entityType = "Ally"
        displayColor = "lightseagreen"
    else
        entityType = "Ship"
        displayColor = "red"
    end
    
    -- Get current position info
    local waypoint = system.getWaypointFromPlayerPos()
    local shipInfo = {
        type = entityType,
        name = name,
        size = size,
        id = shipId,
        shortName = getShortName(shipId),
        color = displayColor,
        position = waypoint,
        detected = system.getTime()
    }
    
    return shipInfo
end
```

### Utility Functions Library

**String and Data Manipulation:**
```lua
-- Split string by delimiter
function split(s, delimiter)
    local t = {}
    s:gsub("[^" .. delimiter .. "]+", function(w)
        table.insert(t, w)
    end)
    return t
end

-- Trim whitespace
function trim(s)
    return s:match("^%s*(.*%S)%s*$") or ""
end

-- String padding
function padString(str, length, char)
    char = char or " "
    return str .. string.rep(char, math.max(0, length - #str))
end

-- Format numbers with thousand separators
function formatNumber(num)
    local str = tostring(num)
    local result = ""
    for i = 1, #str do
        if i > 1 and (i - 1) % 3 == 0 then
            result = "," .. result
        end
        result = str:sub(#str - i + 1, #str - i + 1) .. result
    end
    return result
end
```

**Table Utilities:**
```lua
-- Deep copy table
function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Merge tables
function mergeTables(t1, t2)
    local result = deepCopy(t1)
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

-- Find value in table
function tableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Get table size
function tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Filter table by predicate
function filterTable(tbl, predicate)
    local result = {}
    for k, v in pairs(tbl) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end
```

**Hashing and Identification:**
```lua
-- Character set generation (skip O, Q, 0 for clarity)
local kSkipCharSet = { ["O"] = true, ["Q"] = true, ["0"] = true }
local kCharSet = {}

function buildCharacterSet()
    addRangeToCharSet(48, 57)  -- 0-9
    addRangeToCharSet(65, 90)  -- A-Z
    return kCharSet
end

function addRangeToCharSet(startCode, endCode)
    for i = startCode, endCode do
        local c = string.char(i)
        if not kSkipCharSet[c] then
            table.insert(kCharSet, c)
        end
    end
end

-- Deterministic hash function
function getHash(x)
    x = ((x >> 16) ~ x) * 0x45d9f3b
    x = ((x >> 16) ~ x) * 0x45d9f3b
    x = (x >> 16) ~ x
    if x < 0 then x = ~x end
    return x
end

-- Generate unique short identifier from ID
function getShortName(id)
    local seed = getHash(id) % 8388593
    local a = (seed * 653276) % 8388593
    local b = (a * 653276) % 8388593
    local c = (b * 653276) % 8388593
    local charSetSize = #kCharSet
    
    return kCharSet[a % charSetSize + 1] ..
           kCharSet[b % charSetSize + 1] ..
           kCharSet[c % charSetSize + 1]
end
```

### Rendering System Deep Dive

**Dynamic Responsive Rendering:**
```lua
-- Get display dimensions
function getDisplayDimensions()
    local width = system.getScreenWidth()
    local height = system.getScreenHeight()
    
    -- Account for virtual mode rotation
    local vmode = system.isVirtualDisplayMode()
    local vmodeSide = system.getVirtualDisplaySide()
    
    if vmode then
        height, width = width, height  -- Swap for rotated display
        if vmodeSide == "right" then
            -- Additional adjustments for right-side mounting
        end
    end
    
    return { width = width, height = height, virtualMode = vmode }
end

-- Build responsive SVG container
function buildResponsiveContainer()
    local dim = getDisplayDimensions()
    return [[
        <style>
            .responsive-container {
                position: absolute;
                left: 0;
                top: 0;
                width: 100vw;
                height: 100vh;
                overflow: hidden;
            }
            .border-frame {
                stroke-width: 15;
                stroke: red;
                fill: none;
            }
        </style>
        <svg class="responsive-container">
            <rect class="border-frame" 
                  x="7" y="7" 
                  width="]] .. dim.width - 15 .. [[" 
                  height="]] .. dim.height - 15 .. [[" />
        </svg>
    ]]
end

-- Animation support
function buildAnimatedAlert(color, message)
    return [[
        setBackgroundColor(15/255, 24/255, 29/255)
        local rx, ry = getResolution()
        local time = getTime()
        local pulse = (math.sin(time * 4) + 1) / 2  -- 0 to 1 pulse
        
        local front = createLayer()
        local back = createLayer()
        
        -- Draw pulsing border
        setDefaultStrokeColor(back, Shape_Line, ]] .. color .. [[[1] * pulse, ]] .. color .. [[[2], ]] .. color .. [[[3], 1)
        setDefaultShadow(back, Shape_Line, 6, 0, 0, 0, pulse)
        
        addLine(back, 0, 100, rx, 100)
        addText(front, loadFont('Play-Bold', 40), "]] .. message .. [[", rx/2, ry/2)
        
        requestAnimationFrame(10)
    ]]
end
```

**Render Script Framework:**
```lua
-- Complete render script system
RenderScript = {}

function RenderScript:new(options)
    local obj = {
        backgroundColor = options.backgroundColor or {15/255, 24/255, 29/255},
        textColor = options.textColor or {0.710, 0.878, 0.941},
        headerHeight = options.headerHeight or 55,
        padding = options.padding or 20,
        layers = {},
        elements = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function RenderScript:build()
    return [[
        setBackgroundColor(]] .. self.backgroundColor[1] .. [[, ]] .. self.backgroundColor[2] .. [[, ]] .. self.backgroundColor[3] .. [[)
        local rx, ry = getResolution()
        
        local front = createLayer()
        local back = createLayer()
        
        setDefaultFillColor(front, Shape_Text, ]] .. self.textColor[1] .. [[, ]] .. self.textColor[2] .. [[, ]] .. self.textColor[3] .. [[, 1)
        
        -- Draw elements
        ]] .. self:renderElements() .. [[
        
        requestAnimationFrame(10)
    ]]
end

function RenderScript:renderElements()
    -- Override in subclass
    return ""
end
```

### State Management and Persistence

**State Machine Pattern:**
```lua
-- Define state machine
StateMachine = {
    states = {
        IDLE = 1,
        SCANNING = 2,
        ALERT = 3,
        LOCKED_DOWN = 4
    },
    currentState = 1
}

function StateMachine:transition(newState)
    if self.currentState == newState then return end
    
    -- Exit handler
    self:onExit(self.currentState)
    
    -- State change
    self.currentState = newState
    
    -- Enter handler
    self:onEnter(newState)
end

function StateMachine:onEnter(state)
    if state == self.states.SCANNING then
        system.print("Entering SCANNING state")
        radar_1.showWidget()
    elseif state == self.states.ALERT then
        system.playSound("alert.mp3")
        activateAlertMode()
    end
end

function StateMachine:onExit(state)
    if state == self.states.ALERT then
        deactivateAlertMode()
    end
end
```

**Persistent State with Databank:**
```lua
-- State persistence layer
StateManager = {}

function StateManager:save(databank, state)
    local serialized = {
        timestamp = system.getTime(),
        version = "1.0",
        state = state,
        checksum = self:calculateChecksum(state)
    }
    databank.setData(system.D2K(serialized))
end

function StateManager:load(databank)
    local data = system.K2D(databank.getData())
    if not data then return nil end
    
    -- Validate checksum
    if data.checksum ~= self:calculateChecksum(data.state) then
        system.print("WARNING: State corruption detected")
        return nil
    end
    
    return data.state
end

function StateManager:calculateChecksum(data)
    local str = system.D2K(data)
    return #str  -- Simple checksum, expand as needed
end
```

### Advanced UI Patterns

**Modal Dialog System:**
```lua
-- Modal state
Modal = {
    isOpen = false,
    title = "",
    message = "",
    buttons = {},
    callback = nil
}

function Modal:open(title, message, buttons, callback)
    self.isOpen = true
    self.title = title
    self.message = message
    self.buttons = buttons
    self.callback = callback
    self:render()
end

function Modal:close()
    self.isOpen = false
    self:render()
end

function Modal:handleInput(inputText)
    if not self.isOpen then return end
    
    for _, button in pairs(self.buttons) do
        if inputText:lower() == button.key:lower() then
            if self.callback then
                self.callback(button.action)
            end
            self:close()
            break
        end
    end
end

function Modal:render()
    if not self.isOpen then return end
    
    local renderScript = [[
        setBackgroundColor(0, 0, 0)
        local rx, ry = getResolution()
        
        local overlay = createLayer()
        local modal = createLayer()
        
        -- Semi-transparent overlay
        setDefaultFillColor(overlay, Shape_Box, 0, 0, 0, 0.7)
        addBox(overlay, 0, 0, rx, ry)
        
        -- Modal box
        setDefaultFillColor(modal, Shape_Box, 0.1, 0.1, 0.1, 1)
        local modalWidth = rx * 0.6
        local modalHeight = ry * 0.4
        local modalX = (rx - modalWidth) / 2
        local modalY = (ry - modalHeight) / 2
        
        addBox(modal, modalX, modalY, modalWidth, modalHeight)
        
        -- Text
        setDefaultFillColor(modal, Shape_Text, 1, 1, 1, 1)
        addText(modal, loadFont('Play-Bold', 24), "]] .. self.title .. [[", rx/2, modalY + 30)
        addText(modal, loadFont('Play', 16), "]] .. self.message .. [[", rx/2, modalY + 100)
        
        requestAnimationFrame(10)
    ]]
    
    if screen then
        screen.setRenderScript(renderScript)
    end
end
```

**List/Menu System:**
```lua
-- Scrollable menu
Menu = {
    items = {},
    selectedIndex = 1,
    visibleCount = 10,
    scrollOffset = 0
}

function Menu:addItem(label, action)
    table.insert(self.items, { label = label, action = action })
end

function Menu:moveSelection(direction)
    self.selectedIndex = self.selectedIndex + direction
    
    -- Clamp to valid range
    if self.selectedIndex < 1 then
        self.selectedIndex = 1
    elseif self.selectedIndex > #self.items then
        self.selectedIndex = #self.items
    end
    
    -- Adjust scroll to keep selection visible
    if self.selectedIndex < self.scrollOffset + 1 then
        self.scrollOffset = self.selectedIndex - 1
    elseif self.selectedIndex > self.scrollOffset + self.visibleCount then
        self.scrollOffset = self.selectedIndex - self.visibleCount
    end
    
    self:render()
end

function Menu:selectCurrent()
    local item = self.items[self.selectedIndex]
    if item and item.action then
        item.action()
    end
end

function Menu:render()
    local renderScript = "-- Render menu here\n"
    if screen then
        screen.setRenderScript(renderScript)
    end
end
```

### Debugging and Logging

**Comprehensive Logging System:**
```lua
-- Logging levels
Logger = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    level = 2,  -- INFO level
    buffer = {},
    maxBuffer = 1000
}

function Logger:log(level, message)
    if level < self.level then return end
    
    local time = system.getTime()
    local entry = {
        timestamp = time,
        level = level,
        message = message
    }
    
    table.insert(self.buffer, entry)
    if #self.buffer > self.maxBuffer then
        table.remove(self.buffer, 1)
    end
    
    -- Also print to console
    system.print(self:formatEntry(entry))
end

function Logger:formatEntry(entry)
    local levelNames = { "DEBUG", "INFO", "WARN", "ERROR" }
    local levelName = levelNames[entry.level] or "UNKNOWN"
    return string.format("[%s] %s", levelName, entry.message)
end

function Logger:debug(msg)
    self:log(self.DEBUG, msg)
end

function Logger:info(msg)
    self:log(self.INFO, msg)
end

function Logger:warn(msg)
    self:log(self.WARN, msg)
end

function Logger:error(msg)
    self:log(self.ERROR, msg)
end

function Logger:getRecentLogs(count)
    local result = {}
    local start = math.max(1, #self.buffer - (count or 50) + 1)
    for i = start, #self.buffer do
        table.insert(result, self:formatEntry(self.buffer[i]))
    end
    return result
end
```

## Code Example: Complete Access Control System

This example demonstrates multiple best practices in action:

```lua
-- Access control with screen rendering
function main()
    -- Initialize
    Doors = {}
    Fields = {}
    Screens = {}
    
    -- Auto-detect and organize slots
    for slotName, slot in pairs(unit) do
        if type(slot) == "table" and slot.getClass then
            local ElementClass = slot.getClass():lower()
            if ElementClass:find("doorunit") then
                table.insert(Doors, slot)
            elseif ElementClass:find("forcefieldunit") then
                table.insert(Fields, slot)
            elseif ElementClass:find("screenunit") then
                table.insert(Screens, slot)
            end
        end
    end
    
    -- Check player access
    local player_id = player.getId()
    local player_name = player.getName()
    local allowed = checkAccessRights(player_id, player_name)
    
    -- Act based on access
    if allowed then
        grantAccess()
    else
        denyAccess()
    end
end

function grantAccess()
    -- Open all doors connected to this board
    for _, door in pairs(Doors) do
        if door and type(door.open) == "function" then
            door.open()
        end
    end
    -- Deactivate all force fields
    for _, field in pairs(Fields) do
        if field and type(field.deactivate) == "function" then
            field.deactivate()
        end
    end
    setScreenState(Screens, true)
end

function denyAccess()
    setScreenState(Screens, false)
end

function setScreenState(screens, granted)
    for _, screenUnit in pairs(screens) do
        if screenUnit and type(screenUnit.setCenteredText) == "function" then
            local message = granted and "Access Granted" or "Access Denied"
            screenUnit.setCenteredText(message)
        end
    end
end
```

## Code Example: Radar Monitoring System

```lua
-- Initialize radar system
function initRadarSystem()
    buildCharacterSet()
    alarm = {
        timer = 0,
        lastId = 0,
        color = ""
    }
    
    unit.setTimer("ScoutHUD", 0.8)
    system.showScreen(1)
    unit.hideWidget()
    radar_1.showWidget()
end

-- Timer tick for radar display (system tick event from Programming Board)
function tick(timerId)
    if timerId ~= "ScoutHUD" then return end
    
    local XScreenRes = system.getScreenWidth()
    local YScreenRes = system.getScreenHeight()
    
    -- Update alarm timer
    if alarm.timer > 0 then
        alarm.timer = alarm.timer - 1
    end
    
    -- Build SVG display for system screen
    local svg = [[
        <style>
            .radar-display {
                position: absolute;
                left: 0;
                top: 0;
                height: 100vh;
                width: 100vw;
            }
        </style>
        <svg class="radar-display">
    ]]
    
    -- Draw alert border if active
    if alarm.timer > 0 then
        svg = svg .. [[<rect x="7" y="7" width="]] .. XScreenRes - 15 .. 
                     [[" height="]] .. YScreenRes - 15 .. 
                     [[" stroke="]] .. alarm.color .. 
                     [[" stroke-width="15" fill="transparent" />]]
    end
    
    svg = svg .. "</svg>"
    
    -- Detect mouse input to reset timer
    if system.getMouseDeltaX() ~= 0 or system.getMouseDeltaY() ~= 0 then
        alarm.timer = alarm.timer - 1
    end
    
    -- Display on system screen
    system.setScreen(svg)
end

-- Radar enter event
function onRadarEnter(contactId)
    system.print("New Ship on radar: " .. contactId)
    alarm.lastId = contactId
    alarm.timer = 3
    system.playSound("contact.mp3")
end

-- Radar leave event
function onRadarLeave(contactId)
    system.playSound("targetleft.mp3")
end

-- Process and display ship info
function processContact(contactId)
    if contactId <= 0 then return end
    
    local shipInfo = getShipInfo(contactId)
    local days, hours, minutes, seconds = convertSectoDay(system.getTime())
    
    local timeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    local info = timeStr .. " " .. shipInfo.type .. ": (" .. shipInfo.shortName .. 
                 ") " .. contactId .. " Name: " .. shipInfo.name .. 
                 " Size: " .. shipInfo.size .. " at " .. shipInfo.position
    
    system.print(info)
    
    if screen then
        screen.setCenteredText(info)
    end
end
```

## Code Example: Complex Permission System

```lua
-- Comprehensive permission checking
local AllowedUsersId = ""      -- export
local AllowedUsersName = "Player1,Player2"  -- export
local AllowedUserOrgsId = ""   -- export
local AllowedUserOrgsName = "MyOrg"  -- export

function checkAccessRights(playerId, playerName)
    -- Level 1: User ID check
    if checkUserIdAccess(playerId) then
        return true
    end
    
    -- Level 2: User name check
    if checkUserNameAccess(playerName) then
        return true
    end
    
    -- Level 3: Organization ID check
    local orgIds = player.getOrgIds()
    for _, orgId in pairs(orgIds) do
        if checkOrgIdAccess(orgId) then
            return true
        end
    end
    
    -- Level 4: Organization name check
    for _, orgId in pairs(orgIds) do
        local org = system.getOrganization(orgId)
        if org and checkOrgNameAccess(org.name) then
            return true
        end
    end
    
    return false
end

function checkUserIdAccess(userId)
    local allowedIds = split(AllowedUsersId, ',')
    return tableContains(allowedIds, tostring(userId))
end

function checkUserNameAccess(userName)
    local allowedNames = split(AllowedUsersName, ',')
    return tableContains(allowedNames, userName)
end

function checkOrgIdAccess(orgId)
    local allowedOrgIds = split(AllowedUserOrgsId, ',')
    return tableContains(allowedOrgIds, tostring(orgId))
end

function checkOrgNameAccess(orgName)
    local allowedOrgNames = split(AllowedUserOrgsName, ',')
    return tableContains(allowedOrgNames, orgName)
end
```

## Error Handling and Validation

**Input Validation Framework:**
```lua
-- Validation utilities
Validator = {}

function Validator:isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

function Validator:isPositive(value)
    return type(value) == "number" and value > 0
end

function Validator:isInRange(value, min, max)
    return type(value) == "number" and value >= min and value <= max
end

function Validator:isString(value)
    return type(value) == "string"
end

function Validator:isTable(value)
    return type(value) == "table"
end

function Validator:isNotEmpty(value)
    if type(value) == "string" then
        return #value > 0
    elseif type(value) == "table" then
        return tableSize(value) > 0
    end
    return value ~= nil
end

function Validator:validate(data, schema)
    local errors = {}
    for field, validator in pairs(schema) do
        if not validator(data[field]) then
            table.insert(errors, field .. " validation failed")
        end
    end
    return #errors == 0, errors
end
```

**Error Handling Patterns:**
```lua
-- Safe function wrapper
function safeCall(func, args, onError)
    local success, result = pcall(function()
        return func(unpack(args or {}))
    end)
    
    if not success then
        if onError then
            onError(result)
        end
        system.print("ERROR: " .. result)
        return nil
    end
    
    return result
end

-- Protected slot access
function safeSlotAccess(slot, method, ...)
    if not slot then
        system.print("ERROR: Slot not found")
        return nil
    end
    
    if not slot[method] then
        system.print("ERROR: Method " .. method .. " not found")
        return nil
    end
    
    return safeCall(slot[method], {...}, function(err)
        system.print("Slot method error: " .. err)
    end)
end

-- Graceful degradation
function useScreenOrPrintback(screen, text)
    if screen and type(screen.setCenteredText) == "function" then
        screen.setCenteredText(text)
    else
        system.print(text)
    end
end
```

## Performance Optimization Guide

**Profiling and Benchmarking:**
```lua
-- Performance profiler
Profiler = {
    marks = {},
    measurements = {}
}

function Profiler:startMark(name)
    self.marks[name] = system.getTime()
end

function Profiler:endMark(name)
    if not self.marks[name] then
        system.print("WARNING: Mark " .. name .. " not started")
        return
    end
    
    local duration = system.getTime() - self.marks[name]
    if not self.measurements[name] then
        self.measurements[name] = { count = 0, total = 0, min = duration, max = duration }
    end
    
    local m = self.measurements[name]
    m.count = m.count + 1
    m.total = m.total + duration
    m.min = math.min(m.min, duration)
    m.max = math.max(m.max, duration)
end

function Profiler:report()
    for name, data in pairs(self.measurements) do
        local avg = data.total / data.count
        system.print(string.format(
            "%s: avg=%.4fs, min=%.4fs, max=%.4fs (calls=%d)",
            name, avg, data.min, data.max, data.count
        ))
    end
end
```

**Memory Optimization:**
```lua
-- Lazy loading pattern
LazyLoader = {}

function LazyLoader:create()
    return {
        data = nil,
        loaded = false,
        loader = nil
    }
end

function LazyLoader:load(lazyObj, loaderFunc)
    lazyObj.loader = loaderFunc
end

function LazyLoader:get(lazyObj)
    if not lazyObj.loaded then
        lazyObj.data = lazyObj.loader()
        lazyObj.loaded = true
    end
    return lazyObj.data
end

-- Object pooling for frequently created objects
ObjectPool = {}

function ObjectPool:create(factory)
    return {
        factory = factory,
        available = {},
        inUse = {}
    }
end

function ObjectPool:acquire(pool)
    local obj
    if #pool.available > 0 then
        obj = table.remove(pool.available)
    else
        obj = pool.factory()
    end
    table.insert(pool.inUse, obj)
    return obj
end

function ObjectPool:release(pool, obj)
    for i, used in pairs(pool.inUse) do
        if used == obj then
            table.remove(pool.inUse, i)
            table.insert(pool.available, obj)
            break
        end
    end
end

function ObjectPool:reset(obj)
    -- Clear object data for reuse
    for k in pairs(obj) do
        obj[k] = nil
    end
end
```

**Caching Strategies:**
```lua
-- Memoization for expensive functions
Cache = {}

function Cache:memoize(func, ttl)
    ttl = ttl or math.huge  -- Time to live in seconds
    local cache = {}
    
    return function(...)
        local key = table.concat({...}, "|")
        local entry = cache[key]
        
        if entry and (entry.time + ttl > system.getTime()) then
            return entry.value
        end
        
        local result = func(...)
        cache[key] = { value = result, time = system.getTime() }
        return result
    end
end

-- LRU (Least Recently Used) cache
LRUCache = {}

function LRUCache:new(maxSize)
    return {
        maxSize = maxSize,
        data = {},
        order = {}
    }
end

function LRUCache:set(cache, key, value)
    if cache.data[key] then
        -- Remove from order
        for i, k in pairs(cache.order) do
            if k == key then
                table.remove(cache.order, i)
                break
            end
        end
    end
    
    -- Add to end (most recent)
    table.insert(cache.order, key)
    cache.data[key] = value
    
    -- Evict least recent if over capacity
    if #cache.order > cache.maxSize then
        local removed = table.remove(cache.order, 1)
        cache.data[removed] = nil
    end
end

function LRUCache:get(cache, key)
    return cache.data[key]
end
```

## Testing and Validation

**Unit Testing Framework:**
```lua
-- Simple test framework
Test = {
    tests = {},
    passed = 0,
    failed = 0
}

function Test:assert(condition, message)
    if not condition then
        system.print("FAIL: " .. (message or "Assertion failed"))
        self.failed = self.failed + 1
        return false
    else
        self.passed = self.passed + 1
        return true
    end
end

function Test:assertEqual(actual, expected, message)
    if actual ~= expected then
        system.print(string.format("FAIL: %s (expected: %s, got: %s)", 
            message or "Equality check", expected, actual))
        self.failed = self.failed + 1
        return false
    end
    self.passed = self.passed + 1
    return true
end

function Test:registerTest(name, testFunc)
    table.insert(self.tests, { name = name, func = testFunc })
end

function Test:runAll()
    system.print("Running " .. #self.tests .. " tests...")
    for _, test in pairs(self.tests) do
        system.print("Running: " .. test.name)
        test.func(self)
    end
    
    local total = self.passed + self.failed
    local percentage = (self.passed / total * 100)
    system.print(string.format("\nResults: %d/%d passed (%.1f%%)", 
        self.passed, total, percentage))
end
```

**Testing Examples:**
```lua
-- Define test cases
Test:registerTest("String Split", function(test)
    local result = split("a,b,c", ",")
    test:assertEqual(#result, 3, "Split array length")
    test:assertEqual(result[1], "a", "First element")
end)

Test:registerTest("Hash Function", function(test)
    local hash1 = getHash(12345)
    local hash2 = getHash(12345)
    test:assertEqual(hash1, hash2, "Hash determinism")
    test:assert(hash1 > 0, "Hash is positive")
end)

Test:registerTest("Table Operations", function(test)
    local tbl = { a = 1, b = 2, c = 3 }
    test:assertEqual(tableSize(tbl), 3, "Table size")
    test:assert(tableContains(tbl, 2), "Table contains value")
end)
```

## Advanced Techniques

### Closures and Callbacks
```lua
-- Function factory pattern
function createCounter(initialValue)
    local value = initialValue or 0
    return function(increment)
        increment = increment or 1
        value = value + increment
        return value
    end
end

-- Usage
local counter = createCounter(10)
system.print(counter(5))  -- 15
system.print(counter(3))  -- 18

-- Event callback system
EventBus = {
    listeners = {}
}

function EventBus:on(event, callback)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    table.insert(self.listeners[event], callback)
end

function EventBus:emit(event, ...)
    if not self.listeners[event] then return end
    for _, callback in pairs(self.listeners[event]) do
        callback(...)
    end
end

-- Usage
EventBus:on("playerEnter", function(playerId, playerName)
    system.print("Player entered: " .. playerName)
end)

EventBus:emit("playerEnter", 123, "Player1")
```

### Metatable Programming
```lua
-- Property validation with metamethods
function createValidatedObject(schema)
    local obj = {}
    
    local meta = {
        __index = function(t, k)
            return rawget(t, "_data")[k]
        end,
        __newindex = function(t, k, v)
            if schema[k] then
                if schema[k](v) then
                    rawget(t, "_data")[k] = v
                else
                    error("Invalid value for property: " .. k)
                end
            else
                rawget(t, "_data")[k] = v
            end
        end
    }
    
    obj._data = {}
    setmetatable(obj, meta)
    return obj
end

-- Usage
local shipSchema = {
    id = function(v) return type(v) == "number" and v > 0 end,
    name = function(v) return type(v) == "string" and #v > 0 end,
    size = function(v) return type(v) == "string" end
}

local ship = createValidatedObject(shipSchema)
ship.id = 123
ship.name = "Explorer"
-- ship.id = -1  -- Would error: "Invalid value for property: id"
```

### Coroutines for Complex Operations
```lua
-- Coroutine-based async operations
AsyncOperation = {}

function AsyncOperation:create(generator)
    return coroutine.create(generator)
end

function AsyncOperation:step(coro)
    local success, result = coroutine.resume(coro)
    if not success then
        system.print("Coroutine error: " .. result)
    end
    return coroutine.status(coro), result
end

-- Example: Long-running operation split across frames
function scanRadarAsync()
    for i = 1, 100 do
        coroutine.yield()
        processRadarData(i)
    end
end

local radarScan = AsyncOperation:create(scanRadarAsync)

-- In main loop:
-- local status = AsyncOperation:step(radarScan)
```

## Common DU-Lua Patterns

### Pattern: Slot Discovery and Registration
```lua
-- Flexible slot auto-detection
local SlotRegistry = {
    slots = {},
    typeMap = {
        door = "DoorUnit",
        screen = {"ScreenUnit", "ScreenSignUnit"},
        databank = "DataBankUnit",
        forcefield = "ForceFieldUnit",
        radar = "RadarUnit",
        switch = "ManualSwitchUnit"
    }
}

function SlotRegistry:scan()
    for slotName, slot in pairs(unit) do
        if type(slot) == "table" and slot.getClass then
            local class = slot.getClass():lower()
            for key, types in pairs(self.typeMap) do
                if type(types) == "table" then
                    for _, t in pairs(types) do
                        if class:find(t:lower()) then
                            self:register(key, slot, slotName)
                            break
                        end
                    end
                else
                    if class:find(types:lower()) then
                        self:register(key, slot, slotName)
                        break
                    end
                end
            end
        end
    end
end

function SlotRegistry:register(key, slot, slotName)
    if not self.slots[key] then
        self.slots[key] = {}
    end
    table.insert(self.slots[key], { slot = slot, name = slotName })
end

function SlotRegistry:getByType(key)
    return self.slots[key] or {}
end
```

### Pattern: Configuration Management
```lua
-- Centralized configuration
Config = {
    version = "1.0",
    debug = false,
    features = {
        radarMonitoring = true,
        accessControl = true,
        soundAlerts = true
    },
    timings = {
        scanInterval = 0.8,
        alertDuration = 3,
        lockdownTimeout = 60
    },
    limits = {
        maxContacts = 100,
        maxStoredData = 10000
    }
}

-- Configuration with validation
function Config:set(key, value)
    -- Validate before setting
    if key == "scanInterval" and value < 0.1 then
        system.print("WARNING: Scan interval too low, clamping to 0.1")
        value = 0.1
    end
    self[key] = value
end

function Config:export()
    -- For saving to databank
    return system.D2K(self)
end

function Config:import(data)
    local loaded = system.K2D(data)
    for k, v in pairs(loaded) do
        self[k] = v
    end
end
```

### Pattern: Event-Driven Architecture
```lua
-- Complete event system
EventSystem = {
    events = {},
    eventHistory = {}
}

function EventSystem:register(eventName, handler, priority)
    priority = priority or 0
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    
    table.insert(self.events[eventName], {
        handler = handler,
        priority = priority
    })
    
    -- Sort by priority
    table.sort(self.events[eventName], function(a, b)
        return a.priority > b.priority
    end)
end

function EventSystem:fire(eventName, ...)
    if not self.events[eventName] then return end
    
    -- Log event
    table.insert(self.eventHistory, {
        name = eventName,
        timestamp = system.getTime(),
        args = {...}
    })
    
    -- Execute handlers
    for _, entry in pairs(self.events[eventName]) do
        local success, result = pcall(entry.handler, ...)
        if not success then
            system.print("Event handler error for " .. eventName .. ": " .. result)
        end
    end
end

function EventSystem:getHistory(count)
    local result = {}
    local start = math.max(1, #self.eventHistory - (count or 50) + 1)
    for i = start, #self.eventHistory do
        table.insert(result, self.eventHistory[i])
    end
    return result
end
```

## Troubleshooting Guide

**Common Issues and Solutions:**

| Issue | Cause | Solution |
|-------|-------|----------|
| Script exceeds size limit | Too much code in single handler | Split into multiple handlers or use external libraries |
| Poor performance (lag) | Expensive operations in loop | Use timers, optimize algorithms, profile with Profiler |
| Slots not found | Incorrect slot detection | Use proper class name matching, debug with system.print |
| Databank errors | Corrupted serialization | Validate data before K2D/D2K, implement checksum |
| Screen not updating | Render script not called | Ensure screen.setRenderScript() is used correctly |
| Event handlers not firing | Wrong signature or no connection | Verify handler name matches event, check slot connections |
| UI unresponsive | Blocking operations | Use coroutines or timers for long operations |

## References and Resources - MUST HAVE TO ALWAYS VERIFY THE WRITTEN CODE
- [DU-Lua Codex - Official Documentation](https://du-lua.dev/#/codex)
- [Dual Universe Official Wiki](https://wiki.dualuniverse.game/)
- Community Discord and Forums

## Changelog
- **Version 2.0** (January 15, 2026): Expanded with error handling, performance optimization, testing frameworks, advanced techniques, and troubleshooting
- **Version 1.0**: Initial comprehensive documentation with core systems, best practices, rulesets, and code examples