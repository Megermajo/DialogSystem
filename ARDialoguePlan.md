# AR Dialogue PB Action Plan

## Objectives
- Load dialogue tree from databank and drive player-facing AR dialogue.
- Present up to 5 answers; execute optional `fn` callbacks; handle Exit/default.
- Maintain state (current node, history/stack) and handle missing links gracefully.

## Data / Schema
- Nodes per constitution: `id`, `title`, `answers[1..5]{text,nextId?,fn?}`.
- Databank keys compact; validate on load; strip empty answers; cap at 5.

## Flow
- Start: load nodes/meta; pick entry node (configurable, fallback first); validate; set default Exit if missing.
- Present: render title + answers (AR or screen as needed); highlight selectable answers.
- Select: on input, resolve `answer`:
  - If `fn` present, dispatch callback string (map to local functions table) with no args for now.
  - If `nextId` present, jump; else end.
- Exit: last answer defaults to Exit; ends dialogue when chosen.
- Distance/availability: if no player or too far, gracefully stop (inspired by ref AR script); hide UI.

## Inputs / Messages (from Screen/controls if any)
- Envelope `{type,id,payload}` minimal; e.g., `ui:clickAnswer` `{ idx }`.

## Outputs / Feedback
- Optional `system.print` for debug toggles; avoid verbose logs.
- If using system screen/AR, update visuals per node change.

## Error Handling
- Missing `nextId`: treat as end; optionally flag once in debug.
- Missing `fn`: ignore.
- Corrupted data: fall back to empty/end state; do not crash.

## Performance
- Keep handlers <20ms; use cached nodes; no heavy loops.
- Avoid large redraws every tick; update on change.

## Comments
- Short inline comments for branching/state transitions, distance checks, and callback dispatch.
