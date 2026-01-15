# Dialogue System Tutorial

This tutorial walks through creating a complete quest dialogue system using the Dialogue System framework.

## Scenario: Space Station Merchant Quest

We'll create a dialogue tree where:
1. Player meets a merchant at a space station
2. Merchant offers a delivery quest
3. Player can accept or decline
4. Upon acceptance, a callback gives the quest item
5. Player receives final instructions

## Setup

### Step 1: Install Editor Components
1. Place a Programming Board in your space station
2. Connect a Databank to the Programming Board
3. (Optional) Connect a ScreenUnit for visual editing
4. Copy the contents of `DialogueEditor.lua` into the Programming Board
5. Activate the Programming Board

### Step 2: Verify Installation
You should see in the console:
```
Dialogue Editor started. Type 'help' for commands.
```

## Creating the Dialogue Tree

### Node 1: Initial Greeting
```
new merchant_greeting
title merchant_greeting Greetings, traveler! Welcome to Star Haven Station.
ans merchant_greeting 1 Who are you?
ans merchant_greeting 2 What do you do here?
ans merchant_greeting 3 I'm just browsing
next merchant_greeting 1 merchant_intro
next merchant_greeting 2 merchant_intro
```

### Node 2: Merchant Introduction
```
new merchant_intro
title merchant_intro I'm Elara, a merchant dealing in rare goods. I need help with deliveries.
ans merchant_intro 1 What kind of deliveries?
ans merchant_intro 2 I might be interested
ans merchant_intro 3 Not interested
next merchant_intro 1 quest_details
next merchant_intro 2 quest_details
```

### Node 3: Quest Details
```
new quest_details
title quest_details I need someone to deliver a package to Prometheus Station. It's urgent!
ans quest_details 1 What's in the package?
ans quest_details 2 I'll do it
ans quest_details 3 Sounds risky, no thanks
next quest_details 1 quest_package_info
next quest_details 2 quest_accept
```

### Node 4: Package Information
```
new quest_package_info
title quest_package_info It's rare element samples. Nothing dangerous, but very valuable.
ans quest_package_info 1 Alright, I'll deliver it
ans quest_package_info 2 Too much responsibility for me
next quest_package_info 1 quest_accept
```

### Node 5: Quest Acceptance
```
new quest_accept
title quest_accept Excellent! Here's the package. Deliver it to the receiving dock at Prometheus.
ans quest_accept 1 I'll get it done
ans quest_accept 2 What's my reward?
fn quest_accept 1 giveQuestItem
fn quest_accept 2 giveQuestItem
next quest_accept 1 quest_confirm
next quest_accept 2 quest_reward_info
```

### Node 6: Reward Information
```
new quest_reward_info
title quest_reward_info I'll pay you 50,000 credits upon successful delivery. Fair?
ans quest_reward_info 1 Fair enough, I'm on my way
next quest_reward_info 1 quest_confirm
```

### Node 7: Quest Confirmation
```
new quest_confirm
title quest_confirm Safe travels! The package is in your cargo. Don't drop it!
ans quest_confirm 1 Goodbye
```

### Save the Dialogue
```
save
```

## Verifying the Dialogue

### List All Nodes
```
list
```

Expected output:
```
Nodes: 7
  merchant_greeting: Greetings, traveler! Welcome to Star Haven Station. (3 answers)
  merchant_intro: I'm Elara, a merchant dealing in rare goods. I need help with deliveries. (3 answers)
  quest_details: I need someone to deliver a package to Prometheus Station. It's urgent! (3 answers)
  quest_package_info: It's rare element samples. Nothing dangerous, but very valuable. (2 answers)
  quest_accept: Excellent! Here's the package. Deliver it to the receiving dock at Prometheus. (2 answers)
  quest_reward_info: I'll pay you 50,000 credits upon successful delivery. Fair? (1 answers)
  quest_confirm: Safe travels! The package is in your cargo. Don't drop it! (1 answers)
```

### Check Individual Nodes
```
select merchant_greeting
```

## Setting Up Playback

### Step 1: Install AR Dialogue Components
1. Place a second Programming Board (for playback)
2. Connect the SAME Databank used by the Editor
3. (Optional) Connect a ScreenUnit for display
4. Copy the contents of `ARDialogue.lua` into this Programming Board

### Step 2: Configure Callbacks
Before activating, edit the callbacks section in `ARDialogue.lua`:

```lua
local callbacks = {
    giveQuestItem = function()
        system.print("Quest item added to cargo!")
        -- In real implementation:
        -- inventory.addItem("rare_element_package", 1)
        -- player.notify("Quest item received: Rare Element Package")
    end
}
```

### Step 3: Activate AR Dialogue
Activate the Programming Board. You should see:
```
Loaded 7 dialogue nodes
AR Dialogue ready. Type 'start' to begin.
```

## Testing the Dialogue

### Start the Dialogue
Type in LUA-CHAT:
```
start
```

Expected output:
```
=== Greetings, traveler! Welcome to Star Haven Station. ===
1. Who are you? →merchant_intro
2. What do you do here? →merchant_intro
3. I'm just browsing [END]
```

### Make Choices
Type the number of your choice:
```
1
```

The dialogue will progress through the tree based on your choices.

### Test Different Paths

**Path 1: Quick Accept**
```
start
2 (What do you do here?)
2 (I might be interested)
2 (I'll do it)
1 (I'll get it done)
```

