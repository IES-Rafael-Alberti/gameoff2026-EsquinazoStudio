class_name Configuracion_Tablero
extends Resource

# Dimensiones del tablero
@export var COLUMNAS: int
@export var FILAS: int
@export var TAM_CELDA: int
@export var CANTIDAD_PIEZAS: int

@export_group("Categorías")
@export_range(0.0, 100.0, 0.1) var PESO_CATEGORIA_A: float = 1.0
@export_range(0.0, 100.0, 0.1) var PESO_CATEGORIA_B: float = 1.0
@export_range(0.0, 100.0, 0.1) var PESO_CATEGORIA_C: float = 1.0
@export_range(0.0, 100.0, 0.1) var PESO_CATEGORIA_D: float = 1.0
@export_range(0.0, 100.0, 0.1) var PESO_CATEGORIA_E: float = 1.0
@export_range(0.0, 100.0, 0.1) var PESO_CATEGORIA_F: float = 1.0

@export_group("Biomas")
@export var BIOMAS_NIVEL: Array[int] = [1] # 1 = Medieval
# Dimensiones calculadas del tablero
var ANCHO_TABLERO: int:
	get:
		return COLUMNAS * TAM_CELDA

var ALTO_TABLERO: int:
	get:
		return FILAS * TAM_CELDA
