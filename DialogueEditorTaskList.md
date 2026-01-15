# Dialogue Editor - Implementation Task List

## Core Data Structures ✓
- [x] Define node schema (id, title, answers array)
- [x] Define answer schema (text, nextId, fn)
- [x] Define metadata structure (version, created, updated)
- [x] Define configuration structure (debounceDelay, exitLabel)
- [x] Initialize state variables (nodes, meta, cfg, currentNodeId)

## Databank Persistence ✓
- [x] Implement saveToDatabank() function
  - [x] Serialize data with system.D2K
  - [x] Update timestamp
  - [x] Handle missing databank gracefully
  - [x] Clear needsSave flag
- [x] Implement loadFromDatabank() function
  - [x] Deserialize with system.K2D
  - [x] Validate data structure
  - [x] Strip empty answers
  - [x] Validate each node
  - [x] Handle corruption with fallback
- [x] Add autosave timer mechanism
  - [x] Debounce with configurable delay
  - [x] Reset timer after save

## Validation Functions ✓
- [x] Implement validateNode()
  - [x] Check required fields (id, title)
  - [x] Validate answers array (1-5 items)
  - [x] Check answer text non-empty
  - [x] Return success/error message
- [x] Implement stripEmptyAnswers()
  - [x] Filter out answers with empty text
  - [x] Preserve order

## Node CRUD Operations ✓
- [x] Implement createNode(id)
  - [x] Check for duplicate ID
  - [x] Create with default structure
  - [x] Add default Exit answer
  - [x] Set as current node
  - [x] Mark needsSave
  - [x] Send update to screen
- [x] Implement deleteNode(id)
  - [x] Verify node exists
  - [x] Remove from nodes table
  - [x] Check for dangling references
  - [x] Mark needsSave
  - [x] Send list update to screen
- [x] Implement setNodeTitle(id, title)
  - [x] Validate node exists
  - [x] Update title
  - [x] Mark needsSave
  - [x] Send update to screen
- [x] Implement setAnswerText(id, slot, text)
  - [x] Validate node exists
  - [x] Validate slot range (1-5)
  - [x] Expand answers array if needed
  - [x] Update answer text
  - [x] Mark needsSave
  - [x] Send update to screen
- [x] Implement setAnswerNext(id, slot, nextId)
  - [x] Validate node and slot
  - [x] Handle "none" to clear
  - [x] Update nextId
  - [x] Mark needsSave
  - [x] Send update to screen
- [x] Implement setAnswerFn(id, slot, fn)
  - [x] Validate node and slot
  - [x] Handle "none" to clear
  - [x] Update fn
  - [x] Mark needsSave
  - [x] Send update to screen

## LUA-CHAT Command Parser ✓
- [x] Implement parseCommand(text)
  - [x] Trim whitespace
  - [x] Split into parts
  - [x] Route to appropriate handler
- [x] Command: new <id>
  - [x] Call createNode
  - [x] Handle errors
- [x] Command: title <id> <text>
  - [x] Parse multi-word text
  - [x] Call setNodeTitle
  - [x] Handle errors
- [x] Command: ans <id> <slot> <text>
  - [x] Parse multi-word text
  - [x] Call setAnswerText
  - [x] Handle errors
- [x] Command: next <id> <slot> <nextId|none>
  - [x] Call setAnswerNext
  - [x] Handle errors
- [x] Command: fn <id> <slot> <fnName|none>
  - [x] Call setAnswerFn
  - [x] Handle errors
- [x] Command: del <id>
  - [x] Call deleteNode
  - [x] Handle errors
- [x] Command: select <id>
  - [x] Update currentNodeId
  - [x] Send update to screen
  - [x] Handle errors
- [x] Command: list
  - [x] Get node list
  - [x] Print to console
  - [x] Send to screen
- [x] Command: save
  - [x] Force save to databank
- [x] Command: help
  - [x] Print all commands

## Message Handling ✓
- [x] Implement sendToScreen(msgType, payload)
  - [x] Create envelope structure
  - [x] Store in global for screen access
- [x] Implement sendError(msg)
  - [x] Print to console
  - [x] Send ui:error message
- [x] Message type: ui:list
  - [x] Send node summaries
- [x] Message type: ui:updateNode
  - [x] Send full node data
- [x] Message type: ui:error
  - [x] Send error message

## Event Handlers ✓
- [x] Implement start handler
  - [x] Load from databank
  - [x] Create starter node if empty
  - [x] Show screen
  - [x] Set timer
  - [x] Set input prompt
  - [x] Send initial state to screen
- [x] Implement stop() handler
  - [x] Save if needed
  - [x] Print confirmation
- [x] Implement tick(timerId) handler
  - [x] Handle autosave timer
  - [x] Check needsSave flag
  - [x] Debounce save
- [x] Implement onInputText(text) handler
  - [x] Call parseCommand

## Utility Functions ✓
- [x] Implement tableSize(tbl)
- [x] Implement getNodeList()
  - [x] Create summary for each node
  - [x] Include id, title, answerCount

## Error Handling ✓
- [x] Graceful databank connection check
- [x] Validation error messages
- [x] Corruption recovery
- [x] Missing node warnings
- [x] Dangling reference warnings

## Testing Tasks
- [ ] Test node creation
- [ ] Test title editing
- [ ] Test answer editing (all slots)
- [ ] Test nextId assignment
- [ ] Test fn assignment
- [ ] Test node deletion
- [ ] Test dangling reference detection
- [ ] Test save/load cycle
- [ ] Test corruption recovery
- [ ] Test all commands via LUA-CHAT
- [ ] Test with empty databank
- [ ] Test with multiple nodes
- [ ] Test autosave timing
- [ ] Verify screen message passing

## Performance Targets ✓
- [x] Target handler execution <20ms
- [x] Minimize per-tick work
- [x] Use debounced autosave

## Comments ✓
- [x] Short inline comments for non-obvious logic
- [x] Section headers for organization
