class_name Caja
extends AnimatableBody2D
## Caja empujable por casillas. El jugador la empuja con su movimiento (ver player.gd):
## tras empujar un instante contra ella, avanza una casilla si la de delante está libre.
## Si no puede avanzar, intercambia el sitio con el jugador para que no se quede atascada.

const TAM_CELDA := 64.0

## Segundos que hay que empujar contra la caja antes de que se mueva.
@export var tiempo_empuje := 0.2
## Segundos que tarda en deslizarse a la casilla siguiente.
@export var duracion_movimiento := 0.15
## Si no puede avanzar (pared u obstáculo), intercambia su posición con el jugador.
@export var intercambiar_al_atascar := true

var _posicion_inicial := Vector2.ZERO
var _moviendo := false
var _direccion := Vector2.ZERO
var _acumulado := 0.0
var _empujada := false
var _tween: Tween

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("caja")
	_posicion_inicial = global_position
	if _sprite.texture != null:
		_sprite.scale = Vector2.ONE * TAM_CELDA / _sprite.texture.get_size()


func _physics_process(_delta: float) -> void:
	# Si este paso nadie la ha empujado, el contador de empuje se pone a cero.
	if not _empujada:
		_acumulado = 0.0
	_empujada = false


## Lo llama el jugador cada paso de física mientras empuja. normal: la normal del choque.
func empujar(normal: Vector2, delta: float, jugador: CharacterBody2D = null) -> void:
	if _moviendo:
		return
	var direccion := _a_eje(normal)
	if direccion != _direccion:
		_direccion = direccion
		_acumulado = 0.0
	_empujada = true
	_acumulado += delta
	if _acumulado >= tiempo_empuje:
		_acumulado = 0.0
		_intentar_mover(direccion, jugador)


## Vuelve a su casilla inicial (botón de reinicio de la sala).
func reiniciar() -> void:
	if _tween != null:
		_tween.kill()
	_moviendo = false
	global_position = _posicion_inicial


func _intentar_mover(direccion: Vector2, jugador: CharacterBody2D) -> void:
	var destino := global_position + direccion * TAM_CELDA
	if _casilla_libre(destino, jugador):
		_moviendo = true
		_tween = create_tween()
		_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		_tween.tween_property(self, "global_position", destino, duracion_movimiento)
		_tween.finished.connect(func(): _moviendo = false)
	elif intercambiar_al_atascar and jugador != null:
		_intercambiar(direccion, jugador)


## La caja no puede avanzar: el jugador pasa a su casilla y la caja a la casilla de detrás.
func _intercambiar(direccion: Vector2, jugador: CharacterBody2D) -> void:
	var detras := global_position - direccion * TAM_CELDA
	if not _casilla_libre(detras, jugador):
		return
	# El origen del jugador está en los pies: se coloca su centro en el centro de la caja.
	var centro_jugador := jugador.global_position
	if jugador.has_method("centro"):
		centro_jugador = jugador.centro()
	jugador.global_position += global_position - centro_jugador
	global_position = detras


## Comprueba que no hay muros, puertas, enemigos, sierras ni otras cajas en la casilla destino.
## ignorar: un cuerpo que no cuenta (el jugador que empuja).
func _casilla_libre(centro: Vector2, ignorar: CollisionObject2D = null) -> bool:
	var forma := RectangleShape2D.new()
	forma.size = Vector2.ONE * (TAM_CELDA - 8.0)

	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, centro)
	consulta.collision_mask = Capas.MUROS | Capas.CAJAS | Capas.ENEMIGOS | Capas.SIERRAS
	consulta.collide_with_areas = true # para ver también la zona de las sierras atravesables
	var excluidos: Array[RID] = [get_rid()]
	if ignorar != null:
		excluidos.append(ignorar.get_rid())
	consulta.exclude = excluidos
	return get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


## Convierte una normal cualquiera al eje cardinal dominante, en sentido contrario al choque.
func _a_eje(normal: Vector2) -> Vector2:
	var empuje := -normal
	if absf(empuje.x) > absf(empuje.y):
		return Vector2(signf(empuje.x), 0.0)
	return Vector2(0.0, signf(empuje.y))
