class_name Configuracion_Tablero
extends Resource

## Nombres de las piezas, en el MISMO orden que Piezas.FORMAS y que las casillas de PIEZAS_NIVEL.
## Si añades una pieza: añádela al final de FORMAS, de esta lista y de @export_flags.
const NOMBRES_PIEZAS := ["I", "O", "T", "S", "Z", "J", "L", "TT", "H", "X", "P", "+", "-", "C"]

# Dimensiones del tablero
@export var COLUMNAS: int
@export var FILAS: int
@export var TAM_CELDA: int
@export var CANTIDAD_PIEZAS: int

@export_group("Categorías")
## Peso de cada categoría al generar cuadrados. Las categorías que no estén aquí pesan 1.
@export var PESOS_CATEGORIAS: Array[PesoCategoria] = []

@export_group("Salas")
## Pools de salas del nivel. De aquí salen también los biomas y las categorías que se generan:
## solo cuentan los biomas y categorías que tienen al menos una sala.
@export var CONTENIDO: ContenidoSalas

@export_group("Piezas")
## Qué piezas pueden salir en este nivel: marca las casillas. Por defecto, todas.
@export_flags("I", "O", "T", "S", "Z", "J", "L", "TT", "H", "X", "P", "+", "-", "C") var PIEZAS_NIVEL: int = 16383

# Dimensiones calculadas del tablero
var ANCHO_TABLERO: int:
	get:
		return COLUMNAS * TAM_CELDA

var ALTO_TABLERO: int:
	get:
		return FILAS * TAM_CELDA


## Nombres de las piezas marcadas en PIEZAS_NIVEL.
func piezas_permitidas() -> Array[String]:
	var permitidas: Array[String] = []
	for i in NOMBRES_PIEZAS.size():
		if PIEZAS_NIVEL & (1 << i):
			permitidas.append(NOMBRES_PIEZAS[i])
	return permitidas


## Peso de una categoría: el de la lista si está, y 1 si no.
func peso_de(categoria: CategoriaSala) -> float:
	for entrada in PESOS_CATEGORIAS:
		if entrada != null and entrada.categoria == categoria:
			return maxf(entrada.peso, 0.0)
	return 1.0
