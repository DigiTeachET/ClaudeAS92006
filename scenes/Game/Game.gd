extends Node2D
## Game.gd
##
## Runs one full survival run: owns the arena, the player, the wave
## sequence (via WaveManager), and the between-wave question interstitial.
## A run ends either when the player's health reaches 0 (soft ending, no
## punishment beyond stopping the run early - all mastery already recorded
## that run is kept, since ProgressTracker.record_answer saves immediately)
## or when every wave in content/waves.json is cleared.

const ARENA_BOUNDS := Rect2(40, 40, 1200, 640)

@onready var player: Player = $Player
@onready var enemies_root: Node2D = $Enemies
@onready var wave_manager: WaveManager = $WaveManager
@onready var question_interstitial: QuestionInterstitial = $QuestionInterstitial
@onready var health_label: Label = $UI/HUD/Box/HealthLabel
@onready var wave_label: Label = $UI/HUD/Box/WaveLabel
@onready var enemies_label: Label = $UI/HUD/Box/EnemiesLabel
@onready var weapon_label: Label = $UI/HUD/Box/WeaponLabel
@onready var run_end_overlay: Control = $UI/RunEndOverlay
@onready var run_end_message: Label = $UI/RunEndOverlay/Panel/Margin/VBox/MessageLabel
@onready var run_end_button: Button = $UI/RunEndOverlay/Panel/Margin/VBox/ReturnButton

var _wave_index := 0

func _ready() -> void:
	player.arena_bounds = ARENA_BOUNDS
	player.position = ARENA_BOUNDS.get_center()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	wave_manager.arena_bounds = ARENA_BOUNDS
	wave_manager.setup(player, enemies_root)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.enemy_count_changed.connect(_on_enemy_count_changed)
	question_interstitial.resolved.connect(_on_question_resolved)
	run_end_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	run_end_overlay.hide()
	run_end_button.pressed.connect(_on_return_to_hub)
	_update_health_label()
	_update_weapon_label()
	_start_wave(0)

func _start_wave(index: int) -> void:
	_wave_index = index
	var wave_data := wave_manager.get_wave(index)
	wave_label.text = wave_data.get("label", "Wave %d" % (index + 1))
	wave_manager.start_wave(index)

func _on_enemy_count_changed(remaining: int) -> void:
	enemies_label.text = "Enemies: %d" % remaining

func _on_wave_cleared(wave_data: Dictionary) -> void:
	get_tree().paused = true
	question_interstitial.begin(wave_data)

func _on_question_resolved(tier: String) -> void:
	player.apply_upgrade(tier)
	_update_weapon_label()
	get_tree().paused = false
	var next_index := _wave_index + 1
	if next_index >= wave_manager.wave_count():
		_end_run(true)
	else:
		_start_wave(next_index)

func _on_player_health_changed(_current: int, _current_max_health: int) -> void:
	_update_health_label()

func _update_health_label() -> void:
	health_label.text = "Health: %d/%d" % [player.health, player.max_health]

func _update_weapon_label() -> void:
	weapon_label.text = "Damage %.1f   Bullets %d" % [player.damage, player.bullet_count]

func _on_player_died() -> void:
	get_tree().paused = true
	_end_run(false)

func _end_run(cleared_all_waves: bool) -> void:
	var wave_reached := _wave_index + 1 if cleared_all_waves else _wave_index
	ProgressTracker.record_run_result(wave_reached)
	if cleared_all_waves:
		run_end_message.text = "Every wave, cleared. The static's gone quiet for now."
	else:
		run_end_message.text = "The light dims here for now - but nothing you learned this run is lost. Try again whenever you're ready."
	run_end_overlay.show()

func _on_return_to_hub() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn")
