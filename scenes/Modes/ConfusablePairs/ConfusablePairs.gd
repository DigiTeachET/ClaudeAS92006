extends Control
## ConfusablePairs.gd
##
## "Confusable Pairs" boss round - unlocked once all four other rooms are
## done. Rapid forced choice between the two pairs students mix up most
## often each year: Error Prevention vs Error Recovery, and User Control
## and Freedom vs Flexibility and Efficiency of Use. Tracks a running streak
## rather than a per-question grade tier - a wrong answer resets the streak
## and feels like "not yet", never a game over.

const QUESTIONS_PATH := "res://content/confusable_pairs_questions.json"

@onready var scenario_label: Label = $Margin/Layout/ScenarioLabel
@onready var streak_label: Label = $Margin/Layout/StreakLabel
@onready var option_a_button: Button = $Margin/Layout/OptionsBox/OptionA
@onready var option_b_button: Button = $Margin/Layout/OptionsBox/OptionB
@onready var report: Control = $Report
@onready var back_button: Button = $BackButton

var _questions: Array = []
var _principles: Dictionary = {}
var _index: int = 0
var _current: Dictionary = {}
var _streak := 0

func _ready() -> void:
	_questions = ContentLoader.load_json(QUESTIONS_PATH).get("questions", [])
	_questions.shuffle()
	_principles = ContentLoader.load_principles()
	option_a_button.pressed.connect(_on_option_selected.bind("a"))
	option_b_button.pressed.connect(_on_option_selected.bind("b"))
	report.continued.connect(_on_report_continued)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn"))
	streak_label.text = "Streak: 0"
	_load_question(0)

func _load_question(i: int) -> void:
	if i >= _questions.size():
		ProgressTracker.record_confusable_streak(_streak)
		ProgressTracker.complete_round("confusable_pairs")
		get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn")
		return
	_index = i
	_current = _questions[i]
	scenario_label.text = _current.get("scenario", "")
	option_a_button.text = _principles.get(_current["option_a"], {}).get("name_en", _current["option_a"])
	option_b_button.text = _principles.get(_current["option_b"], {}).get("name_en", _current["option_b"])
	option_a_button.disabled = false
	option_b_button.disabled = false

func _on_option_selected(picked: String) -> void:
	option_a_button.disabled = true
	option_b_button.disabled = true
	var picked_id: String = _current["option_a"] if picked == "a" else _current["option_b"]
	var correct_id: String = _current["correct_principle"]
	var is_correct: bool = picked_id == correct_id
	var feedback: Dictionary = _current.get("feedback", {})
	_streak = _streak + 1 if is_correct else 0
	streak_label.text = "Streak: %d" % _streak
	var tier := "merit" if is_correct else "not_achieved"
	ProgressTracker.record_answer(correct_id, tier)
	var message: String = feedback.get("correct", "") if is_correct else feedback.get("incorrect", "")
	report.show_report(tier, _principles.get(correct_id, {}), message, ProgressTracker.exam_wording_mode)

func _on_report_continued() -> void:
	_load_question(_index + 1)
