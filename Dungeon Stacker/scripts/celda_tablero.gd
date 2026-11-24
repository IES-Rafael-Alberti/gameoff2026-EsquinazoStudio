class_name CeldaTablero
extends RefCounted

var textura_fondo: Texture2D
var categoria: CategoriaSala
var bioma: int = Catalogo.Bioma.MEDIEVAL
## Si esta casilla es relleno sin habitación: ocupa el tablero y cuenta para las líneas, pero
## la mazmorra no la convierte en sala.
var sin_habitacion := false
## Si la pieza original era sin habitación. sin_habitacion puede ser true solo por estar sobre
## una barrera activa; al desactivarla vuelve a este valor.
var sin_habitacion_original := false
## Si esta sala solo tiene puertas Este y Oeste (nunca Norte ni Sur).
var solo_horizontal := false
## Casilla fija del nivel (ver CasillaFija): inmóvil, no se borra al hacer línea, y sí es sala.
var fija := false
## Casilla bloqueada del nivel: muro inmóvil que no se borra, cuenta para las líneas y no es sala.
var bloqueada := false
var resuelta := false
## Variante de sala elegida del pool la primera vez que se entra. Se mantiene mientras
## exista esta celda, para que al volver siempre sea la misma sala.
var escena_sala: PackedScene
## Número al azar fijo de esta celda, sorteado al crearla. Sirve para decisiones al azar de
## la sala que deben salir siempre igual al volver a ella (ver AparicionAleatoria).
var semilla := randi()
## Posiciones de las minas de esta sala que ya han explotado, para que no vuelvan a salir
## al recargar la sala. Desaparecen con la celda.
var minas_explotadas: Array[Vector2i] = []
var llaves_recogidas: Array[Vector2i] = []
var cerraduras_abiertas: Array[Vector2i] = []
var curaciones_recogidas: Array[Vector2i] = []
## Posiciones de los cofres de botín de esta sala que ya se han abierto: vuelven a aparecer
## abiertos y vacíos al recargar la sala.
var cofres_abiertos: Array[Vector2i] = []
## Rutas (desde la sala) de los CambiadorBaldosas de esta sala que están ahora mismo
## "alternados" (con sus baldosas intercambiadas). Al recargar la sala se vuelven a aplicar.
var cambiadores_alternados: Array[String] = []
## Solo se rellenan con la sala resuelta (los guarda al salir). Claves: ruta del nodo desde la sala.
## Si están encendidos los láseres de esta sala (ruta -> bool).
var lasers_encendidos: Dictionary = {}
## Dónde quedaron las cajas (ruta -> posición dentro de la sala). Las cajas que cayeron al vacío
## no se guardan: reaparecen en su sitio inicial.
var cajas_posicion: Dictionary = {}

func _init(p_textura: Texture2D = null, p_categoria: CategoriaSala = null, p_bioma: int = Catalogo.Bioma.MEDIEVAL) -> void:
	textura_fondo = p_textura
	categoria = p_categoria
	bioma = p_bioma

## Las casillas inmóviles no se borran al hacer línea ni caen cuando se borra la de abajo.
func es_inmovil() -> bool:
	return fija or bloqueada
