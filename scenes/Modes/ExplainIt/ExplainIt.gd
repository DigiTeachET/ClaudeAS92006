extends Control
## ExplainIt.gd
##
## "Explain It" mini-game - the Merit-tier room. First the student names the
## usability principle at a hotspot (same as Spot It), then explains WHY
## that feature actually helps the user reach the interface's stated
## purpose. Naming the principle correctly but only describing it (a
## "surface" answer) caps the round at Achievement - matching how NZQA
## marks this standard.

const QUESTIONS_PATH := "res://content/explain_it_questions.json"

@onready var prompt_label: Label = $Margin/Layout/PromptLabel
@onready var purpose_label: Label = $Margin/Layout/PurposeLabel
@onready var progress_label: Label = $Margin/Layout/ProgressLabel
@onready var panel: Control = $Margin/Layout/HotspotInterfacePanel
@onready var choices_box: VBoxContainer = $Margin/Layout/ChoicesBox
@onready var report: Control = $Report
@onready var back_button: Button = $BackButton

var _questions: Array = []
var _principles: Dictionary = {}
var _index: int = 0
var _current: Dictionary = {}
var _stage := "identify" # identify -> explain

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
		ProgressTracker.complete_round("explain_it")
		get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn")
		return
	_index = i
	_current = _questions[i]
	_stage = "identify"
	progress_label.text = "Question %d of %d" % [i + 1, _questions.size()]
	prompt_label.text = _current.get("prompt", "")
	purpose_label.text = "Interface purpose: %s" % _current.get("interface_purpose", "")
	_clear_choices()
	panel.build(_current["mock_interface"], [_current["hotspot"]])

func _clear_choices() -> void:
	for c in choices_box.get_children():
		c.queue_free()

func _on_hotspot_pressed(_i: int) -> void:
	if _stage != "identify" or choices_box.get_child_count() > 0:
		return
	var choices: Array = _current["principle_choices"].duplicate()
	choices.shuffle()
	for pid in choices:
		var b := Button.new()
		b.text = _principles.get(pid, {}).get("name_en", pid)
		b.pressed.connect(_on_principle_selected.bind(pid))
		choices_box.add_child(b)

func _on_principle_selected(pid: String) -> void:
	var correct: String = _current["correct_principle"]
	if pid != correct:
		_clear_choices()
		ProgressTracker.record_answer(correct, "not_achieved")
		report.show_report("not_achieved", _principles.get(correct, {}),
			"Not quite the right principle for this feature - naming the correct one is the first step.",
			ProgressTracker.exam_wording_mode)
		return
	_stage = "explain"
	_clear_choices()
	var explanations: Array = _current["explanation_choices"].duplicate()
	explanations.shuffle()
	for choice in explanations:
		var b := Button.new()
		b.text = choice["text"]
		b.pressed.connect(_on_explanation_selected.bind(choice))
		choices_box.add_child(b)

func _on_explanation_selected(choice: Dictionary) -> void:
	_clear_choices()
	var correct: String = _current["correct_principle"]
	var tier: String = choice.get("tier", "not_achieved")
	ProgressTracker.record_answer(correct, tier)
	report.show_report(tier, _principles.get(correct, {}), choice.get("feedback", ""), ProgressTracker.exam_wording_mode)

func _on_report_continued() -> void:
	_load_question(_index + 1)
