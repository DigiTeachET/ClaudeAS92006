# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Usability Quest** is a Godot 4 (GDScript) revision game for NCEA Level 1 Digital Technologies AS92006 ("Demonstrate understanding of usability in human-computer interfaces"). It replaces a quiz-app UI with a small walkable hub world (`scenes/Hub/Hub.tscn`) that the player explores between five mini-game "rooms," each testing usability concepts at a different NZQA grade tier.

There is no build system, package manager, or test suite — this is a pure Godot project. "Running" it means opening `project.godot` in the Godot 4.x editor and pressing Play (F5), or running a single scene directly (F6 with that scene open) to iterate on one mini-game without walking through the hub each time.

## Commands

- **Open the project**: launch Godot 4.x, Import `project.godot` at the repo root.
- **Run the whole game**: F5 in the editor (starts at `scenes/Hub/Hub.tscn`, set via `run/main_scene` in `project.godot`).
- **Run one mini-game in isolation**: open its `.tscn` (e.g. `scenes/Modes/SpotIt/SpotIt.tscn`) and press F6 ("Run Current Scene"). Each mode scene is self-contained and loads its own question bank in `_ready()`, so this is the fastest way to check a content edit.
- **Validate JSON content after editing**: `python3 -m json.tool content/<file>.json` (no Python dependency is otherwise required; this is just a convenient JSON syntax check before loading it in Godot).
- There is no linter, formatter, or automated test suite configured for this project.

## Architecture

### Content-driven mini-games, not hardcoded questions

Every question — mock UI layout, hotspot position, correct answer, distractor text, tiered feedback — lives in `content/*.json`, never in GDScript. Each mode script (`scenes/Modes/*/*.gd`) follows the same shape: load its question bank via the `ContentLoader` autoload, `shuffle()` it, and walk through questions one at a time, rebuilding UI from the current question's dictionary. **Schema for every content file is documented in `content/README.md`** — read that before touching either the JSON or the mode scripts, since the two must stay in sync (e.g. `principles.json` ids are referenced by every other content file, and renaming one silently breaks lookups since `ContentLoader.load_principles()` keys everything by `id`).

### Two autoload singletons (`autoload/`)

- **`ProgressTracker.gd`** — the single source of truth for save state: mastery score (0-100) per usability concept (`PRINCIPLE_IDS`), which hub doors are unlocked, and round-completion counts. Every mini-game reports outcomes through `record_answer(principle_id, tier)` where `tier` is one of `"excellence" | "merit" | "achievement" | "not_achieved"` — this is the one place score math (`TIER_DELTA`) lives. Persists to a single JSON file at `user://usability_quest_save.json` via `save_progress()`/`load_progress()`. Mode-completion (`complete_round(mode_id)`) drives a simple linear door-unlock chain (`_update_unlocks()`).
- **`ContentLoader.gd`** — shared JSON-reading helper so mode scripts don't duplicate `FileAccess` boilerplate. `load_principles()` returns `content/principles.json` keyed by `id` for O(1) lookup of a principle's display name/definition/tip.

### Mock interfaces are built at runtime, never screenshotted

`scenes/Shared/HotspotInterfacePanel.gd` is a reusable component that takes a `mock_interface` dictionary (title + `elements` array of `{type, text, rect}`) and constructs it live out of plain `Control` nodes (`Panel`, `Label`, `Button`, `ColorRect`) — this is deliberate, to avoid using real screenshots of commercial sites. It also lays invisible clickable "hotspot" buttons over specific features and emits `hotspot_pressed(index)`; the owning mode script listens for that signal to advance the question flow. All five mode scenes instance this same component (`CompareIt.tscn` instances it twice, side by side, for `PanelA`/`PanelB`).

### Shared grading feedback (`scenes/Shared/RoundReport.gd`)

Every mode instances the same `RoundReport.tscn` overlay and calls `show_report(tier, principle_dict, message, exam_wording)` after marking an answer. This is what renders the Excellence/Merit/Achievement/Not Achieved tier label plus a `not_achieved_tip` pulled straight from `principles.json` — keeping grading language consistent across all five mini-games instead of each one rolling its own feedback UI.

### Mode-specific flow differences

All mode scripts (`scenes/Modes/*/*.gd`) share the load-question / build-panel / handle-choice / show-report loop, but differ in staging:
- **SpotIt**: single-stage (identify principle).
- **ExplainIt**: two-stage (`_stage`: `"identify"` → `"explain"`) — naming the principle wrong short-circuits straight to Not Achieved; naming it right unlocks a second multiple-choice stage where the *tier* comes from the chosen explanation's own `"tier"` field in the JSON (this is where Merit vs. Achievement vs. Not Achieved get decided by content, not code).
- **CompareIt**: three-stage (`"pick"` → `"justify"` → `"improve"`) across two side-by-side `HotspotInterfacePanel`s.
- **MatapoMaori**: branches per-question on a `"type"` field (`"hotspot"` vs `"macron_check"`) rather than having a fixed stage sequence.
- **ConfusablePairs**: no `RoundReport`-driven progression logic beyond a running `_streak` counter (reset on a wrong answer, never a fail state) — passed to `ProgressTracker.record_confusable_streak()` at the end.

### Hub world wiring (`scenes/Hub/Hub.gd` + `Hub.tscn`)

Doors, the companion NPC, and the journal object are all `Area2D` nodes distinguished by a `metadata/kind` string (`"door" | "companion" | "journal"`) set directly in the `.tscn` file rather than in code — `Hub.gd` reads `area.get_meta(...)` to decide what interacting with a given object does. Door unlock state is visualized by toggling a `Locked` overlay child node per-door in `_refresh_doors()`, driven by `ProgressTracker.is_mode_unlocked(mode_id)`. Player movement is a plain `Node2D` position update (no physics body) with an `Area2D` "Detector" child used only for proximity overlap detection, not collision.

### Companion dialogue (`scenes/Companion/`)

`Companion.gd` (attached directly to the hub's `CompanionNPC` Area2D) and `DialogueBox.gd` (a simple one-line-at-a-time text box, advanced with the `interact` action) are decoupled from game logic — dialogue text lives in `content/companion_dialogue.json`, picked by `ProgressTracker.overall_light_level()` tier (`early`/`mid`/`late`), so tone/wording can change without touching GDScript.

### Input map

Custom actions `move_up/down/left/right` (WASD + arrows) and `interact` (E/Enter) are defined in `project.godot`'s `[input]` section — reuse these action names rather than hardcoding key checks.
