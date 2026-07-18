extends Control
## MatapoMaori.gd
##
## "Mātāpono Māori" mini-game - tests the usability lens specific to this
## standard's scenario B: manaakitanga, rangatiratanga, whanaungatanga,
## wairuatanga, correct macron/tohutō use, and whether an interface supports
## the expression of mātauranga Māori. Reuses the Spot It hotspot mechanic
## for "hotspot" questions, plus a "which version is correct" choice for
## "macron_check" questions.

const QUESTIONS_PATH := "res://content/matapono_maori_questions.json"

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
		ProgressTracker.complete_round("matapono_maori")
		get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn")
		return
	_index = i
	_current = _questions[i]
	progress_label.text = "Question %d of %d" % [i + 1, _questions.size()]
	prompt_label.text = _current.get("prompt", "")
	_clear_choices()
	if _current.get("type", "hotspot") == "hotspot":
		panel.show()
		panel.build(_current["mock_interface"], [_current["hotspot"]])
	else:
		panel.hide()
		_build_macron_choice()

func _clear_choices() -> void:
	for c in choices_box.get_children():
		c.queue_free()

func _build_macron_choice() -> void:
	var a := Button.new()
	a.text = _current["option_a"]
	a.autowrap_mode = TextServer.AUTOWRAP_WORD
	a.pressed.connect(_on_macron_selected.bind("a"))
	choices_box.add_child(a)
	var b := Button.new()
	b.text = _current["option_b"]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD
	b.pressed.connect(_on_macron_selected.bind("b"))
	choices_box.add_child(b)

func _on_macron_selected(picked: String) -> void:
	_clear_choices()
	var correct: String = _current["correct_option"]
	var pid: String = _current["correct_principle"]
	var is_correct: bool = picked == correct
	_show_result(pid, is_correct)

func _on_hotspot_pressed(_i: int) -> void:
	if choices_box.get_child_count() > 0:
		return
	var choices: Array = _current["choices"].duplicate()
	choices.shuffle()
	for pid in choices:
		var b := Button.new()
		b.text = _principles.get(pid, {}).get("name_en", pid)
		b.pressed.connect(_on_principle_selected.bind(pid))
		choices_box.add_child(b)

func _on_principle_selected(pid: String) -> void:
	_clear_choices()
	var correct: String = _current["correct_principle"]
	_show_result(correct, pid == correct)

func _show_result(principle_id: String, is_correct: bool) -> void:
	var tier := "achievement" if is_correct else "not_achieved"
	var feedback: Dictionary = _current.get("feedback", {})
	var message: String = feedback.get("correct", "") if is_correct else feedback.get("incorrect", "")
	ProgressTracker.record_answer(principle_id, tier)
	report.show_report(tier, _principles.get(principle_id, {}), message, ProgressTracker.exam_wording_mode)

func _on_report_continued() -> void:
	_load_question(_index + 1)
