class_name BotinPiezas
extends Node
## Hace que un enemigo suelte piezas para el tetris al morir. Se pone como hijo de cualquier
## Enemigo (con máquina de estados o no) y escucha su señal murio: en cuanto la vida llega a 0
## decide, con la probabilidad elegida, si suelta piezas y cuántas.
##
## Las piezas viajan por señales, igual que las del cofre de botín: el componente se lo dice a
## su Habitacion, esta a la Mazmorra y Juego las suma al tetris. No hay objeto en el suelo.
##
## Los enemigos invocados (cofre falso, spawner...) no sueltan nada salvo que se marque
## soltar_si_invocado, para no poder sacar piezas sin fin de un spawner.

## Probabilidad (en %) de soltar piezas al morir. 100 = siempre, 0 = nunca.
@export_range(0.0, 100.0, 0.5, "suffix:%") var probabilidad := 100.0

@export_group("Piezas")
## Piezas que suelta. Es el valor que se usa si "usar_rango" está desmarcado.
@export_range(0, 99) var piezas := 1
## Si está marcado, suelta un número al azar entre piezas_minimas y piezas_maximas (los dos
## incluidos) en vez de "piezas".
@export var usar_rango := false
@export_range(0, 99) var piezas_minimas := 1
@export_range(0, 99) var piezas_maximas := 2

@export_group("Invocados")
## Si los enemigos invocados también pueden soltar piezas.
@export var soltar_si_invocado := false

var _enemigo: Enemigo
var _habitacion: Habitacion


func _ready() -> void:
	_enemigo = get_parent() as Enemigo
	if _enemigo == null:
		push_warning("BotinPiezas %s debe ser hijo de un Enemigo." % name)
		return
	_habitacion = _buscar_habitacion()
	_enemigo.murio.connect(_on_murio)


func _on_murio() -> void:
	if _habitacion == null:
		return
	if _enemigo.invocado and not soltar_si_invocado:
		return
	if randf() * 100.0 >= probabilidad:
		return
	_habitacion.entregar_piezas(_calcular_piezas())


func _calcular_piezas() -> int:
	if usar_rango:
		return randi_range(mini(piezas_minimas, piezas_maximas), maxi(piezas_minimas, piezas_maximas))
	return piezas


func _buscar_habitacion() -> Habitacion:
	var nodo := get_parent()
	while nodo != null and not nodo is Habitacion:
		nodo = nodo.get_parent()
	return nodo as Habitacion
