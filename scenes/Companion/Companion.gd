extends Node
## Companion.gd
##
## Ono, the small companion who greets the student on the Hub screen. Just
## picks a warm line depending on how revision is going, read from
## content/companion_dialogue.json so a teacher can adjust the tone or
## wording without touching this script.

const DIALOGUE_PATH := "res://content/companion_dialogue.json"

## Returns one dialogue sequence (an Array of lines) appropriate to the
## student's current overall progress.
func get_greeting_lines() -> Array:
	var data := ContentLoader.load_json(DIALOGUE_PATH)
	var pools: Dictionary = data.get("hub_greetings", {})
	var light := ProgressTracker.overall_light_level()
	var pool_key := "early"
	if light >= 66.0:
		pool_key = "late"
	elif light >= 25.0:
		pool_key = "mid"
	var sequences: Array = pools.get(pool_key, [["Hello. Take your time."]])
	if sequences.is_empty():
		return ["Hello. Take your time."]
	return sequences[randi() % sequences.size()]
