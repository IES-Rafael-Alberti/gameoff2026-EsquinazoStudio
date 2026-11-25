class_name ObjetivoElectrico
extends Desafio
## Objetivo de un puzle eléctrico: cuando la corriente le llega, se enciende y el desafío queda
## resuelto para siempre (aunque la corriente se corte después, su luz se apaga pero el desafío
## sigue resuelto). Se coloca sobre una casilla de cable y se arrastra a la lista "receptores" de
## la CapaElectrica.
##
## Estructura: un Node2D con este script y, opcionalmente, un hijo Sprite2D llamado "Sprite".

@export_group("Sprites")
## Sin corriente.
@export var sprite_apagado: Texture2D
## Con corriente.
@export var sprite_encendido: Texture2D

@onready var _sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D


func _ready() -> void:
	super._ready()
	if not esta_resuelto:
		_poner_sprite(false)


## Lo llama la CapaElectrica.
func recibir_corriente(hay_corriente: bool) -> void:
	_poner_sprite(hay_corriente)
	if hay_corriente:
		resolver()


## Lo llama la CapaElectrica al cargar la sala, si el objetivo ya está conectado a una fuente.
func corriente_inicial(hay_corriente: bool) -> void:
	if hay_corriente:
		recibir_corriente(true)


func _al_cargar_resuelto() -> void:
	_poner_sprite(true)


func _poner_sprite(encendido: bool) -> void:
	if _sprite == null:
		return
	var textura := sprite_encendido if encendido else sprite_apagado
	if textura != null:
		_sprite.texture = textura
