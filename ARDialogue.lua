-- AR Dialogue Programming Board
-- Loads dialogue tree from databank and presents interactive dialogues to players

-- State
local nodes = {}
local meta = {}
local currentNodeId = nil
local history = {}  -- Stack of visited nodes for potential back navigation
local isActive = false
local playerDistance = 0
local maxDistance = 50  -- Max meters from PB to show dialogue

-- Callback functions registry
local callbacks = {
    giveQuest = function()
        system.print("Quest given!")
    end,
    openDoor = function()
        system.print("Door opened!")
    end,
    giveReward = function()
        system.print("Reward given!")
    end,
    -- Add more callbacks as needed
}

-- Load dialogue from databank
local function loadDialogue()
    if not databank then
        system.print("ERROR: No databank connected")
        return false
    end
    
    local json = databank.getData()
    if not json or json == "" then
        system.print("ERROR: No dialogue data in databank")
        return false
    end
    
    local data = system.K2D(json)
    if not data or not data.nodes then
        system.print("ERROR: Invalid dialogue data")
        return false
    end
    
    -- Load and validate nodes
    nodes = {}
    for id, node in pairs(data.nodes) do
        -- Strip empty answers
        if node.answers then
            local cleanAnswers = {}
            for _, ans in ipairs(node.answers) do
                if ans.text and ans.text ~= "" then
                    table.insert(cleanAnswers, ans)
                end
            end
            node.answers = cleanAnswers
            
            -- Validate: cap at 5 answers
            if #node.answers > 5 then
                system.print("WARNING: Node " .. id .. " has >5 answers, capping")
                while #node.answers > 5 do
                    table.remove(node.answers)
                end
            end
            
            -- Ensure at least one answer
            if #node.answers == 0 then
                table.insert(node.answers, { text = "Exit", nextId = nil, fn = nil })
            end
        else
            node.answers = {{ text = "Exit", nextId = nil, fn = nil }}
        end
        
        nodes[id] = node
    end
    
    if data.meta then meta = data.meta end
    
    system.print("Loaded " .. tableSize(nodes) .. " dialogue nodes")
    return true
end

-- Utility
local function tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Find entry node (configurable, or first node as fallback)
local function findEntryNode()
    -- Look for "start" node first
    if nodes["start"] then return "start" end
    
    -- Otherwise return first node
    for id, _ in pairs(nodes) do
        return id
    end
    
    return nil
end

-- Start dialogue
local function startDialogue()
    if tableSize(nodes) == 0 then
        system.print("ERROR: No dialogue nodes loaded")
        return false
    end
    
    local entryId = findEntryNode()
    if not entryId then
        system.print("ERROR: No entry node found")
        return false
    end
    
    currentNodeId = entryId
    history = {}
    isActive = true
    
    presentNode(currentNodeId)
    return true
end

-- Stop dialogue
local function stopDialogue()
    isActive = false
    currentNodeId = nil
    history = {}
    clearPresentation()
    system.print("Dialogue ended")
end

-- Present current node
function presentNode(nodeId)
    local node = nodes[nodeId]
    if not node then
        system.print("ERROR: Node not found: " .. tostring(nodeId))
        stopDialogue()
        return
    end
    
    -- Update display (AR or screen)
    local content = buildPresentationContent(node)
    
    if screen then
        screen.setRenderScript(content)
    else
        -- Fallback to system screen
        system.setScreen(content)
    end
    
    -- Debug output
    system.print("=== " .. node.title .. " ===")
    for i, ans in ipairs(node.answers) do
        local marker = ans.nextId and ("→" .. ans.nextId) or "[END]"
        local fnMarker = ans.fn and (" ƒ" .. ans.fn) or ""
        system.print(i .. ". " .. ans.text .. " " .. marker .. fnMarker)
    end
end

