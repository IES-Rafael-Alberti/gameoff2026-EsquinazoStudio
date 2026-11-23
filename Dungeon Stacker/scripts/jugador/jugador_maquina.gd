class_name JugadorMaquina
extends Node
## Máquina de estados del jugador. Sus hijos son los estados (nodos que heredan de
## JugadorEstado). Solo el estado activo corre. Una vez en Muerte no se sale de ahí.

## Estado con el que empieza. Vacío = el primer hijo.
@export var estado_inicial: JugadorEstado

var actual: JugadorEstado

var _estados := {} # nombre -> JugadorEstado


## Lo llama el jugador cuando está listo.
func iniciar(jugador: Jugador) -> void:
	for hijo in get_children():
		var estado := hijo as JugadorEstado
		if estado == null:
			continue
		_estados[estado.name] = estado
		estado.jugador = jugador
		estado.terminado.connect(_on_estado_terminado.bind(estado))
	var primero := estado_inicial
	if primero == null:
		for estado in _estados.values():
			primero = estado
			break
	if primero == null:
		push_error("La máquina de estados del jugador no tiene ningún estado.")
		return
	_entrar_en(primero, &"", {})


func fisica(delta: float) -> void:
	if actual != null:
		actual.fisica(delta)


func entrada(evento: InputEvent) -> void:
	if actual != null:
		actual.entrada(evento)


func esta_en(nombre: StringName) -> bool:
	return actual != null and actual.name == nombre


func cambiar_a(nombre: StringName, datos := {}) -> void:
	if not _estados.has(nombre):
		push_error("La máquina de estados del jugador no tiene el estado %s." % nombre)
		return
	if esta_en(JugadorEstado.MUERTE):
		return # de la muerte no se vuelve
	var anterior := actual.name if actual != null else &""
	if actual != null:
		actual.salir()
	_entrar_en(_estados[nombre], anterior, datos)


func _entrar_en(estado: JugadorEstado, anterior: StringName, datos: Dictionary) -> void:
	# "actual" se pone antes de entrar: un estado puede terminar dentro de su propio entrar().
	actual = estado
	estado.entrar(anterior, datos)


# Se ignora lo que pida un estado que ya no es el activo.
func _on_estado_terminado(siguiente: StringName, datos: Dictionary, emisor: JugadorEstado) -> void:
	if emisor == actual:
		cambiar_a(siguiente, datos)
