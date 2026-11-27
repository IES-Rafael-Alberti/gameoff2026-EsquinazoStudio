class_name Caja
extends AnimatableBody2D
## Caja empujable por casillas. El jugador la empuja con su movimiento:
## tras empujar un instante contra ella, avanza una casilla si la de delante está libre.
## Si no puede avanzar, intercambia el sitio con el jugador para que no se quede atascada.
## Sobre hielo resbala como el jugador: al terminar una casilla de hielo sigue avanzando en la
## misma dirección, casilla a casilla (con la misma duración que al empujarla), hasta que la
## siguiente está bloqueada o la casilla en la que termina ya no es hielo.

const TAM_CELDA := 64.0

@export var tiempo_empuje := 0.2
@export var intercambiar_al_atascar := true
## Lo que tarda la caja en avanzar una casilla. Cuanto más cerca de lo que tarda el jugador en
## recorrerla (64 / velocidad del jugador), más pegada a él se siente.
@export var duracion_movimiento := 0.3
## Tras mover la caja, tiempo durante el que seguir empujando en la misma dirección la mueve
## otra casilla sin esperar de nuevo "tiempo_empuje". 0 = siempre hay que esperar.
@export var ventana_encadenado := 0.4
## Si esta caja conduce la electricidad: solo las cajas conductoras activan los puentes
## eléctricos que lo exigen.
@export var conduce_electricidad := false

var _posicion_inicial := Vector2.ZERO
var _moviendo := false
var _direccion := Vector2.ZERO
var _acumulado := 0.0
var _empujada := false
var _intercambiando := false
var _tween: Tween
var _fin_movimiento_ms := -100000
var _visibilidad_inicial := true
var _escala_inicial := Vector2.ONE
var _id_caida := 0

## True mientras la caja cae al vacío o se está reiniciando.
var cayendo := false
var reiniciando := false

@onready var _sprite: Sprite2D = $Sprite
@onready var _colision: CollisionShape2D = $CollisionShape2D
@onready var _animacion: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group("caja")
	_posicion_inicial = global_position
	_visibilidad_inicial = visible
	if _sprite.texture != null:
		_sprite.scale = Vector2.ONE * TAM_CELDA / _sprite.texture.get_size()
	_escala_inicial = _sprite.scale
	# La sala aún no está lista aquí (los hijos se preparan antes que ella): se hace al terminar el frame.
	_ajustar_a_cuadricula.call_deferred()


func _physics_process(_delta: float) -> void:
	if not _empujada:
		_acumulado = 0.0
	_empujada = false


## Lo llama el jugador cada paso de física mientras empuja.
func empujar(normal: Vector2, delta: float, jugador: CharacterBody2D = null) -> void:
	if _moviendo or _intercambiando or cayendo or reiniciando:
		return
	var direccion := _a_eje(normal)
	var encadenado := direccion == _direccion \
			and (Time.get_ticks_msec() - _fin_movimiento_ms) / 1000.0 <= ventana_encadenado
	if direccion != _direccion:
		_direccion = direccion
		_acumulado = 0.0
	_empujada = true
	_acumulado += delta
	if encadenado:
		_acumulado = tiempo_empuje
	if _acumulado >= tiempo_empuje:
		_acumulado = 0.0
		_intentar_mover(direccion, jugador, encadenado)

## Caída al vacío mediante AnimationPlayer.
func caer_al_vacio() -> void:
	if cayendo or reiniciando:
		return
	cayendo = true
	_id_caida += 1
	var id_actual := _id_caida
	if _tween != null:
		_tween.kill()
		_tween = null
	_moviendo = false
	_intercambiando = false
	_empujada = false
	_acumulado = 0.0
	_colision.set_deferred("disabled", true)
	_animacion.play("caida")
	await _animacion.animation_finished
	if id_actual != _id_caida:
		return
	visible = false

## Devuelve la caja a su posición inicial.
func reiniciar() -> void:
	if not cayendo and not _moviendo and global_position.is_equal_approx(_posicion_inicial):
		return
	reiniciando = true
	_id_caida += 1
	visible = false
	if _tween != null:
		_tween.kill()
		_tween = null
	_animacion.stop()
	_moviendo = false
	_intercambiando = false
	cayendo = false
	_empujada = false
	_acumulado = 0.0
	global_position = _posicion_inicial
	_sprite.scale = _escala_inicial
	_colision.set_deferred("disabled", false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	visible = _visibilidad_inicial
	reiniciando = false

func _intentar_mover(direccion: Vector2, jugador: CharacterBody2D, encadenado := false) -> void:
	var destino := _centro_de_su_celda() + direccion * TAM_CELDA
	if _casilla_libre(destino, jugador):
		_mover_a(destino)
	elif encadenado:
		# Al topar con algo tras un empuje seguido, el intercambio espera su tiempo normal.
		_fin_movimiento_ms = -100000
	elif intercambiar_al_atascar and jugador != null:
		_intercambiar(direccion, jugador)

## Mueve la caja a la casilla de destino (la que ya se ha comprobado que está libre).
func _mover_a(destino: Vector2) -> void:
	_moviendo = true
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, "global_position", destino, duracion_movimiento)
	_tween.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
	_moviendo = false
	_fin_movimiento_ms = Time.get_ticks_msec()
	_tween = null
	_seguir_resbalando()

