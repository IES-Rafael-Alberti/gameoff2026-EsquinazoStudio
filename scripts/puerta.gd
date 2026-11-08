class_name Puerta
extends StaticBody2D

## Se emite cuando el jugador entra en el hueco de la puerta y está abierta.
signal jugador_cruzo(puerta: Puerta)

enum Direccion { NORTE, ESTE, SUR, OESTE }

@export var direccion: Direccion = Direccion.NORTE
@export var color_cerrada := Color(0.45, 0.28, 0.12)
@export var color_sellada := Color(0.16, 0.14, 0.18)

var _conectada := false # hay habitación al otro lado
var _bloqueada := false # un combate/puzzle la mantiene cerrada

@onready var _colision: CollisionShape2D = $Colision
@onready var _visual: ColorRect = $Visual
@onready var _umbral: Area2D = $Umbral


func _ready() -> void:
	_umbral.body_entered.connect(_on_umbral_cuerpo_entro)
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
	if esta_abierta() and cuerpo.is_in_group("jugador"):
		jugador_cruzo.emit(self)


func _aplicar_estado() -> void:
	if not is_node_ready():
		return
	var abierta := esta_abierta()
	_colision.set_deferred("disabled", abierta)
	_visual.visible = not abierta
	_visual.color = color_cerrada if _conectada else color_sellada
