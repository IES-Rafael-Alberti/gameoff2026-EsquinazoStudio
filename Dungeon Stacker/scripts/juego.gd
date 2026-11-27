class_name Juego
extends Node

enum Modo { TETRIS, MAZMORRA }
var modo := Modo.MAZMORRA

@onready var _tetris: Tetris = $Tetris
@onready var _mazmorra: Mazmorra = $Mazmorra

## La pantalla de "has muerto" (instancia de su escena dentro de juego.tscn). Su señal
## reinicio_pedido se conecta a reiniciar_nivel desde el editor.
@export var pantalla_muerte: PantallaMuerte
## Texto de controles en pantalla (opcional). Se le avisa del modo al cambiar.
@export var controles: ControlesPantalla

## Antes de que nada del tablero lea su configuración (el padre entra en el árbol antes que sus
## hijos), se pone la del nivel elegido en el menú. Sin nivel elegido (F6 sobre esta escena)
## se queda la que lleve el nodo Tetris.
func _enter_tree() -> void:
	var configuracion: Configuracion_Tablero = Partida.configuracion_actual()
	if configuracion != null:
		(get_node("Tetris") as Tetris).Configuracion = configuracion

func _ready() -> void:
	# Los pools de salas son del nivel: viven en su configuración y los comparten tetris y mazmorra.
	_mazmorra.contenido = _tetris.Configuracion.CONTENIDO
	# Las piezas que se consiguen en la mazmorra (cofres...) se suman al tetris.
	_mazmorra.piezas_obtenidas.connect(_tetris.agregar_piezas)
	# Las salas objetivo resueltas apagan barreras del tetris.
	_mazmorra.barreras_a_apagar_pedidas.connect(_apagar_barreras)
	# El contador de piezas se ve también en la interfaz de la mazmorra.
	_tetris.piezas_cambiadas.connect(_mazmorra.mostrar_piezas)
	_mazmorra.mostrar_piezas(_tetris.total_piezas())
	# Se empieza en la mazmorra, en la zona de spawn del vestíbulo inferior.
	_mazmorra.sincronizar(_tetris.tablero)
	# La música empieza en el bioma medieval; la mazmorra cambia de bioma al entrar en cada sala.
	Musica.iniciar_juego(Catalogo.Bioma.MEDIEVAL, Musica.Modo.MAZMORRA)
	_aplicar_modo()

	_mazmorra.jugador.murio.connect(_on_jugador_murio)
	# Si viene de un nivel anterior (o reinicia este), empieza con la vida que le toca.
	if Partida.vida_al_empezar >= 0:
		_mazmorra.jugador.vida.establecer(Partida.vida_al_empezar)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cambiar_modo"):
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
	if controles != null:
		controles.mostrar_modo(modo == Modo.TETRIS)
	Musica.cambiar_modo(Musica.Modo.TETRIS if modo == Modo.TETRIS else Musica.Modo.MAZMORRA)

func _activar(nodo: CanvasItem, activo: bool) -> void:
	nodo.visible = activo
	nodo.process_mode = Node.PROCESS_MODE_INHERIT if activo else Node.PROCESS_MODE_DISABLED

## El jugador ha llegado a 0 de vida: se congela todo y se ofrece reiniciar el nivel.
func _on_jugador_murio() -> void:
	get_tree().paused = true
	pantalla_muerte.mostrar()

## Señal nivel_completado de Mazmorra (se conecta desde el editor): el jugador cruzó la puerta de
## salida. Se cura lo que diga la configuración del nivel y pasa al siguiente con esa vida.
func _on_mazmorra_nivel_completado() -> void:
	var vida: Vida = _mazmorra.jugador.vida
	vida.curar(_tetris.Configuracion.CURACION_FIN_NIVEL)
	Partida.terminar_nivel(vida.vida)

## Reinicia solo este nivel (tablero, mazmorra y vida desde cero).
func reiniciar_nivel() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _apagar_barreras(grupos: Array[StringName]) -> void:
	for grupo in grupos:
		_tetris.desactivar_barrera(grupo)
