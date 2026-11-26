class_name BolaNieve
extends Peligro
## Bola de nieve de la trampa TrampaBolaNieve. Cae del techo (el sprite baja de arriba abajo,
## sin hacer daño), aterriza y rueda en línea recta girando sobre sí misma, dañando (y haciendo
## retroceder) al jugador y a los enemigos que andan, como cualquier Peligro. Al pasar sobre un
## vacío se encoge y desaparece. Si choca con una pared desaparece: es solo un respaldo por si
## el diseñador no ha puesto un vacío al final del camino.
##
## Escena: un Area2D raíz con este script (capa Trampas, máscara Jugador + Enemigos; la máscara
## de Muros la añade el código), un CollisionShape2D circular y un Sprite2D hijo asignado en
## "sprite". Normalmente la crea la trampa, no se coloca a mano.

## Píxeles por segundo al rodar.
@export var velocidad := 120.0
## Vueltas por segundo sobre sí misma.
@export var vueltas_por_segundo := 1.0
@export_group("Caída")
## Altura (píxeles) desde la que cae.
@export var altura_caida := 160.0
@export_range(0.05, 3.0, 0.05, "suffix:s") var duracion_caida := 0.4
@export_group("Vacío")
## Segundos que tarda en encogerse al caer por el vacío.
@export_range(0.05, 3.0, 0.05, "suffix:s") var duracion_encogido := 0.4
## El sprite de la bola: baja al caer, gira y se encoge. Debe ser hijo de esta escena.
@onready var sprite: Node2D = $Sprite

## Hacia dónde rueda. La pone la trampa antes de añadirla a la sala.
var direccion := Vector2.RIGHT

enum Fase { CAYENDO, RODANDO, ENCOGIENDO }

var _fase := Fase.CAYENDO
var _sala: Habitacion
var _tween: Tween


func _ready() -> void:
	super._ready()
	# Para el respaldo: detectar paredes además del jugador y los enemigos.
	collision_mask |= Capas.MUROS
	activo = false # mientras cae no hace daño
	_sala = get_tree().get_first_node_in_group("habitacion") as Habitacion
	if sprite == null:
		push_warning("%s no tiene asignado el sprite." % name)
		_aterrizar()
		return
	sprite.position = Vector2(0.0, -altura_caida)
	_tween = create_tween()
	_tween.tween_property(sprite, "position", Vector2.ZERO, duracion_caida) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_aterrizar)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if sprite != null:
		var giro := 1.0 if direccion.x >= 0.0 else -1.0
		sprite.rotation += TAU * vueltas_por_segundo * giro * delta
	if _fase != Fase.RODANDO:
		return
	global_position += direccion * velocidad * delta
	if _sala != null and _sala.es_vacio(global_position):
		_encoger()
	elif _toca_pared():
		queue_free()


func _aterrizar() -> void:
	_fase = Fase.RODANDO
	activo = true


## Cae por un vacío: deja de hacer daño, se para y se encoge hasta desaparecer.
func _encoger() -> void:
	_fase = Fase.ENCOGIENDO
	activo = false
	if sprite == null:
		queue_free()
		return
	_tween = create_tween()
	_tween.tween_property(sprite, "scale", Vector2.ZERO, duracion_encogido)
	_tween.tween_callback(queue_free)


## Pared (la capa Muros: tiles, puertas...). Los tiles llegan como TileMapLayer.
func _toca_pared() -> bool:
	for cuerpo in get_overlapping_bodies():
		if cuerpo is TileMapLayer or Capas.esta_en(cuerpo, Capas.MUROS):
			return true
	return false
