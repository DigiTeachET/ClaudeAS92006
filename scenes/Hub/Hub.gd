extends Control
## Hub.gd
##
## The hub is a simple welcome screen, not a walkable space: Ono greets the
## student, "Start" begins a survival run, and "Journal" opens the mastery
## notebook. There's no more menu of separate mode-doors to walk between -
## the whole game is one run now, with different question types woven into
## different waves instead of separate rooms.

@onready var companion: Companion = $CompanionNPC
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var start_button: Button = $Margin/VBox/ButtonsBox/StartButton
@onready var journal_button: Button = $Margin/VBox/ButtonsBox/JournalButton
@onready var talk_button: Button = $Margin/VBox/ButtonsBox/TalkButton
@onready var light_meter: ProgressBar = $Margin/VBox/LightMeterBox/VBox/LightMeter
@onready var run_stats_label: Label = $Margin/VBox/RunStatsLabel

func _ready() -> void:
	dialogue_box.hide()
	start_button.pressed.connect(_on_start_pressed)
	journal_button.pressed.connect(_on_journal_pressed)
	talk_button.pressed.connect(_on_talk_pressed)
	light_meter.value = ProgressTracker.overall_light_level()
	_update_run_stats_label()
	dialogue_box.say(companion.get_greeting_lines())

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game/Game.tscn")

func _on_journal_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Journal/Journal.tscn")

func _on_talk_pressed() -> void:
	dialogue_box.say(companion.get_greeting_lines())

func _update_run_stats_label() -> void:
	if ProgressTracker.total_runs <= 0:
		run_stats_label.text = "No runs yet - Ono's waiting for you to begin."
	else:
		run_stats_label.text = "Runs so far: %d   Best wave reached: %d" % [ProgressTracker.total_runs, ProgressTracker.best_wave_reached]
