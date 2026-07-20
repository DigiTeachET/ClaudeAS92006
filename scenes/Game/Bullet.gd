extends Area2D
class_name Bullet
## Bullet.gd
##
## A single light-bolt fired from the player's blaster. Travels in a
## straight line, deals damage to whatever it hits, and frees itself on
## impact or after a short lifetime so the arena doesn't fill up with
## off-screen bullets.

const SPEED := 520.0
const LIFETIME := 1.5

var _velocity := Vector2.ZERO
var _damage := 1.0
var _age := 0.0

func setup(direction: Vector2, damage: float) -> void:
	_velocity = direction * SPEED
	_damage = damage
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	var enemy := body as Enemy
	if enemy:
		enemy.take_damage(_damage)
	queue_free()
