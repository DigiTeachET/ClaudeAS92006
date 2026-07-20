extends CharacterBody2D
## Enemy.gd
##
## A "glitch" - a small hostile shape that chases the player and deals
## contact damage. Simple chase AI (move straight toward the player each
## frame) since the arena is one open room and doesn't need pathfinding.
## WaveManager sets max_health/speed_override right after instantiating,
## before adding it to the tree, so tougher "boss_glitch" waves just mean
## bigger numbers on the same scene.

signal died

const SPEED := 90.0
const CONTACT_DAMAGE := 1
const CONTACT_TICK := 0.6

@export var max_health := 2.0
@export var speed_override := 0.0 # 0 means use SPEED

var health := 0.0
var _target: Node2D = null
var _touching_player := false
var _contact_timer := 0.0

@onready var contact_area: Area2D = $ContactArea

func _ready() -> void:
	health = max_health
	contact_area.body_entered.connect(_on_contact_entered)
	contact_area.body_exited.connect(_on_contact_exited)

func set_target(target: Node2D) -> void:
	_target = target

func _physics_process(delta: float) -> void:
	if _target:
		var dir := (_target.global_position - global_position).normalized()
		var move_speed: float = speed_override if speed_override > 0.0 else SPEED
		velocity = dir * move_speed
		move_and_slide()
	_handle_contact_damage(delta)

func _handle_contact_damage(delta: float) -> void:
	if not _touching_player:
		return
	_contact_timer -= delta
	if _contact_timer <= 0.0:
		if _target and _target.has_method("take_damage"):
			_target.take_damage(CONTACT_DAMAGE)
		_contact_timer = CONTACT_TICK

func _on_contact_entered(body: Node2D) -> void:
	if body == _target:
		_touching_player = true
		_contact_timer = 0.0

func _on_contact_exited(body: Node2D) -> void:
	if body == _target:
		_touching_player = false

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		died.emit()
		queue_free()
