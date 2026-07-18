extends Control
## CompareIt.gd
##
## "Compare It" mini-game - the Excellence-tier room. Two mocked interfaces
## solve the same usability problem differently. The student picks the one
## that does it better, justifies the choice, then suggests one improvement
## - only reaching Excellence if the improvement is correctly tied to a
## named usability principle.

const QUESTIONS_PATH := "res://content/compare_it_questions.json"

@onready var prompt_label: Label = $Margin/Layout/PromptLabel
@onready var progress_label: Label = $Margin/Layout/ProgressLabel
@onready var panel_a: Control = $Margin/Layout/PanelsBox/PanelA
@onready var panel_b: Control = $Margin/Layout/PanelsBox/PanelB
@onready var choices_box: VBoxContainer = $Margin/Layout/ChoicesBox
@onready var report: Control = $Report
@onready var back_button: Button = $BackButton

var _questions: Array = []
var _principles: Dictionary = {}
var _index: int = 0
var _current: Dictionary = {}
var _stage := "pick" # pick -> justify -> improve

func _ready() -> void:
	_questions = ContentLoader.load_json(QUESTIONS_PATH).get("questions", [])
	_questions.shuffle()
	_principles = ContentLoader.load_principles()
	panel_a.hotspot_pressed.connect(_on_panel_picked.bind("a"))
	panel_b.hotspot_pressed.connect(_on_panel_picked.bind("b"))
	report.continued.connect(_on_report_continued)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn"))
	_load_question(0)

func _load_question(i: int) -> void:
	if i >= _questions.size():
		ProgressTracker.complete_round("compare_it")
		get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn")
		return
	_index = i
	_current = _questions[i]
	_stage = "pick"
	progress_label.text = "Question %d of %d" % [i + 1, _questions.size()]
	prompt_label.text = _current.get("prompt", "")
	_clear_choices()
	panel_a.build(_current["panel_a"]["mock_interface"], [_current["panel_a"]["hotspot"]])
	panel_b.build(_current["panel_b"]["mock_interface"], [_current["panel_b"]["hotspot"]])

func _clear_choices() -> void:
	for c in choices_box.get_children():
		c.queue_free()

func _on_panel_picked(_i: int, which: String) -> void:
	if _stage != "pick":
		return
	var correct_panel: String = _current["better_panel"]
	var principle: Dictionary = _principles.get(_current["principle_focus"], {})
	if which != correct_panel:
		ProgressTracker.record_answer(_current["principle_focus"], "not_achieved")
		report.show_report("not_achieved", principle,
			"Look again at how each screen handles this - one of them does it more effectively.",
			ProgressTracker.exam_wording_mode)
		return
	_stage = "justify"
	_clear_choices()
	var justifications: Array = _current["justification_choices"].duplicate()
	justifications.shuffle()
	for choice in justifications:
		var b := Button.new()
		b.text = choice["text"]
		b.pressed.connect(_on_justification_selected.bind(choice))
		choices_box.add_child(b)

func _on_justification_selected(choice: Dictionary) -> void:
	_clear_choices()
	var principle: Dictionary = _principles.get(_current["principle_focus"], {})
	if not choice.get("correct", false):
		ProgressTracker.record_answer(_current["principle_focus"], "achievement")
		report.show_report("achievement", principle,
			"You picked the right screen, but the reasoning needs to connect to the principle itself, not just describe the feature.",
			ProgressTracker.exam_wording_mode)
		return
	_stage = "improve"
	var improvements: Array = _current["improvement_choices"].duplicate()
	improvements.shuffle()
	for choice2 in improvements:
		var b := Button.new()
		b.text = choice2["text"]
		b.pressed.connect(_on_improvement_selected.bind(choice2))
		choices_box.add_child(b)

func _on_improvement_selected(choice: Dictionary) -> void:
	_clear_choices()
	var principle: Dictionary = _principles.get(_current["principle_focus"], {})
	var tier: String = choice.get("tier", "merit")
	ProgressTracker.record_answer(_current["principle_focus"], tier)
	report.show_report(tier, principle, choice.get("feedback", ""), ProgressTracker.exam_wording_mode)

func _on_report_continued() -> void:
	_load_question(_index + 1)
