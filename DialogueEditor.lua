-- Dialogue Editor Programming Board
-- Manages dialogue node CRUD operations, LUA-CHAT commands, and ScreenUnit communication

-- Data structures
local nodes = {}  -- { [id] = { id, title, answers = {{text, nextId?, fn?}, ...} } }
local meta = { version = "1.0", created = 0, updated = 0 }
local cfg = { debounceDelay = 1.5, exitLabel = "Exit" }
local currentNodeId = nil
local saveTimer = 0
local needsSave = false

-- Message helpers
local function sendToScreen(msgType, payload)
    if not screen then return end
    local msg = { type = msgType, id = currentNodeId or "", payload = payload }
    -- Store in global for screen render script to read
    -- Production: Use global variables (_G) accessible by render scripts,
    -- or implement databank-based message queue for reliable cross-board communication
    _G.editorMessage = msg
end

local function sendError(msg)
    system.print("ERROR: " .. msg)
    sendToScreen("ui:error", { msg = msg })
end

-- Validation
local function validateNode(node)
    if not node.id or node.id == "" then return false, "Node ID required" end
    if not node.title or node.title == "" then return false, "Title required" end
    if not node.answers or type(node.answers) ~= "table" then return false, "Answers must be a table" end
    if #node.answers < 1 or #node.answers > 5 then return false, "Answers must be 1-5" end
    
    for i, ans in ipairs(node.answers) do
        if not ans.text or ans.text == "" then return false, "Answer " .. i .. " text required" end
    end
    
    return true, ""
end

local function stripEmptyAnswers(answers)
    local result = {}
    for _, ans in ipairs(answers) do
        if ans.text and ans.text ~= "" then
            table.insert(result, ans)
        end
    end
    return result
end

-- Persistence
local function saveToDatabank()
    if not databank then
        system.print("WARNING: No databank connected")
        return
    end
    
    meta.updated = system.getTime()
    local data = {
        meta = meta,
        cfg = cfg,
        nodes = nodes
    }
    
    local json = system.D2K(data)
    databank.setData(json)
    system.print("Saved " .. tableSize(nodes) .. " nodes")
    needsSave = false
end

local function loadFromDatabank()
    if not databank then
        system.print("WARNING: No databank connected")
        return false
    end
    
    local json = databank.getData()
    if not json or json == "" then
        system.print("No data in databank, starting fresh")
        return false
    end
    
    local data = system.K2D(json)
    if not data then
        system.print("ERROR: Failed to parse databank, starting fresh")
        return false
    end
    
    -- Validate and load
    if data.meta then meta = data.meta end
    if data.cfg then cfg = data.cfg end
    if data.nodes then
        nodes = {}
        for id, node in pairs(data.nodes) do
            node.answers = stripEmptyAnswers(node.answers or {})
            local valid, err = validateNode(node)
            if valid then
                nodes[id] = node
            else
                system.print("WARNING: Skipping invalid node " .. id .. ": " .. err)
            end
        end
    end
    
    system.print("Loaded " .. tableSize(nodes) .. " nodes")
    return true
end

-- Utility
local function tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

