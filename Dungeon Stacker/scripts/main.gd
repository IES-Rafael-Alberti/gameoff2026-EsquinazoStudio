class_name Tetris
extends Node2D

## Devuelve el Tetris al que pertenece este nodo, subiendo por el árbol hasta encontrarlo.
## Así los componentes no dependen de qué escena sea la "escena actual".
static func de(nodo: Node) -> Tetris:
	var actual := nodo
	while actual != null and not actual is Tetris:
		actual = actual.get_parent()
	return actual as Tetris

@export var Configuracion: Configuracion_Tablero
@export var MAX_PREVIEWS := 5

@export_group("Colocación en pantalla")
## Dónde queda el centro del tablero en vertical, medido desde abajo (0 = abajo del todo,
## 1 = arriba del todo, 0,33 = a un tercio). Si el tablero no cabe, se ajusta para no salirse.
@export_range(0.0, 1.0, 0.01) var altura_centro_desde_abajo := 1.0 / 3.0
## Separación (px) entre el borde derecho del tablero y el panel lateral.
@export var separacion_panel := 40.0

@onready var fixed_blocks = $Board/FixedBlocks
@onready var barreras = $Board/Barreras
@onready var ghost_piece = $Board/GhostPiece
@onready var current_piece = $Board/CurrentPiece
@onready var tablero_nodo = $Board/Tablero
@onready var previews = [
	$SidePanel/NextPiece1,
	$SidePanel/NextPiece2,
	$SidePanel/NextPiece3,
	$SidePanel/NextPiece4,
	$SidePanel/NextPiece5,
]
@onready var piezas_label = $SidePanel/PiezasLabel
## Panel de la pieza guardada (opcional: si el nodo no existe, simplemente no se dibuja).
@onready var hold_panel = get_node_or_null("SidePanel/HoldPiece")
@onready var piezas = $Piezas
@onready var _board: Node2D = $Board
@onready var _panel_lateral: Control = $SidePanel
@onready var controlador_pieza = $ControladorPieza

var piezas_disponibles: int = 0
var cola_piezas: Array[PiezaGenerada] = []
## Pieza en la reserva (null = vacía). Cuenta como pieza pendiente del nivel.
var pieza_guardada: PiezaGenerada = null
var bloqueado: bool = false
var juego_activo := true

var tablero: Array:
	get:
		return tablero_nodo.matriz

func _ready() -> void:
	controlador_pieza.configurar(
		tablero_nodo,
		piezas,
		current_piece,
		ghost_piece
	)
	controlador_pieza.solicitar_fijar_pieza.connect(fijar_pieza)
	crear_tablero()
	colocar_tablero()
	get_viewport().size_changed.connect(colocar_tablero)
	piezas_disponibles = maxi(Configuracion.CANTIDAD_PIEZAS, 0)
	refrescar_cola()
	generar_pieza()
	actualizar_contador()

## Centra el tablero en horizontal, lo sube a la altura elegida y pega el panel lateral a su
## derecha. Depende del tamaño del tablero del nivel y del de la pantalla.
func colocar_tablero() -> void:
	var pantalla := get_viewport_rect().size
	var tam := Vector2(Configuracion.ANCHO_TABLERO, Configuracion.ALTO_TABLERO)
	var centro_y := pantalla.y * (1.0 - altura_centro_desde_abajo)
	var y := clampf(centro_y - tam.y / 2.0, 0.0, maxf(pantalla.y - tam.y, 0.0))
	_board.position = Vector2((pantalla.x - tam.x) / 2.0, y)
	_panel_lateral.position.x = _board.position.x + tam.x + separacion_panel

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reiniciar"):
		reiniciar_tetris()
		return

	if not juego_activo:
		return

	if Input.is_action_just_pressed("mover_izquierda"):
		controlador_pieza.mover_pieza(Vector2i(-1, 0))
	elif Input.is_action_just_pressed("mover_derecha"):
		controlador_pieza.mover_pieza(Vector2i(1, 0))
	elif Input.is_action_just_pressed("mover_arriba"):
		controlador_pieza.rotar_pieza(1)
	elif Input.is_action_just_pressed("rotar_izquierda"):
		controlador_pieza.rotar_pieza(-1)
	elif Input.is_action_just_pressed("rotar_derecha"):
		controlador_pieza.rotar_pieza(1)
	elif Input.is_action_just_pressed("accion"):
		controlador_pieza.hard_drop()
	elif InputMap.has_action("guardar_pieza") and Input.is_action_just_pressed("guardar_pieza"):
		guardar_pieza()

	controlador_pieza.soft_drop_activo = Input.is_action_pressed("mover_abajo")
	controlador_pieza.procesar_caida(delta)

func crear_tablero() -> void:
	tablero_nodo.crear_tablero()
	fixed_blocks.actualizar_tablero(tablero)
	barreras.actualizar(tablero_nodo.posiciones_barrera())

func refrescar_cola() -> void:
	var objetivo = mini(piezas_disponibles, mini(MAX_PREVIEWS, previews.size()))
	while cola_piezas.size() < objetivo:
		cola_piezas.append(piezas.generar_pieza())
	while cola_piezas.size() > objetivo:
		cola_piezas.pop_back()
	actualizar_previews()

func actualizar_previews() -> void:
	for i in previews.size():
		var preview = previews[i]
		if i < cola_piezas.size():
			var pieza = cola_piezas[i]
			preview.actualizar_pieza(
				pieza.forma,
				pieza.textura_fondo,
				pieza.textura_marco,
				pieza.categorias,
				pieza.solo_horizontal
			)
		else:
			preview.actualizar_pieza([], null, null, [])

