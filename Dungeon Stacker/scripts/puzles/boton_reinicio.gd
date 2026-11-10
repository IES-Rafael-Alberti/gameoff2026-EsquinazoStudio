class_name BotonReinicio
extends StaticBody2D
## Botón que se pulsa golpeándolo con el ataque. Devuelve los puzles de la sala
## (y sus cajas) a su estado inicial. No hace nada si la sala ya está resuelta.

## Lado de la celda en píxeles: el sprite se escala a este tamaño.
const TAM_CELDA := 64.0

@export_group("Sprites")
@export var sprite_levantada: Texture2D
@export var sprite_hundida: Texture2D
## Segundos que se queda hundido tras el golpe.
@export var duracion_pulsado := 0.3

var _pulsado := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_poner_sprite(false)


## Lo llama el ataque del jugador (ver player.gd).
func recibir_golpe() -> void:
	if _pulsado:
		return
	_pulsado = true
	_poner_sprite(true)
	var habitacion := _buscar_habitacion()
	if habitacion != null:
		habitacion.reiniciar_puzles()
	await get_tree().create_timer(duracion_pulsado).timeout
	if not is_inside_tree():
		return
	_pulsado = false
	_poner_sprite(false)


func _poner_sprite(hundido: bool) -> void:
	var textura := sprite_hundida if hundido else sprite_levantada
	if textura == null:
		textura = sprite_levantada
	_sprite.texture = textura
	if textura != null:
		_sprite.scale = Vector2.ONE * TAM_CELDA / textura.get_size()


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
