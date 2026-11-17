class_name MaquinaEstados
extends Node
## Máquina de estados de un enemigo. Sus hijos son los estados (nodos que heredan de Estado).
## Solo el estado activo corre; el enemigo le pasa cada paso de física.
##
## Un estado cambia a otro emitiendo su señal terminado (con _terminar()); el enemigo puede
## forzar un cambio desde fuera con cambiar_a() (por ejemplo, aturdido al recibir daño).
## Una vez en Muerte no se sale de ahí.

## Estado con el que empieza. Vacío = el primer hijo.
@export var estado_inicial: Estado

var actual: Estado

var _estados := {} # nombre -> Estado


## Lo llama el enemigo cuando está listo.
func iniciar(enemigo: EnemigoEstados) -> void:
	for hijo in get_children():
		var estado := hijo as Estado
		if estado == null:
			continue
		_estados[estado.name] = estado
		estado.enemigo = enemigo
		estado.terminado.connect(_on_estado_terminado.bind(estado))
	var primero := estado_inicial
	if primero == null:
		for estado in _estados.values():
			primero = estado
			break
	if primero == null:
		push_error("La máquina de estados de %s no tiene ningún estado." % enemigo.name)
		return
	_entrar_en(primero, &"", {})


func fisica(delta: float) -> void:
	if actual != null:
		actual.fisica(delta)


func tiene(nombre: StringName) -> bool:
	return _estados.has(nombre)


func obtener(nombre: StringName) -> Estado:
	return _estados.get(nombre) as Estado


func esta_en(nombre: StringName) -> bool:
	return actual != null and actual.name == nombre


func cambiar_a(nombre: StringName, datos := {}) -> void:
	if not _estados.has(nombre):
		push_error("La máquina de estados no tiene el estado %s." % nombre)
		return
	if esta_en(Estado.MUERTE):
		return # de la muerte no se vuelve
	var anterior := actual.name if actual != null else &""
	if actual != null:
		actual.salir()
	_entrar_en(_estados[nombre], anterior, datos)


func _entrar_en(estado: Estado, anterior: StringName, datos: Dictionary) -> void:
	# "actual" se pone antes de entrar: un estado puede terminar dentro de su propio entrar().
	actual = estado
	actual.enemigo.reproducir(estado.animacion)
	estado.entrar(anterior, datos)


# Se ignora lo que pida un estado que ya no es el activo.
func _on_estado_terminado(siguiente: StringName, datos: Dictionary, emisor: Estado) -> void:
	if emisor == actual:
		cambiar_a(siguiente, datos)
