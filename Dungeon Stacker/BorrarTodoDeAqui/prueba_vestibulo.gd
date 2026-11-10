extends Node2D
## SOLO PARA PRUEBAS: borra esta escena y este script al terminar V2.

const COLUMNAS := 10

@onready var _inferior: Vestibulo = $Inferior
@onready var _superior: Vestibulo = $Superior


func _ready() -> void:
	_inferior.construir(COLUMNAS)
	_superior.construir(COLUMNAS)
	_inferior.puerta_cruzada.connect(func(c): print("Inferior: cruzó la columna ", c))
	_superior.puerta_cruzada.connect(func(c): print("Superior: cruzó la columna ", c))

	# Solo se abren las columnas pares.
	for columna in COLUMNAS:
		_inferior.establecer_puerta(columna, columna % 2 == 0)
		_superior.establecer_puerta(columna, columna % 2 == 0)

	$Jugador.position = _inferior.posicion_entrada(0)
