extends CanvasLayer
## QuestionInterstitial.gd
##
## Shown between waves (and as the boss gate before the final wave). Ports
## the five question "shapes" that used to live in five separate mode
## scenes (SpotIt/ExplainIt/CompareIt/MatapoMaori/ConfusablePairs) into one
## place, since they're now triggered by wave completion instead of by
## walking through a hub door. Reuses the same HotspotInterfacePanel and
## RoundReport components those scenes used, so the mock interfaces and
## tier-feedback panel look and behave identically. Set to
## PROCESS_MODE_ALWAYS so its buttons stay clickable while Game.gd has the
## rest of the tree paused.
##
## Each content bank is shuffled once per run and drawn from in order (see
## _next_question), so a bank used across multiple waves never repeats a
## question within the same run.

signal resolved(tier: String)

const BANK_PATHS := {
	"spot_it": "res://content/spot_it_questions.json",
	"explain_it": "res://content/explain_it_questions.json",
	"compare_it": "res://content/compare_it_questions.json",
	"matapono_maori": "res://content/matapono_maori_questions.json",
	"confusable_pairs": "res://content/confusable_pairs_questions.json",
}

@onready var progress_label: Label = $Overlay/Margin/Layout/ProgressLabel
@onready var prompt_label: Label = $Overlay/Margin/Layout/PromptLabel
@onready var purpose_label: Label = $Overlay/Margin/Layout/PurposeLabel
@onready var panels_box: HBoxContainer = $Overlay/Margin/Layout/PanelsBox
@onready var panel_a: Control = $Overlay/Margin/Layout/PanelsBox/PanelA
@onready var panel_b: Control = $Overlay/Margin/Layout/PanelsBox/PanelB
@onready var choices_box: VBoxContainer = $Overlay/Margin/Layout/ChoicesBox
@onready var report: Control = $Report

var _principles: Dictionary = {}
var _banks: Dictionary = {} # source -> Array of not-yet-used questions this run
var _source := ""
var _current: Dictionary = {}
var _stage := ""
var _boss_streak := 0
var _boss_questions_left := 0
var _pending_tier := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_principles = ContentLoader.load_principles()
	panel_a.hotspot_pressed.connect(_on_panel_a_hotspot)
	panel_b.hotspot_pressed.connect(_on_panel_b_hotspot)
	report.continued.connect(_on_report_continued)
	hide()

## Called by Game.gd once a wave's enemies are all cleared.
func begin(wave_data: Dictionary) -> void:
	_source = wave_data.get("question_source", "spot_it")
	progress_label.text = "%s complete" % wave_data.get("label", "Wave")
	_clear_choices()
	show()
	match _source:
		"spot_it":
			_current = _next_question("spot_it")
			_start_spot_it()
		"explain_it":
			_current = _next_question("explain_it")
			_start_explain_it()
		"compare_it":
			_current = _next_question("compare_it")
			_start_compare_it()
		"matapono_maori":
			_current = _next_question("matapono_maori")
			_start_matapono()
		"confusable_pairs":
			_boss_streak = 0
			_boss_questions_left = 2
			_start_confusable_question()

func _next_question(source: String) -> Dictionary:
	var queue: Array = _banks.get(source, [])
	if queue.is_empty():
		var data := ContentLoader.load_json(BANK_PATHS[source])
		queue = data.get("questions", []).duplicate()
		queue.shuffle()
	var question: Dictionary = queue.pop_front()
	_banks[source] = queue
	return question

func _clear_choices() -> void:
	for c in choices_box.get_children():
		c.queue_free()

func _reset_panels() -> void:
	purpose_label.visible = false
	panels_box.visible = true
	panel_b.visible = false

## --- Spot It shape: single hotspot, identify the principle ---

func _start_spot_it() -> void:
	_reset_panels()
	_stage = "identify"
	prompt_label.text = _current.get("prompt", "")
	panel_a.build(_current["mock_interface"], [_current["hotspot"]])

func _on_spot_it_hotspot() -> void:
	if choices_box.get_child_count() > 0:
		return
	var choices: Array = _current["choices"].duplicate()
	choices.shuffle()
	for pid in choices:
		var b := Button.new()
		b.text = _principles.get(pid, {}).get("name_en", pid)
		b.pressed.connect(_on_spot_it_choice.bind(pid))
		choices_box.add_child(b)

