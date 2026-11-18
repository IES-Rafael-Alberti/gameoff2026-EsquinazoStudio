@tool
class_name PiezaEscogida
extends Resource
## Una pieza de Tetris diseñada a mano: forma, categoría de cada cuadrado y bioma.
## Se usa en Configuracion_Tablero (secuencia inicial, turnos concretos y pool con peso).

## Forma de la pieza. Debe ser uno de los nombres de Configuracion_Tablero.NOMBRES_PIEZAS.
@export_enum("I", "O", "T", "S", "Z", "J", "L", "TT", "H", "X", "P", "+", "-", "C") var forma: String = "I":
	set(valor):
		forma = valor
		_ajustar_escenas()

## Bioma de la pieza (define el marco y de qué pool salen sus salas).
@export var bioma: Catalogo.Bioma = Catalogo.Bioma.MEDIEVAL

## Categoría de cada cuadrado, en el orden de los cuadrados de la forma (Piezas.FORMAS).
## Un hueco vacío (o un array más corto que la forma) = esa casilla sale al azar según los
## pesos de categoría del nivel, salvo si ese cuadrado tiene escena (ver `escenas`): entonces
## se queda sin categoría. Las que sobren se ignoran.
@export var categorias: Array[CategoriaSala] = []

## Escena de sala de cada cuadrado, en el mismo orden que las categorías. El array tiene siempre
## tantos huecos como cuadrados tiene la forma (se ajusta solo). Un hueco con escena carga esa
## sala exacta; un hueco vacío saca la sala del pool según su categoría, como siempre. Puedes
## poner además la categoría de ese cuadrado si quieres que muestre su icono; si la dejas vacía
## no tendrá icono.
@export var escenas: Array[PackedScene] = []:
	set(valor):
		escenas = valor
		_ajustar_escenas()

## Pieza sin habitación (solo relleno del tablero). Si está marcada, ignora las categorías.
@export var sin_habitacion := false

## Salas solo con puertas Este y Oeste.
@export var solo_horizontal := false


func _init() -> void:
	_ajustar_escenas()


## Deja el array de escenas con tantos huecos como cuadrados tiene la forma.
func _ajustar_escenas() -> void:
	var formas: Dictionary = load("res://scripts/piezas.gd").FORMAS
	if not formas.has(forma):
		return
	var cantidad: int = formas[forma].size()
	if escenas.size() != cantidad:
		escenas.resize(cantidad)
		notify_property_list_changed()
