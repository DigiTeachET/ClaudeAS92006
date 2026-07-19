# Usability Quest

A small, gentle revision game for **NCEA Level 1 Digital Technologies, AS92006**
("Demonstrate understanding of usability in human-computer interfaces").
Built in **Godot 4 (GDScript)**.

Instead of a menu and a quiz, the game is a short walkable hub world. A
small companion, Ono, keeps you company between five revision rooms, one per
grade tier of the standard plus a mātāpono Māori room and a "confusable
pairs" boss round. A quiet notebook in the hub tracks mastery per usability
concept instead of a bare percentage bar.

## Opening the project

1. Install [Godot 4.x](https://godotengine.org/download) (the standard
   build - no C#/.NET version needed, this project is pure GDScript).
2. Open Godot, choose **Import**, and select the `project.godot` file at
   the root of this repository.
3. Press **F5** (or the Play button) to run. The game starts in the hub
   world (`scenes/Hub/Hub.tscn`).

No external plugins or addons are required - everything uses Godot's
built-in nodes and 2D drawing.

## Controls

- **WASD / Arrow keys** - walk around the hub world.
- **E** (or Enter, or click) - interact with a nearby door, Ono, or the
  journal; also advances dialogue.
- Doors, questions and multiple-choice answers are otherwise mouse-driven.

## How the game is organised

```
project.godot            Godot project settings, autoloads, input map
icon.svg                 Project icon (a small lightbulb)

autoload/
  ProgressTracker.gd      Singleton: mastery scores, unlocks, save/load
  ContentLoader.gd         Singleton: shared JSON-loading helper

scenes/
  Hub/                     The walkable hub world (stands in for a menu)
  Companion/               Ono the companion NPC + dialogue box system
  Shared/                  HotspotInterfacePanel (mock UI renderer) and
                            RoundReport (shared grade-marker feedback panel)
  Modes/
    SpotIt/                Achievement tier - identify a principle
    ExplainIt/              Merit tier - identify + explain why it matters
    CompareIt/               Excellence tier - compare two interfaces
    MatapoMaori/            Mātāpono Māori room
    ConfusablePairs/         Boss round - rapid confusable-pair drilling
  Journal/                 Ono's journal - a hand-drawn mastery bar chart

content/
  principles.json          Every usability concept the game tests
  *_questions.json          Question banks, one file per mini-game
  companion_dialogue.json  Ono's hub-world dialogue lines
  README.md                 Full schema reference for adding new content
```

## Adding or editing questions

You don't need to touch any GDScript. Everything a teacher would want to
change lives in the `content/` folder as plain JSON files - see
**`content/README.md`** for the full schema and examples of every question
type (hotspot questions, explanation stages, side-by-side comparisons,
macron-spotting items, and confusable-pair prompts).

A quick example - adding a new Spot It question means copying an existing
entry in `content/spot_it_questions.json`, giving it a new `id`, and
changing the mock screen, hotspot position, and correct principle. Re-run
the game (or just the `SpotIt.tscn` scene) to see it in the mix.

## Design notes

- **No real screenshots.** Every mocked interface (checkout screens, forum
  posts, booking forms, etc.) is built live from JSON at runtime using
  plain Godot `Control` nodes (`Panel`, `Label`, `Button`, `ColorRect`) via
  `scenes/Shared/HotspotInterfacePanel.gd`. This avoids any copyright or
  trademark concern with real commercial sites.
- **Grading mirrors the standard.** Every answer is marked as Excellence,
  Merit, Achievement, or Not Achieved - not just right/wrong - and the tip
  shown on a Not Achieved result is written to target the specific
  misunderstanding (surface description vs functional explanation,
  Error Prevention vs Error Recovery, User Control and Freedom vs
  Flexibility and Efficiency of Use), matching language from the
  standard's own assessment reports.
- **One save file.** `ProgressTracker.gd` stores mastery per concept,
  which doors are unlocked, and a couple of small settings, all in a
  single JSON file in Godot's user data directory
  (`user://usability_quest_save.json`).
- **New Zealand English** spelling is used throughout the UI text, and te
  reo Māori is woven into labels naturally rather than offered as a
  separate translated mode.

## Known limitations / good next steps

- The hub world is a straight chain of rooms (entry room, then one room
  per mode) rather than a branching map - simple on purpose. Room order,
  width, name and colour all live in the `ROOMS` constant at the top of
  `scenes/Hub/Hub.gd`, so reordering or adding a room mostly means editing
  that list (plus moving the matching door/companion/journal node in
  `Hub.tscn` to line up with the new room centre).
- There's no exam-wording toggle UI yet - `ProgressTracker.exam_wording_mode`
  already drives which wording `RoundReport` shows, it just needs a
  checkbox somewhere (the hub's UI CanvasLayer is a natural spot).
- Only a handful of sample questions ship per mode (3-8, covering a spread
  of principles and both confusable pairs) - see `content/README.md` to
  add more.
