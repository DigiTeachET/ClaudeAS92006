# Content folder - how to add or edit questions

Everything a teacher would want to change lives in this folder as plain
JSON files. Nothing here requires editing GDScript. Open a file in any text
editor, copy an existing entry, change the text, save, and re-run the game.

All files must stay valid JSON (matching curly braces, commas between items
but not after the last one, double quotes around text). If a mini-game shows
no questions, check the Godot "Output" panel for a `ContentLoader` warning -
it will name the broken file.

## `principles.json`

The master list of every usability concept the game can test. Every
question in every other file refers to principles **by `id`**, so don't
rename an `id` unless you also update every question that uses it.

Fields per principle:

| Field | Meaning |
|---|---|
| `id` | Unique key, used everywhere else. Don't change existing ids. |
| `category` | `heuristic`, `additional`, or `matapono_maori` (grouping only). |
| `name_en` | Display name shown to students. |
| `name_mi` | (Optional) Māori name, used for mātāpono Māori entries. |
| `plain_definition` | Short, plain-English explanation (shown by default). |
| `exam_wording` | More formal NZQA-style wording (shown when "exam wording" mode is on). |
| `not_achieved_tip` | Shown when a student is marked Not Achieved - should point at the *specific* misunderstanding, ideally referencing a common confusion. |
| `confusable_with` | (Optional) array of other principle ids students often mix this one up with. |

## Question bank files

- `spot_it_questions.json` - Achievement tier. One hotspot, one correct
  principle, up to 4 multiple-choice `choices` (principle ids).
- `explain_it_questions.json` - Merit tier. Same hotspot idea, plus a second
  stage of `explanation_choices`. Each explanation choice needs a `tier`
  (`merit`, `achievement`, or `not_achieved`) and `feedback` text. Exactly
  one choice per question should be `merit` (correct AND linked to the
  interface's purpose); one should be `achievement` (true, but only
  describes the feature - a "surface" answer); the rest are distractors,
  and at least one should test a commonly confused principle pair.
- `compare_it_questions.json` - Excellence tier. Two mock interfaces
  (`panel_a`, `panel_b`) solve the same problem differently. Three stages:
  pick the `better_panel` (`"a"` or `"b"`), pick the correct
  `justification_choices` entry, then pick an `improvement_choices` entry.
  Only the `excellence`-tier improvement should correctly name and link to
  a usability principle.
- `matapono_maori_questions.json` - Mātāpono Māori mode. Each question has
  a `type`: either `hotspot` (same shape as Spot It) or `macron_check`
  (`option_a`/`option_b` text, `correct_option` is `"a"` or `"b"`) for
  spot-the-incorrect-tohutō items.
- `confusable_pairs_questions.json` - the boss round. Each question is a
  forced choice between exactly two principle ids (`option_a`, `option_b`),
  with `correct_principle` equal to one of them. Keep mixing the order so
  students can't just memorise a screen position.

### The mock interface format

Every mini-game screen is built from a small JSON description, not a real
screenshot - this avoids any copyright/trademark issue and keeps the file
easy to edit. A `mock_interface` looks like:

```json
{
  "title": "Shown at the top of the mock screen",
  "elements": [
    { "type": "label", "text": "...", "rect": [x, y, width, height] },
    { "type": "panel", "text": "...", "rect": [x, y, width, height] },
    { "type": "button", "text": "...", "rect": [x, y, width, height] },
    { "type": "icon", "text": "🛒", "color": "#7fa08f", "rect": [x, y, width, height] }
  ]
}
```

`rect` coordinates are pixels inside the mock screen area (roughly
400x250). A `hotspot` is a separate `{ "rect": [x, y, width, height] }`
placed over the feature you want the student to click - it doesn't have to
exactly match an element's rect, just cover the area you want clickable.

## `companion_dialogue.json`

Lines spoken by Ono, the hub-world companion. `hub_greetings` has three
pools (`early`, `mid`, `late`) chosen by the student's overall mastery
level; each pool is a list of *sequences* (arrays of lines shown one at a
time). Keep the tone warm and understated - short lines, no exclamation
marks, never scoring or scolding.

## Adding a brand new question

1. Copy an existing question object in the relevant file.
2. Give it a new, unique `id`.
3. Change the text, `rect` positions, and `correct_principle`/choices.
4. Make sure every principle id you reference exists in `principles.json`.
5. Save and re-run the scene in Godot (F6, or open the mode's `.tscn` and
   press the "Run Current Scene" button) to check it looks right.
