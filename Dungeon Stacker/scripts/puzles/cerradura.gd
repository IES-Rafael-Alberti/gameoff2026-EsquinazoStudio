
class_name Cerradura
extends StaticBody2D

signal abierta_senal

const TAM_CELDA := 64.0

@export var margen_contacto := 4.0

@export_group("Puzle")
@export var cuenta_como_requisito := false

var abierta := false

var _habitacion: Habitacion
var _zona_contacto: Area2D

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_habitacion = _buscar_habitacion()
	if _habitacion != null and _habitacion.datos != null \
			and _habitacion.datos.cerraduras_abiertas.has(_clave()):
		abierta = true
		queue_free()
		return

	if _sprite.texture != null:
		_sprite.scale = Vector2.ONE * TAM_CELDA / _sprite.texture.get_size()

	_crear_zona_contacto()


func _crear_zona_contacto() -> void:
	for hijo in get_children():
		if not hijo is CollisionShape2D:
			continue
		var forma := hijo.shape as RectangleShape2D
		if forma == null:
			push_warning("La cerradura %s necesita un CollisionShape2D rectangular." % name)
			return

		var zona_forma := RectangleShape2D.new()
		zona_forma.size = forma.size + Vector2.ONE * margen_contacto * 2.0

		var colision := CollisionShape2D.new()
		colision.shape = zona_forma
		colision.position = hijo.position

		_zona_contacto = Area2D.new()
		_zona_contacto.collision_layer = 0
		_zona_contacto.collision_mask = Capas.JUGADOR
		_zona_contacto.add_child(colision)

		add_child(_zona_contacto)
		_zona_contacto.body_entered.connect(_on_cuerpo_entro)
		return

	push_warning("La cerradura %s no tiene CollisionShape2D." % name)


func _on_cuerpo_entro(cuerpo: Node2D) -> void:
	if abierta or not cuerpo.is_in_group("jugador"):
		return
	if not cuerpo.has_method("usar_llave"):
		return
	if not cuerpo.usar_llave():
		return
	_abrir()


func _abrir() -> void:
	abierta = true

	if _zona_contacto != null:
		_zona_contacto.set_deferred("monitoring", false)

	for hijo in get_children():
		if hijo is CollisionShape2D:
			hijo.set_deferred("disabled", true)

	if _habitacion != null:
		_habitacion.registrar_cerradura_abierta(_clave())

	abierta_senal.emit()
	queue_free()


func _clave() -> Vector2i:
	return Vector2i(global_position.round())


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
