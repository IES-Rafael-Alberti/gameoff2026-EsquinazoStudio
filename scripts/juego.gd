class_name Juego
extends Node

enum Modo { TETRIS, MAZMORRA }

var modo := Modo.TETRIS

@onready var _tetris: Tetris = $Tetris
@onready var _mazmorra: Mazmorra = $Mazmorra

func _ready() -> void:
	_aplicar_modo()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SHIFT:
		cambiar_modo()


func cambiar_modo() -> void:
	if modo == Modo.TETRIS:
		if not _mazmorra.sincronizar(_tetris.tablero):
			print("No hay habitaciones en el tablero")
			return
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
