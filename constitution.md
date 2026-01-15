# Dialogue Framework Constitution

## Scope and Roles
- Components: Dialogue Editor PB, ScreenUnit UI, AR Dialogue PB, Databank (shared state).
- Slots: descriptive names; handlers are case-sensitive (`start`, `tick`, `stop`, `onUpdate`, `onInputText`; radar `enter`/`onLeave` if used).
- Screen: system screen via `system.setScreen`; ScreenUnit via `screen.setSVG` / `screen.setRenderScript` / `screen.setCenteredText`.

## Message Envelope (flat, compact)
- Shape: `{ type, id, payload }`
- `type`: string (channel + intent, e.g., `ui:clickAnswer`, `ui:updateNode`, `ui:error`).
- `id`: string|number (typically node id or request id).
- `payload`: flat table with minimal keys (e.g., `{ idx = 2 }`, `{ node = {...} }`). Keep small for databank limits.

## Dialogue Node Schema (compact, max 5 answers)
- `id`: string|number (unique per node).
- `title`: string (non-empty).
- `answers`: array (1..5). Each answer:
  - `text`: string (non-empty).
  - `nextId`: optional string|number; nil = end.
  - `fn`: optional string callback name; empty if none.
- Default: last answer prefilled as Exit (end); user can clear/change.

## Persistence & Versioning
- Storage: databank using `system.D2K` / `system.K2D`.
- Keys: compact (`cfg`, `nodes`, `meta`).
- Include `meta` with `created`, `updated`, `version` (short string), optional checksum.
- On load: validate presence, types, bounds (answers 1..5), strip empty answers.
- On stop: autosave Editor state; on start: load state; fail safe to empty skeleton if corrupted.

## Performance & Size Targets
- Handlers target ≤20ms; avoid >100ms.
- Script size per handler: keep ≤30–50KB; split if larger.
- Use timers over tight loops; cache expensive values; avoid nested loops >1000 iterations.

## Input & Interaction
- LUA-CHAT: validate non-empty; acknowledge; parse commands tersely.
- Screen clicks: send envelope with answer index; optional debounce ~200ms (configurable).
- Mouse deltas for activity if needed.

## Commenting Standard
- Short inline comments only where logic is non-obvious (why over what).
- No exhaustive or line-by-line comments; keep concise.

## Error Handling
- Validate before save/load; fallback to empty node list with notice.
- Log via `system.print` sparingly; prefer one-line diagnostics.
- Gracefully handle missing slots/screens/databank (no crash).

## Testing Checklist (high level)
- Start/stop preserves nodes.
- Create/edit/delete nodes within 1..5 answers.
- Screen click → envelope → state change.
- AR playback through branch, exit path, missing `nextId` handled.
- Corrupted databank recovers to clean state.
- Performance within targets; layout OK for 5 answers.
