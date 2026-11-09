class_name Puerta
extends StaticBody2D

## Se emite cuando el jugador entra en el hueco de la puerta y está abierta.
signal jugador_cruzo(puerta: Puerta)

enum Direccion { NORTE, ESTE, SUR, OESTE }

## Si el jugador está más lejos que esto (en píxeles), no cuenta como cruce.
const DISTANCIA_MAXIMA_CRUCE := 128.0
## Lado de la celda de la puerta en píxeles: los sprites se escalan a este tamaño.
const TAM_CELDA := 64.0

@export var direccion: Direccion = Direccion.NORTE

@export_group("Sprites")
## Puerta abierta: el hueco por el que se pasa.
@export var sprite_abierta: Texture2D
## Puerta cerrada: hay sala al otro lado pero un combate o puzle la bloquea.
@export var sprite_cerrada: Texture2D
## Sin sala al otro lado. Si no se asigna, se usa el sprite de cerrada.
@export var sprite_sellada: Texture2D

var _conectada := false # hay habitación al otro lado
var _bloqueada := false # un combate/puzzle la mantiene cerrada

@onready var _colision: CollisionShape2D = $Colision
@onready var _sprite: Sprite2D = $Sprite
@onready var _umbral: Area2D = $Umbral


func _ready() -> void:
	_umbral.body_entered.connect(_on_umbral_cuerpo_entro)
	# El sprite del atlas está dibujado para la puerta SUR; las demás son giros de 90°.
	_sprite.rotation_degrees = (int(direccion) - 2) * 90.0
	_aplicar_estado()


## Hacia dónde mira la puerta en el tablero del tetris (la y crece hacia abajo).
static func vector_de(dir: Direccion) -> Vector2i:
	match dir:
		Direccion.NORTE:
			return Vector2i(0, -1)
		Direccion.ESTE:
			return Vector2i(1, 0)
		Direccion.SUR:
			return Vector2i(0, 1)
		_:
			return Vector2i(-1, 0)


## La puerta de la habitación vecina que conecta con esta.
static func opuesta(dir: Direccion) -> Direccion:
	return ((dir + 2) % 4) as Direccion


func esta_abierta() -> bool:
	return _conectada and not _bloqueada


func establecer_conectada(valor: bool) -> void:
	_conectada = valor
	_aplicar_estado()


func cerrar() -> void:
	_bloqueada = true
	_aplicar_estado()


func abrir() -> void:
	_bloqueada = false
	_aplicar_estado()


func _on_umbral_cuerpo_entro(cuerpo: Node2D) -> void:
	if not esta_abierta() or not cuerpo.is_in_group("jugador"):
		return
	# Al cargar una sala nueva, la física puede avisar con la posición antigua del
	# jugador (que ya se ha movido). Solo cuenta si de verdad está junto a la puerta.
	if cuerpo.global_position.distance_to(global_position) > DISTANCIA_MAXIMA_CRUCE:
		return
	jugador_cruzo.emit(self)


func _aplicar_estado() -> void:
	if not is_node_ready():
		return
	var abierta := esta_abierta()
	_colision.set_deferred("disabled", abierta)
	_mostrar(_textura_para(abierta))


## Qué sprite toca según el estado de la puerta.
func _textura_para(abierta: bool) -> Texture2D:
	if abierta:
		return sprite_abierta
	if _conectada:
		return sprite_cerrada
	return sprite_sellada if sprite_sellada != null else sprite_cerrada


func _mostrar(textura: Texture2D) -> void:
	_sprite.texture = textura
	_sprite.visible = textura != null
	if textura != null:
		var medida := textura.get_size()
		_sprite.scale = Vector2(TAM_CELDA / medida.x, TAM_CELDA / medida.y)
