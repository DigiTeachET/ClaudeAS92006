# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Usability Quest** is a Godot 4 (GDScript) revision game for NCEA Level 1 Digital Technologies AS92006 ("Demonstrate understanding of usability in human-computer interfaces"). It's a top-down survival game: the student fights waves of small enemies in an arena, and between waves answers an AS92006 usability question - the grade tier earned (Excellence/Merit/Achievement/Not Achieved) upgrades their weapon before the next wave.

There is no build system, package manager, or test suite — this is a pure Godot project. "Running" it means opening `project.godot` in the Godot 4.x editor and pressing Play (F5), which starts on the Hub screen (`scenes/Hub/Hub.tscn`) and lets you begin a run into `scenes/Game/Game.tscn`.

## Commands

- **Open the project**: launch Godot 4.x, Import `project.godot` at the repo root.
- **Run the whole game**: F5 in the editor (starts at `scenes/Hub/Hub.tscn`, set via `run/main_scene` in `project.godot`).
- **Validate JSON content after editing**: `python3 -m json.tool content/<file>.json` (no Python dependency is otherwise required; this is just a convenient JSON syntax check before loading it in Godot).
- There is no linter, formatter, or automated test suite configured for this project.

## Architecture

### One run, driven by `content/waves.json`

A run is a fixed sequence of waves (`scenes/Game/Game.gd` owns it, `scenes/Game/WaveManager.gd` executes it). Each wave entry names an `enemy_count`/`enemy_type` and a `question_source` (which `content/*_questions.json` bank to draw from once the wave is cleared) — see `content/README.md` for the full schema. `WaveManager.gd`'s `ENEMY_STATS` dict is the only place enemy difficulty numbers live; `Game.gd` never spawns enemies directly, it just calls `wave_manager.start_wave(index)` and reacts to the `wave_cleared` signal.

### Content-driven questions, not hardcoded ones

Every question — mock UI layout, hotspot position, correct answer, distractor text, tiered feedback — lives in `content/*_questions.json`, never in GDScript. `content/principles.json` ids are referenced by every other content file; renaming one silently breaks lookups since `ContentLoader.load_principles()` keys everything by `id`. **Schema for every content file is documented in `content/README.md`** — read that before touching either the JSON or `QuestionInterstitial.gd`, since the two must stay in sync.

### `QuestionInterstitial.gd` — one script, five question shapes

Between-wave questions all funnel through `scenes/Game/QuestionInterstitial.gd`, dispatched by `wave_data.question_source`:
- **`spot_it`**: single-stage (identify principle from a hotspot).
- **`explain_it`**: two-stage (`_stage`: `"identify"` → `"explain"`) — naming the principle wrong short-circuits straight to Not Achieved; naming it right unlocks a second multiple-choice stage where the *tier* comes from the chosen explanation's own `"tier"` field in the JSON.
- **`compare_it`**: three-stage (`"pick"` → `"justify"` → `"improve"`) across two side-by-side `HotspotInterfacePanel`s (`panel_a`/`panel_b`).
- **`matapono_maori`**: branches per-question on a `"type"` field (`"hotspot"` vs `"macron_check"`).
- **`confusable_pairs`**: the boss-wave gate — two rapid forced-choice questions in a row (tracked via `_boss_streak`), resolved into one aggregate tier (`merit`/`achievement`/`not_achieved`) for the weapon upgrade, while each individual answer still separately calls `ProgressTracker.record_answer()`.

The interstitial pauses the whole tree (`get_tree().paused = true`, set by `Game.gd`) and is itself `process_mode = PROCESS_MODE_ALWAYS` so its buttons keep working — the same trick `Game.gd`'s `RunEndOverlay` uses when a run ends. It emits `resolved(tier)` back to `Game.gd`, which calls `player.apply_upgrade(tier)` and unpauses.

### Mock interfaces are built at runtime, never screenshotted

`scenes/Shared/HotspotInterfacePanel.gd` is a reusable component that takes a `mock_interface` dictionary (title + `elements` array of `{type, text, rect}`) and constructs it live out of plain `Control` nodes (`Panel`, `Label`, `Button`, `ColorRect`) — this is deliberate, to avoid using real screenshots of commercial sites. It also lays invisible clickable "hotspot" buttons over specific features and emits `hotspot_pressed(index)`; `QuestionInterstitial.gd` listens for that signal to advance the question flow.

### Shared grading feedback (`scenes/Shared/RoundReport.gd`)

`QuestionInterstitial.gd` calls `show_report(tier, principle_dict, message, exam_wording)` after marking every answer. This is what renders the Excellence/Merit/Achievement/Not Achieved tier label plus a `not_achieved_tip` pulled straight from `principles.json`.

### Combat (`scenes/Game/Player.gd`, `Enemy.gd`, `Bullet.gd`)

Physics layers: player = layer 1, enemies = layer 2, player bullets = layer 4 (bullets only monitor layer 2, so they never hit the player who fired them). `Player.gd` fires `Bullet` instances toward the mouse on left-click, spread across `bullet_count` parallel shots when upgraded. `Enemy.gd` has no pathfinding — it just moves straight at whatever `set_target()` was given each physics frame, since the arena is one open room — and deals contact damage via a child `ContactArea` Area2D rather than physics-collision callbacks, ticking damage on a timer while overlapping the player. Weapon upgrades (`Player.apply_upgrade(tier)`) are **run-local and never saved** — they reset to base values every run because `Player.tscn` is freshly instanced each time `Game.tscn` loads. Persistent progress is mastery only, via `ProgressTracker`.

### `ProgressTracker.gd` (autoload) — mastery is the only thing that persists

Tracks mastery score (0-100) per usability concept (`PRINCIPLE_IDS`) plus a couple of run stats (`best_wave_reached`, `total_runs`, `best_boss_streak`). Every question anywhere in the game reports outcomes through `record_answer(principle_id, tier)` where `tier` is one of `"excellence" | "merit" | "achievement" | "not_achieved"` — this is the one place score math (`TIER_DELTA`) lives. Persists to a single JSON file at `user://usability_quest_save.json` via `save_progress()`/`load_progress()`. Deliberately holds nothing about combat/run state beyond those stats — see the "Combat" section above for why.

### `ContentLoader.gd` (autoload)

Shared JSON-reading helper so scripts don't duplicate `FileAccess` boilerplate. `load_principles()` returns `content/principles.json` keyed by `id` for O(1) lookup of a principle's display name/definition/tip.

### Hub screen (`scenes/Hub/Hub.gd` + `Hub.tscn`)

A static welcome screen, not a walkable space — Ono greets the student (`Companion.gd.get_greeting_lines()`, picked by `ProgressTracker.overall_light_level()` tier: `early`/`mid`/`late`, read from `content/companion_dialogue.json`), then "Start" loads `scenes/Game/Game.tscn` and "Journal" loads `scenes/Journal/Journal.tscn`. `Companion.gd` is a plain `Node`, not tied to any scene-specific transform, so it can be reused wherever Ono needs to speak.

### Input map

Custom actions `move_up/down/left/right` (WASD + arrows) are defined in `project.godot`'s `[input]` section — reuse these action names rather than hardcoding key checks. Shooting is *not* in the input map — `Player.gd` checks `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)` directly.
