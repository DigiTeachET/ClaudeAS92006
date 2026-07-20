# Usability Quest

A small, gentle revision game for **NCEA Level 1 Digital Technologies, AS92006**
("Demonstrate understanding of usability in human-computer interfaces").
Built in **Godot 4 (GDScript)**.

The game is a top-down survival run: the student moves around an arena and
fires a light-blaster at small hostile "glitches". Clear a wave and the
game pauses for an AS92006 usability question; the grade tier earned
(Excellence / Merit / Achievement / Not Achieved) upgrades the weapon
before the next wave. A companion, Ono, greets the student on the Hub
screen, and a quiet notebook tracks mastery per usability concept across
every run - a wrong answer just means no upgrade this wave, never a
punishment.

## Opening the project

1. Install [Godot 4.x](https://godotengine.org/download) (the standard
   build - no C#/.NET version needed, this project is pure GDScript).
2. Open Godot, choose **Import**, and select the `project.godot` file at
   the root of this repository.
3. Press **F5** (or the Play button) to run. The game starts on the Hub
   screen (`scenes/Hub/Hub.tscn`).

No external plugins or addons are required - everything uses Godot's
built-in nodes, physics and 2D drawing.

## Controls

- **WASD / Arrow keys** - move around the arena.
- **Left mouse button** (held) - fire the blaster, aimed at the cursor.
- **E** (or Enter, or click) - advance Ono's dialogue on the Hub screen.
- Buttons, wave questions and multiple-choice answers are otherwise
  mouse-driven.

## How the game is organised

```
project.godot            Godot project settings, autoloads, input map
icon.svg                 Project icon (a small lightbulb)

autoload/
  ProgressTracker.gd      Singleton: mastery scores, run stats, save/load
  ContentLoader.gd         Singleton: shared JSON-loading helper

scenes/
  Hub/                     Welcome screen: Ono greets you, Start, Journal
  Companion/               Ono's greeting lines + the dialogue box system
  Journal/                 Ono's journal - a hand-drawn mastery bar chart
  Shared/                  HotspotInterfacePanel (mock UI renderer) and
                            RoundReport (shared grade-marker feedback panel)
  Game/
    Game.tscn/.gd            Run controller: arena, HUD, wave sequencing
    Player.tscn/.gd          The student's light-blaster avatar
    Enemy.tscn/.gd           A "glitch" - chases the player, deals contact damage
    Bullet.tscn/.gd          A single light-bolt projectile
    WaveManager.gd           Spawns each wave's enemies from waves.json
    QuestionInterstitial.tscn/.gd
                              Shown between waves; every question "shape"
                              (identify, identify+explain, compare-two-panels,
                              macron-check, rapid boss pairs) lives here

content/
  principles.json          Every usability concept the game tests
  waves.json               The run's wave sequence (enemy count/type, question source)
  *_questions.json          Question banks, one file per question shape
  companion_dialogue.json  Ono's Hub-screen dialogue lines
  README.md                 Full schema reference for adding new content
```

## Adding or editing questions

You don't need to touch any GDScript. Everything a teacher would want to
change lives in the `content/` folder as plain JSON files - see
**`content/README.md`** for the full schema: every question type (hotspot
questions, explanation stages, side-by-side comparisons, macron-spotting
items, confusable-pair prompts) and the wave sequence itself.

A quick example - adding a new Spot-It-style question means copying an
existing entry in `content/spot_it_questions.json`, giving it a new `id`,
and changing the mock screen, hotspot position, and correct principle.
Press F5 and play through a run to see it turn up.

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
- **Mastery persists, combat power doesn't.** `ProgressTracker.gd` saves
  mastery per concept (and a couple of run stats) to a single JSON file
  in Godot's user data directory (`user://usability_quest_save.json`).
  The player's weapon stats (damage, fire rate, bullet count) live on
  `Player.gd` instead and reset every run, so a new run is always a fair
  challenge - only the student's actual understanding carries forward.
- **No punishing fail state.** If the player's health reaches 0, the run
  ends early and returns to the Hub with a soft, non-judgemental message -
  every question already answered that run still counted.
- **New Zealand English** spelling is used throughout the UI text, and te
  reo Māori is woven into labels naturally rather than offered as a
  separate translated mode.

## Known limitations / good next steps

- There's no exam-wording toggle UI yet - `ProgressTracker.exam_wording_mode`
  already drives which wording `RoundReport` shows, it just needs a
  checkbox somewhere (the Hub screen is a natural spot).
- Enemies use simple "always move straight at the player" chase logic with
  no pathfinding or obstacles - fine for one open arena, but would need
  real navigation if the arena ever gets walls or terrain.
- Only a handful of sample questions ship per bank (3-8, covering a spread
  of principles and both confusable pairs) - see `content/README.md` to
  add more, especially since a couple of banks get drawn from twice in one
  run.
