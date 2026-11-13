class_name Juego
extends Node

enum Modo { TETRIS, MAZMORRA }

var modo := Modo.MAZMORRA

@onready var _tetris: Tetris = $Tetris
@onready var _mazmorra: Mazmorra = $Mazmorra

var _pantalla_muerte: PantallaMuerte

func _ready() -> void:
	# Los pools de salas son del nivel: viven en su configuración y los comparten tetris y mazmorra.
	_mazmorra.contenido = _tetris.Configuracion.CONTENIDO
	# Las piezas que se consiguen en la mazmorra (cofres...) se suman al tetris.
	_mazmorra.piezas_obtenidas.connect(_tetris.agregar_piezas)
	# Se empieza en la mazmorra, en la zona de spawn del vestíbulo inferior.
	_mazmorra.sincronizar(_tetris.tablero)
	_aplicar_modo()

	_pantalla_muerte = PantallaMuerte.new()
	add_child(_pantalla_muerte)
	_pantalla_muerte.reinicio_pedido.connect(reiniciar_nivel)
	_mazmorra.jugador.murio.connect(_on_jugador_murio)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SHIFT:
		cambiar_modo()

func cambiar_modo() -> void:
	if modo == Modo.MAZMORRA and not _mazmorra.puede_cambiar_modo():
		print("Sala sin resolver: no se puede cambiar de modo")
		return
	if modo == Modo.TETRIS:
		_mazmorra.sincronizar(_tetris.tablero)
		modo = Modo.MAZMORRA
	else:
		modo = Modo.TETRIS
	_aplicar_modo()

## Solo el modo activo se ve y recibe entrada y procesamiento; el otro queda congelado.
func _aplicar_modo() -> void:
	_activar(_tetris, modo == Modo.TETRIS)
	_activar(_mazmorra, modo == Modo.MAZMORRA)
	_mazmorra.set_activa(modo == Modo.MAZMORRA)
	print("Modo: ", Modo.keys()[modo])


func _activar(nodo: CanvasItem, activo: bool) -> void:
	nodo.visible = activo
	nodo.process_mode = Node.PROCESS_MODE_INHERIT if activo else Node.PROCESS_MODE_DISABLED


## El jugador ha llegado a 0 de vida: se congela todo y se ofrece reiniciar el nivel.
func _on_jugador_murio() -> void:
	get_tree().paused = true
	_pantalla_muerte.mostrar()


## Reinicia solo este nivel (tablero, mazmorra y vida desde cero).
func reiniciar_nivel() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
