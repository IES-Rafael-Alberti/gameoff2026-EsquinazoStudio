class_name CeldaTablero
extends RefCounted

var textura_fondo: Texture2D
var categoria: int = Catalogo.Categoria.A
var bioma: int = Catalogo.Bioma.MEDIEVAL

func _init(p_textura: Texture2D = null, p_categoria: int = Catalogo.Categoria.A, p_bioma: int = Catalogo.Bioma.MEDIEVAL) -> void:
	textura_fondo = p_textura
	categoria = p_categoria
	bioma = p_bioma
