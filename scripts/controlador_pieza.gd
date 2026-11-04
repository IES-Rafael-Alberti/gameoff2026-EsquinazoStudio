extends Node
signal solicitar_fijar_pieza
signal game_over

var tablero_nodo: Node
var piezas: Node
var current_piece: Node2D
var ghost_piece: Node2D
var pieza_actual = ""
var forma_actual: Array = []
var color_actual = Color.WHITE

var posicion_pieza = Vector2i(3, 0)

# 0 = inicial
# 1 = 90 grados
# 2 = 180 grados
# 3 = 270 grados
var estado_rotacion = 0

# Velocidad de caída
var velocidad_caida = 0.7
var velocidad_soft_drop = 0.05
var soft_drop_activo = false

# Temporizador
var temporizador = 0.0

# Desplazamientos SRS para J, L, S, T y Z
const KICKS_JLSTZ = {
	"0_1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"1_0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"1_2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"2_1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"2_3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	"3_2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"3_0": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"0_3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)]
}

# Desplazamientos SRS para I
const KICKS_I = {
	"0_1": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"1_0": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"1_2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	"2_1": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"2_3": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"3_2": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"3_0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"0_3": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)]
}

func configurar(
	tablero: Node,
	gestor_piezas: Node,
	pieza_visual: Node2D,
	fantasma_visual: Node2D
) -> void:
	tablero_nodo = tablero
	piezas = gestor_piezas
	current_piece = pieza_visual
	ghost_piece = fantasma_visual
	
func actualizar_pieza_actual() -> void:
	if forma_actual.is_empty():
		current_piece.actualizar_pieza([], Vector2i.ZERO, color_actual, false)
		return

	current_piece.actualizar_pieza(forma_actual, posicion_pieza, color_actual, true)


func actualizar_pieza_fantasma() -> void:
	if forma_actual.is_empty():
		ghost_piece.actualizar_pieza([], Vector2i.ZERO, color_actual, false)
		return
	var posicion_fantasma = calcular_posicion_fantasma()
	ghost_piece.actualizar_pieza(forma_actual, posicion_fantasma, color_actual, true)

func calcular_posicion_fantasma() -> Vector2i:
	var posicion_fantasma = posicion_pieza

	while not tablero_nodo.comprobar_colision(
		posicion_fantasma + Vector2i(0, 1),
		forma_actual
	):
		posicion_fantasma.y += 1

	return posicion_fantasma
	
func mover_pieza(direccion: Vector2i) -> void:
	var nueva_posicion = posicion_pieza + direccion

	if not tablero_nodo.comprobar_colision(nueva_posicion, forma_actual):
		posicion_pieza = nueva_posicion
		actualizar_pieza_actual()
		actualizar_pieza_fantasma()
	elif direccion.y > 0:
		solicitar_fijar_pieza.emit()

func rotar_pieza(direccion: int = 1):
	if pieza_actual == "O":
		return

	var nueva_forma: Array[Vector2i] = []

	# Calcular la nueva orientación de cada bloque.
	for punto in forma_actual:
		var nuevo_punto: Vector2i
		if pieza_actual == "I":
			if direccion == 1:
				nuevo_punto = Vector2i(3 - punto.y, punto.x)
			else:
				nuevo_punto = Vector2i(punto.y, 3 - punto.x)
		else:
			if direccion == 1:
				nuevo_punto = Vector2i(2 - punto.y, punto.x)
			else:
				nuevo_punto = Vector2i(punto.y, 2 - punto.x)

		nueva_forma.append(nuevo_punto)

	# Calcular el nuevo estado de rotación.
	var nuevo_estado = (estado_rotacion + direccion + 4) % 4

	# Obtener la tabla de movimientos correspondiente.
	var clave = "%d_%d" % [estado_rotacion, nuevo_estado]

	var tabla_kicks = KICKS_I if pieza_actual == "I" else KICKS_JLSTZ
	var movimientos = tabla_kicks[clave]

	# Probar cada desplazamiento hasta encontrar uno válido.
	for kick in movimientos:
		var nueva_posicion = posicion_pieza + kick
		if not tablero_nodo.comprobar_colision(nueva_posicion, nueva_forma):
			forma_actual = nueva_forma
			posicion_pieza = nueva_posicion
			estado_rotacion = nuevo_estado
			
			actualizar_pieza_actual()
			actualizar_pieza_fantasma()
			return

func hard_drop() -> void:
	while not tablero_nodo.comprobar_colision(
		posicion_pieza + Vector2i(0, 1),
		forma_actual
	):
		posicion_pieza.y += 1

	solicitar_fijar_pieza.emit()

func procesar_caida(delta: float) -> void:
	temporizador += delta

	var velocidad_actual = velocidad_soft_drop if soft_drop_activo else velocidad_caida

	if temporizador >= velocidad_actual:
		temporizador = 0.0
		mover_pieza(Vector2i(0, 1))
		
func establecer_pieza(nombre: String) -> bool:
	pieza_actual = nombre
	forma_actual = piezas.FORMAS[pieza_actual]
	color_actual = piezas.COLORES[pieza_actual]
	posicion_pieza = Vector2i(3, 0)
	estado_rotacion = 0

	if tablero_nodo.comprobar_colision(posicion_pieza, forma_actual):
		game_over.emit()
		return false

	actualizar_pieza_actual()
	actualizar_pieza_fantasma()
	return true
