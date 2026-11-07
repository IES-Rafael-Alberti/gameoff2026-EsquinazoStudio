extends Node2D

@export var Configuracion: Configuracion_Tablero
@export var MAX_PREVIEWS := 5

@onready var fixed_blocks = $Board/FixedBlocks
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
@onready var piezas = $Piezas
@onready var controlador_pieza = $ControladorPieza

var piezas_disponibles: int = 0
var cola_piezas: Array[PiezaGenerada] = []
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
	piezas_disponibles = maxi(Configuracion.CANTIDAD_PIEZAS, 0)
	refrescar_cola()
	generar_pieza()
	actualizar_contador()

func _process(delta: float) -> void:
	if not juego_activo:
		return
	controlador_pieza.procesar_caida(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		reiniciar_tetris()
		return

	if not juego_activo:
		return

	if event is InputEventKey:
		if event.keycode == KEY_DOWN:
			controlador_pieza.soft_drop_activo = event.pressed
		if event.pressed and not event.echo:
			if event.keycode == KEY_LEFT:
				controlador_pieza.mover_pieza(Vector2i(-1, 0))
			elif event.keycode == KEY_RIGHT:
				controlador_pieza.mover_pieza(Vector2i(1, 0))
			elif event.keycode == KEY_Z:
				controlador_pieza.rotar_pieza(-1)
			elif event.keycode == KEY_X or event.keycode == KEY_UP:
				controlador_pieza.rotar_pieza(1)
			elif event.keycode == KEY_SPACE:
				controlador_pieza.hard_drop()

func crear_tablero() -> void:
	tablero_nodo.crear_tablero()
	fixed_blocks.actualizar_tablero(tablero)

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
				pieza.categorias
			)
		else:
			preview.actualizar_pieza([], null, null, [])

func generar_pieza() -> void:
	if not juego_activo or bloqueado:
		return
	if piezas_disponibles <= 0:
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
		controlador_pieza.bioma_actual
	)
	tablero_nodo.comprobar_lineas()
	fixed_blocks.actualizar_tablero(tablero)

	if colocadas == 0:
		bloqueado = true
		controlador_pieza.limpiar_pieza()
		actualizar_contador()
		print("BLOQUEADO - PULSA R PARA REINICIAR")
		return

	generar_pieza()

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
	refrescar_cola()
	generar_pieza()
	actualizar_contador()

func actualizar_contador() -> void:
	if piezas_label == null:
		return
	var actual = 0
	if controlador_pieza.pieza_actual != null:
		actual = 1
	piezas_label.text = "PIEZAS: %d" % (piezas_disponibles + actual)
