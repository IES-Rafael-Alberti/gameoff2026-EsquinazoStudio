class_name Llave
extends Area2D

const TAM_CELDA := 64.0

var _recogida := false
var _habitacion: Habitacion

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_habitacion = _buscar_habitacion()
	if _habitacion != null and _habitacion.datos != null \
			and _habitacion.datos.llaves_recogidas.has(_clave()):
		queue_free()
		return
	if _sprite.texture != null:
		_sprite.scale = Vector2.ONE * TAM_CELDA / _sprite.texture.get_size()


func _physics_process(_delta: float) -> void:
	if _recogida:
		return
	for cuerpo in get_overlapping_bodies():
		if not cuerpo.is_in_group("jugador"):
			continue
		if not cuerpo.has_method("recoger_llave"):
			continue
		if cuerpo.recoger_llave():
			_recogida = true
			if _habitacion != null:
				_habitacion.registrar_llave_recogida(_clave())
			queue_free()
			return


func _clave() -> Vector2i:
	return Vector2i(global_position.round())


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