func generar_pieza() -> void:
	if not juego_activo or bloqueado:
		return
	if piezas_disponibles <= 0:
		# Sin piezas en la cola: si hay una guardada, sale ella (no se puede dejar atascada).
		if pieza_guardada != null:
			var sacada := pieza_guardada
			pieza_guardada = null
			controlador_pieza.establecer_pieza(sacada)
			actualizar_hold()
		else:
			controlador_pieza.limpiar_pieza()
		actualizar_contador()
		return

	if cola_piezas.is_empty():
		cola_piezas.append(piezas.generar_pieza())

	var pieza = cola_piezas.pop_front()
	if not controlador_pieza.establecer_pieza(pieza):
		return

	piezas_disponibles -= 1
	refrescar_cola()
	actualizar_contador()

func fijar_pieza() -> void:
	if bloqueado:
		return

	var colocadas = tablero_nodo.fijar_pieza(
		controlador_pieza.posicion_pieza,
		controlador_pieza.forma_actual,
		controlador_pieza.textura_actual,
		controlador_pieza.categorias_actuales,
		controlador_pieza.bioma_actual,
		controlador_pieza.sin_habitacion_actual,
		controlador_pieza.solo_horizontal_actual
	)
	var lineas: int = tablero_nodo.comprobar_lineas()
	_regalar_tesoro(lineas)
	fixed_blocks.actualizar_tablero(tablero)

	if colocadas == 0:
		bloqueado = true
		controlador_pieza.limpiar_pieza()
		actualizar_contador()
		print("BLOQUEADO - PULSA R PARA REINICIAR")
		return

	generar_pieza()

## Guarda la pieza que cae en la reserva y saca la que había. Sin límite de usos. Con la reserva
## vacía, la pieza actual se guarda y entra la primera de la cola (gasta una pieza del contador).
## La pieza que sale aparece arriba, sin rotar.
func guardar_pieza() -> void:
	if not Configuracion.PERMITIR_GUARDAR_PIEZA:
		return
	if not juego_activo or bloqueado or controlador_pieza.pieza_actual == null:
		return
	var actual: PiezaGenerada = controlador_pieza.pieza_actual

	if pieza_guardada == null:
		if piezas_disponibles <= 0:
			return
		if cola_piezas.is_empty():
			cola_piezas.append(piezas.generar_pieza())
		var siguiente: PiezaGenerada = cola_piezas.pop_front()
		pieza_guardada = actual
		controlador_pieza.establecer_pieza(siguiente)
		piezas_disponibles -= 1
		refrescar_cola()
	else:
		var sacada := pieza_guardada
		pieza_guardada = actual
		controlador_pieza.establecer_pieza(sacada)

	actualizar_hold()
	actualizar_contador()

func actualizar_hold() -> void:
	if hold_panel == null:
		return
	if pieza_guardada == null:
		hold_panel.actualizar_pieza([], null, null, [])
	else:
		hold_panel.actualizar_pieza(
			pieza_guardada.forma,
			pieza_guardada.textura_fondo,
			pieza_guardada.textura_marco,
			pieza_guardada.categorias,
			pieza_guardada.solo_horizontal
		)

## Por cada línea completada, una casilla de las piezas de la cola pasa a ser Tesoro. Se empieza
## por la primera pieza; las casillas que ya son de tesoro, las piezas sin habitación y las
## piezas escogidas se ignoran, y lo que no cabe en una pieza pasa a la siguiente de la cola.
func _regalar_tesoro(lineas: int) -> void:
	var tesoro: CategoriaSala = Configuracion.CATEGORIA_TESORO
	if lineas <= 0 or tesoro == null:
		return

	var pendientes := lineas
	for pieza in cola_piezas:
		if pendientes <= 0:
			break
		if pieza.sin_habitacion or pieza.escogida:
			continue
		var candidatas: Array[int] = []
		for i in pieza.categorias.size():
			if not Configuracion.es_tesoro(pieza.categorias[i]):
				candidatas.append(i)
		candidatas.shuffle()
		var cambiadas := mini(pendientes, candidatas.size())
		for i in cambiadas:
			pieza.categorias[candidatas[i]] = tesoro
		pendientes -= cambiadas
	actualizar_previews()

## Apaga un grupo de barreras por su nombre (lo llamará el objetivo del nivel). Las casillas
## colocadas sobre ellas recuperan su sala.
func desactivar_barrera(grupo: StringName) -> void:
	if not tablero_nodo.desactivar_barrera(grupo):
		push_warning("desactivar_barrera: no hay barrera activa con el nombre '%s'." % grupo)
	barreras.actualizar(tablero_nodo.posiciones_barrera())

func agregar_piezas(cantidad: int) -> void:
	if cantidad <= 0:
		return
	piezas_disponibles += cantidad
	refrescar_cola()
	actualizar_contador()
	if not bloqueado and controlador_pieza.pieza_actual == null:
		generar_pieza()

func reiniciar_tetris() -> void:
	bloqueado = false
	juego_activo = true
	controlador_pieza.reiniciar_estado()
	crear_tablero()
	piezas_disponibles = maxi(Configuracion.CANTIDAD_PIEZAS, 0)
	cola_piezas.clear()
	pieza_guardada = null
	actualizar_hold()
	piezas.reiniciar_secuencia()
	refrescar_cola()
	generar_pieza()
	actualizar_contador()

func actualizar_contador() -> void:
	if piezas_label == null:
		return
	var actual = 0
	if controlador_pieza.pieza_actual != null:
		actual = 1
	var guardada := 1 if pieza_guardada != null else 0
	piezas_label.text = "PIEZAS: %d" % (piezas_disponibles + actual + guardada)
