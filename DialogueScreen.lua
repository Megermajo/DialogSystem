-- ScreenUnit Render Script for Dialogue Editor
-- Displays current node with answer slots and handles click interactions

-- State
local currentNode = nil
local nodeList = {}
local errorMsg = nil
local errorTimer = 0
local lastClickTime = 0
local clickDebounce = 0.2  -- 200ms

-- Layout constants
local headerHeight = 60
local answerRowHeight = 50
local padding = 20
local statusBarHeight = 40

-- Click handling
local lastMouseX = 0
local lastMouseY = 0
local mousePressed = false

-- Message handling (from Editor PB)
function processEditorMessage()
    local msg = _G.editorMessage
    if not msg then return end
    
    if msg.type == "ui:updateNode" then
        if msg.payload and msg.payload.node then
            currentNode = msg.payload.node
        end
    elseif msg.type == "ui:list" then
        if msg.payload and msg.payload.nodes then
            nodeList = msg.payload.nodes
        end
    elseif msg.type == "ui:error" then
        if msg.payload and msg.payload.msg then
            errorMsg = msg.payload.msg
            errorTimer = 3  -- Show for 3 seconds
        end
    end
    
    _G.editorMessage = nil  -- Clear message
end

-- Send message to Editor PB
function sendToEditor(msgType, payload)
    local msg = { type = msgType, payload = payload }
    -- Store in global for Editor to read
    -- In production, use appropriate IPC mechanism based on DU API version
    _G.screenMessage = msg
end

-- Render
function renderEditor()
    local rx, ry = getResolution()
    
    setBackgroundColor(15/255, 24/255, 29/255)
    
    local layer = createLayer()
    local titleFont = loadFont('Play-Bold', 24)
    local textFont = loadFont('Play', 18)
    local smallFont = loadFont('Play', 14)
    
    -- Header
    setDefaultFillColor(layer, Shape_Box, 0.1, 0.1, 0.15, 1)
    addBox(layer, 0, 0, rx, headerHeight)
    
    setDefaultFillColor(layer, Shape_Text, 0.710, 0.878, 0.941, 1)
    if currentNode then
        addText(layer, titleFont, "Editing: " .. currentNode.id, rx/2, 15)
        addText(layer, smallFont, currentNode.title, rx/2, 40)
    else
        addText(layer, titleFont, "Dialogue Editor", rx/2, 30)
    end
    
    -- Answers section
    local startY = headerHeight + padding
    
    if not currentNode or not currentNode.answers then
        -- Empty state
        setDefaultFillColor(layer, Shape_Text, 0.5, 0.5, 0.5, 1)
        addText(layer, textFont, "No node selected", rx/2, startY + 50)
        addText(layer, smallFont, "Use LUA-CHAT: 'new <id>' to create", rx/2, startY + 80)
    else
        -- Render answer slots
        for i = 1, 5 do
            local y = startY + (i - 1) * answerRowHeight
            local answer = currentNode.answers[i]
            
            -- Answer box background
            local bgColor = answer and {0.15, 0.15, 0.2} or {0.08, 0.08, 0.1}
            setDefaultFillColor(layer, Shape_Box, bgColor[1], bgColor[2], bgColor[3], 1)
            addBox(layer, padding, y, rx - padding * 2, answerRowHeight - 5)
            
            -- Answer index
            setDefaultFillColor(layer, Shape_Text, 0.5, 0.5, 0.5, 1)
            addText(layer, textFont, tostring(i), padding + 15, y + 15)
            
            if answer and answer.text and answer.text ~= "" then
                -- Answer text
                setDefaultFillColor(layer, Shape_Text, 1, 1, 1, 1)
                local displayText = answer.text
                if #displayText > 40 then
                    displayText = displayText:sub(1, 37) .. "..."
                end
                addText(layer, textFont, displayText, padding + 50, y + 12)
                
                -- Markers for nextId and fn
                local markerX = rx - padding - 100
                if answer.nextId then
                    setDefaultFillColor(layer, Shape_Text, 0.3, 0.8, 0.3, 1)
                    addText(layer, smallFont, "→" .. answer.nextId, markerX, y + 15)
                    markerX = markerX - 60
                end
                
                if answer.fn then
                    setDefaultFillColor(layer, Shape_Text, 0.8, 0.6, 0.3, 1)
                    addText(layer, smallFont, "ƒ " .. answer.fn, markerX, y + 15)
                end
            else
                -- Empty slot
                setDefaultFillColor(layer, Shape_Text, 0.3, 0.3, 0.3, 1)
                addText(layer, smallFont, "empty", padding + 50, y + 15)
            end
        end
    end
    
    -- Status bar
    local statusY = ry - statusBarHeight
    setDefaultFillColor(layer, Shape_Box, 0.05, 0.05, 0.08, 1)
    addBox(layer, 0, statusY, rx, statusBarHeight)
    
    setDefaultFillColor(layer, Shape_Text, 0.5, 0.5, 0.5, 1)
    local nodeCount = 0
    for _ in pairs(nodeList) do nodeCount = nodeCount + 1 end
    addText(layer, smallFont, nodeCount .. " nodes | Use LUA-CHAT for commands", padding + 10, statusY + 12)
    
    -- Error banner
    if errorMsg and errorTimer > 0 then
        setDefaultFillColor(layer, Shape_Box, 0.8, 0.2, 0.2, 0.9)
        addBox(layer, padding, ry/2 - 30, rx - padding * 2, 60)
        
        setDefaultFillColor(layer, Shape_Text, 1, 1, 1, 1)
        addText(layer, textFont, "Error: " .. errorMsg, rx/2, ry/2 - 15)
        
        errorTimer = errorTimer - 0.1
        if errorTimer <= 0 then
            errorMsg = nil
        end
    end
    
    requestAnimationFrame(10)
end

-- Main render loop
function renderLoop()
    processEditorMessage()
    
    -- Handle mouse clicks
    local mx, my = getCursor()
    local pressed = getCursorPressed()
    
    if pressed and not mousePressed then
        -- Mouse just pressed
        local currentTime = getTime()
        if currentTime - lastClickTime > clickDebounce then
            handleClick(mx, my)
            lastClickTime = currentTime
        end
    end
    
    mousePressed = pressed
    
    renderEditor()
end

-- Click handler
function handleClick(mx, my)
    local rx, ry = getResolution()
    
    if not currentNode or not currentNode.answers then return end
    
    local startY = headerHeight + padding
    
    -- Check if click is in answers area
    for i = 1, 5 do
        local y = startY + (i - 1) * answerRowHeight
        local boxHeight = answerRowHeight - 5
        
        if mx >= padding and mx <= rx - padding and 
           my >= y and my <= y + boxHeight then
            -- Clicked on answer slot i
            sendToEditor("ui:clickAnswer", { idx = i })
            return
        end
    end
end

-- Initialize
renderLoop()