func _on_spot_it_choice(pid: String) -> void:
	_clear_choices()
	var correct: String = _current["correct_principle"]
	var is_correct: bool = pid == correct
	var tier := "achievement" if is_correct else "not_achieved"
	var feedback: Dictionary = _current.get("feedback", {})
	var message: String = feedback.get("correct", "") if is_correct else feedback.get("incorrect", "")
	ProgressTracker.record_answer(correct, tier)
	_show_report_and_resolve(tier, correct, message)

## --- Explain It shape: identify -> explain why ---

func _start_explain_it() -> void:
	_reset_panels()
	_stage = "identify"
	prompt_label.text = _current.get("prompt", "")
	purpose_label.visible = true
	purpose_label.text = "Interface purpose: %s" % _current.get("interface_purpose", "")
	panel_a.build(_current["mock_interface"], [_current["hotspot"]])

func _on_explain_it_hotspot() -> void:
	if _stage != "identify" or choices_box.get_child_count() > 0:
		return
	var choices: Array = _current["principle_choices"].duplicate()
	choices.shuffle()
	for pid in choices:
		var b := Button.new()
		b.text = _principles.get(pid, {}).get("name_en", pid)
		b.pressed.connect(_on_explain_it_principle.bind(pid))
		choices_box.add_child(b)

func _on_explain_it_principle(pid: String) -> void:
	var correct: String = _current["correct_principle"]
	if pid != correct:
		_clear_choices()
		ProgressTracker.record_answer(correct, "not_achieved")
		_show_report_and_resolve("not_achieved", correct,
			"Not quite the right principle for this feature - naming the correct one is the first step.")
		return
	_stage = "explain"
	_clear_choices()
	var explanations: Array = _current["explanation_choices"].duplicate()
	explanations.shuffle()
	for choice in explanations:
		var b := Button.new()
		b.text = choice["text"]
		b.pressed.connect(_on_explain_it_explanation.bind(choice))
		choices_box.add_child(b)

func _on_explain_it_explanation(choice: Dictionary) -> void:
	_clear_choices()
	var correct: String = _current["correct_principle"]
	var tier: String = choice.get("tier", "not_achieved")
	ProgressTracker.record_answer(correct, tier)
	_show_report_and_resolve(tier, correct, choice.get("feedback", ""))

## --- Compare It shape: pick the better panel -> justify -> improve ---

func _start_compare_it() -> void:
	_reset_panels()
	_stage = "pick"
	prompt_label.text = _current.get("prompt", "")
	panel_b.visible = true
	panel_a.build(_current["panel_a"]["mock_interface"], [_current["panel_a"]["hotspot"]])
	panel_b.build(_current["panel_b"]["mock_interface"], [_current["panel_b"]["hotspot"]])

func _on_compare_it_panel(which: String) -> void:
	if _stage != "pick":
		return
	var correct_panel: String = _current["better_panel"]
	var principle_id: String = _current["principle_focus"]
	if which != correct_panel:
		ProgressTracker.record_answer(principle_id, "not_achieved")
		_show_report_and_resolve("not_achieved", principle_id,
			"Look again at how each screen handles this - one of them does it more effectively.")
		return
	_stage = "justify"
	_clear_choices()
	var justifications: Array = _current["justification_choices"].duplicate()
	justifications.shuffle()
	for choice in justifications:
		var b := Button.new()
		b.text = choice["text"]
		b.pressed.connect(_on_compare_it_justification.bind(choice))
		choices_box.add_child(b)

func _on_compare_it_justification(choice: Dictionary) -> void:
	_clear_choices()
	var principle_id: String = _current["principle_focus"]
	if not choice.get("correct", false):
		ProgressTracker.record_answer(principle_id, "achievement")
		_show_report_and_resolve("achievement", principle_id,
			"You picked the right screen, but the reasoning needs to connect to the principle itself, not just describe the feature.")
		return
	_stage = "improve"
	_clear_choices()
	var improvements: Array = _current["improvement_choices"].duplicate()
	improvements.shuffle()
	for choice2 in improvements:
		var b := Button.new()
		b.text = choice2["text"]
		b.pressed.connect(_on_compare_it_improvement.bind(choice2))
		choices_box.add_child(b)

