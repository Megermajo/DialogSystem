# Dialogue Editor PB Action Plan

## Objectives
- Provide CRUD for dialogue nodes (1–5 answers, last default Exit editable).
- Persist state to databank on stop; load on start; recover from corruption.
- Drive ScreenUnit UI and consume LUA-CHAT commands.
- Keep payloads and storage compact.

## Data Model
- Node schema per constitution (`id`, `title`, `answers[{text,nextId?,fn?}]`).
- Store compact: `nodes` (array/map), `meta` (version, timestamps), `cfg` (options, e.g., debounce, exitLabel).
- Validate: title non-empty; answers 1..5; trim blanks; `nextId` optional; `fn` optional string.

## Message Contract (Editor ⇄ Screen)
- To Screen:
  - `ui:list` `{ nodes }` (summary only if needed).
  - `ui:updateNode` `{ node }` (current node detail).
  - `ui:error` `{ msg }` (short).
- From Screen:
  - `ui:clickAnswer` `{ idx }` (answer selection in editor context).
  - `ui:selectNode` `{ id }` (choose node to edit).
  - `ui:action` `{ op, id? }` (e.g., new, delete, duplicate).

## LUA-CHAT Commands (examples)
- `new <id>` create node with default Exit answer.
- `title <id> <text>` set title.
- `ans <id> <slot(1-5)> <text>` set answer text.
- `next <id> <slot> <nextId>` set next pointer (or `none`).
- `fn <id> <slot> <name>` set callback (or `none`).
- `del <id>` delete node.
- `list` summarize nodes.
- `save` force save.

## Flows
- Start: load databank -> validate -> init defaults -> send `ui:list` and `ui:updateNode` for current.
- Edit: chat or screen action mutates node -> validate -> update cache -> push `ui:updateNode`.
- Save: on stop and on significant change (throttled) write compact D2K.
- Delete node: rewire answers pointing to it? (warn, do not auto-edit; flag dangling refs).
- Default Exit: on node create, prefill answer slot 5 (or first free) as Exit with no `nextId`/`fn`.

## Error Handling
- If load fails: reset to empty list with starter node; log once.
- If validation fails: reject change, emit `ui:error`.
- Dangling `nextId`: highlight/flag in UI state (e.g., `ui:updateNode` includes `dangling=true`).

## Performance / UX
- Use timers for autosave debounce (e.g., 1–2s after change) to reduce writes.
- Keep handlers short (<20ms). Cache parsed data.
- Optional click debounce 200ms in Screen; Editor just honors incoming events.

## Comments
- Use short inline comments for non-obvious validation, save/load fallback, and message routing.
