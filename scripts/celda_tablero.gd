class_name CeldaTablero
extends RefCounted

var textura_fondo: Texture2D
var categoria: CategoriaSala
var bioma: int = Catalogo.Bioma.MEDIEVAL
var resuelta := false
## Variante de sala elegida del pool la primera vez que se entra. Se mantiene mientras
## exista esta celda, para que al volver siempre sea la misma sala.
var escena_sala: PackedScene

func _init(p_textura: Texture2D = null, p_categoria: CategoriaSala = null, p_bioma: int = Catalogo.Bioma.MEDIEVAL) -> void:
	textura_fondo = p_textura
	categoria = p_categoria
	bioma = p_bioma
