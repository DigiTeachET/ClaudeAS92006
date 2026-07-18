extends Control
## SpotIt.gd
##
## "Spot It" mini-game - the Achievement-tier room. The student clicks a
## highlighted hotspot on a mocked interface, then picks the usability
## principle it demonstrates from a short multiple-choice list. Getting the
## principle right earns Achievement; getting it wrong earns Not Achieved
## with a tip pointing at the mix-up.

const QUESTIONS_PATH := "res://content/spot_it_questions.json"

@onready var prompt_label: Label = $Margin/Layout/PromptLabel
@onready var progress_label: Label = $Margin/Layout/ProgressLabel
@onready var panel: Control = $Margin/Layout/HotspotInterfacePanel
@onready var choices_box: VBoxContainer = $Margin/Layout/ChoicesBox
@onready var report: Control = $Report
@onready var back_button: Button = $BackButton

var _questions: Array = []
var _principles: Dictionary = {}
var _index: int = 0
var _current: Dictionary = {}

func _ready() -> void:
	_questions = ContentLoader.load_json(QUESTIONS_PATH).get("questions", [])
	_questions.shuffle()
	_principles = ContentLoader.load_principles()
	panel.hotspot_pressed.connect(_on_hotspot_pressed)
	report.continued.connect(_on_report_continued)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn"))
	_load_question(0)

func _load_question(i: int) -> void:
	if i >= _questions.size():
		ProgressTracker.complete_round("spot_it")
		get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn")
		return
	_index = i
	_current = _questions[i]
	progress_label.text = "Question %d of %d" % [i + 1, _questions.size()]
	prompt_label.text = _current.get("prompt", "")
	_clear_choices()
	panel.build(_current["mock_interface"], [_current["hotspot"]])

func _clear_choices() -> void:
	for c in choices_box.get_children():
		c.queue_free()

func _on_hotspot_pressed(_hotspot_index: int) -> void:
	if choices_box.get_child_count() > 0:
		return
	var choices: Array = _current["choices"].duplicate()
	choices.shuffle()
	for pid in choices:
		var b := Button.new()
		b.text = _principles.get(pid, {}).get("name_en", pid)
		b.pressed.connect(_on_choice_selected.bind(pid))
		choices_box.add_child(b)

func _on_choice_selected(pid: String) -> void:
	_clear_choices()
	var correct: String = _current["correct_principle"]
	var is_correct: bool = pid == correct
	var tier := "achievement" if is_correct else "not_achieved"
	var feedback: Dictionary = _current.get("feedback", {})
	var message: String = feedback.get("correct", "") if is_correct else feedback.get("incorrect", "")
	ProgressTracker.record_answer(correct, tier)
	report.show_report(tier, _principles.get(correct, {}), message, ProgressTracker.exam_wording_mode)

func _on_report_continued() -> void:
	_load_question(_index + 1)
