class_name PuzleBotones
extends Desafio
## Se resuelve cuando todas las Placa que cuelgan de este nodo están activas a la vez.
## Con placas que solo aceptan caja es el puzle de bloques; con placas que se quedan
## hundidas, el de pisarlas todas, una a una.

var _placas: Array[Placa] = []


func _ready() -> void:
	# Las placas se recogen antes del _ready base, que puede necesitarlas ya (sala resuelta).
	_recoger_placas(self)
	for placa in _placas:
		placa.activada.connect(_comprobar)
	super._ready()


func _recoger_placas(nodo: Node) -> void:
	for hijo in nodo.get_children():
		if hijo is Placa:
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
		placa.forzar_activa()