-- Build presentation content (render script)
function buildPresentationContent(node)
    -- Simple render script for displaying dialogue
    local answersCode = ""
    for i, ans in ipairs(node.answers) do
        local escaped = ans.text:gsub('"', '\\"')
        answersCode = answersCode .. 'addText(layer, textFont, "' .. i .. '. ' .. escaped .. '", 50, ' .. (100 + i * 40) .. ')\n'
    end
    
    return [[
        setBackgroundColor(10/255, 15/255, 20/255)
        local rx, ry = getResolution()
        local layer = createLayer()
        
        local titleFont = loadFont('Play-Bold', 28)
        local textFont = loadFont('Play', 20)
        
        setDefaultFillColor(layer, Shape_Text, 0.9, 0.9, 1, 1)
        addText(layer, titleFont, "]] .. node.title:gsub('"', '\\"') .. [[", rx/2, 40)
        
        setDefaultFillColor(layer, Shape_Text, 0.7, 0.8, 0.9, 1)
        ]] .. answersCode .. [[
        
        setDefaultFillColor(layer, Shape_Text, 0.5, 0.5, 0.5, 1)
        addText(layer, loadFont('Play', 14), "Use LUA-CHAT: type answer number", rx/2, ry - 30)
        
        requestAnimationFrame(10)
    ]]
end

-- Clear presentation
function clearPresentation()
    if screen then
        screen.clear()
    end
end

-- Select answer
function selectAnswer(index)
    if not isActive or not currentNodeId then
        system.print("No active dialogue")
        return
    end
    
    local node = nodes[currentNodeId]
    if not node then
        system.print("ERROR: Current node not found")
        stopDialogue()
        return
    end
    
    local answerIndex = tonumber(index)
    if not answerIndex or answerIndex < 1 or answerIndex > #node.answers then
        system.print("Invalid answer: " .. tostring(index))
        return
    end
    
    local answer = node.answers[answerIndex]
    
    -- Execute callback if present
    if answer.fn and answer.fn ~= "" then
        if callbacks[answer.fn] then
            callbacks[answer.fn]()
        else
            system.print("WARNING: Callback not found: " .. answer.fn)
        end
    end
    
    -- Navigate to next node or end
    if answer.nextId and answer.nextId ~= "" then
        if nodes[answer.nextId] then
            table.insert(history, currentNodeId)
            currentNodeId = answer.nextId
            presentNode(currentNodeId)
        else
            system.print("ERROR: Next node not found: " .. answer.nextId)
            -- Treat as end
            stopDialogue()
        end
    else
        -- No nextId means end of dialogue
        stopDialogue()
    end
end

-- Distance check (if player interaction is needed)
function checkPlayerDistance()
    -- In actual DU, check player position vs construct position
    -- For now, assume player is always in range
    -- If player detection is available:
    -- local playerPos = player.getPosition()
    -- local pbPos = system.getConstructPosition()
    -- local distance = calculateDistance(playerPos, pbPos)
    -- return distance <= maxDistance
    return true
end

-- Event handlers

-- Start: Load dialogue and prepare
if not loadDialogue() then
    system.print("Failed to load dialogue")
else
    system.print("AR Dialogue ready. Type 'start' to begin.")
    system.showScreen(1)
    unit.setTimer("checkDistance", 1.0)  -- Check player distance every second
end

-- Stop
function stop()
    stopDialogue()
    system.print("AR Dialogue stopped")
end

-- Tick: Check player distance
function tick(timerId)
    if timerId == "checkDistance" then
        if isActive then
            if not checkPlayerDistance() then
                system.print("Player too far, stopping dialogue")
                stopDialogue()
            end
        end
    end
end

-- Input: Handle dialogue choices
function onInputText(text)
    if not text or text == "" then return end
    
    text = text:match("^%s*(.-)%s*$")  -- Trim
    
    if text:lower() == "start" then
        startDialogue()
    elseif text:lower() == "stop" or text:lower() == "exit" then
        stopDialogue()
    elseif text:lower() == "restart" then
        stopDialogue()
        startDialogue()
    else
        -- Try to parse as answer selection
        local num = tonumber(text)
        if num then
            selectAnswer(num)
        else
            system.print("Unknown command. Use 'start', 'stop', or answer number")
        end
    end
end