## Si la caja ha acabado sobre hielo y la casilla siguiente está libre, avanza otra casilla.
## En una casilla que no es hielo (o con algo delante) se queda ahí.
func _seguir_resbalando() -> void:
	if cayendo or reiniciando or _direccion == Vector2.ZERO:
		return
	var sala := get_tree().get_first_node_in_group("habitacion") as Habitacion
	if sala == null or not sala.es_hielo(global_position):
		return
	var destino := _centro_de_su_celda() + _direccion * TAM_CELDA
	if _casilla_libre(destino):
		_mover_a(destino)

## La caja no puede avanzar: el jugador pasa a su casilla y la caja a la casilla de detrás.
func _intercambiar(direccion: Vector2, jugador: CharacterBody2D) -> void:
	if _intercambiando:
		return
	_intercambiando = true
	var detras := _centro_de_su_celda() - direccion * TAM_CELDA
	if not _casilla_libre(detras, jugador):
		_intercambiando = false
		return
	var centro_jugador := jugador.global_position
	if jugador.has_method("centro"):
		centro_jugador = jugador.centro()
	var destino_jugador := jugador.global_position + global_position - centro_jugador
	_sincronizar_body(jugador, destino_jugador)
	_sincronizar_body(self, detras)
	_intercambiando = false

func _sincronizar_body(cuerpo: CollisionObject2D, destino: Vector2) -> void:
	var transform := cuerpo.global_transform
	transform.origin = destino
	cuerpo.global_transform = transform
	PhysicsServer2D.body_set_state(cuerpo.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, transform)

## Comprueba que no hay muros, puertas, enemigos, sierras ni otras cajas en la casilla destino.
func _casilla_libre(centro: Vector2, ignorar: CollisionObject2D = null) -> bool:
	for cuerpo in get_tree().get_nodes_in_group(&"caja"):
		if cuerpo is CollisionObject2D:
			_sincronizar_body(cuerpo, cuerpo.global_position)
	var forma := RectangleShape2D.new()
	forma.size = Vector2.ONE * (TAM_CELDA - 8.0)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, centro)
	consulta.collision_mask = Capas.MUROS | Capas.CAJAS | Capas.ENEMIGOS | Capas.SIERRAS
	consulta.collide_with_areas = true
	var excluidos: Array[RID] = [get_rid()]
	if ignorar != null:
		excluidos.append(ignorar.get_rid())
	# El haz de los láseres no la detiene: puede entrar en él y cortarlo.
	for haz in get_tree().get_nodes_in_group(&"haz_laser"):
		if haz is CollisionObject2D:
			excluidos.append(haz.get_rid())
	consulta.exclude = excluidos
	return get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()

## Centro de la casilla de la sala en la que está la caja. Todos los destinos se calculan desde
## aquí y no desde la posición actual, para que la caja nunca se desvíe de la cuadrícula.
func _centro_de_su_celda() -> Vector2:
	return _centro_de_celda_de(global_position)

func _centro_de_celda_de(posicion: Vector2) -> Vector2:
	var sala := get_tree().get_first_node_in_group("habitacion") as Habitacion
	if sala == null:
		return posicion # escena suelta (pruebas): sin sala no hay cuadrícula
	return sala.centro_de_celda(sala.celda_de(posicion))

## Recoloca la caja (y su posición de reinicio) en el centro de su casilla. Corrige cajas puestas
## a ojo en el editor o restauradas a medio movimiento.
func _ajustar_a_cuadricula() -> void:
	_posicion_inicial = _centro_de_celda_de(_posicion_inicial)
	if _moviendo or cayendo or reiniciando:
		return
	var centro := _centro_de_su_celda()
	if not global_position.is_equal_approx(centro):
		_sincronizar_body(self, centro)

## Convierte una normal cualquiera al eje cardinal dominante.
func _a_eje(normal: Vector2) -> Vector2:
	var empuje := -normal
	if absf(empuje.x) > absf(empuje.y):
		return Vector2(signf(empuje.x), 0.0)
	return Vector2(0.0, signf(empuje.y))
