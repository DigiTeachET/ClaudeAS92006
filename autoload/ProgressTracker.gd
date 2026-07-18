extends Node
## ProgressTracker.gd
##
## Autoload singleton (see project.godot -> [autoload]) that stores the
## student's progress through Usability Quest:
##   - mastery scores (0-100) for every usability concept in AS92006
##   - which mini-game "doors" in the hub world are unlocked
##   - a couple of small session settings (exam-wording toggle, best streak)
##
## This is the ONE place score logic lives. Every mini-game calls
## record_answer() when a question is marked, and the Journal scene reads
## mastery straight back out of here to draw its chart. Everything is saved
## to a single JSON file (see SAVE_PATH) rather than scattering save data
## across scenes.

const SAVE_PATH := "user://usability_quest_save.json"

## Every concept the standard expects students to know. The order here also
## controls the order rows are drawn in the Journal's bar chart.
const PRINCIPLE_IDS := [
	# Nielsen's 10 usability heuristics
	"visibility_of_system_status",
	"match_system_real_world",
	"user_control_freedom",
	"consistency_standards",
	"error_prevention",
	"recognition_rather_than_recall",
	"flexibility_efficiency",
	"aesthetic_minimalist_design",
	"error_recovery",
	"help_documentation",
	# Additional usability concepts
	"accessibility",
	"commensurate_effort",
	"internal_external_consistency",
	"learnability",
	"short_term_memory",
	"system_response_time",
	# Mātāpono Māori - the usability lens specific to this standard
	"te_reo_orthography",
	"manaakitanga",
	"rangatiratanga",
	"whanaungatanga",
	"wairuatanga",
	"matauranga_maori_expression",
]

const MODE_IDS := ["spot_it", "explain_it", "compare_it", "matapono_maori", "confusable_pairs"]

## How far a mastery score moves for each grade tier a question is marked at.
## Mirrors the standard's own grading: Excellence moves the needle furthest,
## Not Achieved nudges it back so a student sees the effect of guessing.
const TIER_DELTA := {
	"excellence": 12,
	"merit": 8,
	"achievement": 5,
	"not_achieved": -4,
}

var mastery: Dictionary = {}          # principle_id -> int (0-100)
var modes_unlocked: Dictionary = {}   # mode_id -> bool
var rounds_completed: Dictionary = {} # mode_id -> int
var exam_wording_mode: bool = false
var best_confusable_streak: int = 0

func _ready() -> void:
	_reset_defaults()
	load_progress()

func _reset_defaults() -> void:
	for pid in PRINCIPLE_IDS:
		mastery[pid] = 0
	for mid in MODE_IDS:
		modes_unlocked[mid] = false
		rounds_completed[mid] = 0
	modes_unlocked["spot_it"] = true # the first door is always open

## Call this whenever a mini-game finishes marking one answer.
## tier must be one of "excellence", "merit", "achievement", "not_achieved".
func record_answer(principle_id: String, tier: String) -> void:
	if not mastery.has(principle_id):
		return
	var delta: int = TIER_DELTA.get(tier, 0)
	mastery[principle_id] = clampi(mastery[principle_id] + delta, 0, 100)
	save_progress()

func get_mastery(principle_id: String) -> int:
	return mastery.get(principle_id, 0)

## Call once per mini-game when the student reaches the end of a round.
## Unlocks the next door in the hub (a simple, linear progression).
func complete_round(mode_id: String) -> void:
	rounds_completed[mode_id] = rounds_completed.get(mode_id, 0) + 1
	_update_unlocks()
	save_progress()

func _update_unlocks() -> void:
	if rounds_completed.get("spot_it", 0) >= 1:
		modes_unlocked["explain_it"] = true
	if rounds_completed.get("explain_it", 0) >= 1:
		modes_unlocked["compare_it"] = true
	if rounds_completed.get("compare_it", 0) >= 1:
		modes_unlocked["matapono_maori"] = true
	if rounds_completed.get("matapono_maori", 0) >= 1:
		modes_unlocked["confusable_pairs"] = true

func is_mode_unlocked(mode_id: String) -> bool:
	return modes_unlocked.get(mode_id, false)

## Overall "light" level (0-100), used to brighten the hub world / lightbulb
## motif as the student's understanding grows across every concept.
func overall_light_level() -> float:
	if mastery.is_empty():
		return 0.0
	var total := 0
	for pid in PRINCIPLE_IDS:
		total += int(mastery.get(pid, 0))
	return float(total) / float(PRINCIPLE_IDS.size())

func record_confusable_streak(streak: int) -> void:
	if streak > best_confusable_streak:
		best_confusable_streak = streak
		save_progress()

func save_progress() -> void:
	var data := {
		"mastery": mastery,
		"modes_unlocked": modes_unlocked,
		"rounds_completed": rounds_completed,
		"exam_wording_mode": exam_wording_mode,
		"best_confusable_streak": best_confusable_streak,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var saved_mastery: Dictionary = parsed.get("mastery", {})
	for pid in PRINCIPLE_IDS:
		if saved_mastery.has(pid):
			mastery[pid] = saved_mastery[pid]
	var saved_unlocked: Dictionary = parsed.get("modes_unlocked", {})
	var saved_rounds: Dictionary = parsed.get("rounds_completed", {})
	for mid in MODE_IDS:
		if saved_unlocked.has(mid):
			modes_unlocked[mid] = saved_unlocked[mid]
		if saved_rounds.has(mid):
			rounds_completed[mid] = saved_rounds[mid]
	exam_wording_mode = parsed.get("exam_wording_mode", false)
	best_confusable_streak = parsed.get("best_confusable_streak", 0)
