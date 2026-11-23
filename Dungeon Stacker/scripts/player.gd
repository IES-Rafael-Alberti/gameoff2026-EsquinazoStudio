class_name Jugador
extends CharacterBody2D
## Jugador. Lo que hace en cada momento lo decide su máquina de estados (hijo MaquinaEstados
## con los estados Inactivo, Caminar, Atacar, Herido, Caer y Muerte); aquí está lo que comparten:
## vida, daño, invulnerabilidad, llaves y los ayudantes que usan los estados.

signal murio
signal llave_cambiada(tiene: bool)
## Terminó la caída al vacío (con el daño ya aplicado y el jugador reaparecido).
signal caida_terminada

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
@onready var animacion_caida: AnimationPlayer = $Animacion/AnimacionCaida
@onready var maquina: JugadorMaquina = $MaquinaEstados

var vida: Vida
var tiene_llave := false
var last_direction: String = "South"

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
	maquina.iniciar(self)
	
func _physics_process(delta: float) -> void:
	_tiempo_invulnerable = maxf(_tiempo_invulnerable - delta, 0.0)
	maquina.fisica(delta)


func _input(event: InputEvent) -> void:
	maquina.entrada(event)


## Dirección que marca el input de movimiento (vector de longitud 0 a 1).
func direccion_input() -> Vector2:
	return Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")


## Guarda hacia dónde mira según un vector de movimiento.
func actualizar_direccion(direccion: Vector2) -> void:
	if direccion == Vector2.ZERO:
		return
	if abs(direccion.x) > abs(direccion.y):
		last_direction = "East" if direccion.x > 0 else "West"
	else:
		last_direction = "South" if direccion.y > 0 else "North"


## Reproduce "<prefijo>_<dirección>" (por ejemplo Walk_North). Si esa animación no existe, se
## queda con la que estaba.
func animar(prefijo: String) -> void:
	var nombre := prefijo + "_" + last_direction
	if sprite.sprite_frames.has_animation(nombre):
		sprite.play(nombre)


## Parado: el primer fotograma de la caminata de la dirección actual, congelado.
func mostrar_pose_quieto() -> void:
	var nombre := "Walk_" + last_direction
	if sprite.sprite_frames.has_animation(nombre):
		sprite.play(nombre)
		sprite.set_frame_and_progress(0, 0.0)
		sprite.pause()


## Si el jugador avanza contra una caja, la empuja (la caja decide si se mueve).
func empujar_cajas(direccion: Vector2, delta: float) -> void:
	if direccion == Vector2.ZERO:
		return
	for i in get_slide_collision_count():
		var choque := get_slide_collision(i)
		var caja := choque.get_collider() as Caja
		# Solo cuenta si el jugador realmente avanza hacia la caja.
		if caja != null and direccion.dot(-choque.get_normal()) > 0.5:
			caja.empujar(choque.get_normal(), delta, self)


## Si queda retroceso por aplicar, mueve al jugador con él y devuelve true.
func avanzar_retroceso(delta: float) -> bool:
	if _tiempo_retroceso <= 0.0:
		return false
	_tiempo_retroceso -= delta
	velocity = _velocidad_retroceso
	move_and_slide()
	return true


func cancelar_retroceso() -> void:
	_tiempo_retroceso = 0.0


## Centro del cuerpo (el origen del personaje está en los pies).
func centro() -> Vector2:
	return _hitbox.global_position


func esta_invulnerable() -> bool:
	return _tiempo_invulnerable > 0.0 or (maquina.actual != null and maquina.actual.es_invulnerable())


## Empieza el periodo sin poder recibir daño, con el parpadeo.
func iniciar_invulnerabilidad() -> void:
	_tiempo_invulnerable = invulnerabilidad
	_parpadear()


## Para el parpadeo y deja el sprite opaco.
func detener_parpadeo() -> void:
	if _tween_parpadeo != null:
		_tween_parpadeo.kill()
	sprite.modulate.a = 1.0


## origen: punto global de donde viene el daño. Si se indica, el jugador retrocede alejándose de él.
func recibir_dano(cantidad: int, origen := Vector2.INF) -> void:
	if esta_invulnerable() or not vida.esta_viva():
		return
	vida.recibir_dano(cantidad)
	if not vida.esta_viva():
		return
	iniciar_invulnerabilidad()
	if origen != Vector2.INF:
		var direccion := (centro() - origen).normalized()
		if direccion == Vector2.ZERO:
			direccion = -_vector_de(last_direction)
		_velocidad_retroceso = direccion * fuerza_retroceso
		_tiempo_retroceso = duracion_retroceso
		# Atacando, el ataque sigue: el retroceso lo aplica el propio estado Atacar.
		if not maquina.esta_en(JugadorEstado.ATACAR):
			maquina.cambiar_a(JugadorEstado.HERIDO)


## Caída al vacío: el jugador recibe daño y reaparece en destino (coordenadas de la mazmorra) con
## invulnerabilidad. Es una corrutina: quien la llame puede esperar (await) a que termine.
func caer_al_vacio(dano: int, destino: Vector2) -> void:
	if maquina.esta_en(JugadorEstado.CAER) or not vida.esta_viva():
		return
	maquina.cambiar_a(JugadorEstado.CAER, {"dano": dano, "destino": destino})
	await caida_terminada


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


## Daña a todos los enemigos dentro de un círculo delante del jugador (lo llama el estado Atacar).
func golpear() -> void:
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

## La vida llegó a 0: pasa a Muerte, que emite murio cuando acaba el fundido.
func _on_vida_murio() -> void:
	maquina.cambiar_a(JugadorEstado.MUERTE)
