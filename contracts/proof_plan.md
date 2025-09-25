# Proof plan (obligations checklist)

## Safety (AoRTE + flow)
- [ ] `Msg_Queue`: array indexing, head/tail updates remain in range; count never negative.
- [ ] `Request_Parser`: loops prove termination; indices stay within input and output bounds.
- [ ] `Net_Spec`: post `Got <= Max` used by core; no hidden globals.

## Functional
- [ ] Enqueue increases length by 1; Dequeue decreases by 1.
- [ ] Parser returns `Bad` for unknown methods, otherwise `Path_Len <= Max_Path` with copied prefix.
- [ ] Strengthen parser contracts as needed (e.g., allowed character sets, normalization).

## Concurrency
- [ ] Protected object operations are interference-free; no hidden global state.
- [ ] If/when tasks are added: add `Global/Depends` on task-level operations, and protected object invariants.
