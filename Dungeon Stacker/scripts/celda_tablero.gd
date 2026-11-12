class_name CeldaTablero
extends RefCounted

var textura_fondo: Texture2D
var categoria: CategoriaSala
var bioma: int = Catalogo.Bioma.MEDIEVAL
var resuelta := false
## Variante de sala elegida del pool la primera vez que se entra. Se mantiene mientras
## exista esta celda, para que al volver siempre sea la misma sala.
var escena_sala: PackedScene
## Posiciones de las minas de esta sala que ya han explotado, para que no vuelvan a salir
## al recargar la sala. Desaparecen con la celda.
var minas_explotadas: Array[Vector2i] = []
var llaves_recogidas: Array[Vector2i] = []
var cerraduras_abiertas: Array[Vector2i] = []
var curaciones_recogidas: Array[Vector2i] = []

func _init(p_textura: Texture2D = null, p_categoria: CategoriaSala = null, p_bioma: int = Catalogo.Bioma.MEDIEVAL) -> void:
	textura_fondo = p_textura
	categoria = p_categoria
	bioma = p_bioma
