extends CharacterBody2D
## Player.gd
##
## The student's light-blaster avatar. Moves with the existing
## move_up/down/left/right input actions (see project.godot), aims at the
## mouse, and fires on left click. Weapon stats (damage / fire rate /
## bullet count) only ever go up within a single run via apply_upgrade() -
## they start fresh at their base values every run, since combat power is
## a session thing while mastery (ProgressTracker) is what actually
## persists between runs.

signal health_changed(current: int, current_max_health: int)
signal died

const SPEED := 220.0
const BULLET_SCENE := preload("res://scenes/Game/Bullet.tscn")
const INVINCIBILITY_TIME := 0.8
const BASE_FIRE_COOLDOWN := 0.35
const SPREAD_ANGLE := 0.21 # ~12 degrees, in radians

@export var arena_bounds: Rect2 = Rect2(40, 40, 1200, 640)

var max_health := 5
var health := 5
var damage := 1.0
var fire_cooldown := BASE_FIRE_COOLDOWN
var bullet_count := 1

var _invincible := false
var _fire_timer := 0.0

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)

func _handle_movement() -> void:
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if dir.length() > 0.0:
		dir = dir.normalized()
	velocity = dir * SPEED
	move_and_slide()
	position.x = clamp(position.x, arena_bounds.position.x, arena_bounds.end.x)
	position.y = clamp(position.y, arena_bounds.position.y, arena_bounds.end.y)

func _handle_shooting(delta: float) -> void:
	_fire_timer -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _fire_timer <= 0.0:
		_fire()
		_fire_timer = fire_cooldown

func _fire() -> void:
	var aim_dir := (get_global_mouse_position() - global_position).normalized()
	var mid := float(bullet_count - 1) / 2.0
	for i in bullet_count:
		var angle_offset := (float(i) - mid) * SPREAD_ANGLE
		var dir := aim_dir.rotated(angle_offset)
		var bullet := BULLET_SCENE.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.setup(dir, damage)

func take_damage(amount: int) -> void:
	if _invincible:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()
		return
	_start_invincibility()

func _start_invincibility() -> void:
	_invincible = true
	modulate.a = 0.5
	await get_tree().create_timer(INVINCIBILITY_TIME).timeout
	_invincible = false
	modulate.a = 1.0

## Called by QuestionInterstitial after a wave's question is marked. tier is
## "excellence" | "merit" | "achievement" | "not_achieved" - Not Achieved
## simply means no upgrade this wave, never a penalty.
func apply_upgrade(tier: String) -> void:
	match tier:
		"achievement":
			damage += 0.5
		"merit":
			fire_cooldown = max(0.12, fire_cooldown * 0.85)
		"excellence":
			bullet_count += 1
			damage += 0.5
		_:
			pass
