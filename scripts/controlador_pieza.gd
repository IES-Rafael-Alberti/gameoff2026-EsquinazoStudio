extends Node
signal solicitar_fijar_pieza

var tablero_nodo: Node
var piezas: Node
var current_piece: Node2D
var ghost_piece: Node2D

var pieza_actual: PiezaGenerada = null
var forma_actual: Array = []
var textura_actual: Texture2D
var marco_actual: Texture2D
var categorias_actuales: Array[CategoriaSala] = []
var bioma_actual: int = Catalogo.Bioma.MEDIEVAL
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
	
func calcular_posicion_spawn(forma: Array) -> Vector2i:
	if forma.is_empty():
		return Vector2i.ZERO
	var Configuracion = Tetris.de(self).Configuracion
	var min_x: int = forma[0].x
	var max_x: int = forma[0].x
	var max_y: int = forma[0].y
	for bloque in forma:
		min_x = min(min_x, bloque.x)
		max_x = max(max_x, bloque.x)
		max_y = max(max_y, bloque.y)
	var ancho = max_x - min_x + 1
	var x = floori((Configuracion.COLUMNAS - ancho) / 2.0) - min_x
	x = clampi(x, 0, maxi(Configuracion.COLUMNAS - ancho, 0))
	var y = -max_y - 1
	return Vector2i(x, y)

func limpiar_pieza() -> void:
	pieza_actual = null
	forma_actual = []
	textura_actual = null
	marco_actual = null
	categorias_actuales.clear()
	bioma_actual = Catalogo.Bioma.MEDIEVAL
	if current_piece != null:
		current_piece.actualizar_pieza([], Vector2i.ZERO, null, null, [], false)
	if ghost_piece != null:
		ghost_piece.actualizar_pieza([], Vector2i.ZERO, null, null, [], false)

func reiniciar_estado() -> void:
	temporizador = 0.0
	soft_drop_activo = false
	estado_rotacion = 0
	posicion_pieza = Vector2i.ZERO
	limpiar_pieza()
	
func actualizar_pieza_actual() -> void:
	if forma_actual.is_empty():
		current_piece.actualizar_pieza([], Vector2i.ZERO, textura_actual, marco_actual, categorias_actuales, false)
		return

	current_piece.actualizar_pieza(forma_actual, posicion_pieza, textura_actual, marco_actual, categorias_actuales, true)

func actualizar_pieza_fantasma() -> void:
	if forma_actual.is_empty():
		ghost_piece.actualizar_pieza([], Vector2i.ZERO, textura_actual, marco_actual, categorias_actuales, false)
		return

	var posicion_fantasma = calcular_posicion_fantasma()
	ghost_piece.actualizar_pieza(forma_actual, posicion_fantasma, textura_actual, marco_actual, categorias_actuales, true)
	
func calcular_posicion_fantasma() -> Vector2i:
	var posicion_fantasma = posicion_pieza

	while not tablero_nodo.comprobar_colision(
		posicion_fantasma + Vector2i(0, 1),
		forma_actual
	):
		posicion_fantasma.y += 1

	return posicion_fantasma
	
func mover_pieza(direccion: Vector2i) -> void:
	if pieza_actual == null:
		return
	
	var nueva_posicion = posicion_pieza + direccion

	if not tablero_nodo.comprobar_colision(nueva_posicion, forma_actual):
		posicion_pieza = nueva_posicion
		actualizar_pieza_actual()
		actualizar_pieza_fantasma()
	elif direccion.y > 0:
		solicitar_fijar_pieza.emit()

func rotar_pieza(direccion: int = 1):
	if pieza_actual == null:
		return
	if pieza_actual.nombre == "O" or pieza_actual.nombre == "P":
		return

	var nueva_forma: Array[Vector2i] = []

	# Calcular la nueva orientación de cada bloque.
	for punto in forma_actual:
		var nuevo_punto: Vector2i
		if pieza_actual.nombre == "I":
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

	var tabla_kicks = KICKS_I if pieza_actual.nombre == "I" else KICKS_JLSTZ
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
	if pieza_actual == null:
		return
	while not tablero_nodo.comprobar_colision(
		posicion_pieza + Vector2i(0, 1),
		forma_actual
	):
		posicion_pieza.y += 1

	solicitar_fijar_pieza.emit()

func procesar_caida(delta: float) -> void:
	if pieza_actual == null:
		return
	temporizador += delta

	var velocidad_actual = velocidad_soft_drop if soft_drop_activo else velocidad_caida

	if temporizador >= velocidad_actual:
		temporizador -= velocidad_actual
		mover_pieza(Vector2i(0, 1))
		
func establecer_pieza(pieza: PiezaGenerada) -> bool:
	if pieza == null:
		return false

	pieza_actual = pieza
	forma_actual = pieza.forma
	textura_actual = pieza.textura_fondo
	marco_actual = pieza.textura_marco
	categorias_actuales = pieza.categorias
	posicion_pieza = calcular_posicion_spawn(forma_actual)
	estado_rotacion = 0
	temporizador = 0.0
	bioma_actual = pieza.bioma
	
	actualizar_pieza_actual()
	actualizar_pieza_fantasma()
	return true
