# Dialogue System for Dual Universe

A modular dialogue framework for Dual Universe Lua, consisting of three main components for creating, editing, and presenting interactive dialogues.

## Components

### 1. Dialogue Editor (DialogueEditor.lua)
Programming Board script for creating and managing dialogue nodes via LUA-CHAT commands.

**Features:**
- Create, edit, and delete dialogue nodes
- Support for up to 5 answer choices per node
- Persistent storage in Databank
- Auto-save functionality
- Default "Exit" answer on node creation
- Validation and error handling

**Commands:**
- `new <id>` - Create a new dialogue node
- `title <id> <text>` - Set the title/message of a node
- `ans <id> <slot> <text>` - Set answer text for slot 1-5
- `next <id> <slot> <nextId|none>` - Set which node to jump to on answer selection
- `fn <id> <slot> <fnName|none>` - Set callback function for an answer
- `del <id>` - Delete a node (warns about dangling references)
- `select <id>` - Select a node for viewing
- `list` - List all nodes
- `save` - Force save to databank
- `help` - Show command list

**Setup:**
1. Place Programming Board
2. Connect Databank to Programming Board
3. (Optional) Connect ScreenUnit for visual editor
4. Paste DialogueEditor.lua code into Programming Board
5. Activate the board

**Example Workflow:**
```
new start
title start Welcome to my station!
ans start 1 Who are you?
ans start 2 What do you sell?
ans start 3 Goodbye

new info_owner
title info_owner I'm the station owner. Nice to meet you!
ans info_owner 1 What do you sell?
ans info_owner 2 Goodbye

next start 1 info_owner
next start 2 info_shop
```

### 2. ScreenUnit Render Script (DialogueScreen.lua)
Visual interface for the Dialogue Editor showing the current node and answer slots.

**Features:**
- Real-time display of current node being edited
- Visual indicators for nextId (→) and callback functions (ƒ)
- Click debouncing to prevent double-activation
- Error message display with auto-hide
- Status bar showing node count

**Setup:**
1. Connect ScreenUnit to the same Programming Board as DialogueEditor
2. Paste DialogueScreen.lua into the ScreenUnit's render script
3. The screen will automatically sync with the editor

**Visual Layout:**
- Header: Shows current node ID and title
- Answer Slots: 5 rows showing answer text and metadata
- Status Bar: Node count and hint text
- Error Banner: Temporary error messages

### 3. AR Dialogue Playback (ARDialogue.lua)
Programming Board script for presenting dialogues to players in-game.

**Features:**
- Load dialogue tree from Databank
- Present up to 5 answer choices
- Execute callback functions on answer selection
- Navigate through dialogue branches
- Automatic fallback to Exit if no nextId
- Distance checking (optional)
- Graceful error handling

**Setup:**
1. Place a separate Programming Board (for playback)
2. Connect the same Databank containing dialogue data
3. (Optional) Connect ScreenUnit or use system screen
4. Paste ARDialogue.lua code into Programming Board
5. Activate the board

**Commands:**
- `start` - Begin the dialogue from entry node
- `stop` or `exit` - End the current dialogue
- `restart` - Stop and restart from beginning
- `1-5` - Select answer by number

**Callback System:**
Modify the `callbacks` table in ARDialogue.lua to add custom functions:
```lua
local callbacks = {
    giveQuest = function()
        system.print("Quest given!")
        -- Add your quest logic here
    end,
    openDoor = function()
        -- Add door opening logic
        if door then door.activate() end
    end,
    giveReward = function()
        -- Add reward logic
        system.print("Here's your reward!")
    end
}
```

## Data Schema

### Node Structure
```lua
{
    id = "unique_id",           -- String or number
    title = "Node Title",       -- Display text/message
    answers = {                 -- Array of 1-5 answers
        {
            text = "Answer 1",  -- Required: answer text
            nextId = "next_node_id",  -- Optional: next node to jump to
            fn = "callbackName"       -- Optional: callback function name
        },
        -- ... up to 5 answers
    }
}
```

### Databank Storage
```lua
{
    meta = {
        version = "1.0",
        created = timestamp,
        updated = timestamp
    },
    cfg = {
        debounceDelay = 1.5,
        exitLabel = "Exit"
    },
    nodes = {
        [id] = node_data,
        -- ...
    }
}
```

## Best Practices

### Node Design
1. **Keep messages concise** - Databank storage is limited
2. **Always provide an exit path** - Last answer defaults to Exit
3. **Validate node IDs** - Use descriptive, unique IDs
4. **Test branches** - Ensure all nextId references are valid
5. **Use callbacks sparingly** - Only when actions are needed

### Performance
- Target <20ms per handler execution
- Use autosave debouncing (default 1.5s)
- Cache parsed data when possible
- Minimize screen redraws

### Error Handling
- Editor validates input before saving
- Corrupted databank falls back to clean state
- Missing nextId treated as dialogue end
- Unknown callbacks logged but don't crash

## Troubleshooting

### "No databank connected"
- Ensure Databank is properly connected to Programming Board
- Check slot connections in board configuration

### "Node not found"
- Verify node ID exists with `list` command
- Check for typos in node IDs
- Use `select <id>` to verify node data

### Screen not updating
- Check ScreenUnit connection
- Verify render script is properly installed
- Look for errors in system logs

### Dialogue won't start
- Ensure dialogue data is saved in Databank
- Check that at least one node exists
- Verify entry node (default: "start") exists

### Dangling references
- Use `list` to see all nodes
- Delete command warns about references
- Manually update nextId values with `next` command

## Example: Complete Quest Dialogue

```lua
-- Create quest start
new quest_start
title quest_start A mysterious stranger approaches you...
ans quest_start 1 Who are you?
ans quest_start 2 What do you want?
ans quest_start 3 Leave me alone
next quest_start 1 quest_intro
next quest_start 2 quest_offer
next quest_start 3 quest_end

-- Create quest intro
new quest_intro
title quest_intro I am a merchant seeking brave adventurers.
ans quest_intro 1 What's the job?
ans quest_intro 2 I'm not interested
next quest_intro 1 quest_offer

-- Create quest offer
new quest_offer
title quest_offer I need you to deliver a package to the space station.
ans quest_offer 1 I accept the quest
ans quest_offer 2 No thanks
next quest_offer 1 quest_accept
fn quest_offer 1 giveQuest

-- Create quest accept
new quest_accept
title quest_accept Excellent! The package is in your inventory.
ans quest_accept 1 I'll get it done
next quest_accept 1 quest_end

-- Quest end node
new quest_end
title quest_end Safe travels!
ans quest_end 1 Goodbye

-- Save
save
```

## File Structure
```
/DialogSystem/
├── DialogueEditor.lua         # Editor Programming Board
├── DialogueScreen.lua          # ScreenUnit render script
├── ARDialogue.lua              # Playback Programming Board
├── README.md                   # This file
├── constitution.md             # Framework specifications
├── DialogueEditorPlan.md       # Editor design document
├── ScreenUIPlan.md             # Screen UI design document
├── ARDialoguePlan.md           # AR playback design document
└── References/
    └── DualUniverseLuaBestPractices.md
```

## License
This dialogue system is provided as-is for use in Dual Universe. Modify as needed for your specific requirements.

## Credits
Developed following Dual Universe Lua best practices and the modular dialogue framework specification.
