class_name Caja
extends AnimatableBody2D
## Caja empujable por casillas. El jugador la empuja con su movimiento (ver player.gd):
## tras empujar un instante contra ella, avanza una casilla si la de delante está libre.

const TAM_CELDA := 64.0

## Segundos que hay que empujar contra la caja antes de que se mueva.
@export var tiempo_empuje := 0.2
## Segundos que tarda en deslizarse a la casilla siguiente.
@export var duracion_movimiento := 0.15

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
func empujar(normal: Vector2, delta: float) -> void:
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
		_intentar_mover(direccion)


## Vuelve a su casilla inicial (botón de reinicio de la sala).
func reiniciar() -> void:
	if _tween != null:
		_tween.kill()
	_moviendo = false
	global_position = _posicion_inicial


func _intentar_mover(direccion: Vector2) -> void:
	var destino := global_position + direccion * TAM_CELDA
	if not _casilla_libre(destino):
		return
	_moviendo = true
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, "global_position", destino, duracion_movimiento)
	_tween.finished.connect(func(): _moviendo = false)


## Comprueba que no hay muros, puertas, enemigos ni otras cajas en la casilla destino.
func _casilla_libre(centro: Vector2) -> bool:
	var forma := RectangleShape2D.new()
	forma.size = Vector2.ONE * (TAM_CELDA - 8.0)

	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, centro)
	consulta.collision_mask = 1
	consulta.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


## Convierte una normal cualquiera al eje cardinal dominante, en sentido contrario al choque.
func _a_eje(normal: Vector2) -> Vector2:
	var empuje := -normal
	if absf(empuje.x) > absf(empuje.y):
		return Vector2(signf(empuje.x), 0.0)
	return Vector2(0.0, signf(empuje.y))
