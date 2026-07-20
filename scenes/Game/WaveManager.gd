extends Node
## WaveManager.gd
##
## Spawns enemies for one wave at a time, reading the run's wave sequence
## from content/waves.json (see that file for the schema). Owned by
## Game.gd, which calls setup() once then start_wave(index) per wave and
## listens for wave_cleared to know when to show the question interstitial.

signal wave_cleared(wave_data: Dictionary)
signal enemy_count_changed(remaining: int)

const WAVES_PATH := "res://content/waves.json"
const ENEMY_SCENE := preload("res://scenes/Game/Enemy.tscn")

## enemy_type -> stats. "speed": 0.0 means use Enemy.gd's own default speed.
const ENEMY_STATS := {
	"glitch": {"health": 2.0, "speed": 0.0},
	"boss_glitch": {"health": 6.0, "speed": 70.0},
}

@export var arena_bounds: Rect2 = Rect2(40, 40, 1200, 640)
@export var spawn_margin: float = 20.0

var waves: Array = []
var _player: Node2D = null
var _enemies_root: Node = null
var _alive_count := 0
var _current_wave: Dictionary = {}

func setup(player: Node2D, enemies_root: Node) -> void:
	_player = player
	_enemies_root = enemies_root
	waves = ContentLoader.load_json(WAVES_PATH).get("waves", [])

func wave_count() -> int:
	return waves.size()

func get_wave(index: int) -> Dictionary:
	if index < 0 or index >= waves.size():
		return {}
	return waves[index]

func start_wave(index: int) -> void:
	_current_wave = get_wave(index)
	if _current_wave.is_empty():
		return
	var enemy_type: String = _current_wave.get("enemy_type", "glitch")
	var stats: Dictionary = ENEMY_STATS.get(enemy_type, ENEMY_STATS["glitch"])
	var count: int = _current_wave.get("enemy_count", 3)
	_alive_count = count
	enemy_count_changed.emit(_alive_count)
	for i in count:
		_spawn_enemy(stats)

func _spawn_enemy(stats: Dictionary) -> void:
	var enemy := ENEMY_SCENE.instantiate()
	enemy.max_health = stats.get("health", 2.0)
	enemy.speed_override = stats.get("speed", 0.0)
	_enemies_root.add_child(enemy)
	enemy.global_position = _random_edge_point()
	enemy.set_target(_player)
	enemy.died.connect(_on_enemy_died)

func _random_edge_point() -> Vector2:
	var side := randi() % 4
	var x := randf_range(arena_bounds.position.x + spawn_margin, arena_bounds.end.x - spawn_margin)
	var y := randf_range(arena_bounds.position.y + spawn_margin, arena_bounds.end.y - spawn_margin)
	match side:
		0: y = arena_bounds.position.y + spawn_margin
		1: y = arena_bounds.end.y - spawn_margin
		2: x = arena_bounds.position.x + spawn_margin
		_: x = arena_bounds.end.x - spawn_margin
	return Vector2(x, y)

func _on_enemy_died() -> void:
	_alive_count -= 1
	enemy_count_changed.emit(_alive_count)
	if _alive_count <= 0:
		wave_cleared.emit(_current_wave)
