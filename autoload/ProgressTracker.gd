extends Node
## ProgressTracker.gd
##
## Autoload singleton (see project.godot -> [autoload]) that stores the
## student's progress through Usability Quest:
##   - mastery scores (0-100) for every usability concept in AS92006
##   - a couple of small session settings (exam-wording toggle)
##   - best-run stats (how far a run got, how many runs played, best boss streak)
##
## This is the ONE place score logic lives. Every question the student
## answers - in any wave, of any run - calls record_answer(principle_id, tier),
## and the Journal scene reads mastery straight back out of here to draw its
## chart. Everything is saved to a single JSON file (see SAVE_PATH) rather
## than scattering save data across scenes.
##
## Mastery is deliberately the ONLY thing that persists between runs. Combat
## power (weapon tier, fire rate) lives on the Player node instead and resets
## every run, so a new run is always a fair, fresh challenge - only the
## student's actual understanding carries forward.

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
var exam_wording_mode: bool = false
var best_wave_reached: int = 0
var total_runs: int = 0
var best_boss_streak: int = 0

func _ready() -> void:
	_reset_defaults()
	load_progress()

func _reset_defaults() -> void:
	for pid in PRINCIPLE_IDS:
		mastery[pid] = 0

## Call this whenever a question is marked, in any wave of any run.
## tier must be one of "excellence", "merit", "achievement", "not_achieved".
func record_answer(principle_id: String, tier: String) -> void:
	if not mastery.has(principle_id):
		return
	var delta: int = TIER_DELTA.get(tier, 0)
	mastery[principle_id] = clampi(mastery[principle_id] + delta, 0, 100)
	save_progress()

func get_mastery(principle_id: String) -> int:
	return mastery.get(principle_id, 0)

## Overall "light" level (0-100), used to brighten the Hub screen / lightbulb
## motif as the student's understanding grows across every concept.
func overall_light_level() -> float:
	if mastery.is_empty():
		return 0.0
	var total := 0
	for pid in PRINCIPLE_IDS:
		total += int(mastery.get(pid, 0))
	return float(total) / float(PRINCIPLE_IDS.size())

## Call once when a run ends (health depleted or all waves cleared).
func record_run_result(wave_reached: int) -> void:
	total_runs += 1
	if wave_reached > best_wave_reached:
		best_wave_reached = wave_reached
	save_progress()

func record_boss_streak(streak: int) -> void:
	if streak > best_boss_streak:
		best_boss_streak = streak
		save_progress()

func save_progress() -> void:
	var data := {
		"mastery": mastery,
		"exam_wording_mode": exam_wording_mode,
		"best_wave_reached": best_wave_reached,
		"total_runs": total_runs,
		"best_boss_streak": best_boss_streak,
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
	exam_wording_mode = parsed.get("exam_wording_mode", false)
	best_wave_reached = parsed.get("best_wave_reached", 0)
	total_runs = parsed.get("total_runs", 0)
	best_boss_streak = parsed.get("best_boss_streak", 0)