func _on_compare_it_improvement(choice: Dictionary) -> void:
	_clear_choices()
	var principle_id: String = _current["principle_focus"]
	var tier: String = choice.get("tier", "merit")
	ProgressTracker.record_answer(principle_id, tier)
	_show_report_and_resolve(tier, principle_id, choice.get("feedback", ""))

## --- Matapono Maori shape: hotspot identify, or a macron-check choice ---

func _start_matapono() -> void:
	_reset_panels()
	prompt_label.text = _current.get("prompt", "")
	if _current.get("type", "hotspot") == "hotspot":
		_stage = "identify"
		panel_a.build(_current["mock_interface"], [_current["hotspot"]])
	else:
		_stage = "macron"
		panels_box.visible = false
		_build_macron_choice()

func _on_matapono_hotspot() -> void:
	if choices_box.get_child_count() > 0:
		return
	var choices: Array = _current["choices"].duplicate()
	choices.shuffle()
	for pid in choices:
		var b := Button.new()
		b.text = _principles.get(pid, {}).get("name_en", pid)
		b.pressed.connect(_on_matapono_principle.bind(pid))
		choices_box.add_child(b)

func _on_matapono_principle(pid: String) -> void:
	_clear_choices()
	var correct: String = _current["correct_principle"]
	_resolve_matapono(correct, pid == correct)

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
	_resolve_matapono(pid, picked == correct)

func _resolve_matapono(principle_id: String, is_correct: bool) -> void:
	var tier := "achievement" if is_correct else "not_achieved"
	var feedback: Dictionary = _current.get("feedback", {})
	var message: String = feedback.get("correct", "") if is_correct else feedback.get("incorrect", "")
	ProgressTracker.record_answer(principle_id, tier)
	_show_report_and_resolve(tier, principle_id, message)

## --- Confusable Pairs shape: the boss gate, two rapid forced choices ---

func _start_confusable_question() -> void:
	_reset_panels()
	panels_box.visible = false
	_clear_choices()
	_current = _next_question("confusable_pairs")
	prompt_label.text = _current.get("scenario", "")
	var a := Button.new()
	a.text = _principles.get(_current["option_a"], {}).get("name_en", _current["option_a"])
	a.pressed.connect(_on_confusable_option.bind("a"))
	choices_box.add_child(a)
	var b := Button.new()
	b.text = _principles.get(_current["option_b"], {}).get("name_en", _current["option_b"])
	b.pressed.connect(_on_confusable_option.bind("b"))
	choices_box.add_child(b)

func _on_confusable_option(picked: String) -> void:
	_clear_choices()
	var picked_id: String = _current["option_a"] if picked == "a" else _current["option_b"]
	var correct_id: String = _current["correct_principle"]
	var is_correct: bool = picked_id == correct_id
	_boss_streak = _boss_streak + 1 if is_correct else 0
	_boss_questions_left -= 1
	var tier := "merit" if is_correct else "not_achieved"
	var feedback: Dictionary = _current.get("feedback", {})
	var message: String = feedback.get("correct", "") if is_correct else feedback.get("incorrect", "")
	ProgressTracker.record_answer(correct_id, tier)
	report.show_report(tier, _principles.get(correct_id, {}), message, ProgressTracker.exam_wording_mode)

## --- Shared finish-up ---

func _show_report_and_resolve(tier: String, principle_id: String, message: String) -> void:
	_pending_tier = tier
	report.show_report(tier, _principles.get(principle_id, {}), message, ProgressTracker.exam_wording_mode)

func _on_report_continued() -> void:
	if _source == "confusable_pairs" and _boss_questions_left > 0:
		_start_confusable_question()
		return
	if _source == "confusable_pairs":
		ProgressTracker.record_boss_streak(_boss_streak)
		var boss_tier := "not_achieved"
		if _boss_streak >= 2:
			boss_tier = "merit"
		elif _boss_streak >= 1:
			boss_tier = "achievement"
		hide()
		resolved.emit(boss_tier)
		return
	hide()
	resolved.emit(_pending_tier)
