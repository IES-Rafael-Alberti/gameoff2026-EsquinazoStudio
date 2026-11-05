class_name CeldaTablero
extends RefCounted

var textura_fondo: Texture2D
var categoria: int = 0

func _init(p_textura: Texture2D = null, p_categoria: int = 0) -> void:
	textura_fondo = p_textura
	categoria = p_categoria
