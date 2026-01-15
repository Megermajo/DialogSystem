# ScreenUnit UI Action Plan

## Objectives
- Render current node (title + up to 5 answers) and editor controls.
- Send compact click/hit-test results back to Editor PB.
- Handle empty/error states gracefully.

## Inputs / Messages
- From Editor PB:
  - `ui:list` `{ nodes }` (optional summary to populate lists).
  - `ui:updateNode` `{ node }` (current node details, may include flags like `dangling`).
  - `ui:error` `{ msg }` (short message to display briefly).

## Outputs / Messages
- To Editor PB (envelope `{type,id,payload}`):
  - `ui:clickAnswer` `{ idx }` when user selects an answer slot.
  - `ui:selectNode` `{ id }` when picking a node from list.
  - `ui:action` `{ op, id? }` for buttons (new, delete, duplicate).

## Render Script Layout
- Zones: header (dialogue title), answers list (1–5 rows), status bar (hints/errors), optional node list sidebar if space permits.
- Each answer row: index, text, markers for `nextId`/`fn` presence.
- Empty state: show “No nodes yet” and a “New” action.
- Error state: brief banner (auto-hide after short duration).

## Interaction / Hit-Testing
- Rectangle hit areas per answer row; map y-position to `idx`.
- Optional debounce: ~200ms to prevent double-activations.
- Provide visual hover/active feedback (color highlight).

## Payload Constraints
- Keep payload flat and small (e.g., `{ idx = 3 }`, `{ id = "node1" }`).
- Avoid large lists in frequent messages; only send needed detail for current node.

## Performance
- Minimize per-frame work; reuse layout calculations; avoid heavy string concat in tick.
- Prefer partial redraws or cached SVG segments if feasible.

## Comments
- Use short inline comments for hit-test math, debounce guard, and redraw trigger points.
