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

@export_group("Vida")
## Vida que recupera el jugador al terminar el nivel. 0 = no se cura al terminar.
@export_range(0, 99) var CURACION_FIN_NIVEL := 1

@export_group("Piezas")
## Qué piezas pueden salir en este nivel: marca las casillas. Por defecto, todas.
@export_flags("I", "O", "T", "S", "Z", "J", "L", "TT", "H", "X", "P", "+", "-", "C") var PIEZAS_NIVEL: int = 16383

## Probabilidad (en %) de que cada pieza que se genera salga SIN habitación: ocupa sitio en el
## tablero y cuenta para completar líneas, pero no es una sala (las puertas contiguas se sellan
## y el vestíbulo cierra esa columna). 0 = todas las piezas tienen habitación.
@export_range(0.0, 100.0, 0.5, "suffix:%") var PROBABILIDAD_SIN_HABITACION := 0.0

## Probabilidad (en %) de que cada pieza que se genera (y que sí tiene habitación) salga SOLO
## HORIZONTAL: sus salas no tienen puertas al Norte ni al Sur (solo Este y Oeste). Sin
## protección: una sala así puede quedar aislada, y en la fila de abajo o de arriba cierra la
## puerta de su columna en el vestíbulo. 0 = ninguna.
@export_range(0.0, 100.0, 0.5, "suffix:%") var PROBABILIDAD_SOLO_HORIZONTAL := 0.0

@export_group("Línea completada")
## Categoría a la que se convierte una casilla por cada línea completada (Tesoro.tres). Vacío =
## no hace nada.
@export var CATEGORIA_TESORO: CategoriaSala
## Categorías que ya son de tesoro y no se convierten (Tesoro, TesoroPuzle, TesoroCombate,
## TesoroCuracion...). CATEGORIA_TESORO cuenta siempre como tesoro aunque no esté aquí.
@export var CATEGORIAS_TESORO: Array[CategoriaSala] = []

## Si una categoría ya es de tesoro (y por tanto no se convierte).
func es_tesoro(categoria: CategoriaSala) -> bool:
	return categoria != null and (categoria == CATEGORIA_TESORO or CATEGORIAS_TESORO.has(categoria))

@export_group("Piezas escogidas")
## Primeras piezas del nivel, en orden: la 1ª de la lista es la primera pieza que sale, etc.
@export var SECUENCIA_INICIAL: Array[PiezaEscogida] = []

## Piezas que salen en un turno concreto (número de pieza del nivel). Si coincide con un turno
## de la secuencia inicial, gana la secuencia; si dos entradas comparten turno, gana la primera.
@export var PIEZAS_EN_TURNO: Array[PiezaEnTurno] = []

## Piezas que pueden salir en cualquier momento, con un peso relativo. Compiten en el mismo
## sorteo que la pieza aleatoria normal, cuyo peso es PESO_PIEZA_NORMAL.
@export var POOL_PIEZAS: Array[PiezaConPeso] = []

## Peso de "pieza aleatoria normal" en el sorteo del pool. Con el pool vacío no importa.
@export_range(0.0, 100.0, 0.1) var PESO_PIEZA_NORMAL := 10.0

@export_group("Casillas especiales")
## Habitaciones fijas: aparecen en su coordenada al empezar y no se van al hacer línea.
@export var CASILLAS_FIJAS: Array[CasillaFija] = []

## Posiciones bloqueadas (x = columna, y = fila): muros que las piezas no atraviesan, no se
## borran, cuentan para las líneas y no generan sala.
@export var CASILLAS_BLOQUEADAS: Array[Vector2i] = []

## Textura de fondo de las casillas fijas (sin textura, solo se ve el marco).
@export var TEXTURA_FIJA: Texture2D
## Textura de fondo de las casillas bloqueadas (sin textura, solo se ve el marco).
@export var TEXTURA_BLOQUEADA: Texture2D

@export_group("Barreras")
## Grupos de posiciones barrera: se puede colocar pieza ahí y cuenta para las líneas, pero no
## genera sala mientras el grupo esté activo. La posición permanece aunque se borre la línea.
@export var CASILLAS_BARRERA: Array[GrupoBarrera] = []

## Textura que se dibuja sobre las posiciones con barrera activa (se usa tal cual: hazla
## semitransparente en la propia imagen).
var TEXTURA_BARRERA: Texture2D = preload("res://assets/sprites/piezas/Casilla puntos.png")
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
