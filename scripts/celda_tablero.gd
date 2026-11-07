class_name CeldaTablero
extends RefCounted

var textura_fondo: Texture2D
var categoria: Catalogo.Categoria = Catalogo.Categoria.A

func _init(p_textura: Texture2D = null, p_categoria: Catalogo.Categoria = Catalogo.Categoria.A) -> void:
	textura_fondo = p_textura
	categoria = p_categoria
