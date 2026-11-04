extends Node2D

@onready var fixed_blocks = $Board/FixedBlocks
@onready var ghost_piece = $Board/GhostPiece
@onready var current_piece = $Board/CurrentPiece
@onready var tablero_nodo = $Board/Tablero
@onready var next_piece = $SidePanel/NextPiece
@onready var piezas = $Piezas
@onready var controlador_pieza = $ControladorPieza

var siguiente_pieza = ""
var juego_activo = true

# Matriz del tablero
var tablero: Array:
	get:
		return tablero_nodo.matriz

func _ready():
	controlador_pieza.configurar(
		tablero_nodo,
		piezas,
		current_piece,
		ghost_piece
	)
	controlador_pieza.solicitar_fijar_pieza.connect(fijar_pieza)
	controlador_pieza.game_over.connect(finalizar_partida)
	crear_tablero()
	siguiente_pieza = piezas.pieza_aleatoria()
	generar_pieza()
	
func _process(delta):
	if not juego_activo:
		return
	controlador_pieza.procesar_caida(delta)

func _input(event):
	if event is InputEventKey:
		# Soft Drop: mantener pulsada la flecha abajo
		if event.keycode == KEY_DOWN:
			controlador_pieza.soft_drop_activo = event.pressed
		if not juego_activo:
			return
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

func generar_pieza() -> void:
	if not controlador_pieza.establecer_pieza(siguiente_pieza):
		return
	siguiente_pieza = piezas.pieza_aleatoria()
	actualizar_siguiente_pieza()
	
func fijar_pieza() -> void:
	# Guardar los bloques en el tablero.
	tablero_nodo.fijar_pieza(
		controlador_pieza.posicion_pieza,
		controlador_pieza.forma_actual,
		controlador_pieza.color_actual
	)

	# Comprobar y eliminar líneas completas.
	tablero_nodo.comprobar_lineas()

	# Actualizar los bloques fijados.
	fixed_blocks.actualizar_tablero(tablero)

	# Crear la siguiente pieza.
	generar_pieza()

func actualizar_siguiente_pieza() -> void:
	if siguiente_pieza == "":
		next_piece.actualizar_pieza([], Color.WHITE)
		return
	var forma_preview = piezas.FORMAS[siguiente_pieza]
	var color_preview = piezas.COLORES[siguiente_pieza]
	next_piece.actualizar_pieza(forma_preview, color_preview)
	
func finalizar_partida() -> void:
	juego_activo = false
	print("GAME OVER")
