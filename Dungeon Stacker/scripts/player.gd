
extends CharacterBody2D

signal murio
signal llave_cambiada(tiene: bool)

@export var speed: float = 150.0

@export_group("Combate")
@export var vida_maxima := 3
@export var dano_ataque := 1
## Distancia desde el centro del jugador hasta el centro del golpe (píxeles).
@export var alcance_ataque := 40.0
@export var radio_ataque := 28.0
## Segundos desde que empieza la animación de ataque hasta que el golpe hace daño.
@export var retardo_golpe := 0.1

@export_group("Daño recibido")
## Segundos sin poder recibir daño tras un golpe (el sprite parpadea).
@export var invulnerabilidad := 1.0
## Velocidad (px/s) del retroceso cuando el daño tiene un origen.
@export var fuerza_retroceso := 260.0
## Segundos que dura el retroceso, durante los cuales no se controla al personaje.
@export var duracion_retroceso := 0.15

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: CollisionShape2D = $HitboxPersonaje
@onready var _animacion_caida: AnimationPlayer = $AnimacionCaida

var vida: Vida
var attacking := false
var tiene_llave := false
var last_direction: String = "South"
## True durante la caída al vacío: no se mueve, no ataca y no recibe otro daño.
var cayendo := false

var _tiempo_invulnerable := 0.0
var _tiempo_retroceso := 0.0
var _velocidad_retroceso := Vector2.ZERO
var _tween_parpadeo: Tween

func _ready() -> void:
	add_to_group("jugador")
	vida = Vida.new()
	vida.vida_maxima = vida_maxima
	add_child(vida)
	vida.murio.connect(_on_vida_murio)
	
func _physics_process(delta: float) -> void:
	_tiempo_invulnerable = maxf(_tiempo_invulnerable - delta, 0.0)

	# Cayendo al vacío: sin control mientras dura la animación.
	if cayendo:
		velocity = Vector2.ZERO
		return

	# Retroceso tras un golpe: manda sobre el control y sobre el ataque.
	if _tiempo_retroceso > 0.0:
		_tiempo_retroceso -= delta
		velocity = _velocidad_retroceso
		move_and_slide()
		return

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
	_empujar_cajas(input_direction, delta)
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

## Si el jugador avanza contra una caja, la empuja (la caja decide si se mueve).
func _empujar_cajas(direccion: Vector2, delta: float) -> void:
	if direccion == Vector2.ZERO:
		return
	for i in get_slide_collision_count():
		var choque := get_slide_collision(i)
		var caja := choque.get_collider() as Caja
		# Solo cuenta si el jugador realmente avanza hacia la caja.
		if caja != null and direccion.dot(-choque.get_normal()) > 0.5:
			caja.empujar(choque.get_normal(), delta, self)

func _input(event: InputEvent) -> void:
	if cayendo:
		return
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


func esta_invulnerable() -> bool:
	return _tiempo_invulnerable > 0.0 or cayendo


## origen: punto global de donde viene el daño. Si se indica, el jugador retrocede alejándose de él.
func recibir_dano(cantidad: int, origen := Vector2.INF) -> void:
	if esta_invulnerable() or not vida.esta_viva():
		return
	vida.recibir_dano(cantidad)
	if not vida.esta_viva():
		return
	_tiempo_invulnerable = invulnerabilidad
	_parpadear()
	if origen != Vector2.INF:
		var direccion := (centro() - origen).normalized()
		if direccion == Vector2.ZERO:
			direccion = -_vector_de(last_direction)
		_velocidad_retroceso = direccion * fuerza_retroceso
		_tiempo_retroceso = duracion_retroceso


## Caída al vacío: el sprite se encoge con la animación "caer", el jugador recibe daño
## y reaparece en destino (coordenadas de la mazmorra) con invulnerabilidad.
## Es una corrutina: quien la llame puede esperar (await) a que termine.
func caer_al_vacio(dano: int, destino: Vector2) -> void:
	if cayendo or not vida.esta_viva():
		return
	cayendo = true
	_tiempo_retroceso = 0.0
	velocity = Vector2.ZERO
	_animacion_caida.play("caer")
	await _animacion_caida.animation_finished
	# El daño del vacío no lo frena la invulnerabilidad anterior.
	vida.recibir_dano(dano)
	if vida.esta_viva():
		sprite.scale = Vector2.ONE
		position = destino
		_tiempo_invulnerable = invulnerabilidad
		_parpadear()
	cayendo = false


func curar(cantidad: int) -> void:
	vida.curar(cantidad)

func recoger_llave() -> bool:
	if tiene_llave:
		return false
	tiene_llave = true
	llave_cambiada.emit(true)
	return true


func usar_llave() -> bool:
	if not tiene_llave:
		return false
	tiene_llave = false
	llave_cambiada.emit(false)
	return true


func perder_llave() -> void:
	if not tiene_llave:
		return
	tiene_llave = false
	llave_cambiada.emit(false)

## El sprite parpadea mientras dura la invulnerabilidad.
func _parpadear() -> void:
	if _tween_parpadeo != null:
		_tween_parpadeo.kill()
	var ciclos := maxi(int(invulnerabilidad / 0.2), 1) # 0 ciclos serían infinitos
	_tween_parpadeo = create_tween()
	_tween_parpadeo.set_loops(ciclos)
	_tween_parpadeo.tween_property(sprite, "modulate:a", 0.3, 0.1)
	_tween_parpadeo.tween_property(sprite, "modulate:a", 1.0, 0.1)
	_tween_parpadeo.finished.connect(func(): sprite.modulate.a = 1.0)


## Daña a todos los enemigos dentro de un círculo delante del jugador.
func _golpear() -> void:
	if not attacking:
		return
	var forma := CircleShape2D.new()
	forma.radius = radio_ataque

	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, centro() + _vector_de(last_direction) * alcance_ataque)
	consulta.collision_mask = Capas.ENEMIGOS | Capas.MUROS
	consulta.exclude = [get_rid()]

	for resultado in get_world_2d().direct_space_state.intersect_shape(consulta):
		var objetivo := resultado.collider as Node
		if objetivo is Enemigo:
			objetivo.recibir_dano(dano_ataque)
		elif objetivo.has_method("recibir_golpe"):
			objetivo.recibir_golpe()

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

## Cuánto hay desde el origen del personaje (los pies) hasta el centro de su cuerpo.
func desfase_centro() -> Vector2:
	return _hitbox.global_position - global_position

func _on_vida_murio() -> void:
	print("Jugador muerto")
	murio.emit()
