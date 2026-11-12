class_name PuzleBotones
extends Desafio
## Se resuelve cuando todas las placas están activas a la vez.

var _placas: Array[Node] = []

func _ready() -> void:
	_recoger_placas(self)
	for placa in _placas:
		placa.activada.connect(_comprobar)
	super._ready()

func _recoger_placas(nodo: Node) -> void:
	for hijo in nodo.get_children():
		if hijo is Placa or hijo is PlacaInvisible:
			_placas.append(hijo)
		_recoger_placas(hijo)

func _comprobar() -> void:
	if _placas.is_empty():
		return
	for placa in _placas:
		if not placa.activa:
			return
	resolver()

func _al_reiniciar() -> void:
	for placa in _placas:
		placa.reiniciar()

func _al_cargar_resuelto() -> void:
	for placa in _placas:
		if placa is Placa:
			placa.forzar_activa()
		else:
			placa.activa = true