local function getNodeList()
    local list = {}
    for id, node in pairs(nodes) do
        table.insert(list, { id = id, title = node.title, answerCount = #node.answers })
    end
    return list
end

-- Node operations
local function createNode(id)
    if nodes[id] then
        return false, "Node " .. id .. " already exists"
    end
    
    local node = {
        id = id,
        title = "New Dialogue",
        answers = {
            { text = cfg.exitLabel, nextId = nil, fn = nil }  -- Default exit answer
        }
    }
    
    nodes[id] = node
    currentNodeId = id
    needsSave = true
    
    sendToScreen("ui:updateNode", { node = node })
    system.print("Created node: " .. id)
    return true, ""
end

local function deleteNode(id)
    if not nodes[id] then
        return false, "Node " .. id .. " not found"
    end
    
    nodes[id] = nil
    needsSave = true
    
    -- Check for dangling references
    for _, node in pairs(nodes) do
        for _, ans in ipairs(node.answers) do
            if ans.nextId == id then
                system.print("WARNING: Node " .. node.id .. " has dangling reference to deleted node " .. id)
            end
        end
    end
    
    sendToScreen("ui:list", { nodes = getNodeList() })
    system.print("Deleted node: " .. id)
    return true, ""
end

local function setNodeTitle(id, title)
    if not nodes[id] then
        return false, "Node " .. id .. " not found"
    end
    
    nodes[id].title = title
    needsSave = true
    sendToScreen("ui:updateNode", { node = nodes[id] })
    system.print("Set title for node " .. id)
    return true, ""
end

local function setAnswerText(id, slot, text)
    if not nodes[id] then
        return false, "Node " .. id .. " not found"
    end
    
    local slotNum = tonumber(slot)
    if not slotNum or slotNum < 1 or slotNum > 5 then
        return false, "Slot must be 1-5"
    end
    
    -- Warn if creating gaps in answer slots (filled with empty answers)
    if slotNum > #nodes[id].answers + 1 then
        system.print("WARNING: Skipping slots (current: " .. #nodes[id].answers .. ", setting: " .. slotNum .. "). Empty answers will be created.")
    end
    
    -- Ensure answers array is large enough (fill gaps with empty answers)
    while #nodes[id].answers < slotNum do
        table.insert(nodes[id].answers, { text = "", nextId = nil, fn = nil })
    end
    
    nodes[id].answers[slotNum].text = text
    needsSave = true
    sendToScreen("ui:updateNode", { node = nodes[id] })
    system.print("Set answer " .. slot .. " for node " .. id)
    return true, ""
end

local function setAnswerNext(id, slot, nextId)
    if not nodes[id] then
        return false, "Node " .. id .. " not found"
    end
    
    local slotNum = tonumber(slot)
    if not slotNum or slotNum < 1 or slotNum > 5 then
        return false, "Slot must be 1-5"
    end
    
    if slotNum > #nodes[id].answers then
        return false, "Answer slot " .. slot .. " doesn't exist yet"
    end
    
    -- "none" clears the nextId
    if nextId == "none" or nextId == "" then
        nodes[id].answers[slotNum].nextId = nil
    else
        nodes[id].answers[slotNum].nextId = nextId
    end
    
    needsSave = true
    sendToScreen("ui:updateNode", { node = nodes[id] })
    system.print("Set next for answer " .. slot .. " of node " .. id)
    return true, ""
end

local function setAnswerFn(id, slot, fn)
    if not nodes[id] then
        return false, "Node " .. id .. " not found"
    end
    
    local slotNum = tonumber(slot)
    if not slotNum or slotNum < 1 or slotNum > 5 then
        return false, "Slot must be 1-5"
    end
    
    if slotNum > #nodes[id].answers then
        return false, "Answer slot " .. slot .. " doesn't exist yet"
    end
    
    -- "none" clears the fn
    if fn == "none" or fn == "" then
        nodes[id].answers[slotNum].fn = nil
    else
        nodes[id].answers[slotNum].fn = fn
    end
    
    needsSave = true
    sendToScreen("ui:updateNode", { node = nodes[id] })
    system.print("Set fn for answer " .. slot .. " of node " .. id)
    return true, ""
end

-- LUA-CHAT command parser
local function parseCommand(text)
    if not text or text == "" then return end
    
    text = text:match("^%s*(.-)%s*$")  -- Trim whitespace
    local parts = {}
    for part in text:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then return end
    
    local cmd = parts[1]:lower()
    
    if cmd == "new" and parts[2] then
        local success, err = createNode(parts[2])
        if not success then sendError(err) end
        
    elseif cmd == "title" and parts[2] then
        local titleText = text:match("^%S+%s+%S+%s+(.+)$")
        if titleText then
            local success, err = setNodeTitle(parts[2], titleText)
            if not success then sendError(err) end
        else
            sendError("Usage: title <id> <text>")
        end
        
    elseif cmd == "ans" and parts[2] and parts[3] then
        local ansText = text:match("^%S+%s+%S+%s+%S+%s+(.+)$")
        if ansText then
            local success, err = setAnswerText(parts[2], parts[3], ansText)
            if not success then sendError(err) end
        else
            sendError("Usage: ans <id> <slot> <text>")
        end
        
    elseif cmd == "next" and parts[2] and parts[3] and parts[4] then
        local success, err = setAnswerNext(parts[2], parts[3], parts[4])
        if not success then sendError(err) end
        
    elseif cmd == "fn" and parts[2] and parts[3] and parts[4] then
        local success, err = setAnswerFn(parts[2], parts[3], parts[4])
        if not success then sendError(err) end
        
    elseif cmd == "del" and parts[2] then
        local success, err = deleteNode(parts[2])
        if not success then sendError(err) end
        
    elseif cmd == "list" then
        local list = getNodeList()
        system.print("Nodes: " .. tableSize(nodes))
        for _, item in ipairs(list) do
            system.print("  " .. item.id .. ": " .. item.title .. " (" .. item.answerCount .. " answers)")
        end
        sendToScreen("ui:list", { nodes = list })
        
    elseif cmd == "save" then
        saveToDatabank()
        
    elseif cmd == "select" and parts[2] then
        if nodes[parts[2]] then
            currentNodeId = parts[2]
            sendToScreen("ui:updateNode", { node = nodes[parts[2]] })
            system.print("Selected node: " .. parts[2])
        else
            sendError("Node not found: " .. parts[2])
        end
        
    elseif cmd == "help" then
        system.print("Commands:")
        system.print("  new <id> - Create node")
        system.print("  title <id> <text> - Set title")
        system.print("  ans <id> <slot> <text> - Set answer text")
        system.print("  next <id> <slot> <nextId|none> - Set next node")
        system.print("  fn <id> <slot> <fnName|none> - Set callback")
        system.print("  del <id> - Delete node")
        system.print("  select <id> - Select node for editing")
        system.print("  list - List all nodes")
        system.print("  save - Force save to databank")
        
    else
        sendError("Unknown command. Type 'help' for commands.")
    end
end

-- Event handlers

-- Start: Load from databank
meta.created = system.getTime()
if not loadFromDatabank() then
    -- Create starter node if empty
    createNode("start")
    setNodeTitle("start", "Welcome")
    setAnswerText("start", 1, "Hello!")
end

system.showScreen(1)
unit.setTimer("autosave", cfg.debounceDelay)
unit.setInputText("Enter command (or 'help')")

-- Send initial state to screen
sendToScreen("ui:list", { nodes = getNodeList() })
if currentNodeId and nodes[currentNodeId] then
    sendToScreen("ui:updateNode", { node = nodes[currentNodeId] })
elseif tableSize(nodes) > 0 then
    local firstId = next(nodes)
    currentNodeId = firstId
    sendToScreen("ui:updateNode", { node = nodes[firstId] })
end

system.print("Dialogue Editor started. Type 'help' for commands.")

-- Stop: Save to databank
function stop()
    if needsSave then
        saveToDatabank()
    end
    system.print("Dialogue Editor stopped")
end

-- Tick: Autosave check
function tick(timerId)
    if timerId == "autosave" then
        if needsSave then
            saveTimer = saveTimer + cfg.debounceDelay
            -- Save when accumulated time exceeds debounce threshold
            if saveTimer >= cfg.debounceDelay then
                saveToDatabank()
                saveTimer = 0
            end
        else
            saveTimer = 0
        end
    end
end

-- Input: LUA-CHAT commands
function onInputText(text)
    parseCommand(text)
end
