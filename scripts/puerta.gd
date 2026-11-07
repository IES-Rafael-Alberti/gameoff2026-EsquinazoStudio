class_name Puerta
extends StaticBody2D

enum Direccion { NORTE, ESTE, SUR, OESTE }

@export var direccion: Direccion = Direccion.NORTE
@export var color_cerrada := Color(0.45, 0.28, 0.12)
@export var color_sellada := Color(0.16, 0.14, 0.18)

var _conectada := false # hay habitación al otro lado
var _bloqueada := false # un combate/puzzle la mantiene cerrada

@onready var _colision: CollisionShape2D = $Colision
@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	_aplicar_estado()


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


func _aplicar_estado() -> void:
	if not is_node_ready():
		return
	var abierta := esta_abierta()
	_colision.set_deferred("disabled", abierta)
	_visual.visible = not abierta
	_visual.color = color_cerrada if _conectada else color_sellada
