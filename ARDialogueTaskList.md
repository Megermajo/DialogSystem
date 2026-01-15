# AR Dialogue Playback - Implementation Task List

## Core State Management ✓
- [x] Define state variables
  - [x] nodes (dialogue tree)
  - [x] meta (version info)
  - [x] currentNodeId
  - [x] history (visited nodes stack)
  - [x] isActive (dialogue state)
  - [x] playerDistance
  - [x] maxDistance threshold

## Callback System ✓
- [x] Define callbacks registry
  - [x] Structure: { fnName: function }
  - [x] Example: giveQuest callback
  - [x] Example: openDoor callback
  - [x] Example: giveReward callback
- [x] Implement callback dispatch
  - [x] Check if callback exists
  - [x] Execute callback function
  - [x] Handle missing callbacks gracefully

## Databank Loading ✓
- [x] Implement loadDialogue()
  - [x] Check databank connection
  - [x] Retrieve JSON data
  - [x] Deserialize with system.K2D
  - [x] Validate data structure
  - [x] Process each node
  - [x] Strip empty answers
  - [x] Cap answers at 5
  - [x] Ensure at least one answer
  - [x] Add default Exit if needed
  - [x] Store validated nodes
  - [x] Load metadata
  - [x] Return success/failure

## Node Navigation ✓
- [x] Implement findEntryNode()
  - [x] Look for "start" node first
  - [x] Fallback to first available node
  - [x] Return node ID or nil
- [x] Implement startDialogue()
  - [x] Check if nodes loaded
  - [x] Find entry node
  - [x] Initialize currentNodeId
  - [x] Clear history
  - [x] Set isActive flag
  - [x] Present first node
- [x] Implement stopDialogue()
  - [x] Clear isActive flag
  - [x] Clear currentNodeId
  - [x] Clear history
  - [x] Clear presentation
  - [x] Print confirmation

## Presentation Logic ✓
- [x] Implement presentNode(nodeId)
  - [x] Validate node exists
  - [x] Build presentation content
  - [x] Render to screen or system screen
  - [x] Print debug output to console
  - [x] Show title and answers
  - [x] Show markers for nextId and fn
- [x] Implement buildPresentationContent(node)
  - [x] Create render script structure
  - [x] Set background color
  - [x] Create layer
  - [x] Load fonts
  - [x] Render title
  - [x] Render each answer with index
  - [x] Add usage hint
  - [x] Request animation frame
  - [x] Escape special characters
- [x] Implement clearPresentation()
  - [x] Clear screen or system screen

## Answer Selection ✓
- [x] Implement selectAnswer(index)
  - [x] Check dialogue is active
  - [x] Validate current node exists
  - [x] Parse answer index
  - [x] Validate index range
  - [x] Get selected answer
  - [x] Execute callback if present
  - [x] Check callback exists in registry
  - [x] Handle missing callbacks
  - [x] Navigate to next node if nextId present
  - [x] Add current node to history
  - [x] Update currentNodeId
  - [x] Present new node
  - [x] Handle missing next node
  - [x] End dialogue if no nextId

## Distance Checking ✓
- [x] Implement checkPlayerDistance()
  - [x] Return true for now (placeholder)
  - [x] Add comments for future implementation
  - [x] Structure for player position check
  - [x] Structure for distance calculation

## Event Handlers ✓
- [x] Implement start handler
  - [x] Call loadDialogue
  - [x] Handle load failure
  - [x] Show screen
  - [x] Set distance check timer
  - [x] Print ready message
- [x] Implement stop() handler
  - [x] Stop dialogue
  - [x] Print confirmation
- [x] Implement tick(timerId) handler
  - [x] Handle distance check timer
  - [x] Check if dialogue active
  - [x] Check player distance
  - [x] Stop dialogue if too far
- [x] Implement onInputText(text) handler
  - [x] Trim whitespace
  - [x] Handle "start" command
  - [x] Handle "stop"/"exit" command
  - [x] Handle "restart" command
  - [x] Parse numeric input as answer
  - [x] Call selectAnswer
  - [x] Handle unknown commands

## Utility Functions ✓
- [x] Implement tableSize(tbl)

## Error Handling ✓
- [x] Graceful databank check
- [x] Invalid data handling
- [x] Missing node handling
- [x] Missing callback warning
- [x] Invalid answer index handling
- [x] No active dialogue handling
- [x] Empty nodes handling
- [x] No entry node handling

## Performance Targets ✓
- [x] Target handler execution <20ms
- [x] Use timer for periodic checks (1s interval)
- [x] Minimize per-tick work
- [x] Cache node data

## DU Lua API Usage ✓
- [x] databank.getData() for loading
- [x] system.K2D() for deserialization
- [x] system.print() for logging
- [x] system.showScreen() for visibility
- [x] screen.setRenderScript() for rendering
- [x] screen.clear() for cleanup
- [x] unit.setTimer() for periodic tasks
- [x] system.getTime() for timestamps

## Testing Tasks
- [ ] Test dialogue loading from databank
- [ ] Test with empty databank
- [ ] Test with corrupted data
- [ ] Test start command
- [ ] Test stop command
- [ ] Test restart command
- [ ] Test answer selection (1-5)
- [ ] Test navigation through branches
- [ ] Test callback execution
- [ ] Test missing callback handling
- [ ] Test missing nextId (dialogue end)
- [ ] Test missing node reference
- [ ] Test with single-node dialogue
- [ ] Test with multi-branch dialogue
- [ ] Test with 5-answer node
- [ ] Test distance check timer
- [ ] Verify screen rendering
- [ ] Test console debug output

## Edge Cases ✓
- [x] No databank connected
- [x] Empty dialogue data
- [x] Missing entry node
- [x] Circular node references (via history)
- [x] Dangling nextId references
- [x] Unknown callback functions
- [x] Invalid answer indices
- [x] Dialogue already active
- [x] Player out of range

## Integration Points ✓
- [x] Share databank with Editor
- [x] Compatible node schema
- [x] Handle Editor-created data

## Comments ✓
- [x] Short inline comments for branching logic
- [x] Comments for state transitions
- [x] Comments for callback dispatch
- [x] Comments for distance checks
- [x] Comments for future enhancements

## Future Enhancements (Not in Current Scope)
- [ ] Player position detection
- [ ] Distance calculation implementation
- [ ] AR hologram rendering
- [ ] Multi-player dialogue support
- [ ] Dialogue choice memory/tracking
- [ ] Conditional answer visibility
- [ ] Variable substitution in text
- [ ] Sound effects on answer selection
- [ ] Animation transitions
- [ ] Back button (use history stack)
