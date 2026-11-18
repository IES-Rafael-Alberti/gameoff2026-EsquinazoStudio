class_name PiezaEscogida
extends Resource
## Una pieza de Tetris diseñada a mano: forma, categoría de cada cuadrado y bioma.
## Se usa en Configuracion_Tablero (secuencia inicial, turnos concretos y pool con peso).

## Forma de la pieza. Debe ser uno de los nombres de Configuracion_Tablero.NOMBRES_PIEZAS.
@export_enum("I", "O", "T", "S", "Z", "J", "L", "TT", "H", "X", "P", "+", "-", "C") var forma: String = "I"

## Bioma de la pieza (define el marco y de qué pool salen sus salas).
@export var bioma: Catalogo.Bioma = Catalogo.Bioma.MEDIEVAL

## Categoría de cada cuadrado, en el orden de los cuadrados de la forma (Piezas.FORMAS).
## Un hueco vacío (o un array más corto que la forma) = esa casilla sale al azar según los
## pesos de categoría del nivel. Las que sobren se ignoran.
@export var categorias: Array[CategoriaSala] = []

## Pieza sin habitación (solo relleno del tablero). Si está marcada, ignora las categorías.
@export var sin_habitacion := false

## Salas solo con puertas Este y Oeste.
@export var solo_horizontal := false
