
extends CharacterBody2D

signal murio

@export var speed: float = 150.0

@export_group("Combate")
@export var vida_maxima := 1
@export var dano_ataque := 1
## Distancia desde el centro del jugador hasta el centro del golpe (píxeles).
@export var alcance_ataque := 40.0
@export var radio_ataque := 28.0
## Segundos desde que empieza la animación de ataque hasta que el golpe hace daño.
@export var retardo_golpe := 0.1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: CollisionShape2D = $HitboxPersonaje

var vida: Vida
var attacking := false
var last_direction: String = "South"

func _ready() -> void:
	add_to_group("jugador")
	vida = Vida.new()
	vida.vida_maxima = vida_maxima
	add_child(vida)
	vida.murio.connect(_on_vida_murio)
	
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
		play_idle()


func play_idle() -> void:
	var idle_anim = "Idle_" + last_direction
	if sprite.sprite_frames.has_animation(idle_anim):
		sprite.play(idle_anim)
	else:
		sprite.play("Walk_" + last_direction)
		sprite.frame = 0
		sprite.pause()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not event.is_echo():
		if not attacking:
			attack()


func attack() -> void:
	attacking = true
	sprite.play("Attack_" + last_direction)
	get_tree().create_timer(retardo_golpe).timeout.connect(_golpear)
	await sprite.animation_finished
	attacking = false


## Centro del cuerpo (el origen del personaje está en los pies).
func centro() -> Vector2:
	return _hitbox.global_position


func recibir_dano(cantidad: int) -> void:
	vida.recibir_dano(cantidad)


## Daña a todos los enemigos dentro de un círculo delante del jugador.
func _golpear() -> void:
	if not attacking:
		return
	var forma := CircleShape2D.new()
	forma.radius = radio_ataque

	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, centro() + _vector_de(last_direction) * alcance_ataque)
	consulta.collision_mask = 1
	consulta.exclude = [get_rid()]

	for resultado in get_world_2d().direct_space_state.intersect_shape(consulta):
		var objetivo := resultado.collider as Node
		if objetivo is Enemigo:
			objetivo.recibir_dano(dano_ataque)


func _vector_de(direccion: String) -> Vector2:
	match direccion:
		"North":
			return Vector2.UP
		"East":
			return Vector2.RIGHT
		"West":
			return Vector2.LEFT
		_:
			return Vector2.DOWN


func _on_vida_murio() -> void:
	print("Jugador muerto")
	murio.emit()
