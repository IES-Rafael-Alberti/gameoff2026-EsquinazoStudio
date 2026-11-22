extends Node
## Autoload "Partida" (se registra como ESCENA: Partida.tscn con este script en el nodo raíz).
##
## Recuerda qué nivel se ha elegido, qué niveles están completados (y lo guarda en disco) y
## cambia entre el menú y el juego. El nivel 0 es el tutorial.

const RUTA_GUARDADO := "user://progreso.cfg"

@export_group("Escenas")
## La escena del juego (scenes/juego.tscn). Es la misma para todos los niveles.
@export var escena_juego: PackedScene
@export var escena_menu: PackedScene

@export_group("Niveles")
## Una configuración por nivel, en orden: 0 = tutorial, 1..3 = niveles.
@export var configuraciones: Array[Configuracion_Tablero] = []

## Nivel que se está jugando. -1 = ninguno elegido (por ejemplo, al abrir juego.tscn con F6):
## en ese caso el juego usa la configuración que lleve su propio nodo Tetris.
var nivel_actual := -1
var _completados: Array[bool] = []


func _ready() -> void:
	_cargar()


func cantidad_niveles() -> int:
	return configuraciones.size()


## La configuración del nivel elegido, o null si no hay ninguno elegido.
func configuracion_actual() -> Configuracion_Tablero:
	if nivel_actual < 0 or nivel_actual >= configuraciones.size():
		return null
	return configuraciones[nivel_actual]


func nivel_completado(nivel: int) -> bool:
	return nivel >= 0 and nivel < _completados.size() and _completados[nivel]


## Un nivel se puede jugar si es el tutorial o si el anterior está completado.
func nivel_disponible(nivel: int) -> bool:
	if nivel < 0 or nivel >= configuraciones.size():
		return false
	return nivel == 0 or nivel_completado(nivel - 1)


## Primer nivel sin completar, o -1 si están todos completados.
func siguiente_nivel() -> int:
	for i in configuraciones.size():
		if not nivel_completado(i):
			return i
	return -1


## CONTINUE: solo con el tutorial terminado y algún nivel por jugar.
func puede_continuar() -> bool:
	return nivel_completado(0) and siguiente_nivel() != -1


## Marca el nivel como completado y lo guarda en disco. Lo llamará el fin de nivel.
func completar_nivel(nivel: int) -> void:
	if nivel < 0 or nivel >= configuraciones.size():
		return
	_completados.resize(configuraciones.size())
	_completados[nivel] = true
	_guardar()


## Empieza el nivel indicado desde cero.
func jugar_nivel(nivel: int) -> void:
	if not nivel_disponible(nivel):
		return
	nivel_actual = nivel
	get_tree().paused = false
	get_tree().change_scene_to_packed(escena_juego)


func continuar() -> void:
	if puede_continuar():
		jugar_nivel(siguiente_nivel())


func volver_al_menu() -> void:
	nivel_actual = -1
	get_tree().paused = false
	get_tree().change_scene_to_packed(escena_menu)


## Borra el progreso (para pruebas).
func borrar_progreso() -> void:
	_completados.clear()
	_completados.resize(configuraciones.size())
	_guardar()


func _cargar() -> void:
	_completados.clear()
	_completados.resize(configuraciones.size())
	var archivo := ConfigFile.new()
	if archivo.load(RUTA_GUARDADO) != OK:
		return
	for i in configuraciones.size():
		_completados[i] = archivo.get_value("niveles", str(i), false)


func _guardar() -> void:
	var archivo := ConfigFile.new()
	for i in _completados.size():
		archivo.set_value("niveles", str(i), _completados[i])
	archivo.save(RUTA_GUARDADO)
