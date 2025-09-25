# AGENT.md — how to work in this repo (proofs-first)

1) For any new subprogram: add/adjust `Pre`, `Post`, `Global`, `Depends`; add loop invariants and variants.
2) For shared state: declare `Abstract_State`/`Refined_State` where appropriate; keep data-flow explicit.
3) Prefer ghost model functions if properties are easier over sets/sequences than concrete structures.
4) Before committing, run `make profile PROFILE=Jorvik` (or `Ravenscar`) and `make prove`. Do **not** commit with unproved checks.
5) If an external breaks proof visibility, create/extend a boundary package in `src_boundary/`; the SPARK core should depend on the spec in SPARK, with a non‑SPARK body that delegates to the real OS primitive.
