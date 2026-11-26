
class_name PuzleBotones
extends Desafio

var _placas: Array[Node] = []
var _cerraduras: Array[Cerradura] = []


func _ready() -> void:
	_recoger_elementos(self)

	if _placas.is_empty() and _cerraduras.is_empty():
		return

	for placa in _placas:
		placa.activada.connect(_comprobar)
		placa.desactivada.connect(_on_placa_desactivada)

	for cerradura in _cerraduras:
		cerradura.abierta_senal.connect(_comprobar)

	super._ready()
	_comprobar()


func _recoger_elementos(nodo: Node) -> void:
	for hijo in nodo.get_children():
		if hijo is Placa or hijo is PlacaInvisible:
			_placas.append(hijo)
		elif hijo is Cerradura and hijo.cuenta_como_requisito:
			_cerraduras.append(hijo)

		_recoger_elementos(hijo)


func _condicion_cumplida() -> bool:
	for placa in _placas:
		if not placa.activa:
			return false

	for cerradura in _cerraduras:
		if not cerradura.abierta:
			return false

	return true


func _comprobar() -> void:
	if esta_resuelto or not _condicion_cumplida():
		return

	resolver()


func _on_placa_desactivada() -> void:
	if esta_resuelto and not _condicion_cumplida():
		desresolver()


func _al_reiniciar() -> void:
	for placa in _placas:
		placa.reiniciar()


func _al_cargar_resuelto() -> void:
	for placa in _placas:
		if placa is Placa:
			placa.forzar_activa()
		else:
			placa.activa = true
