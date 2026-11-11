
class_name PlacaInvisible
extends Area2D
## Placa invisible. Se activa cuando algo válido está encima:
## el jugador, una caja o ambos.

signal activada
signal desactivada

@export_group("Comportamiento")
@export var activa_jugador := true
@export var activa_caja := true
@export var se_queda_activa := false

var activa := false
var _ocupantes: Array[Node2D] = []


func _ready() -> void:
	body_entered.connect(_on_cuerpo_entro)
	body_exited.connect(_on_cuerpo_salio)


## Vuelve a estar desactivada.
func reiniciar() -> void:
	_ocupantes.clear()
	_poner_activa(false)


func _on_cuerpo_entro(cuerpo: Node2D) -> void:
	if _es_valido(cuerpo) and not cuerpo in _ocupantes:
		_ocupantes.append(cuerpo)
		_evaluar()


func _on_cuerpo_salio(cuerpo: Node2D) -> void:
	if cuerpo in _ocupantes:
		_ocupantes.erase(cuerpo)
		_evaluar()


func _es_valido(cuerpo: Node2D) -> bool:
	return (activa_jugador and cuerpo.is_in_group("jugador")) \
		or (activa_caja and cuerpo.is_in_group("caja"))


func _evaluar() -> void:
	if not _ocupantes.is_empty():
		_poner_activa(true)
	elif not se_queda_activa:
		_poner_activa(false)


func _poner_activa(valor: bool) -> void:
	if valor == activa:
		return

	activa = valor

	if activa:
		activada.emit()
	else:
		desactivada.emit()
