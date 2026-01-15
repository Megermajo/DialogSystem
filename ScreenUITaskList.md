# ScreenUnit UI - Implementation Task List

## Core Structure ✓
- [x] Define state variables
  - [x] currentNode
  - [x] nodeList
  - [x] errorMsg and errorTimer
  - [x] Click debounce variables
  - [x] Mouse state tracking
- [x] Define layout constants
  - [x] headerHeight
  - [x] answerRowHeight
  - [x] padding
  - [x] statusBarHeight
  - [x] clickDebounce duration

## Message Handling ✓
- [x] Implement processEditorMessage()
  - [x] Read from global _G.editorMessage
  - [x] Handle ui:updateNode message
  - [x] Handle ui:list message
  - [x] Handle ui:error message
  - [x] Clear message after processing
- [x] Implement sendToEditor(msgType, payload)
  - [x] Create envelope structure
  - [x] Store in global _G.screenMessage

## Render Functions ✓
- [x] Implement renderEditor()
  - [x] Get resolution
  - [x] Set background color
  - [x] Create layer
  - [x] Load fonts (title, text, small)
  
### Header Section ✓
- [x] Draw header background box
- [x] Display current node ID
- [x] Display current node title
- [x] Handle no-node state

### Answers Section ✓
- [x] Calculate answer row positions
- [x] Handle empty state
  - [x] Show "No node selected" message
  - [x] Show usage hint
- [x] Render each answer slot (1-5)
  - [x] Draw background box (different color for empty)
  - [x] Display slot index
  - [x] Display answer text (truncate if >40 chars)
  - [x] Display nextId marker (→)
  - [x] Display fn marker (ƒ)
  - [x] Show "empty" for unused slots

### Status Bar ✓
- [x] Draw status bar background
- [x] Display node count
- [x] Display usage hint

### Error Banner ✓
- [x] Check errorTimer
- [x] Draw semi-transparent error box
- [x] Display error message
- [x] Decrement timer
- [x] Clear error when timer expires

## Interaction Handling ✓
- [x] Implement renderLoop()
  - [x] Process editor messages
  - [x] Handle mouse input
  - [x] Call render function
  - [x] Request next animation frame
- [x] Implement handleClick(mx, my)
  - [x] Check if in answer area
  - [x] Calculate which row was clicked
  - [x] Send ui:clickAnswer message with index
- [x] Mouse state management
  - [x] Track pressed state
  - [x] Detect press events (edge detection)
  - [x] Apply debounce timer
  - [x] Store lastClickTime

## Visual Feedback ✓
- [x] Different colors for filled vs empty slots
- [x] Visual markers for nextId (→)
- [x] Visual markers for fn (ƒ)
- [x] Color coding (green for nextId, orange for fn)
- [x] Error banner with distinct color

## Performance Optimization ✓
- [x] Minimize per-frame calculations
- [x] Use requestAnimationFrame with appropriate delay
- [x] Avoid heavy string operations in render loop
- [x] Cache layout calculations (constants)

## DU Lua API Usage ✓
- [x] getResolution() for screen dimensions
- [x] setBackgroundColor() for background
- [x] createLayer() for drawing
- [x] loadFont() for text rendering
- [x] setDefaultFillColor() for colors
- [x] addBox() for rectangles
- [x] addText() for text
- [x] getCursor() for mouse position
- [x] getCursorPressed() for mouse state
- [x] getTime() for debounce timing
- [x] requestAnimationFrame() for loop

## Message Protocol ✓
- [x] Outgoing: ui:clickAnswer with { idx }
- [x] Outgoing: ui:selectNode with { id }
- [x] Outgoing: ui:action with { op, id? }
- [x] Incoming: ui:list with { nodes }
- [x] Incoming: ui:updateNode with { node }
- [x] Incoming: ui:error with { msg }

## Testing Tasks
- [ ] Test render with no node selected
- [ ] Test render with node containing 1 answer
- [ ] Test render with node containing 5 answers
- [ ] Test click detection on each row
- [ ] Test click debounce (rapid clicks)
- [ ] Test error message display and auto-hide
- [ ] Test nextId marker display
- [ ] Test fn marker display
- [ ] Test text truncation for long answers
- [ ] Test node count display
- [ ] Test message passing to Editor
- [ ] Test message receiving from Editor
- [ ] Verify visual layout on different resolutions

## Edge Cases ✓
- [x] Handle null/undefined currentNode
- [x] Handle empty nodeList
- [x] Handle long answer text (truncation)
- [x] Handle answers with both nextId and fn
- [x] Handle rapid clicks (debounce)
- [x] Handle error message overflow

## Comments ✓
- [x] Short inline comments for hit-test logic
- [x] Section comments for layout areas
- [x] Comments for debounce mechanism