**Path 2: Ask Questions**
```
start
1 (Who are you?)
1 (What kind of deliveries?)
1 (What's in the package?)
1 (Alright, I'll deliver it)
2 (What's my reward?)
1 (Fair enough, I'm on my way)
```

**Path 3: Decline**
```
start
1 (Who are you?)
2 (I might be interested)
3 (Sounds risky, no thanks)
```

## Advanced: Adding More Functionality

### Adding a Back Button
Modify an answer to return to previous node:

```
ans quest_details 4 Actually, tell me more about you
next quest_details 4 merchant_intro
```

### Adding Multiple Callbacks
```
new quest_complete
title quest_complete Package delivered! Here's your reward.
ans quest_complete 1 Thank you!
fn quest_complete 1 giveReward
fn quest_complete 1 completeQuest
```

Then in ARDialogue.lua:
```lua
local callbacks = {
    giveQuestItem = function()
        system.print("Quest item added to cargo!")
    end,
    giveReward = function()
        system.print("50,000 credits added to account!")
        -- player.addCredits(50000)
    end,
    completeQuest = function()
        system.print("Quest completed!")
        -- questSystem.complete("merchant_delivery")
    end
}
```

### Creating Conditional Dialogues
For dialogues that change based on player state, create multiple branches:

```
new merchant_greeting_repeat
title merchant_greeting_repeat Ah, you're back! Do you have the package?
ans merchant_greeting_repeat 1 Not yet, still working on it
ans merchant_greeting_repeat 2 Here it is!
next merchant_greeting_repeat 2 quest_complete
```

## Troubleshooting Common Issues

### Issue: "Node not found" Error
**Solution:** Check node ID spelling with `list` command. Node IDs are case-sensitive.

### Issue: Dialogue Doesn't Progress
**Solution:** Check that answers have `nextId` set:
```
next <node_id> <slot> <target_node_id>
```

### Issue: Callback Not Executing
**Solution:** 
1. Verify callback name matches in both editor and ARDialogue.lua
2. Check callback is defined in the callbacks table
3. Ensure answer has fn set: `fn <node_id> <slot> <callback_name>`

### Issue: "No data in databank"
**Solution:** Make sure you've saved in the editor: `save`

### Issue: Screen Not Updating
**Solution:** 
1. Check ScreenUnit is properly connected
2. Verify render script is installed
3. Try reactivating the Programming Board

## Best Practices

### 1. Plan Your Dialogue Flow
Sketch out the dialogue tree on paper first:
```
merchant_greeting
    ├─→ merchant_intro
    │       ├─→ quest_details
    │       │       ├─→ quest_package_info
    │       │       │       └─→ quest_accept
    │       │       └─→ quest_accept
    │       └─→ [END]
    └─→ [END]
```

### 2. Use Descriptive Node IDs
- Good: `merchant_greeting`, `quest_accept`, `reward_info`
- Bad: `node1`, `n2`, `x`

### 3. Keep Messages Concise
Databank storage is limited. Aim for:
- Titles: 50-100 characters
- Answers: 20-50 characters

### 4. Provide Exit Options
Always give players a way to exit:
```
ans <node_id> <last_slot> Goodbye
```

### 5. Test All Branches
Walk through every possible path to ensure:
- No dead ends (except intentional ones)
- All nextId references are valid
- Callbacks execute correctly

### 6. Use Callbacks Wisely
Callbacks should be quick (<20ms). For complex operations:
```lua
startComplexOperation = function()
    system.print("Starting operation...")
    -- Set a flag or trigger another system
    -- Don't do heavy computation here
end
```

### 7. Version Your Dialogues
Use the save command with comments in your planning:
```
-- Version 1.0: Initial merchant quest
-- Last updated: 2026-01-15
```

## Complete Command Reference

### Editor Commands
| Command | Description | Example |
|---------|-------------|---------|
| `new <id>` | Create node | `new greeting` |
| `title <id> <text>` | Set title | `title greeting Hello!` |
| `ans <id> <slot> <text>` | Set answer | `ans greeting 1 Hi there` |
| `next <id> <slot> <target>` | Set next node | `next greeting 1 intro` |
| `fn <id> <slot> <callback>` | Set callback | `fn greeting 1 giveItem` |
| `del <id>` | Delete node | `del greeting` |
| `select <id>` | View node | `select greeting` |
| `list` | List all nodes | `list` |
| `save` | Force save | `save` |
| `help` | Show commands | `help` |

### Playback Commands
| Command | Description | Example |
|---------|-------------|---------|
| `start` | Start dialogue | `start` |
| `stop` | Stop dialogue | `stop` |
| `restart` | Restart from beginning | `restart` |
| `1-5` | Select answer | `2` |

## Next Steps

1. **Create Your Own Dialogue**: Use this tutorial as a template
2. **Add More Callbacks**: Extend functionality with custom callbacks
3. **Integrate with Game Systems**: Connect to doors, shops, quest systems
4. **Create Multiple Dialogues**: Different NPCs, different databанks
5. **Share Your Dialogues**: Export and share dialogue trees with others

## Additional Resources

- `README.md` - Full system documentation
- `DialogueEditorPlan.md` - Editor design specification
- `ARDialoguePlan.md` - Playback design specification
- `constitution.md` - Framework constitution
- `References/DualUniverseLuaBestPractices.md` - Lua best practices

Happy dialogue crafting!
