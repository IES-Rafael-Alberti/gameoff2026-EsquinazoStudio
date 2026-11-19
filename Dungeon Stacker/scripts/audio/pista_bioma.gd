class_name PistasBioma
extends Resource
## Las dos canciones de un bioma: la versión del modo Tetris y la de la Mazmorra. Deben durar lo
## mismo y ser la misma pieza musical, porque suenan sincronizadas.

@export var bioma: Catalogo.Bioma = Catalogo.Bioma.MEDIEVAL
@export var tetris: AudioStream
@export var mazmorra: AudioStream
