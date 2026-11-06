class_name Configuracion_Tablero
extends Resource

# Dimensiones del tablero
@export var COLUMNAS: int
@export var FILAS: int
@export var TAM_CELDA: int

# Dimensiones calculadas del tablero
var ANCHO_TABLERO: int:
	get:
		return COLUMNAS * TAM_CELDA

var ALTO_TABLERO: int:
	get:
		return FILAS * TAM_CELDA
