
extends CharacterBody2D

@export var speed: float = 150.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var attacking := false
var last_direction: String = "South"


func _physics_process(_delta: float) -> void:

	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
        "ui_down"
	)

	velocity = input_direction * speed
	move_and_slide()
	if input_direction != Vector2.ZERO:
		if abs(input_direction.x) > abs(input_direction.y):
			last_direction = "East" if input_direction.x > 0 else "West"
		else:
			last_direction = "South" if input_direction.y > 0 else "North"
		sprite.play("Walk_" + last_direction)
	else:
		sprite.play("Idle_South")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not event.is_echo():
		if not attacking:
			attack()


func attack() -> void:
	attacking = true
	sprite.play("Attack_" + last_direction)
	await sprite.animation_finished
	attacking = false
